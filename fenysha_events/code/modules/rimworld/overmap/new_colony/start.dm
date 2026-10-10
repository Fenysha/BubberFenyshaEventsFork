/datum/settlement_setup/proc/prepare_character()
	RETURN_TYPE(/mob/living/carbon/human)

	if(!viewer?.client)
		return null

	var/mob/living/carbon/human/owner = new(null)
	viewer.client.rw_prefs.apply_to_human(owner)

	return owner

/datum/settlement_setup/proc/transfer_to_character(mob/living/carbon/human/character)
	if(!viewer?.client || !viewer.mind || !character)
		return FALSE

	var/datum/mind/preserved_mind = viewer.mind

	if(isnewplayer(viewer))
		var/mob/dead/new_player/player = viewer
		player.hide_title_screen()

	preserved_mind.active = FALSE
	preserved_mind.transfer_to(character)
	preserved_mind.set_original_character(character)

	if(!(preserved_mind in SSticker.minds))
		SSticker.minds += preserved_mind

	character.PossessByPlayer(viewer.key)

	if(character.client)
		character.client.init_verbs()

	character.stop_sound_channel(CHANNEL_LOBBYMUSIC)

	/*
	var/area/joined_area = get_area(character.loc)
	if(joined_area)
		joined_area.on_joining_game(character)
	*/

	if(character.ckey && !(character.ckey in GLOB.joined_player_list))
		GLOB.joined_player_list += character.ckey

	qdel(viewer)
	return TRUE


/datum/settlement_setup/proc/do_create()
	if(!planet || !viewer?.client || isnull(target_x) || isnull(target_y))
		return FALSE

	var/site_error = planet.validate_player_settlement_site(target_x, target_y)
	if(site_error)
		return fail_loading(site_error)

	var/datum/planet_cell/cell = planet.get_or_create_cell(
		target_x,
		target_y,
		FALSE
	)

	if(!cell)
		return fail_loading("Unable to create planet cell.")

	loading_cell = cell
	loading_error = null

	// Prevent closing the planet map while generation is running.
	parent_view.prevent_close = TRUE
	parent_view.auto_reopen_on_login = TRUE
	parent_view.loading = TRUE

	SStgui.update_uis(src)

	var/result = cell.ensure_loaded(
		post_load_callback = CALLBACK(src, PROC_REF(on_cell_loaded)),
		progress_callback = CALLBACK(src, PROC_REF(on_load_progress))
	)

	if(!result)
		return fail_loading("Unable to start local map generation.")

	return TRUE

/datum/settlement_setup/proc/on_cell_loaded(datum/planet_cell/cell)
	var/faction_id = "player_[viewer.ckey || REF(viewer)]"
	var/datum/rw_faction/player/player_faction = SSfactions.get_or_create_player_faction(
		faction_id,
		faction_name
	)

	if(!player_faction)
		return fail_loading("Unable to create faction.")

	player_faction.name = faction_name
	player_faction.desc = faction_desc
	player_faction.color = faction_color
	player_faction.icon_state = faction_icon
	player_faction.join_mode = join_mode
	player_faction.join_password = (join_mode == RW_JOIN_PASSWORD) ? join_password : ""
	player_faction.visible_on_map = visible_on_map

	var/mob/living/carbon/human/owner = prepare_character()
	if(!owner)
		return fail_loading("Unable to prepare character.")

	SSfactions.add_member(player_faction, owner, force = TRUE)
	var/datum/rimworld_planet_object/settlement/settlement = planet.create_settlement(
		target_x,
		target_y,
		faction_name
	)

	if(!settlement)
		qdel(owner)
		return fail_loading("Unable to create settlement.")

	apply_create_policy(player_faction, settlement, cell, owner)

	settlement.set_faction(player_faction.id)
	settlement.set_population(1)
	settlement.data["join_mode"] = join_mode
	settlement.data["visible"] = visible_on_map
	settlement.data["scenario"] = scenario_id


	addtimer(CALLBACK(src, PROC_REF(finish_and_close)), 1)

	if(!transfer_to_character(owner))
		qdel(owner)
		return FALSE

	launch_rimworld_pod(cell, list(owner))
	spawn_scenario_gear(cell, owner)

	// Ambient weather for the newly loaded cell
	cell.on_loaded_start_weather()


/datum/settlement_setup/proc/spawn_scenario_gear(datum/planet_cell/cell, mob/living/carbon/human/owner)
	if(QDELETED(owner) || !cell)
		return
	var/datum/rimworld_scenario/S = get_rimworld_scenario(scenario_id)
	addtimer(CALLBACK(S, TYPE_PROC_REF(/datum/rimworld_scenario, spawn_starting_gear), cell, owner), 2 SECONDS)


/datum/settlement_setup/proc/do_join()
	if(!planet || !viewer?.client || !join_settlement_id)
		return FALSE

	var/datum/rimworld_planet_object/settlement/sett = planet.get_object(join_settlement_id)

	if(!sett)
		return FALSE

	var/faction_id = sett.data["faction"]
	var/datum/rw_faction/player/fac = faction_id ? SSfactions.get_faction(faction_id) : null
	if(!istype(fac) || !fac.player_faction)
		return FALSE

	if(!fac.can_join_from_map(join_attempt_password))
		if(fac.join_mode == RW_JOIN_CLOSED)
			to_chat(viewer, span_warning("This settlement is closed to new members."))
		else if(fac.join_mode == RW_JOIN_PASSWORD)
			to_chat(viewer, span_warning("Incorrect password."))
		else
			to_chat(viewer, span_warning("Cannot join this settlement."))
		return FALSE

	var/mob/living/carbon/human/owner = prepare_character()
	if(!owner)
		return FALSE
	SSfactions.add_member(fac, owner, force = TRUE)
	sett.set_population((sett.data["population"] || 0) + 1)


	var/datum/planet_cell/cell = planet.get_or_create_cell(sett.x, sett.y, FALSE)

	if(!cell)
		qdel(owner)
		return FALSE

	addtimer(CALLBACK(src, PROC_REF(finish_and_close)), 1)

	if(!transfer_to_character(owner))
		qdel(owner)
		return FALSE
	launch_rimworld_pod(cell, list(owner))
	return TRUE
