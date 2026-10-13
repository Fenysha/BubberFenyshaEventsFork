/datum/storyteller
	var/id = "cas_classic"
	var/name = "Cas'Classic"
	var/desc = "A steady, balanced story."
	var/ooc_desc = "Incidents are selected randomly from the available pool for each active planet cell."
	var/ooc_difficulty = "Medium"
	var/portrait_path = ""
	var/logo_path = ""
	var/average_event_interval_days = STORYTELLER_DEFAULT_INTERVAL_DAYS
	var/difficulty_multiplier = STORYTELLER_DEFAULT_DIFFICULTY
	var/datum/storyteller_mood/mood
	var/list/welcome_speech = list()
	var/list/round_speech = list()
	var/list/recent_event_ids = list()
	var/recent_event_limit = 8
	/// Weight multiplier for incidents that were fired recently (stops the same event spamming).
	var/recent_event_weight_mult = 0.3

/datum/storyteller/New(new_id)
	. = ..()
	if(new_id)
		id = new_id
	mood = new /datum/storyteller_mood/classic

/datum/storyteller/Destroy(force)
	QDEL_NULL(mood)
	return ..()

/datum/storyteller/proc/apply_profile(list/profile)
	if(!islist(profile))
		return FALSE

	id = profile["id"] || id
	name = profile["name"] || name
	desc = profile["desc"] || desc
	ooc_desc = profile["ooc_desc"] || ooc_desc
	ooc_difficulty = profile["ooc_difficulty"] || ooc_difficulty
	portrait_path = profile["portrait_path"] || ""
	logo_path = profile["logo_path"] || ""
	average_event_interval_days = clamp(profile["average_event_interval_days"] || STORYTELLER_DEFAULT_INTERVAL_DAYS, STORYTELLER_MIN_INTERVAL_DAYS, STORYTELLER_MAX_INTERVAL_DAYS)

	var/mood_path = profile["mood_path"]
	if(ispath(mood_path, /datum/storyteller_mood))
		QDEL_NULL(mood)
		mood = new mood_path
	else if(!mood)
		mood = new /datum/storyteller_mood/classic

	welcome_speech = islist(profile["welcome_speech"]) ? profile["welcome_speech"] : list()
	round_speech = islist(profile["round_speech"]) ? profile["round_speech"] : list()
	return TRUE

/datum/storyteller/proc/get_next_interval_days(datum/storyteller_cell_plan/plan)
	var/interval = plan && plan.interval_override_days > 0 ? plan.interval_override_days : average_event_interval_days
	if(mood)
		interval *= mood.get_interval_multiplier()
	interval *= rand(75, 125) / 100
	return clamp(interval, STORYTELLER_MIN_INTERVAL_DAYS, STORYTELLER_MAX_INTERVAL_DAYS)

/// Picks the next incident for a cell: category from the mood, then a weighted pick inside it.
/datum/storyteller/proc/pick_event_for_cell(datum/planet_cell/cell, last_event_id = null)
	if(!cell || !SSstorytellers)
		return null

	var/list/available = list()
	for(var/event_id in SSstorytellers.events_by_id)
		var/datum/storyteller_event/event = SSstorytellers.events_by_id[event_id]
		if(!event || !event.is_available(cell, src) || !event.passes_selection_rules(cell, src))
			continue
		if(event.get_weight(cell, src) <= 0)
			continue
		available += event

	if(length(available) > 1 && last_event_id)
		for(var/datum/storyteller_event/event as anything in available)
			if(event.id == last_event_id)
				available -= event
				break

	if(!length(available))
		return null

	var/target_category = mood ? mood.pick_category(difficulty_multiplier) : STORY_EVENT_NEUTRAL
	var/list/pool = list()
	for(var/datum/storyteller_event/event as anything in available)
		if(event.category == target_category)
			pool += event
	// The wanted category may be empty (e.g. only a threat is wanted but it is on cooldown): fall back gently.
	if(!length(pool))
		for(var/datum/storyteller_event/event as anything in available)
			if(event.category == STORY_EVENT_NEUTRAL || event.category == STORY_EVENT_GOOD)
				pool += event
	if(!length(pool))
		pool = available

	var/list/weighted = list()
	for(var/datum/storyteller_event/event as anything in pool)
		var/event_weight = event.get_weight(cell, src)
		if(event.id in recent_event_ids)
			event_weight *= recent_event_weight_mult
		weighted[event] = max(0.01, event_weight)
	return pick_weight(weighted)

/// Threat points for a colony cell. Raids spend these points on raiders.
/// Colonists have diminishing returns, wealth adds linearly, older colonies get a bonus,
/// and the whole thing is multiplied by the voted difficulty.
/datum/storyteller/proc/get_threat_points(datum/planet_cell/cell)
	if(!cell)
		return STORYTELLER_THREAT_MIN
	var/pawn_points = 0
	var/step = STORYTELLER_THREAT_PER_COLONIST
	for(var/i in 1 to cell.get_colonist_count())
		pawn_points += step
		step *= STORYTELLER_THREAT_COLONIST_DECAY
	var/wealth_points = cell.get_colony_wealth() / STORYTELLER_THREAT_WEALTH_DIVISOR
	var/age_factor = 1 + STORYTELLER_THREAT_AGE_BONUS * clamp(cell.get_colony_age_days() / STORYTELLER_THREAT_AGE_RAMP_DAYS, 0, 1)
	var/points = (STORYTELLER_THREAT_BASE + pawn_points + wealth_points) * age_factor * difficulty_multiplier
	return clamp(round(points), STORYTELLER_THREAT_MIN, STORYTELLER_THREAT_MAX)

/// What gets passed to /datum/storyteller_event/proc/execute() as `difficulty`.
/datum/storyteller/proc/calculate_event_difficulty(datum/planet_cell/cell, datum/storyteller_event/event)
	if(event?.threat)
		return get_threat_points(cell)
	return difficulty_multiplier

/datum/storyteller/proc/remember_event(event_id)
	if(!event_id)
		return
	recent_event_ids += event_id
	while(length(recent_event_ids) > recent_event_limit)
		recent_event_ids.Cut(1, 2)
