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

/**
 * Returns the viewer's planet-map tile (1-based) if they are inside a loaded cell of this planet.
 * null if not on the map / not in a cell.
 */
/datum/planetmap_view/proc/get_viewer_planet_position(mob/user)
	if(!user || !planet)
		return null

	var/turf/T = get_turf(user)
	if(!T)
		return null

	var/datum/planet_cell/cell = get_planet_cell(T)
	if(!cell)
		return null

	// Only show marker when the cell belongs to the planet this view is bound to
	if(cell.planet && cell.planet != planet)
		return null

	if(!planet.is_valid_coordinate(cell.x, cell.y))
		return null

	return list("x" = cell.x, "y" = cell.y)


/**
 * Payload for the avatar marker on the planet surface:
 * list("x", "y", "icon") where icon is a base64 PNG of the atom's appearance, or null.
 * Override in caravan (and similar) views that are not physically on a cell.
 */
/datum/planetmap_view/proc/get_map_avatar_payload(mob/user)
	var/list/pos = get_viewer_planet_position(user)
	if(!pos)
		return null

	return list(
		"x" = pos["x"],
		"y" = pos["y"],
		"icon" = get_atom_map_icon_b64(user),
	)


/**
 * Renders an atom's current appearance to a base64 PNG for the planet map UI.
 * Same pattern as trader portraits: getFlatIcon(atom, SOUTH, start = FALSE).
 */
/proc/get_atom_map_icon_b64(atom/A)
	if(!A)
		return null
	var/icon/flat = getFlatIcon(A, SOUTH, start = FALSE)
	if(!flat)
		return null
	return icon2base64(flat)


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
	data["canControlTime"] = can_control_time || check_rights_for(user?.client, R_ADMIN)

	data["staticObjects"] = planet.get_static_objects()
	// tgui lets static data win over live data for the same key, so anything that changes stays out of here.
	data -= "autoRotate"

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
	data["objects"] = get_visible_objects()

	var/list/rotation = SSrimworld_planetmap.get_rotation_data()
	data["rotationAngle"] = rotation["rotationAngle"]
	data["autoRotate"] = rotation["autoRotate"]
	data["rotationSpeed"] = rotation["rotationSpeed"]
	data["dayLengthMinutes"] = rotation["dayLengthMinutes"]

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

	// Avatar marker on the global hex map (position + optional appearance icon)
	var/list/avatar = get_map_avatar_payload(user)
	if(avatar)
		data["playerX"] = avatar["x"]
		data["playerY"] = avatar["y"]
		data["playerIcon"] = avatar["icon"]
	else
		data["playerX"] = null
		data["playerY"] = null
		data["playerIcon"] = null

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


/datum/planetmap_view/proc/objects_of_types(list/allowed_types)
	var/list/result = list()
	if(!planet)
		return result
	for(var/object_id in planet.objects)
		var/datum/rimworld_planet_object/object = planet.objects[object_id]
		if(!object || !(object.object_type in allowed_types))
			continue
		result += list(object.get_data())
	return result


/// Overview and any view without its own filter see settlements only.
/datum/planetmap_view/proc/get_visible_objects()
	return planet ? planet.get_dynamic_objects() : list()


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

		if("set_time_of_day")
			if(!can_control_time)
				return FALSE
			var/hour = text2num(params["hour"])
			if(isnull(hour))
				return FALSE
			SSrimworld_planetmap.set_time_of_day(hour)
			log_admin("[key_name(ui.user)] turned the planet clock to [SSrimworld_planetmap.time_of_day] from the planet map")
			SStgui.update_uis(src)
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

		if("tile_double_click")
			var/dx = params["x"]
			var/dy = params["y"]
			if(!isnum(dx))
				dx = text2num("[dx]")
			if(!isnum(dy))
				dy = text2num("[dy]")
			if(isnull(dx) || isnull(dy))
				return FALSE
			return on_tile_double_click(dx, dy)

	return handle_view_act(action, params)


/datum/planetmap_view/proc/on_tile_double_click(x, y)
	return on_select_tile(x, y)

/datum/planetmap_view/overview
	view_type = "overview"
	window_title = "Planet Overview"

/datum/planetmap_view/caravan
	view_type = "caravan"
	window_title = "Caravan Map"
	prevent_close = TRUE
	auto_reopen_on_login = TRUE

	var/caravan_id
	var/origin_x
	var/origin_y
	var/destination_x
	var/destination_y

	var/datum/rimworld_caravan/caravan


