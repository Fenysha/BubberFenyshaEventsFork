SUBSYSTEM_DEF(storytellers)
	name = "RimWorld Storyteller"
	wait = STORYTELLER_THINK_INTERVAL
	runlevels = RUNLEVEL_GAME
	ss_flags = SS_BACKGROUND | SS_KEEP_TIMING
	dependencies = list(/datum/controller/subsystem/rimworld_planetmap)

	var/datum/storyteller/active
	var/list/storyteller_data = list()
	var/list/events_by_id = list()

	/// ckey -> list("storyteller" = id or null, "difficulty" = number)
	var/list/vote_ballots = list()
	/// client -> /datum/storyteller_vote_ui
	var/list/storyteller_vote_uis = list()
	var/selected_id
	var/difficulty_multiplier = STORYTELLER_DEFAULT_DIFFICULTY
	var/vote_active = FALSE
	var/vote_start_time = 0
	var/current_vote_duration = STORYTELLER_VOTE_DURATION
	/// TRUE once any vote has finished with at least one ballot.
	var/vote_held = FALSE
	/// Result of the last finished vote, shown in the results window.
	var/list/last_vote_result
	/// world.time at which the automatic vote starts. 0 = not scheduled yet.
	var/auto_vote_at = 0
	/// Debug: lifts the player-count requirement on difficulty levels.
	var/hard_debug = FALSE
	/// Whether a storyteller was chosen for the round during setup / vote.
	var/storyteller_chosen = FALSE

/datum/controller/subsystem/storytellers/Initialize()
	load_storyteller_data()
	collect_events()

	if(!length(storyteller_data))
		load_default_storytellers()

	var/default_id = "cas_classic"
	if(!storyteller_data[default_id])
		var/list/profile_ids = list()
		for(var/id in storyteller_data)
			profile_ids += id
		default_id = pick(profile_ids)
	set_storyteller(default_id, STORYTELLER_DEFAULT_DIFFICULTY, FALSE, FALSE)
	return SS_INIT_SUCCESS

/datum/controller/subsystem/storytellers/Destroy()
	QDEL_NULL(active)
	clear_vote_uis()
	storyteller_vote_uis = null
	return ..()

/datum/controller/subsystem/storytellers/fire(resumed)
	if(STORYTELLER_VOTE_AUTO_START && !vote_held && !vote_active)
		if(!auto_vote_at)
			auto_vote_at = world.time + STORYTELLER_VOTE_AUTO_DELAY
		else if(world.time >= auto_vote_at)
			start_vote()
			auto_vote_at = 0

	if(vote_active)
		if(world.time >= vote_start_time + current_vote_duration)
			end_vote()
		else
			open_vote_for_new_clients()

	if(!active || !SSrimworld_planetmap?.planet)
		return

	var/current_day = get_current_day()
	for(var/cell_key in SSrimworld_planetmap.planet.cells)
		var/datum/planet_cell/cell = SSrimworld_planetmap.planet.cells[cell_key]
		if(!cell || !cell.is_loaded())
			continue
		cell.get_storyteller_plan().process_plan(active, current_day)

/datum/controller/subsystem/storytellers/proc/get_current_day()
	if(!SSrimworld_planetmap)
		return world.time / (24 HOURS)
	return SSrimworld_planetmap.total_days + (SSrimworld_planetmap.rotation_angle / 360)

/datum/controller/subsystem/storytellers/proc/load_default_storytellers()
	storyteller_data = list(
		"cas_classic" = list(
			"id" = "cas_classic", "name" = "Cas'Classic", "desc" = "A steady mixture of incidents.",
			"ooc_desc" = "A balanced pace of positive, neutral and negative events.", "ooc_difficulty" = "Medium",
			"average_event_interval_days" = 2, "mood_path" = /datum/storyteller_mood/classic,
			"portrait_path" = STORYTELLER_ICONS_PATH + "portraits/p_cas.png", "logo_path" = STORYTELLER_ICONS_PATH + "logos/logo_cas.png",
			"welcome_speech" = list("A new story begins.")
		),
		"mia_chill" = list(
			"id" = "mia_chill", "name" = "Mia'Chill", "desc" = "A quieter, kinder story.",
			"ooc_desc" = "Positive and neutral events are more common, and the pace is slower.", "ooc_difficulty" = "Easy",
			"average_event_interval_days" = 2.5, "mood_path" = /datum/storyteller_mood/chill,
			"portrait_path" = STORYTELLER_ICONS_PATH + "portraits/p_mia.png", "logo_path" = STORYTELLER_ICONS_PATH + "logos/logo_mia.png",
			"welcome_speech" = list("May your colony find a little peace.")
		)
	)

