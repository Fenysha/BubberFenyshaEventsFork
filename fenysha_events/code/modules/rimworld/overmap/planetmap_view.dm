/datum/planetmap_view
	var/mob/viewer
	var/datum/rimworld_planet/planet

	var/view_type = "overview"
	var/window_title = "Planet Map"

	var/can_edit = FALSE
	var/can_regenerate = FALSE
	var/can_select_tiles = TRUE

	var/selected_x
	var/selected_y
	var/selected_object_id

/datum/planetmap_view/New(mob/user, datum/rimworld_planet/new_planet)
	viewer = user
	planet = new_planet
	SSrimworld_planetmap.register_view(src)
	return ..()


/datum/planetmap_view/Destroy()
	SStgui.close_uis(src)
	SSrimworld_planetmap.unregister_view(src)
	viewer = null
	planet = null
	return ..()


/datum/planetmap_view/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)

	if(!ui)
		ui = new(user, src, "RimworldPlanetMap")
		ui.open()


/datum/planetmap_view/ui_state(mob/user)
	return GLOB.always_state


/datum/planetmap_view/ui_close(mob/user)
	. = ..()

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
	return data

/datum/planetmap_view/ui_assets(mob/user)
	return list(get_asset_datum(/datum/asset/simple/rimworld_planet_layers))

/datum/planetmap_view/ui_data(mob/user)
	if(!planet)
		return list()

	var/list/data = planet.get_runtime_data()

	data["viewType"] = view_type
	data["selectedTile"] = get_selected_tile_payload()
	data["selectedObject"] = get_selected_object_payload()
	data["view"] = get_view_data()

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
	if(isnull(selected_x) || isnull(selected_y))
		return null

	if(!planet)
		return null

	var/list/tile = planet.get_tile_data(selected_x, selected_y)

	return tile


/datum/planetmap_view/proc/get_selected_object_payload()
	if(!selected_object_id || !planet)
		return null

	var/datum/rimworld_planet_object/object = planet.get_object(selected_object_id)

	if(!object)
		selected_object_id = null
		return null

	return object.get_data()


/datum/planetmap_view/proc/on_select_tile(x, y)
	if(!can_select_tiles)
		return FALSE

	if(!planet)
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

	if(!planet.get_object(object_id))
		return FALSE

	var/datum/rimworld_planet_object/object = planet.get_object(object_id)

	selected_object_id = object_id
	selected_x = object.x
	selected_y = object.y

	SStgui.update_uis(src)

	return TRUE



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

			if(!on_select_tile(x, y))
				return FALSE

			return TRUE

		if("select_object")
			if(isnull(params["id"]))
				return FALSE

			if(!on_select_object(params["id"]))
				return FALSE

			return TRUE

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


/datum/planetmap_view/admin
	view_type = "admin"
	window_title = "Planet Admin"
	can_edit = TRUE
	can_regenerate = TRUE

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
		var/datum/planet_cell/cell = planet.get_cell(
			selected_x,
			selected_y
		)

		if(cell)
			data["cell"] = cell.get_data()

	return data

/datum/planetmap_view/admin/clear_selection()
	. = ..()
	road_start_x = null
	road_start_y = null


/datum/planetmap_view/admin/handle_view_act(action, list/params)
	switch(action)
		if("toggle_rotation")
			if(planet)
				planet.auto_rotate = !planet.auto_rotate
				SStgui.update_uis(src)
			return TRUE

		if("set_rotation_speed")
			if(planet && !isnull(params["speed"]))
				planet.rotation_speed = text2num(params["speed"])
				SStgui.update_uis(src)
			return TRUE

		if("set_rotation_angle")
			if(planet && !isnull(params["angle"]))
				planet.rotation_angle = text2num(params["angle"])
				SStgui.update_uis(src)
			return TRUE

		if("regenerate")
			if(!can_regenerate)
				return FALSE

			var/planet_type = params["planetType"] || planet.planet_type
			var/planet_seed = text2num(params["seed"])

			if(!planet_seed)
				planet_seed = null

			var/list/custom_params = list()
			var/list/param_keys = list(
				"terrainSeed",
				"heatSeed",
				"humiditySeed",
				"geologySeed",
				"precipitationSeed",
				"noiseScale",
				"terrainScale",
				"heatScale",
				"humidityScale",
				"geologyScale",
				"precipitationScale",
				"elevationCoastLow",
				"elevationCoastHigh",
				"elevationLowlandLow",
				"elevationLowlandHigh",
				"elevationHighlandLow",
				"elevationHighlandHigh",
				"elevationMountainLow",
				"elevationMountainHigh",
				"elevationSnowLow",
				"elevationSnowHigh",
				"heatThresholdLow",
				"heatThresholdHigh",
				"humidityThresholdLow",
				"humidityThresholdHigh"
			)

			for(var/key in param_keys)
				if(!isnull(params[key]))
					custom_params[key] = text2num(params[key])

			SSrimworld_planetmap.generate_planet(
				planet_type,
				planet_seed,
				custom_params
			)

			SStgui.try_update_ui(usr, src)
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


