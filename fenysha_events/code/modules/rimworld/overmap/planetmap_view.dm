/client
	var/datum/planetmap_view/forced_planetmap_view

/client/proc/try_reopen_forced_planetmap()
	if(!forced_planetmap_view || QDELETED(forced_planetmap_view))
		forced_planetmap_view = null
		return

	var/datum/planetmap_view/view = forced_planetmap_view
	if(!view.auto_reopen_on_login)
		return

	view.viewer = mob
	view.ui_interact(mob)


/mob/Login()
	. = ..()
	if(client)
		client.try_reopen_forced_planetmap()

/datum/planetmap_view
	var/mob/viewer
	var/datum/rimworld_planet/planet

	var/view_type = "overview"
	var/window_title = "Planet Map"

	var/can_edit = FALSE
	var/can_regenerate = FALSE
	var/can_select_tiles = TRUE
	/// Admin (and future) views that may change calendar / time of day
	var/can_control_time = FALSE

	var/selected_x
	var/selected_y
	var/selected_object_id

	var/prevent_close = FALSE
	var/auto_reopen_on_login = FALSE
	var/client/owner_client

/datum/planetmap_view/New(mob/user, datum/rimworld_planet/new_planet)
	viewer = user
	planet = new_planet
	if(user?.client)
		owner_client = user.client
	SSrimworld_planetmap.register_view(src)
	return ..()


/datum/planetmap_view/Destroy()
	SStgui.close_uis(src)
	SSrimworld_planetmap.unregister_view(src)

	if(owner_client)
		if(owner_client.forced_planetmap_view == src)
			owner_client.forced_planetmap_view = null
		owner_client = null

	viewer = null
	planet = null
	return ..()

/datum/planetmap_view/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new /datum/tgui/map_embedded(user, src, "RimworldPlanetMap")
		ui.open()


/datum/planetmap_view/ui_state(mob/user)
	return GLOB.always_state


/datum/planetmap_view/ui_close(mob/user)
	. = ..()
	if(auto_reopen_on_login)
		SSrimworld_planetmap.clear_view(user, src)
		if(!QDELING(src))
			qdel(src)


/datum/planetmap_view/ui_static_data(mob/user)
	if(!planet)
		return list()

	var/list/data = planet.get_generator_data()
	data["viewType"] = view_type
	data["windowTitle"] = window_title
	data["canEdit"] = can_edit
	data["canRegenerate"] = can_regenerate
	data["canSelectTiles"] = can_select_tiles
	data["canControlTime"] = can_control_time

	var/list/rotation = SSrimworld_planetmap.get_rotation_data()
	data["autoRotate"] = rotation["autoRotate"]
	data["rotationSpeed"] = rotation["rotationSpeed"]
	data["rotationAngle"] = rotation["rotationAngle"]

	data["daysPerYear"] = RW_DAYS_PER_YEAR
	data["daysPerQuadrum"] = RW_DAYS_PER_QUADRUM
	data["quadrumNames"] = RW_QUADRUM_NAMES
	data["seasons"] = list(RW_SEASON_SPRING, RW_SEASON_SUMMER, RW_SEASON_FALL, RW_SEASON_WINTER)
	data["startingYear"] = RW_STARTING_YEAR

	return data


/datum/planetmap_view/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/simple/rimworld_planet_layers),
		get_asset_datum(/datum/asset/simple/rimworld_planet_icons),
	)


/datum/planetmap_view/ui_data(mob/user)
	if(!planet)
		return list()

	var/list/data = planet.get_runtime_data()

	data["viewType"] = view_type
	data["selectedTile"] = get_selected_tile_payload()
	data["selectedObject"] = get_selected_object_payload()
	data["view"] = get_view_data()

	var/list/rotation = SSrimworld_planetmap.get_rotation_data()
	data["rotationAngle"] = rotation["rotationAngle"]
	data["autoRotate"] = rotation["autoRotate"]
	data["rotationSpeed"] = rotation["rotationSpeed"]

	var/list/calendar = SSrimworld_planetmap.get_calendar_data()
	data["calendar"] = calendar
	data["timeOfDay"] = calendar["timeOfDay"]
	data["currentYear"] = calendar["year"]
	data["dayOfYear"] = calendar["dayOfYear"]
	data["quadrum"] = calendar["quadrum"]
	data["quadrumName"] = calendar["quadrumName"]
	data["dayOfQuadrum"] = calendar["dayOfQuadrum"]
	data["seasonNorth"] = calendar["seasonNorth"]
	data["seasonSouth"] = calendar["seasonSouth"]
	data["timeScale"] = calendar["timeScale"]

	return data


