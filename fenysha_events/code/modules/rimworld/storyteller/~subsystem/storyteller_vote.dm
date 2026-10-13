/datum/asset/simple/storyteller_art
	assets = list()
	var/populated = FALSE

/datum/asset/simple/storyteller_art/ensure_ready()
	if(populated)
		return src

	assets = list()
	for(var/id in SSstorytellers.storyteller_data)
		var/list/profile = SSstorytellers.storyteller_data[id]
		if(!profile)
			continue
		if(profile["portrait_path"] && rustg_file_exists(profile["portrait_path"]))
			assets["[id]_portrait.png"] = profile["portrait_path"]
		if(profile["logo_path"] && rustg_file_exists(profile["logo_path"]))
			assets["[id]_logo.png"] = profile["logo_path"]

	for(var/asset_name in assets)
		var/datum/asset_cache_item/ACI = SSassets.transport.register_asset(asset_name, assets[asset_name])
		if(!ACI)
			log_asset("ERROR: Invalid storyteller asset: [asset_name]")
			continue
		assets[asset_name] = ACI

	populated = TRUE
	return src


/datum/action/storyteller_vote
	name = "Vote for Storyteller"
	button_icon_state = "vote"
	show_to_observers = FALSE

/datum/action/storyteller_vote/IsAvailable(feedback = FALSE)
	return SSstorytellers.vote_active

/datum/action/storyteller_vote/Grant(mob/grant_to)
	. = ..()
	if(.)
		RegisterSignal(SSstorytellers, COMSIG_STORYTELLER_VOTE_END, PROC_REF(on_vote_ended), TRUE)

/datum/action/storyteller_vote/Trigger(mob/clicker, trigger_flags)
	. = ..()
	if(!.)
		return
	if(!SSstorytellers.vote_active)
		Remove(owner)
		return
	SSstorytellers.open_vote_ui(clicker.client)

/datum/action/storyteller_vote/Topic(href, href_list)
	. = ..()
	if(.)
		return
	if(href_list["open_ui"])
		Trigger(owner)

/datum/action/storyteller_vote/proc/on_vote_ended()
	SIGNAL_HANDLER
	Remove(owner)

/datum/action/storyteller_vote/Remove(mob/removed_from)
	UnregisterSignal(SSstorytellers, COMSIG_STORYTELLER_VOTE_END)
	if(removed_from?.persistent_client)
		removed_from.persistent_client.player_actions -= src
	else if(removed_from?.ckey)
		var/datum/persistent_client/pc = GLOB.persistent_clients_by_ckey[removed_from.ckey]
		pc?.player_actions -= src
	return ..()


/datum/controller/subsystem/storytellers/proc/can_client_vote(client/C)
	if(!C || !vote_active)
		return FALSE
	if(isnewplayer(C.mob) || isliving(C.mob) || C.holder)
		return TRUE
	return FALSE

/datum/controller/subsystem/storytellers/proc/get_eligible_voters()
	var/list/result = list()
	for(var/client/C as anything in GLOB.clients)
		if(can_client_vote(C))
			result += C
	return result

/datum/controller/subsystem/storytellers/proc/is_difficulty_allowed(value)
	if(hard_debug)
		return TRUE
	var/list/level = storyteller_snap_level(value)
	return level && length(get_eligible_voters()) >= level["min_players"]

/datum/controller/subsystem/storytellers/proc/get_default_difficulty()
	var/result = GLOB.storyteller_difficulty_levels[1]["value"]
	for(var/list/level as anything in GLOB.storyteller_difficulty_levels)
		if(level["value"] > STORYTELLER_DEFAULT_DIFFICULTY)
			break
		if(is_difficulty_allowed(level["value"]))
			result = level["value"]
	return result

/datum/controller/subsystem/storytellers/proc/open_vote_ui(client/C)
	if(!C)
		return
	var/datum/storyteller_vote_ui/ui = storyteller_vote_uis[C]
	if(!ui)
		ui = new(C)
	ui.ui_interact(C.mob)

/datum/controller/subsystem/storytellers/proc/open_vote_for_new_clients()
	for(var/client/C as anything in GLOB.clients)
		if(!C?.mob || storyteller_vote_uis[C])
			continue
		open_vote_ui(C)

