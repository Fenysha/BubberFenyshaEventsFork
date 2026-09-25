/datum/planetmap_view/settlement
	view_type = "settlement"
	window_title = "Settlement Selection"
	can_select_tiles = TRUE
	can_edit = FALSE
	can_regenerate = FALSE
	can_control_time = FALSE

	var/loading = FALSE
	var/mode = "start"

	var/start_x
	var/start_y

	var/join_settlement_id


/datum/planetmap_view/settlement/New(mob/user, datum/rimworld_planet/new_planet, new_mode = "start")
	. = ..(user, new_planet)
	mode = new_mode

	if(mode == "start")
		window_title = "Choose Your Settlement"
		if(isnewplayer(user))
			var/mob/dead/new_player/new_player = user
			new_player.hide_title_screen()
	else
		prevent_close = TRUE
		auto_reopen_on_login = TRUE
		window_title = "Planet Observer"
		if(user?.client)
			user.client.forced_planetmap_view = src

/datum/planetmap_view/settlement/get_view_data()
	var/list/data = list(
		"mode" = mode,
		"isLoading" = loading,
		"startX" = start_x,
		"startY" = start_y,
		"joinSettlementId" = join_settlement_id,
		"canCreate" = (mode == "start" && !isnull(start_x) && !isnull(start_y) && !join_settlement_id),
		"canJoin" = (mode == "start" && !!join_settlement_id),
	)

	if(planet)
		var/list/player_settlements = list()
		for(var/object_id in planet.settlements)
			var/datum/rimworld_planet_object/settlement/sett = planet.settlements[object_id]
			if(!sett)
				continue

			var/faction_id = sett.data["faction"]
			if(!faction_id)
				continue
			var/datum/rw_faction/fac = SSfactions.get_faction(faction_id)
			if(!fac || !fac.player_faction)
				continue

			var/datum/planet_cell/cell = planet.get_cell(sett.x, sett.y)
			if(!cell || !cell.is_generated)
				continue

			player_settlements += list(list(
				"id" = sett.id,
				"name" = sett.name,
				"x" = sett.x,
				"y" = sett.y,
				"population" = sett.data["population"] || 0,
				"faction" = fac.name,
			))

		data["playerSettlements"] = player_settlements

	if(mode == "observer" && planet)
		var/list/loaded = list()
		for(var/key in planet.cells)
			var/datum/planet_cell/cell = planet.cells[key]
			if(!cell || !cell.is_generated)
				continue
			loaded += list(list(
				"x" = cell.x,
				"y" = cell.y,
				"id" = cell.id,
				"name" = cell.get_name() || "[cell.x]:[cell.y]",
			))
		data["loadedCells"] = loaded

	return data


/datum/planetmap_view/settlement/on_select_tile(x, y)
	. = ..()
	if(!.)
		return

	start_x = x
	start_y = y
	join_settlement_id = null

	if(mode == "start" && planet)
		for(var/object_id in planet.settlements)
			var/datum/rimworld_planet_object/settlement/sett = planet.settlements[object_id]
			if(!sett || sett.x != x || sett.y != y)
				continue

			var/faction_id = sett.data["faction"]
			var/datum/rw_faction/fac = faction_id ? SSfactions.get_faction(faction_id) : null
			if(fac && fac.player_faction)
				join_settlement_id = sett.id
				break

	SStgui.update_uis(src)
	return TRUE

/datum/planetmap_view/settlement/handle_close(sucessful)
	if(sucessful && isnewplayer(viewer))
		var/mob/dead/new_player/new_player = viewer
		new_player.show_title_screen()

/datum/planetmap_view/settlement/handle_view_act(action, list/params)
	switch(action)
		if("open_create_setup")
			return open_create_setup()

		if("open_join_setup")
			return open_join_setup(params["id"] || join_settlement_id)

		if("jump_to_cell")
			return jump_to_cell(params)

		if("tile_double_click")
			if(mode == "observer")
				return jump_to_coordinates(params["x"], params["y"])
			return FALSE

		if("select_settlement")
			var/sett_id = params["id"]
			if(!sett_id || !planet)
				return FALSE
			var/datum/rimworld_planet_object/settlement/sett = planet.get_object(sett_id)
			if(!sett)
				return FALSE
			start_x = sett.x
			start_y = sett.y
			join_settlement_id = sett.id
			selected_x = sett.x
			selected_y = sett.y
			SStgui.update_uis(src)
			return TRUE

	return FALSE


/datum/planetmap_view/settlement/proc/open_create_setup()
	if(mode != "start" || !viewer || isnull(start_x) || isnull(start_y))
		return FALSE
	if(join_settlement_id)
		return FALSE

	var/datum/settlement_setup/setup = new(viewer, planet, src, start_x, start_y, null)
	setup.ui_interact(viewer)
	return TRUE


/datum/planetmap_view/settlement/proc/open_join_setup(settlement_id)
	if(mode != "start" || !viewer || !settlement_id)
		return FALSE

	var/datum/rimworld_planet_object/settlement/sett = planet?.get_object(settlement_id)
	if(!sett)
		return FALSE

	var/datum/settlement_setup/setup = new(viewer, planet, src, sett.x, sett.y, sett.id)
	setup.ui_interact(viewer)
	return TRUE


