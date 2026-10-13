ADMIN_VERB(storyteller_vote, R_ADMIN | R_DEBUG, "Storyteller - Start Vote", "Start a global storyteller and difficulty vote.", ADMIN_CATEGORY_STORYTELLER)
	var/duration = tgui_input_number(usr, "Duration in seconds:", "Storyteller Vote", 60, 600, 10)
	if(isnull(duration))
		return
	if(!SSstorytellers.start_vote(duration SECONDS))
		to_chat(usr, span_warning("A storyteller vote is already running."))

ADMIN_VERB(storyteller_end_vote, R_ADMIN | R_DEBUG, "Storyteller - End Vote", "End the storyteller vote early.", ADMIN_CATEGORY_STORYTELLER)
	SSstorytellers.end_vote()

/datum/asset/simple/storyteller_art
	assets = list()

/datum/asset/simple/storyteller_art/New()
	GLOB.asset_datums[type] = src
	for(var/id in SSstorytellers.storyteller_data)
		var/list/profile = SSstorytellers.storyteller_data[id]
		if(!profile)
			continue
		if(profile["portrait_path"] && fexists(profile["portrait_path"]))
			assets["[id]_portrait.png"] = profile["portrait_path"]
		if(profile["logo_path"] && fexists(profile["logo_path"]))
			assets["[id]_logo.png"] = profile["logo_path"]
	..()

/datum/storyteller_vote_ui
	var/client/owner

/datum/storyteller_vote_ui/New(client/new_owner)
	. = ..()
	if(!new_owner)
		qdel(src)
		return
	owner = new_owner
	SSstorytellers.storyteller_vote_uis[owner] = src

/datum/storyteller_vote_ui/Destroy()
	if(owner && SSstorytellers.storyteller_vote_uis)
		SSstorytellers.storyteller_vote_uis -= owner
	owner = null
	return ..()

/datum/storyteller_vote_ui/ui_state(mob/user)
	return GLOB.always_state

/datum/storyteller_vote_ui/ui_assets(mob/user)
	return list(get_asset_datum(/datum/asset/simple/storyteller_art))

/datum/storyteller_vote_ui/ui_interact(mob/user, datum/tgui/ui)
	if(!owner || !user)
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "StorytellerVote", "Storyteller Vote")
		ui.open()

/datum/storyteller_vote_ui/ui_static_data(mob/user)
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
	data["difficulty_levels"] = GLOB.storyteller_difficulty_levels
	data["min_difficulty"] = STORYTELLER_MIN_DIFFICULTY
	data["max_difficulty"] = STORYTELLER_MAX_DIFFICULTY
	return data

/datum/storyteller_vote_ui/ui_data(mob/user)
	var/list/data = list()
	var/list/personal = SSstorytellers.vote_ballots[owner?.ckey]
	if(!islist(personal))
		personal = list()

	data["personal_selection"] = personal["storyteller"]
	data["personal_difficulty"] = personal["difficulty"] || SSstorytellers.get_default_difficulty()
	data["is_open"] = SSstorytellers.vote_active
	data["can_vote"] = SSstorytellers.can_client_vote(owner)
	data["admin_mode"] = check_rights_for(owner, R_ADMIN)
	data["debug_mode"] = SSstorytellers.hard_debug
	data["current_storyteller"] = SSstorytellers.active?.id
	data["time_left"] = SSstorytellers.vote_active ? max(0, SSstorytellers.vote_start_time + SSstorytellers.current_vote_duration - world.time) : 0
	data["total_voters"] = length(SSstorytellers.get_eligible_voters())
	data["voted_count"] = length(SSstorytellers.vote_ballots)

	if(SSstorytellers.vote_active || !SSstorytellers.last_vote_result)
		data["top_tallies"] = SSstorytellers.get_tallies()
		data["winner_id"] = null
		data["winner_difficulty"] = null
	else
		var/list/result = SSstorytellers.last_vote_result
		data["top_tallies"] = result["tallies"]
		data["winner_id"] = result["winner_id"]
		data["winner_difficulty"] = result["winner_difficulty"]
	return data

/datum/storyteller_vote_ui/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	switch(action)
		if("select_storyteller")
			if(SSstorytellers.can_client_vote(owner))
				SSstorytellers.cast_vote(owner.ckey, params["id"], null)
			return TRUE
		if("set_difficulty")
			if(SSstorytellers.can_client_vote(owner))
				SSstorytellers.cast_vote(owner.ckey, null, params["value"])
			return TRUE
		if("force_end_vote")
			if(!check_rights_for(owner, R_ADMIN))
				return TRUE
			SSstorytellers.end_vote()
			return TRUE
	return FALSE