/datum/planetmap_view/proc/bind_planet(datum/rimworld_planet/new_planet)
	planet = new_planet
	clear_selection()
	update_static_data_for_all_viewers()
	SStgui.update_uis(src)


/datum/planetmap_view/proc/refresh()
	update_static_data_for_all_viewers()
	SStgui.update_uis(src)


/datum/planetmap_view/proc/clear_selection()
	selected_x = null
	selected_y = null
	selected_object_id = null


/datum/planetmap_view/proc/get_view_data()
	return list()


/datum/planetmap_view/proc/get_selected_tile_payload()
	if(isnull(selected_x) || isnull(selected_y) || !planet)
		return null
	return planet.get_tile_data(selected_x, selected_y)


/datum/planetmap_view/proc/get_selected_object_payload()
	if(!selected_object_id || !planet)
		return null
	var/datum/rimworld_planet_object/object = planet.get_object(selected_object_id)
	if(!object)
		selected_object_id = null
		return null
	return object.get_data()


/datum/planetmap_view/proc/on_select_tile(x, y)
	if(!can_select_tiles || !planet)
		return FALSE
	if(!planet.is_valid_coordinate(x, y))
		return FALSE
	selected_x = x
	selected_y = y
	SStgui.update_uis(src)
	return TRUE


/datum/planetmap_view/proc/on_select_object(object_id)
	if(!planet)
		return FALSE
	var/datum/rimworld_planet_object/object = planet.get_object(object_id)
	if(!object)
		return FALSE
	selected_object_id = object_id
	selected_x = object.x
	selected_y = object.y
	SStgui.update_uis(src)
	return TRUE


/datum/planetmap_view/proc/handle_close(sucessful = FALSE)
	return

/datum/planetmap_view/proc/handle_view_act(action, list/params)
	return FALSE


/datum/planetmap_view/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	if(!planet)
		return

	switch(action)
		if("close")
			if(prevent_close)
				handle_close()
				return TRUE
			handle_close(TRUE)
			SStgui.close_uis(src)
			return TRUE

		if("select_tile")
			var/x = params["x"]
			var/y = params["y"]
			if(!isnum(x))
				x = text2num("[x]")
			if(!isnum(y))
				y = text2num("[y]")
			if(isnull(x) || isnull(y))
				return FALSE
			return on_select_tile(x, y)

		if("select_object")
			if(isnull(params["id"]))
				return FALSE
			return on_select_object(params["id"])

	return handle_view_act(action, params)

/datum/planetmap_view/overview
	view_type = "overview"
	window_title = "Planet Overview"

/datum/planetmap_view/caravan
	view_type = "caravan"
	window_title = "Caravan Map"

	var/caravan_id
	var/origin_x
	var/origin_y
	var/destination_x
	var/destination_y


/datum/planetmap_view/caravan/New(mob/user, datum/rimworld_planet/new_planet, new_caravan_id = null, new_origin_x = null, new_origin_y = null)
	. = ..(user, new_planet)
	caravan_id = new_caravan_id
	origin_x = new_origin_x
	origin_y = new_origin_y


/datum/planetmap_view/caravan/get_view_data()
	return list(
		"caravanId" = caravan_id,
		"originX" = origin_x,
		"originY" = origin_y,
		"destinationX" = destination_x,
		"destinationY" = destination_y,
		"canTravel" = FALSE,
		"status" = "Caravan travel is not implemented yet.",
	)


/datum/planetmap_view/caravan/on_select_tile(x, y)
	. = ..()
	if(!.)
		return
	destination_x = x
	destination_y = y


/datum/planetmap_view/caravan/handle_view_act(action, list/params)
	switch(action)
		if("travel")
			return FALSE
	return FALSE


// ── Admin ───────────────────────────────────────────────────────────────────