/datum/planetmap_view/settlement/proc/jump_to_cell(list/params)
	if(mode != "observer" || !viewer || !isobserver(viewer))
		return FALSE
	var/x = text2num(params["x"])
	var/y = text2num(params["y"])
	return jump_to_coordinates(x, y)


/datum/planetmap_view/settlement/proc/jump_to_coordinates(x, y)
	if(!planet || !viewer || !isobserver(viewer))
		return FALSE
	if(isnull(x) || isnull(y) || !planet.is_valid_coordinate(x, y))
		return FALSE

	var/datum/planet_cell/cell = planet.get_cell(x, y)
	if(!cell || !cell.is_generated)
		return FALSE

	// TODO: реальный прыжок призрака
	to_chat(viewer, span_notice("Jumped to cell [x]:[y]."))
	return TRUE



/datum/settlement_setup
	var/mob/viewer

	var/datum/rimworld_planet/planet
	var/datum/planetmap_view/settlement/parent_view

	var/target_x
	var/target_y

	var/join_settlement_id

	var/faction_name = "New Colony"
	var/faction_desc = "A fledgling settlement."
	var/faction_icon = "default"
	var/faction_ideology = "placeholder"

	var/datum/planet_cell/loading_cell
	var/loading_error


/datum/settlement_setup/New(mob/user, datum/rimworld_planet/new_planet, datum/planetmap_view/settlement/parent, x, y, existing_id = null)
	viewer = user
	planet = new_planet
	parent_view = parent
	target_x = x
	target_y = y
	join_settlement_id = existing_id

	if(join_settlement_id)
		var/datum/rimworld_planet_object/settlement/sett = planet?.get_object(join_settlement_id)
		if(sett)
			faction_name = sett.name
			var/faction_id = sett.data["faction"]
			var/datum/rw_faction/fac = faction_id ? SSfactions.get_faction(faction_id) : null
			if(fac)
				faction_desc = fac.desc || ""


/datum/settlement_setup/Destroy()
	viewer = null
	planet = null
	parent_view = null
	return ..()


/datum/settlement_setup/proc/fail_loading(message)
	loading_error = message || "Settlement generation failed."

	if(parent_view && !QDELETED(parent_view))
		parent_view.loading = FALSE
		parent_view.prevent_close = FALSE
		parent_view.auto_reopen_on_login = FALSE

	SStgui.update_uis(src)

	return FALSE


/datum/settlement_setup/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SettlementSetup")
		ui.open()


/datum/settlement_setup/ui_state(mob/user)
	return GLOB.always_state


/datum/settlement_setup/ui_data(mob/user)
	var/list/data = list(
		"isJoin" = !!join_settlement_id,
		"isLoading" = parent_view?.loading || FALSE,

		"targetX" = target_x,
		"targetY" = target_y,

		"factionName" = faction_name,
		"factionDesc" = faction_desc,
		"factionIcon" = faction_icon,
		"factionIdeology" = faction_ideology,

		"loadingProgress" = 0,
		"loadingStage" = "Preparing",
		"loadingDetail" = "Preparing local world...",
		"loadingCurrent" = 0,
		"loadingTotal" = 0,
		"loadingUnit" = "steps",
		"loadingError" = loading_error,
	)

	if(loading_cell?.loading_job)
		var/list/progress = loading_cell.loading_job.get_progress_data()

		data["loadingProgress"] = progress["progress"]
		data["loadingStage"] = progress["stage"]
		data["loadingDetail"] = progress["detail"]
		data["loadingCurrent"] = progress["current"]
		data["loadingTotal"] = progress["total"]
		data["loadingUnit"] = progress["unit"]

	if(join_settlement_id && planet)
		var/datum/rimworld_planet_object/settlement/sett = planet.get_object(join_settlement_id)

		if(sett)
			data["settlementName"] = sett.name
			data["population"] = sett.data["population"] || 0

			var/faction_id = sett.data["faction"]
			var/datum/rw_faction/fac = faction_id ? SSfactions.get_faction(faction_id) : null

			if(fac)
				data["factionName"] = fac.name
				data["factionDesc"] = fac.desc || ""

	return data

/datum/settlement_setup/proc/on_load_progress(
	datum/rimworld_sublevel_load_job/job
)
	if(QDELETED(src))
		return

	if(parent_view && !QDELETED(parent_view))
		SStgui.update_uis(src)

/datum/settlement_setup/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("set_faction_name")
			if(join_settlement_id)
				return FALSE
			faction_name = params["name"] || "New Colony"
			return TRUE

		if("set_faction_desc")
			if(join_settlement_id)
				return FALSE
			faction_desc = params["desc"] || ""
			return TRUE

		if("set_faction_icon")
			if(join_settlement_id)
				return FALSE
			faction_icon = params["icon"] || "default"
			return TRUE

		if("set_faction_ideology")
			if(join_settlement_id)
				return FALSE
			faction_ideology = params["ideology"] || "placeholder"
			return TRUE

		if("confirm")
			if(join_settlement_id)
				return do_join()
			return do_create()

		if("cancel")
			SStgui.close_uis(src)
			qdel(src)
			return TRUE

	return FALSE


/datum/settlement_setup/proc/finish_and_close()
	if(parent_view)
		parent_view.prevent_close = FALSE
		parent_view.auto_reopen_on_login = FALSE
		if(viewer?.client)
			viewer.client.forced_planetmap_view = null
		SStgui.close_uis(parent_view)
		qdel(parent_view)

	SStgui.close_uis(src)
	qdel(src)