/datum/controller/subsystem/storytellers/proc/clear_vote_uis()
	var/list/old = storyteller_vote_uis ? storyteller_vote_uis.Copy() : list()
	for(var/client/C as anything in old)
		var/datum/storyteller_vote_ui/ui = old[C]
		if(ui)
			qdel(ui)

/// Grants the vote action + sends the fancy chat message + sound + flash
/datum/controller/subsystem/storytellers/proc/grant_vote_action(client/C)
	if(!C?.mob)
		return

	// Don't grant duplicates
	for(var/datum/action/storyteller_vote/existing in C.mob.actions)
		return

	var/datum/action/storyteller_vote/vote_action = new()
	vote_action.Grant(C.mob)
	if(C.persistent_client)
		C.persistent_client.player_actions += vote_action

	send_vote_message(C, vote_action)

/datum/controller/subsystem/storytellers/proc/send_vote_message(client/C, datum/action/storyteller_vote/vote_action)
	if(!C)
		return

	window_flash(C)

	var/polling_sound_pref = C.prefs?.read_preference(/datum/preference/choiced/sound_ghost_poll_prompt)
	var/polling_sound_volume = C.prefs?.read_preference(/datum/preference/numeric/sound_ghost_poll_prompt_volume)
	if(polling_sound_pref && polling_sound_pref != GHOST_POLL_PROMPT_DISABLED && polling_sound_volume)
		var/polling_sound = (polling_sound_pref == GHOST_POLL_PROMPT_1) ? 'sound/misc/prompt1.ogg' : 'sound/misc/prompt2.ogg'
		SEND_SOUND(C.mob, sound(polling_sound, volume = polling_sound_volume))

	var/custom_link_style_start = "<style>a:visited{color:Crimson !important}</style>"
	var/custom_link_style_end = "style='color:DodgerBlue;font-weight:bold;-dm-text-outline: 1px black'"
	var/act_vote = "[custom_link_style_start]<a href='byond://?src=[REF(vote_action)];open_ui=1'[custom_link_style_end]>\[Vote Now\]</a>"

	var/final_message = boxed_message({"<span style='text-align:center;display:block'><span style='font-size:1.2em'>[span_ooc("Storyteller Vote Started! Vote for your preferred storyteller.")]</span><br>[act_vote]</span>"})
	to_chat(C.mob, final_message)

/datum/controller/subsystem/storytellers/proc/start_vote(duration = STORYTELLER_VOTE_DURATION)
	if(vote_active)
		return FALSE

	clear_vote_uis()
	current_vote_duration = clamp(duration, 10 SECONDS, 10 MINUTES)
	vote_start_time = world.time
	vote_ballots = list()
	last_vote_result = null
	vote_active = TRUE
	storyteller_vote_uis = list()

	// Open UI + grant action + message for everyone currently online
	for(var/client/C as anything in GLOB.clients)
		if(!C?.mob)
			continue
		open_vote_ui(C)
		grant_vote_action(C)

	to_chat(world, span_boldnotice("A storyteller vote has started. You have [round(current_vote_duration / 10)] seconds."))
	message_admins("A RimWorld storyteller vote has started for [round(current_vote_duration / 10)] seconds.")
	SEND_SIGNAL(src, COMSIG_STORYTELLER_VOTE_START)

	for(var/mob/dead/new_player/player in GLOB.new_player_list)
		player.update_title_screen()

	return TRUE

/// Called when a client logs in while a vote is running
/datum/controller/subsystem/storytellers/proc/on_client_login(client/C)
	if(!vote_active || !C)
		return
	open_vote_ui(C)
	grant_vote_action(C)

/datum/controller/subsystem/storytellers/proc/cast_vote(voter_ckey, storyteller_id = null, chosen_difficulty = null)
	if(!vote_active || !voter_ckey)
		return FALSE

	var/list/ballot = vote_ballots[voter_ckey]
	if(!islist(ballot))
		ballot = list("storyteller" = null, "difficulty" = get_default_difficulty())

	if(!isnull(storyteller_id))
		if(!istext(storyteller_id) || !storyteller_data[storyteller_id])
			return FALSE
		ballot["storyteller"] = storyteller_id

	if(!isnull(chosen_difficulty))
		var/value = text2num("[chosen_difficulty]")
		if(isnull(value))
			return FALSE
		value = storyteller_snap_difficulty(clamp(value, STORYTELLER_MIN_DIFFICULTY, STORYTELLER_MAX_DIFFICULTY))
		if(!is_difficulty_allowed(value))
			return FALSE
		ballot["difficulty"] = value

	vote_ballots[voter_ckey] = ballot
	return TRUE

