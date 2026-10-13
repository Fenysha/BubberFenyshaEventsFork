ADMIN_VERB(storyteller_admin, R_ADMIN, "Storyteller UI", "Open the RimWorld storyteller and cell planning panel.", ADMIN_CATEGORY_STORYTELLER)
	var/datum/storyteller_admin_ui/ui = new
	ui.ui_interact(usr)

/datum/storyteller_admin_ui
	var/selected_cell_id

/datum/storyteller_admin_ui/ui_state(mob/user)
	return ADMIN_STATE(R_ADMIN)

/datum/storyteller_admin_ui/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Storyteller", "RimWorld Storyteller")
		ui.open()

/datum/storyteller_admin_ui/ui_assets(mob/user)
	return list(get_asset_datum(/datum/asset/simple/storyteller_art))

/datum/storyteller_admin_ui/ui_static_data(mob/user)
	var/list/data = list()
	var/list/storytellers = list()
	for(var/id in SSstorytellers.storyteller_data)
		var/list/profile = SSstorytellers.storyteller_data[id]
		storytellers += list(list(
			"id" = id,
			"name" = profile["name"],
			"desc" = profile["desc"],
			"ooc_desc" = profile["ooc_desc"],
			"ooc_difficulty" = profile["ooc_difficulty"],
			"portrait_asset" = "[id]_portrait.png",
			"logo_asset" = "[id]_logo.png",
		))
	data["storytellers"] = storytellers
	return data

/datum/storyteller_admin_ui/ui_data(mob/user)
	var/list/data = list()
	var/datum/storyteller/active = SSstorytellers.active
	data["active_id"] = active?.id
	data["active_name"] = active?.name || "No storyteller"
	data["active_desc"] = active?.desc || "No profile is active."
	data["active_ooc_desc"] = active?.ooc_desc || ""
	data["difficulty_multiplier"] = SSstorytellers.difficulty_multiplier
	data["current_day"] = SSstorytellers.get_current_day()
	data["vote_active"] = SSstorytellers.vote_active
	data["event_count"] = length(SSstorytellers.events_by_id)

	var/list/cells = list()
	for(var/datum/planet_cell/cell as anything in SSstorytellers.get_cached_cells())
		cells += list(list(
			"id" = cell.id,
			"name" = cell.get_name(),
			"x" = cell.x,
			"y" = cell.y,
			"loaded" = cell.is_loaded(),
		))
	data["cells"] = cells

	var/datum/planet_cell/selected_cell = SSstorytellers.get_cell_by_id(selected_cell_id)
	if(!selected_cell && length(SSstorytellers.get_cached_cells()))
		selected_cell = SSstorytellers.get_cached_cells()[1]
		selected_cell_id = selected_cell.id

	data["selected_cell_id"] = selected_cell?.id
	data["selected_cell"] = null
	data["available_events"] = list()
	if(selected_cell)
		var/datum/storyteller_cell_plan/plan = selected_cell.get_storyteller_plan()
		if(active)
			plan.ensure_queue(active, SSstorytellers.get_current_day())
		var/list/upcoming = list()
		for(var/datum/storyteller_plan_entry/entry as anything in plan.get_upcoming_events(12))
			var/datum/storyteller_event/event = SSstorytellers.get_event_by_id(entry.event_id)
			if(!event)
				continue
			upcoming += list(list(
				"id" = entry.id,
				"event_id" = event.id,
				"name" = event.name,
				"description" = event.description,
				"category" = event.get_category_name(),
				"fire_day" = entry.fire_day,
				"days_until" = max(0, entry.fire_day - SSstorytellers.get_current_day()),
				"manual" = entry.manual,
			))
		var/list/available_events = list()
		for(var/event_id in SSstorytellers.events_by_id)
			var/datum/storyteller_event/event = SSstorytellers.events_by_id[event_id]
			if(!event.is_available(selected_cell, active))
				continue
			available_events += list(list(
				"id" = event.id,
				"name" = event.name,
				"description" = event.description,
				"category" = event.get_category_name(),
			))
		data["available_events"] = available_events
		data["selected_cell"] = list(
			"id" = selected_cell.id,
			"name" = selected_cell.get_name(),
			"x" = selected_cell.x,
			"y" = selected_cell.y,
			"loaded" = selected_cell.is_loaded(),
			"biome" = selected_cell.get_biome(),
			"weather" = selected_cell.weather_type,
			"interval_override_days" = plan.interval_override_days,
			"has_colony" = selected_cell.has_colony(),
			"colonists" = selected_cell.get_colonist_count(),
			"colony_age_days" = selected_cell.get_colony_age_days(),
			"threat_points" = active ? active.get_threat_points(selected_cell) : 0,
			"upcoming" = upcoming,
		)
	return data