/datum/planetmap_view/admin/proc/place_settlement(list/params)
	if(!can_edit)
		return FALSE

	var/x = text2num(params["x"])
	var/y = text2num(params["y"])

	if(isnull(x))
		x = selected_x

	if(isnull(y))
		y = selected_y

	var/settlement_name = params["name"] || "Settlement"
	var/datum/rimworld_planet_object/object = planet.create_settlement(x, y, settlement_name)

	if(!object)
		return FALSE

	selected_object_id = object.id
	selected_x = object.x
	selected_y = object.y
	return TRUE

/datum/planetmap_view/admin/proc/get_selected_cell()
	if(!planet)
		return null

	if(isnull(selected_x) || isnull(selected_y))
		return null

	return planet.get_or_create_cell(
		selected_x,
		selected_y,
		FALSE
	)


/datum/planetmap_view/admin/proc/load_selected_cell()
	if(!can_edit)
		return FALSE

	var/datum/planet_cell/cell = get_selected_cell()
	if(!cell)
		return FALSE

	if(!cell.ensure_loaded())
		return FALSE

	SStgui.update_uis(src)
	return TRUE


/datum/planetmap_view/admin/proc/unload_selected_cell()
	if(!can_edit)
		return FALSE

	var/datum/planet_cell/cell = planet.get_cell(
		selected_x,
		selected_y
	)

	if(!cell)
		return FALSE

	if(!cell.unload())
		return FALSE

	SStgui.update_uis(src)
	return TRUE


/datum/planetmap_view/admin/proc/reload_selected_cell()
	if(!can_edit)
		return FALSE

	var/datum/planet_cell/cell = get_selected_cell()
	if(!cell)
		return FALSE

	if(!cell.reload())
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
			object = planet.create_settlement(
				x,
				y,
				object_name
			)

		if("poi")
			object = planet.create_point_of_interest(
				x,
				y,
				object_name
			)

		if("road")
			var/start_x = text2num(params["startX"])
			var/start_y = text2num(params["startY"])

			if(isnull(start_x))
				start_x = road_start_x

			if(isnull(start_y))
				start_y = road_start_y

			if(isnull(start_x) || isnull(start_y))
				return FALSE

			object = planet.create_road(
				start_x,
				start_y,
				x,
				y
			)

		else
			return FALSE

	if(!object)
		return FALSE

	selected_object_id = object.id
	selected_x = object.x
	selected_y = object.y

	var/load_immediately = !!params["loadImmediately"]

	if(load_immediately)
		var/datum/planet_cell/cell = planet.get_or_create_cell(
			object.x,
			object.y,
			FALSE
		)

		if(cell)
			cell.ensure_loaded(object.name)

	road_start_x = null
	road_start_y = null

	SStgui.update_uis(src)
	return TRUE

/datum/planetmap_view/admin/proc/remove_selected_object(list/params)
	if(!can_edit)
		return FALSE

	var/object_id = params["id"] || selected_object_id

	if(!planet.remove_object(object_id))
		return FALSE

	if(selected_object_id == object_id)
		selected_object_id = null

	return TRUE


/datum/planetmap_view/admin/proc/move_selected_object(list/params)
	if(!can_edit)
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