/datum/planetmap_view/caravan/New(mob/user, datum/rimworld_planet/new_planet, new_caravan_id = null, new_origin_x = null, new_origin_y = null)
	. = ..(user, new_planet)
	caravan_id = new_caravan_id
	origin_x = new_origin_x
	origin_y = new_origin_y
	if(caravan_id)
		caravan = get_rimworld_caravan(caravan_id)
		if(caravan)
			bind_caravan(caravan)


/datum/planetmap_view/caravan/Destroy()
	if(caravan)
		caravan.bound_views -= src
		caravan = null
	return ..()


/datum/planetmap_view/caravan/proc/bind_caravan(datum/rimworld_caravan/C)
	caravan = C
	if(!C)
		return
	caravan_id = C.id
	origin_x = C.origin_x
	origin_y = C.origin_y
	destination_x = C.destination_x
	destination_y = C.destination_y
	C.bound_views |= src


/datum/planetmap_view/caravan/get_view_data()
	sync_from_caravan()

	var/list/member_names = list()
	var/list/nearby_caravans = list()
	var/list/pending_merges = list()
	var/list/pending_attacks = list()
	var/is_leader = FALSE
	var/status = "Idle"
	var/can_travel = FALSE
	var/can_enter = FALSE
	var/in_arena = FALSE

	if(caravan && !QDELETED(caravan))
		is_leader = caravan.is_leader(viewer)
		can_enter = !caravan.active_arena && !caravan.moving
		in_arena = !!caravan.active_arena
		can_travel = is_leader && !isnull(caravan.destination_x) && !caravan.moving && !in_arena

		if(caravan.moving)
			status = "Travelling"
		else if(in_arena)
			status = "In combat"
		else if(!isnull(caravan.destination_x))
			status = "Destination set"
		else
			status = "Idle"

		for(var/mob/living/M as anything in caravan.members)
			member_names += M.real_name || M.name

		for(var/datum/rimworld_caravan/other as anything in get_caravans_at(planet, caravan.current_x, caravan.current_y))
			if(other == caravan || QDELETED(other))
				continue
			nearby_caravans += list(list(
				"id" = other.id,
				"leader" = other.leader?.real_name || other.leader?.name || "?",
				"members" = length(other.members),
				"hasVehicle" = !!other.vehicle,
			))

		for(var/req_id in caravan.pending_merge_from)
			pending_merges += req_id
		for(var/req_id in caravan.pending_attack_from)
			pending_attacks += req_id

	return list(
		"caravanId" = caravan_id,
		"originX" = origin_x,
		"originY" = origin_y,
		"currentX" = caravan?.current_x,
		"currentY" = caravan?.current_y,
		"destinationX" = destination_x,
		"destinationY" = destination_y,
		"canTravel" = can_travel,
		"canEnter" = can_enter,
		"isLeader" = is_leader,
		"inArena" = in_arena,
		"status" = status,
		"members" = member_names,
		"hasVehicle" = !!(caravan?.vehicle),
		"hasInterior" = !!(caravan?.has_interior),
		"nearbyCaravans" = nearby_caravans,
		"pendingMerges" = pending_merges,
		"pendingAttacks" = pending_attacks,
		"path" = caravan?.get_route_ui() || list(),
	)


/datum/planetmap_view/caravan/proc/sync_from_caravan()
	if(!caravan || QDELETED(caravan))
		return
	caravan_id = caravan.id
	origin_x = caravan.origin_x
	origin_y = caravan.origin_y
	destination_x = caravan.destination_x
	destination_y = caravan.destination_y


/datum/planetmap_view/caravan/get_visible_objects()
	var/list/result = list()
	if(!planet)
		return result
	for(var/object_id in planet.objects)
		var/datum/rimworld_planet_object/object = planet.objects[object_id]
		if(!object)
			continue
		if(object.object_type == RW_OBJECT_TYPE_SETTLEMENT || on_caravan_route(object))
			result += list(object.get_data())
	return result


/datum/planetmap_view/caravan/proc/on_caravan_route(datum/rimworld_planet_object/object)
	if(tile_is_endpoint(object.x, object.y))
		return TRUE
	if(!istype(object, /datum/rimworld_planet_object/road))
		return FALSE
	var/datum/rimworld_planet_object/road/road = object
	return tile_is_endpoint(road.start_x, road.start_y) || tile_is_endpoint(road.end_x, road.end_y)


