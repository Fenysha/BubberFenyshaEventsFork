/datum/storyteller_plan_entry
	var/static/next_entry_id = 0
	var/id
	var/event_id
	var/fire_day = 0
	var/created_day = 0
	var/manual = FALSE

/datum/storyteller_plan_entry/New(new_event_id, new_fire_day, new_created_day, is_manual = FALSE)
	. = ..()
	next_entry_id++
	id = next_entry_id
	event_id = new_event_id
	fire_day = new_fire_day
	created_day = new_created_day
	manual = is_manual

/datum/storyteller_cell_plan
	var/datum/planet_cell/cell
	var/list/timeline = list()
	var/last_event_id
	var/last_event_day = 0
	/// Planet day on which the storyteller first saw this cell. Used as colony age.
	var/first_seen_day = 0
	/// Day of the last threat event (raid etc). Very negative = never.
	var/last_threat_day = -9999
	/// Zero means use the active storyteller's interval.
	var/interval_override_days = 0

	cooldowns = list()

/datum/storyteller_cell_plan/New(datum/planet_cell/new_cell)
	. = ..()
	cell = new_cell
	first_seen_day = SSstorytellers ? SSstorytellers.get_current_day() : 0

/datum/storyteller_cell_plan/Destroy(force)
	cell = null
	for(var/datum/storyteller_plan_entry/entry as anything in timeline)
		qdel(entry)
	timeline = null
	return ..()

/datum/storyteller_cell_plan/proc/get_upcoming_events(limit = STORYTELLER_PLAN_LENGTH)
	var/list/result = list()
	var/list/pending = timeline ? timeline.Copy() : list()
	while(length(pending) && length(result) < limit)
		var/datum/storyteller_plan_entry/soonest
		for(var/datum/storyteller_plan_entry/entry as anything in pending)
			if(!soonest || entry.fire_day < soonest.fire_day)
				soonest = entry
		if(!soonest)
			break
		result += soonest
		pending -= soonest
	return result

/datum/storyteller_cell_plan/proc/get_entry(entry_id)
	for(var/datum/storyteller_plan_entry/entry as anything in timeline)
		if(entry.id == text2num("[entry_id]"))
			return entry
	return null

/datum/storyteller_cell_plan/proc/get_latest_planned_day(current_day)
	var/latest_day = max(current_day, last_event_day)
	for(var/datum/storyteller_plan_entry/entry as anything in timeline)
		latest_day = max(latest_day, entry.fire_day)
	return latest_day

/datum/storyteller_cell_plan/proc/is_on_cooldown(event_id)
	return (cooldowns[event_id] || 0) > SSstorytellers.get_current_day()

/// Bookkeeping after an incident really fired (planned, manual or admin-forced).
/datum/storyteller_cell_plan/proc/mark_event_fired(datum/storyteller_event/event, current_day)
	if(!event)
		return
	last_event_id = event.id
	last_event_day = current_day
	if(event.threat)
		last_threat_day = current_day
	if(event.cooldown_days > 0)
		cooldowns[event.id] = current_day + event.cooldown_days

/datum/storyteller_cell_plan/proc/ensure_queue(datum/storyteller/storyteller, current_day)
	if(!cell || !storyteller)
		return

	while(length(timeline) < STORYTELLER_PLAN_LENGTH)
		var/datum/storyteller_event/event = storyteller.pick_event_for_cell(cell, last_event_id)
		if(!event)
			return

		var/fire_day = get_latest_planned_day(current_day) + storyteller.get_next_interval_days(src)
		var/datum/storyteller_plan_entry/entry = new(event.id, fire_day, current_day, FALSE)
		timeline += entry

/datum/storyteller_cell_plan/proc/add_event(event_id, fire_day, current_day, manual = TRUE)
	if(!cell || !SSstorytellers.events_by_id[event_id])
		return null
	var/datum/storyteller_plan_entry/entry = new(event_id, fire_day, current_day, manual)
	timeline += entry
	return entry

/datum/storyteller_cell_plan/proc/cancel_event(entry_id)
	var/datum/storyteller_plan_entry/entry = get_entry(entry_id)
	if(!entry)
		return FALSE
	timeline -= entry
	qdel(entry)
	return TRUE

/datum/storyteller_cell_plan/proc/reschedule_event(entry_id, fire_day)
	var/datum/storyteller_plan_entry/entry = get_entry(entry_id)
	if(!entry)
		return FALSE
	entry.fire_day = max(SSstorytellers.get_current_day(), fire_day)
	entry.manual = TRUE
	return TRUE

/datum/storyteller_cell_plan/proc/clear_events()
	for(var/datum/storyteller_plan_entry/entry as anything in timeline)
		qdel(entry)
	timeline.Cut()

/// Drops what the previous storyteller planned but keeps entries an admin added by hand.
/datum/storyteller_cell_plan/proc/clear_automatic_events()
	for(var/datum/storyteller_plan_entry/entry as anything in timeline.Copy())
		if(entry.manual)
			continue
		timeline -= entry
		qdel(entry)

/datum/storyteller_cell_plan/proc/process_plan(datum/storyteller/storyteller, current_day)
	if(!cell || !cell.is_loaded() || !storyteller)
		return

	ensure_queue(storyteller, current_day)

	var/datum/storyteller_plan_entry/next_entry
	var/list/overdue = list()
	for(var/datum/storyteller_plan_entry/entry as anything in timeline)
		if(entry.fire_day > current_day)
			continue
		overdue += entry
		if(!next_entry || entry.fire_day < next_entry.fire_day)
			next_entry = entry

	if(!next_entry)
		return

	var/event_id_to_fire = next_entry.event_id
	var/was_manual = next_entry.manual
	// A cell that was unloaded for a long time may have several overdue entries.
	// Fire only the oldest one and discard the rest, avoiding a burst on reload.
	for(var/datum/storyteller_plan_entry/entry as anything in overdue)
		timeline -= entry
		qdel(entry)

	// The plan was made a while ago. Automatic entries must still obey pacing rules
	// (a raid planned before the colony's grace period ended, two raids queued back to back, ...).
	var/datum/storyteller_event/prototype = SSstorytellers.get_event_by_id(event_id_to_fire)
	if(prototype && !was_manual && !prototype.passes_selection_rules(cell, storyteller))
		log_storyteller("Skipped planned '[prototype.name]' for [cell.get_name()]: pacing rules.")
	else
		// run_event() does the bookkeeping (recent events, cooldowns, threat pacing).
		SSstorytellers.run_event(cell, event_id_to_fire, was_manual ? "manual plan" : "planned")

	ensure_queue(storyteller, current_day)