/datum/planetmap_view/admin
	view_type = "admin"
	window_title = "Planet Admin"
	can_edit = TRUE
	can_regenerate = TRUE
	can_control_time = TRUE

	var/road_start_x
	var/road_start_y


/datum/planetmap_view/admin/ui_state(mob/user)
	return ADMIN_STATE(R_ADMIN)


/datum/planetmap_view/admin/get_view_data()
	var/list/data = list(
		"roadStartX" = road_start_x,
		"roadStartY" = road_start_y,
	)
	if(planet && !isnull(selected_x) && !isnull(selected_y))
		var/datum/planet_cell/cell = planet.get_cell(selected_x, selected_y)
		if(cell)
			data["cell"] = cell.get_data()
	return data


/datum/planetmap_view/admin/clear_selection()
	. = ..()
	road_start_x = null
	road_start_y = null


/datum/planetmap_view/admin/handle_view_act(action, list/params)
	switch(action)
		// ── Rotation ────────────────────────────────────────────────────────
		if("toggle_rotation")
			SSrimworld_planetmap.set_auto_rotate(!SSrimworld_planetmap.auto_rotate)
			SStgui.update_uis(src)
			return TRUE

		if("set_rotation_speed")
			if(isnull(params["speed"]))
				return FALSE
			SSrimworld_planetmap.set_rotation_speed(text2num(params["speed"]))
			SStgui.update_uis(src)
			return TRUE

		if("set_rotation_angle")
			if(isnull(params["angle"]))
				return FALSE
			SSrimworld_planetmap.set_rotation_angle(text2num(params["angle"]))
			SStgui.update_uis(src)
			return TRUE

		// ── Calendar / time ─────────────────────────────────────────────────
		if("set_time_of_day")
			if(!can_control_time || isnull(params["hour"]))
				return FALSE
			SSrimworld_planetmap.set_time_of_day(text2num(params["hour"]))
			SStgui.update_uis(src)
			return TRUE

		if("set_time_scale")
			if(!can_control_time || isnull(params["scale"]))
				return FALSE
			SSrimworld_planetmap.set_time_scale(text2num(params["scale"]))
			SStgui.update_uis(src)
			return TRUE

		if("toggle_advance_calendar")
			if(!can_control_time)
				return FALSE
			SSrimworld_planetmap.set_advance_calendar(!SSrimworld_planetmap.advance_calendar)
			SStgui.update_uis(src)
			return TRUE

		if("timeskip_days")
			if(!can_control_time || isnull(params["days"]))
				return FALSE
			SSrimworld_planetmap.timeskip_days(text2num(params["days"]))
			SStgui.update_uis(src)
			return TRUE

		if("set_calendar")
			if(!can_control_time)
				return FALSE
			var/year = text2num(params["year"])
			var/doy = text2num(params["dayOfYear"])
			var/hour = params["hour"]
			if(!isnull(hour))
				hour = text2num(hour)
			if(isnull(year) || isnull(doy))
				return FALSE
			SSrimworld_planetmap.set_calendar(year, doy, hour)
			SStgui.update_uis(src)
			return TRUE

		if("set_quadrum")
			if(!can_control_time || isnull(params["quadrum"]))
				return FALSE
			// Accept "0".."3" or numeric index
			var/q = params["quadrum"]
			if(isnum(q))
				q = num2text(q)
			SSrimworld_planetmap.set_quadrum(q)
			SStgui.update_uis(src)
			return TRUE

		if("set_season_north")
			if(!can_control_time || isnull(params["season"]))
				return FALSE
			if(!SSrimworld_planetmap.set_season_north(params["season"]))
				return FALSE
			SStgui.update_uis(src)
			return TRUE

		// ── Regeneration ────────────────────────────────────────────────────
		if("regenerate")
			if(!can_regenerate)
				return FALSE
			var/planet_type = params["planetType"] || planet?.planet_type || RW_PLANET_PRESET_TERRAN
			var/planet_seed = text2num(params["seed"])
			if(!planet_seed)
				planet_seed = null
			var/list/custom_params = list()
			for(var/key in list("mountains", "ocean", "humidity", "temperature", "population"))
				if(!isnull(params[key]))
					custom_params[key] = text2num(params[key])
			SSrimworld_planetmap.generate_planet(planet_type, planet_seed, custom_params)
			return TRUE

		if("load_cell")
			return load_selected_cell()
		if("unload_cell")
			return unload_selected_cell()
		if("reload_cell")
			return reload_selected_cell()
		if("create_object")
			return create_object(params)
		if("remove_object")
			return remove_selected_object(params)
		if("move_object")
			return move_selected_object(params)

		if("mark_road_start")
			if(isnull(selected_x) || isnull(selected_y))
				return FALSE
			road_start_x = selected_x
			road_start_y = selected_y
			SStgui.update_uis(src)
			return TRUE

		if("clear_road_start")
			road_start_x = null
			road_start_y = null
			SStgui.update_uis(src)
			return TRUE

	return FALSE


