/// Parent for RimWorld-style incidents. Add new incidents as children of this datum.
///
/// The `difficulty` argument of execute() means:
///  - threat events: threat points computed from the colony (see /datum/storyteller/proc/get_threat_points)
///  - everything else: the storyteller's difficulty multiplier
/datum/storyteller_event
	abstract_type = /datum/storyteller_event

	var/id
	var/name = "Unnamed incident"
	var/description = "No description provided."
	var/category = STORY_EVENT_NEUTRAL

	/// Relative chance inside its category.
	var/weight = 10
	/// Not picked automatically while the storyteller's difficulty is below this.
	var/min_difficulty = 0
	/// Planet days before the same incident may be picked again for the same cell.
	var/cooldown_days = 0
	/// Threat events are paced separately (grace period, minimum gap) and scale with colony size.
	var/threat = FALSE
	/// Needs a player settlement on the cell.
	var/requires_colony = FALSE
	/// Needs at least this many players on the cell.
	var/min_colonists = 0

/// Hard requirements: can this incident physically run on this cell right now?
/// Admins may force anything that passes this.
/datum/storyteller_event/proc/is_available(datum/planet_cell/cell, datum/storyteller/storyteller)
	if(!cell || !cell.is_valid())
		return FALSE
	if(requires_colony && !cell.has_colony())
		return FALSE
	if(min_colonists > 0 && cell.get_colonist_count() < min_colonists)
		return FALSE
	return TRUE

/// Soft rules used only for automatic selection and firing: difficulty gate, cooldown and threat pacing.
/datum/storyteller_event/proc/passes_selection_rules(datum/planet_cell/cell, datum/storyteller/storyteller)
	if(storyteller && storyteller.difficulty_multiplier < min_difficulty)
		return FALSE
	var/datum/storyteller_cell_plan/plan = cell.get_storyteller_plan()
	if(plan.is_on_cooldown(id))
		return FALSE
	if(threat)
		if(cell.get_colony_age_days() < STORYTELLER_THREAT_GRACE_DAYS)
			return FALSE
		if(SSstorytellers.get_current_day() - plan.last_threat_day < STORYTELLER_THREAT_MIN_GAP_DAYS)
			return FALSE
	return TRUE

/datum/storyteller_event/proc/get_weight(datum/planet_cell/cell, datum/storyteller/storyteller)
	return max(0, weight)

/// Executes an incident against one cell. See the note above about `difficulty`.
/datum/storyteller_event/proc/execute(datum/planet_cell/cell, datum/storyteller/storyteller, difficulty)
	return FALSE

/datum/storyteller_event/proc/get_category_name()
	switch(category)
		if(STORY_EVENT_GOOD)
			return "Positive"
		if(STORY_EVENT_BAD)
			return "Negative"
		if(STORY_EVENT_MAJOR)
			return "Major"
	return "Neutral"
