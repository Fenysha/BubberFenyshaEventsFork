ADMIN_VERB(zone_grid_view, R_ADMIN, "\[RW\] Open Zone Grid", "Open rustg zone overview.", ADMIN_CATEGORY_EVENTS)

	var/datum/zone_grid_ui/ui_datum = new(usr)
	ui_datum.ui_interact(usr)

/datum/zone_grid_ui
	var/mob/user
	var/view_z = 0
	var/origin_x = 1
	var/origin_y = 1
	var/grid_size = 64
	var/selected_x = 0
	var/selected_y = 0
	/// Bumped to force static_data refresh on next update.
	var/static_rev = 0

/datum/zone_grid_ui/New(mob/user)
	src.user = user
	var/turf/T = get_turf(user)
	if(T)
		view_z = T.z
		origin_x = max(1, T.x - round(grid_size / 2))
		origin_y = max(1, T.y - round(grid_size / 2))
		selected_x = T.x
		selected_y = T.y

/datum/zone_grid_ui/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ZoneGridInspector")
		ui.open()

/datum/zone_grid_ui/ui_state(mob/user)
	return GLOB.admin_state

/// Light payload — selection + camera only. No per-tile scan.
/datum/zone_grid_ui/ui_data(mob/user)
	var/list/data = list()
	data["z"] = view_z
	data["origin_x"] = origin_x
	data["origin_y"] = origin_y
	data["grid_size"] = grid_size
	data["selected_x"] = selected_x
	data["selected_y"] = selected_y
	data["static_rev"] = static_rev
	data["initialised"] = !!(SSarea_rust?.initialised_z["[view_z]"])

	if(selected_x && selected_y)
		var/list/sel = rustg_area_tile_info(selected_x, selected_y, view_z)
		var/turf/ST = locate(selected_x, selected_y, view_z)
		var/list/bounds = null
		if(sel && sel["area_id"])
			bounds = rustg_area_get_area_bounds(sel["area_id"], view_z)
		data["selection"] = list(
			"x" = selected_x,
			"y" = selected_y,
			"info" = sel,
			"bounds" = bounds,
			"dm_area" = ST?.loc ? ST.loc.name : "",
			"dm_area_type" = ST?.loc ? "[ST.loc.type]" : "",
			"turf_type" = ST ? "[ST.type]" : "",
		)
	else
		data["selection"] = null

	return data

/// Heavy payload — full tile matrix + zone list + stats. Only on open / refresh.
/datum/zone_grid_ui/ui_static_data(mob/user)
	var/list/data = list()
	var/list/stats = rustg_area_get_stats(view_z)
	data["stats"] = stats

	var/list/rows = list()
	var/max_y = origin_y + grid_size - 1
	var/max_x = origin_x + grid_size - 1

	for(var/y = max_y; y >= origin_y; y--)
		var/list/row = list()
		for(var/x = origin_x; x <= max_x; x++)
			var/list/info = rustg_area_tile_info(x, y, view_z)
			var/turf/T = locate(x, y, view_z)
			var/area/A = T?.loc
			row += list(list(
				"x" = x,
				"y" = y,
				"exists" = !!T,
				"is_boundary" = info?["is_boundary"] || 0,
				"area_id" = info?["area_id"] || 0,
				"kind" = info?["kind"] || 0,
				"is_zone" = istype(A, /area/rimworld/zone),
			))
		rows += list(row)
		CHECK_TICK

	data["rows"] = rows

	var/list/zones = list()
	for(var/key in GLOB.rimworld_rust_zones)
		if(findtext(key, "[view_z]_") != 1)
			continue
		var/area/rimworld/zone/Z = GLOB.rimworld_rust_zones[key]
		if(!Z || QDELETED(Z))
			continue
		var/list/b = rustg_area_get_area_bounds(Z.rust_area_id, view_z)
		zones += list(list(
			"key" = key,
			"name" = Z.name,
			"rust_area_id" = Z.rust_area_id,
			"color" = Z.zone_color,
			"size" = b?["size"] || 0,
		))
	data["zones"] = zones
	return data

/datum/zone_grid_ui/proc/push_static()
	static_rev++
	update_static_data_for_all_viewers()

/datum/zone_grid_ui/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("pan")
			var/nx = text2num(params["x"])
			var/ny = text2num(params["y"])
			if(!isnull(nx))
				origin_x = max(1, round(nx))
			if(!isnull(ny))
				origin_y = max(1, round(ny))
			// Camera-only: do not auto-refresh static grid (user hits Refresh).
			return TRUE

		if("set_size")
			grid_size = clamp(text2num(params["size"]) || 32, 8, 64)
			return TRUE

		if("select")
			selected_x = text2num(params["x"]) || 0
			selected_y = text2num(params["y"]) || 0
			return TRUE

		if("center_on_me")
			var/turf/T = get_turf(user)
			if(T)
				view_z = T.z
				origin_x = max(1, T.x - round(grid_size / 2))
				origin_y = max(1, T.y - round(grid_size / 2))
				selected_x = T.x
				selected_y = T.y
				push_static()
			return TRUE

		if("refresh")
			// Apply optional camera from client then rebuild static grid.
			var/nx = text2num(params["x"])
			var/ny = text2num(params["y"])
			var/ns = text2num(params["size"])
			if(!isnull(nx))
				origin_x = max(1, round(nx))
			if(!isnull(ny))
				origin_y = max(1, round(ny))
			if(!isnull(ns))
				grid_size = clamp(round(ns), 8, 64)
			push_static()
			return TRUE

		if("resync")
			var/area/rimworld/parent = null
			var/turf/T = locate(selected_x || origin_x, selected_y || origin_y, view_z)
			if(T)
				parent = resolve_parent_cell_area(T)
			resync_rimworld_zones_on_z(view_z, parent)
			push_static()
			return TRUE

		if("rebuild_rust")
			rustg_area_force_rebuild(view_z)
			push_static()
			return TRUE

		if("jump")
			var/tx = text2num(params["x"])
			var/ty = text2num(params["y"])
			if(tx && ty && user)
				var/turf/T = locate(tx, ty, view_z)
				if(T)
					user.forceMove(T)
			return TRUE