/datum/controller/subsystem/storytellers/proc/get_mode_difficulty(list/by_value)
	var/best_value = STORYTELLER_DEFAULT_DIFFICULTY
	var/best_count = 0
	for(var/value_text in by_value)
		var/value = text2num(value_text)
		var/count = by_value[value_text]
		if(count > best_count || (count == best_count && value < best_value))
			best_count = count
			best_value = value
	return best_value

/datum/controller/subsystem/storytellers/proc/get_tallies()
	var/list/counts = list()
	var/list/difficulty_votes = list()
	for(var/voter_ckey in vote_ballots)
		var/list/ballot = vote_ballots[voter_ckey]
		var/id = ballot["storyteller"]
		if(!id || !storyteller_data[id])
			continue
		counts[id] = (counts[id] || 0) + 1
		var/list/by_value = difficulty_votes[id]
		if(!by_value)
			by_value = list()
			difficulty_votes[id] = by_value
		by_value["[ballot["difficulty"]]"] += 1

	var/list/results = list()
	for(var/id in counts)
		var/list/profile = storyteller_data[id]
		results += list(list(
			"id" = id,
			"name" = profile["name"],
			"count" = counts[id],
			"difficulty" = get_mode_difficulty(difficulty_votes[id]),
		))
	sortTim(results, GLOBAL_PROC_REF(cmp_storyteller_tally_dsc))
	return results

/proc/cmp_storyteller_tally_dsc(list/a, list/b)
	return b["count"] - a["count"]

/datum/controller/subsystem/storytellers/proc/end_vote()
	if(!vote_active)
		return FALSE
	vote_active = FALSE

	var/list/tallies = get_tallies()
	var/winner_id
	var/winner_difficulty = difficulty_multiplier
	if(length(tallies))
		var/highest = tallies[1]["count"]
		var/list/winners = list()
		for(var/list/entry as anything in tallies)
			if(entry["count"] == highest)
				winners += list(entry)
		var/list/winner = pick(winners)
		winner_id = winner["id"]
		winner_difficulty = winner["difficulty"]

	if(winner_id)
		vote_held = TRUE
		set_storyteller(winner_id, winner_difficulty)
		var/list/level = storyteller_snap_level(winner_difficulty)
		to_chat(world, span_boldnotice("Storyteller vote finished: [active.name] ([level["label"]]) will tell this story."))
		message_admins("Storyteller vote ended. Selected [active.name] at difficulty [winner_difficulty].")
		storyteller_chosen = TRUE
	else
		to_chat(world, span_notice("Storyteller vote finished without ballots; [active?.name || "the current storyteller"] stays."))
		message_admins("Storyteller vote ended without ballots; the current storyteller remains active.")

	last_vote_result = list(
		"winner_id" = winner_id,
		"winner_difficulty" = winner_difficulty,
		"tallies" = tallies,
	)

	// Notify actions to remove themselves
	SEND_SIGNAL(src, COMSIG_STORYTELLER_VOTE_END)

	for(var/mob/dead/new_player/player in GLOB.new_player_list)
		player.update_title_screen()

	// Update open UIs so they show results
	for(var/client/C as anything in storyteller_vote_uis)
		var/datum/storyteller_vote_ui/UI = storyteller_vote_uis[C]
		if(UI)
			SStgui.update_uis(UI)

	addtimer(CALLBACK(src, PROC_REF(finish_vote_cleanup)), STORYTELLER_VOTE_RESULT_LINGER)
	return TRUE

/datum/controller/subsystem/storytellers/proc/finish_vote_cleanup()
	if(vote_active)
		return
	clear_vote_uis()


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
			message_admins("[key_name_admin(owner)] forced the end of the storyteller vote.")
			return TRUE
	return FALSE
