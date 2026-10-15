ADMIN_VERB(object_net_view, R_ADMIN, "\[RW\] ObjectNet Monitor", "Open object-net / power overview.", ADMIN_CATEGORY_EVENTS)
	var/datum/object_net_ui/ui_datum = new(usr)
	ui_datum.ui_interact(usr)

/datum/object_net_ui
	var/mob/user
	var/view_z = 0
	var/origin_x = 1
	var/origin_y = 1
	var/grid_size = 48
	var/selected_x = 0
	var/selected_y = 0
	var/net_type = OBJECT_NET_POWER
	/// Bumped to force static_data refresh.
	var/static_rev = 0

/datum/object_net_ui/New(mob/user)
	src.user = user
	var/turf/T = get_turf(user)
	if(T)
		view_z = T.z
		origin_x = max(1, T.x - round(grid_size / 2))
		origin_y = max(1, T.y - round(grid_size / 2))
		selected_x = T.x
		selected_y = T.y

/datum/object_net_ui/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ObjectNetMonitor")
		ui.open()

/datum/object_net_ui/ui_state(mob/user)
	return GLOB.admin_state

/datum/object_net_ui/ui_data(mob/user)
	var/list/data = list()
	data["z"] = view_z
	data["origin_x"] = origin_x
	data["origin_y"] = origin_y
	data["grid_size"] = grid_size
	data["selected_x"] = selected_x
	data["selected_y"] = selected_y
	data["static_rev"] = static_rev
	data["net_type"] = net_type

	// Live power dump from Rust
	var/dump = rustg_power_net_dump()
	var/list/nets_out = list()
	if(length(dump))
		for(var/entry in splittext(dump, "|"))
			var/sep = findtext(entry, ":")
			if(!sep)
				continue
			var/nid = text2num(copytext(entry, 1, sep))
			var/list/p = splittext(copytext(entry, sep + 1), ",")
			if(length(p) < 8)
				continue
			nets_out += list(list(
				"id" = nid,
				"supply" = text2num(p[1]),
				"demand" = text2num(p[2]),
				"stored" = text2num(p[3]),
				"capacity" = text2num(p[4]),
				"producers" = text2num(p[5]),
				"stores" = text2num(p[6]),
				"connectors" = text2num(p[7]),
				"members" = text2num(p[8]),
			))
	data["nets"] = nets_out

	// Selection detail
	if(selected_x && selected_y)
		var/turf/ST = locate(selected_x, selected_y, view_z)
		var/list/nodes_here = list()
		// Scan local node table for anything on this turf
		for(var/i in 1 to length(SSobject_net.node_atoms))
			var/atom/A = SSobject_net.node_atoms[i]
			if(!A)
				continue
			var/turf/AT = get_turf(A)
			if(AT && AT.x == selected_x && AT.y == selected_y && AT.z == view_z)
				nodes_here += list(list(
					"id" = i,
					"net_id" = SSobject_net.node_net[i],
					"type" = SSobject_net.node_type[i],
					"name" = A.name,
					"path" = "[A.type]",
					"consumers" = length(SSobject_net.node_consumers[i]),
				))
		data["selection"] = list(
			"x" = selected_x,
			"y" = selected_y,
			"turf" = ST ? "[ST.type]" : "",
			"nodes" = nodes_here,
		)
	else
		data["selection"] = null

	// Subsystem stats
	var/stats_raw = rustg_object_net_stats("[net_type]")
	var/list/stats = list()
	if(length(stats_raw))
		for(var/pair in splittext(stats_raw, "|"))
			var/eq = findtext(pair, "=")
			if(eq)
				stats[copytext(pair, 1, eq)] = text2num(copytext(pair, eq + 1))
	data["stats"] = stats
	data["ss_nets"] = length(SSobject_net.nets)
	data["ss_active"] = length(SSobject_net.processing_nets)
	data["ss_pending"] = length(SSobject_net.pending_connect)

	return data

/datum/object_net_ui/ui_static_data(mob/user)
	var/list/data = list()
	// Lightweight grid: only mark tiles that have at least one node
	var/list/rows = list()
	var/max_y = origin_y + grid_size - 1
	var/max_x = origin_x + grid_size - 1

	// Build a set of occupied tiles for O(1) lookup
	var/list/occupied = list() // "x,y" -> net_id
	for(var/i in 1 to length(SSobject_net.node_atoms))
		var/atom/A = SSobject_net.node_atoms[i]
		if(!A || SSobject_net.node_type[i] != net_type)
			continue
		var/turf/AT = get_turf(A)
		if(!AT || AT.z != view_z)
			continue
		if(AT.x < origin_x || AT.x > max_x || AT.y < origin_y || AT.y > max_y)
			continue
		occupied["[AT.x],[AT.y]"] = SSobject_net.node_net[i] || 0

	for(var/y = max_y; y >= origin_y; y--)
		var/list/row = list()
		for(var/x = origin_x; x <= max_x; x++)
			var/nid = occupied["[x],[y]"]
			row += list(list(
				"x" = x,
				"y" = y,
				"has_node" = !isnull(nid),
				"net_id" = nid || 0,
			))
		rows += list(row)
		CHECK_TICK
	data["rows"] = rows
	return data

/datum/object_net_ui/proc/push_static()
	static_rev++
	update_static_data_for_all_viewers()

/datum/object_net_ui/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
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
		if("set_net_type")
			net_type = text2num(params["type"]) || OBJECT_NET_POWER
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
		if("reset_rust")
			rustg_object_net_reset("[net_type]")
			push_static()
			return TRUE