/datum/planetmap_view/caravan/proc/tile_is_endpoint(x, y)
	if(!isnull(origin_x) && x == origin_x && y == origin_y)
		return TRUE
	if(!isnull(destination_x) && x == destination_x && y == destination_y)
		return TRUE
	if(caravan && x == caravan.current_x && y == caravan.current_y)
		return TRUE
	return FALSE


/datum/planetmap_view/caravan/on_select_tile(x, y)
	. = ..()
	if(!.)
		return
	if(!caravan || QDELETED(caravan))
		return FALSE
	if(!caravan.is_leader(viewer))
		to_chat(viewer, span_warning("Only the caravan leader can set a destination."))
		return FALSE
	if(caravan.active_arena)
		to_chat(viewer, span_warning("You cannot travel while in combat."))
		return FALSE

	if(!caravan.set_destination(x, y))
		to_chat(viewer, span_warning("No route to that tile."))
		return FALSE
	destination_x = caravan.destination_x
	destination_y = caravan.destination_y
	return TRUE


/// Double-click sets destination and immediately starts travel.
/datum/planetmap_view/caravan/on_tile_double_click(x, y)
	if(!on_select_tile(x, y))
		return FALSE
	if(!caravan || QDELETED(caravan))
		return FALSE
	if(!caravan.is_leader(viewer))
		return FALSE
	return caravan.start_travel()


/// Caravan avatar uses overmap coordinates + vehicle/leader appearance.
/datum/planetmap_view/caravan/get_map_avatar_payload(mob/user)
	if(!caravan || QDELETED(caravan))
		return null
	if(isnull(caravan.current_x) || isnull(caravan.current_y))
		return null
	if(!planet?.is_valid_coordinate(caravan.current_x, caravan.current_y))
		return null

	return list(
		"x" = caravan.current_x,
		"y" = caravan.current_y,
		"icon" = caravan.get_map_icon_b64(),
	)


/datum/planetmap_view/caravan/handle_view_act(action, list/params)
	if(!caravan || QDELETED(caravan))
		return FALSE

	switch(action)
		if("travel")
			if(!caravan.is_leader(viewer))
				return FALSE
			return caravan.start_travel()

		if("stop_travel")
			if(!caravan.is_leader(viewer))
				return FALSE
			caravan.stop_travel()
			return TRUE

		if("enter_tile")
			return caravan.enter_current_tile()

		if("request_merge")
			var/target_id = params["id"]
			var/datum/rimworld_caravan/target = get_rimworld_caravan(target_id)
			if(!target)
				return FALSE
			return caravan.request_merge(target)

		if("accept_merge")
			if(!caravan.is_leader(viewer))
				return FALSE
			return caravan.accept_merge(params["id"])

		if("deny_merge")
			if(!caravan.is_leader(viewer))
				return FALSE
			return caravan.deny_merge(params["id"])

		if("request_attack")
			var/target_id = params["id"]
			var/datum/rimworld_caravan/target = get_rimworld_caravan(target_id)
			if(!target)
				return FALSE
			return caravan.request_attack(target)

		if("accept_attack")
			if(!caravan.is_leader(viewer))
				return FALSE
			return caravan.accept_attack(params["id"])

		if("deny_attack")
			if(!caravan.is_leader(viewer))
				return FALSE
			return caravan.deny_attack(params["id"])

		if("split")
			if(!caravan.is_leader(viewer))
				return FALSE
			// Split self out if alone request; full member picker left as stub
			var/list/to_split = list(viewer)
			var/datum/rimworld_caravan/fresh = caravan.split_members(to_split, viewer)
			return !!fresh

		// Stubs — wire to your existing UIs later
		if("open_health")
			to_chat(viewer, span_notice("Health UI stub."))
			return TRUE

		if("view_persona")
			to_chat(viewer, span_notice("Persona UI stub."))
			return TRUE

		if("view_faction")
			to_chat(viewer, span_notice("Faction UI stub."))
			return TRUE

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


/datum/planetmap_view/admin/get_visible_objects()
	if(!planet)
		return list()
	return planet.get_interactive_objects()


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

		if("set_day_length")
			if(!can_control_time || isnull(params["minutes"]))
				return FALSE
			SSrimworld_planetmap.set_day_length_minutes(text2num(params["minutes"]))
			SStgui.update_uis(src)
			return TRUE

		if("set_rotation_angle")
			if(isnull(params["angle"]))
				return FALSE
			SSrimworld_planetmap.set_rotation_angle(text2num(params["angle"]))
			SStgui.update_uis(src)
			return TRUE

		// ── Calendar / time ─────────────────────────────────────────────────
		if("set_time_scale")
			return FALSE

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