/datum/controller/subsystem/storytellers/proc/load_storyteller_data()
	storyteller_data = list()
	if(!fexists(STORYTELLER_JSON_PATH))
		log_storyteller("Storyteller JSON not found at [STORYTELLER_JSON_PATH]; using built-in profiles.")
		return

	var/json_text = rustg_file_read(STORYTELLER_JSON_PATH)
	var/list/decoded = json_decode(json_text)
	if(!islist(decoded))
		log_storyteller("Invalid storyteller JSON; using built-in profiles.")
		return

	for(var/list/entry as anything in decoded)
		var/id = entry["id"]
		if(!istext(id) || !length(id))
			continue

		var/list/profile = list()
		profile["id"] = id
		profile["name"] = istext(entry["name"]) ? entry["name"] : id
		profile["desc"] = istext(entry["desc"]) ? entry["desc"] : "No description provided."
		profile["ooc_desc"] = istext(entry["ooc_desc"]) ? entry["ooc_desc"] : profile["desc"]
		profile["ooc_difficulty"] = istext(entry["ooc_difficulty"]) ? entry["ooc_difficulty"] : "Medium"
		profile["average_event_interval_days"] = isnum(entry["average_event_interval_days"]) ? clamp(entry["average_event_interval_days"], STORYTELLER_MIN_INTERVAL_DAYS, STORYTELLER_MAX_INTERVAL_DAYS) : STORYTELLER_DEFAULT_INTERVAL_DAYS
		profile["portrait_path"] = istext(entry["portrait"]) ? STORYTELLER_ICONS_PATH + entry["portrait"] : ""
		profile["logo_path"] = istext(entry["logo"]) ? STORYTELLER_ICONS_PATH + entry["logo"] : ""
		profile["mood_path"] = text2path(entry["mood_type"])
		profile["welcome_speech"] = islist(entry["welcome_speech"]) ? entry["welcome_speech"] : list()
		profile["round_speech"] = islist(entry["round_speech"]) ? entry["round_speech"] : list()
		storyteller_data[id] = profile

	if(!length(storyteller_data))
		load_default_storytellers()
	log_storyteller("Loaded [length(storyteller_data)] storyteller profiles.")

/datum/controller/subsystem/storytellers/proc/collect_events()
	events_by_id = list()
	for(var/event_type in subtypesof(/datum/storyteller_event))
		var/datum/storyteller_event/event = new event_type
		if(!event.id || !length(event.id) || events_by_id[event.id])
			qdel(event)
			continue
		events_by_id[event.id] = event
	log_storyteller("Registered [length(events_by_id)] storyteller incidents.")

/// Switches the active storyteller. `replan` throws away the previous storyteller's automatic
/// queues (manual admin entries stay) so the new personality takes effect immediately.
/datum/controller/subsystem/storytellers/proc/set_storyteller(id, new_difficulty = null, announce = TRUE, replan = TRUE)
	var/list/profile = storyteller_data[id]
	if(!profile)
		return FALSE

	var/datum/storyteller/new_storyteller = new(id)
	new_storyteller.apply_profile(profile)
	if(isnull(new_difficulty))
		new_difficulty = difficulty_multiplier
	new_storyteller.difficulty_multiplier = clamp(new_difficulty, STORYTELLER_MIN_DIFFICULTY, STORYTELLER_MAX_DIFFICULTY)

	QDEL_NULL(active)
	active = new_storyteller
	selected_id = id
	difficulty_multiplier = active.difficulty_multiplier

	if(replan)
		replan_all_cells()

	if(announce && length(active.welcome_speech))
		to_chat(world, span_notice("[active.name]: [pick(active.welcome_speech)]"))
	log_storyteller("Active storyteller changed to [active.name], difficulty [difficulty_multiplier].")
	return TRUE

/datum/controller/subsystem/storytellers/proc/replan_all_cells()
	if(!active || !SSrimworld_planetmap?.planet)
		return
	var/current_day = get_current_day()
	for(var/datum/planet_cell/cell as anything in get_cached_cells())
		// Only cells that already have a plan; creating plans for every cell would be pointless.
		if(!cell.storyteller_plan)
			continue
		cell.storyteller_plan.clear_automatic_events()
		cell.storyteller_plan.ensure_queue(active, current_day)

/datum/controller/subsystem/storytellers/proc/get_event_by_id(event_id)
	return events_by_id[event_id]

/datum/controller/subsystem/storytellers/proc/get_cached_cells()
	var/list/result = list()
	if(!SSrimworld_planetmap?.planet)
		return result
	for(var/key in SSrimworld_planetmap.planet.cells)
		var/datum/planet_cell/cell = SSrimworld_planetmap.planet.cells[key]
		if(cell)
			result += cell
	return result

/datum/controller/subsystem/storytellers/proc/get_cell_by_id(cell_id)
	if(!cell_id)
		return null
	for(var/datum/planet_cell/cell as anything in get_cached_cells())
		if(cell.id == cell_id)
			return cell
	return null

/datum/controller/subsystem/storytellers/proc/run_event(datum/planet_cell/cell, event_id, source = "planned")
	if(!cell || !active)
		return FALSE
	var/datum/storyteller_event/prototype = events_by_id[event_id]
	if(!prototype || !prototype.is_available(cell, active))
		return FALSE

	var/event_type = prototype.type
	var/datum/storyteller_event/execution = new event_type
	var/difficulty = active.calculate_event_difficulty(cell, execution)
	var/success = execution.execute(cell, active, difficulty)
	if(success)
		active.remember_event(event_id)
		cell.get_storyteller_plan().mark_event_fired(execution, get_current_day())
		log_storyteller("[active.name] executed '[execution.name]' for [cell.get_name()] via [source] (difficulty/points: [difficulty]).")
	qdel(execution)
	return success

/datum/controller/subsystem/storytellers/proc/replan_cell(datum/planet_cell/cell)
	if(!cell || !active)
		return FALSE
	var/datum/storyteller_cell_plan/plan = cell.get_storyteller_plan()
	plan.clear_events()
	plan.ensure_queue(active, get_current_day())
	return TRUE

/datum/controller/subsystem/storytellers/proc/set_cell_interval(datum/planet_cell/cell, interval_days)
	if(!cell)
		return FALSE
	var/datum/storyteller_cell_plan/plan = cell.get_storyteller_plan()
	interval_days = text2num("[interval_days]")
	if(isnull(interval_days) || interval_days <= 0)
		plan.interval_override_days = 0
	else
		plan.interval_override_days = clamp(interval_days, STORYTELLER_MIN_INTERVAL_DAYS, STORYTELLER_MAX_INTERVAL_DAYS)
	return TRUE