/datum/planetmap_view/admin/proc/get_selected_cell()
	if(!planet || isnull(selected_x) || isnull(selected_y))
		return null
	return planet.get_or_create_cell(selected_x, selected_y, FALSE)


/datum/planetmap_view/admin/proc/load_selected_cell()
	if(!can_edit)
		return FALSE
	var/datum/planet_cell/cell = get_selected_cell()
	if(!cell || !cell.ensure_loaded())
		return FALSE
	SStgui.update_uis(src)
	return TRUE


/datum/planetmap_view/admin/proc/unload_selected_cell()
	if(!can_edit || !planet)
		return FALSE
	var/datum/planet_cell/cell = planet.get_cell(selected_x, selected_y)
	if(!cell || !cell.unload())
		return FALSE
	SStgui.update_uis(src)
	return TRUE


/datum/planetmap_view/admin/proc/reload_selected_cell()
	if(!can_edit)
		return FALSE
	var/datum/planet_cell/cell = get_selected_cell()
	if(!cell || !cell.reload())
		return FALSE
	SStgui.update_uis(src)
	return TRUE


/datum/planetmap_view/admin/proc/create_object(list/params)
	if(!can_edit || !planet)
		return FALSE
	var/object_type = lowertext(params["type"])
	var/x = text2num(params["x"])
	var/y = text2num(params["y"])
	if(isnull(x))
		x = selected_x
	if(isnull(y))
		y = selected_y
	if(isnull(x) || isnull(y))
		return FALSE
	var/object_name = params["name"] || "Object"
	var/datum/rimworld_planet_object/object
	switch(object_type)
		if("settlement")
			object = planet.create_settlement(x, y, object_name)
		if("poi")
			object = planet.create_point_of_interest(x, y, object_name)
		if("road")
			var/start_x = text2num(params["startX"])
			var/start_y = text2num(params["startY"])
			if(isnull(start_x))
				start_x = road_start_x
			if(isnull(start_y))
				start_y = road_start_y
			if(isnull(start_x) || isnull(start_y))
				return FALSE
			object = planet.create_road(start_x, start_y, x, y)
		else
			return FALSE
	if(!object)
		return FALSE
	selected_object_id = object.id
	selected_x = object.x
	selected_y = object.y
	if(!!params["loadImmediately"])
		var/datum/planet_cell/cell = planet.get_or_create_cell(object.x, object.y, FALSE)
		if(cell)
			cell.ensure_loaded(object.name)
	road_start_x = null
	road_start_y = null
	SStgui.update_uis(src)
	return TRUE


/datum/planetmap_view/admin/proc/remove_selected_object(list/params)
	if(!can_edit || !planet)
		return FALSE
	var/object_id = params["id"] || selected_object_id
	if(!planet.remove_object(object_id))
		return FALSE
	if(selected_object_id == object_id)
		selected_object_id = null
	return TRUE


/datum/planetmap_view/admin/proc/move_selected_object(list/params)
	if(!can_edit || !planet)
		return FALSE
	var/object_id = params["id"] || selected_object_id
	var/new_x = text2num(params["x"])
	var/new_y = text2num(params["y"])
	if(isnull(new_x))
		new_x = selected_x
	if(isnull(new_y))
		new_y = selected_y
	if(!planet.move_object(object_id, new_x, new_y))
		return FALSE
	selected_object_id = object_id
	selected_x = new_x
	selected_y = new_y
	return TRUE