/datum/storyteller_admin_ui/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(!check_rights(R_ADMIN))
		return TRUE

	var/datum/planet_cell/cell = SSstorytellers.get_cell_by_id(selected_cell_id)
	switch(action)
		if("select_cell")
			selected_cell_id = params["id"]
			return TRUE
		if("set_storyteller")
			SSstorytellers.set_storyteller(params["id"], SSstorytellers.difficulty_multiplier)
			return TRUE
		if("set_difficulty")
			SSstorytellers.difficulty_multiplier = clamp(text2num(params["value"]), STORYTELLER_MIN_DIFFICULTY, STORYTELLER_MAX_DIFFICULTY)
			if(SSstorytellers.active)
				SSstorytellers.active.difficulty_multiplier = SSstorytellers.difficulty_multiplier
			return TRUE
		if("force_think")
			if(cell && SSstorytellers.active)
				cell.get_storyteller_plan().process_plan(SSstorytellers.active, SSstorytellers.get_current_day())
			else
				for(var/datum/planet_cell/loaded_cell as anything in SSstorytellers.get_cached_cells())
					if(loaded_cell.is_loaded())
						loaded_cell.get_storyteller_plan().process_plan(SSstorytellers.active, SSstorytellers.get_current_day())
			return TRUE
		if("replan_cell")
			SSstorytellers.replan_cell(cell)
			return TRUE
		if("set_cell_interval")
			SSstorytellers.set_cell_interval(cell, params["value"])
			return TRUE
		if("add_event")
			if(!cell)
				return TRUE
			var/event_id = params["event_id"]
			var/datum/storyteller_event/event = SSstorytellers.get_event_by_id(event_id)
			if(!event || !event.is_available(cell, SSstorytellers.active))
				return TRUE
			var/days_from_now = clamp(text2num(params["days_from_now"]), 0, STORYTELLER_MAX_INTERVAL_DAYS)
			cell.get_storyteller_plan().add_event(event_id, SSstorytellers.get_current_day() + days_from_now, SSstorytellers.get_current_day(), TRUE)
			message_admins("[key_name_admin(usr)] planned '[event.name]' for [cell.get_name()].")
			return TRUE
		if("trigger_event")
			if(!cell)
				return TRUE
			var/datum/storyteller_plan_entry/entry = cell.get_storyteller_plan().get_entry(params["entry_id"])
			if(entry && cell.is_loaded())
				var/event_id = entry.event_id
				cell.get_storyteller_plan().cancel_event(entry.id)
				SSstorytellers.run_event(cell, event_id, "admin")
			return TRUE
		if("remove_event")
			if(cell)
				cell.get_storyteller_plan().cancel_event(params["entry_id"])
			return TRUE
		if("reschedule_event")
			if(cell)
				var/days_from_now = clamp(text2num(params["days_from_now"]), 0, STORYTELLER_MAX_INTERVAL_DAYS)
				cell.get_storyteller_plan().reschedule_event(params["entry_id"], SSstorytellers.get_current_day() + days_from_now)
			return TRUE
		if("reload_profiles")
			SSstorytellers.load_storyteller_data()
			if(!length(SSstorytellers.storyteller_data))
				SSstorytellers.load_default_storytellers()
			var/reload_id = SSstorytellers.storyteller_data[SSstorytellers.selected_id] ? SSstorytellers.selected_id : pick(SSstorytellers.storyteller_data)
			SSstorytellers.set_storyteller(reload_id, SSstorytellers.difficulty_multiplier, FALSE, FALSE)
			return TRUE
		if("start_vote")
			if(!SSstorytellers.start_vote())
				to_chat(usr, span_warning("A storyteller vote is already running."))
			return TRUE
		if("end_vote")
			SSstorytellers.end_vote()
			return TRUE
	return FALSE
