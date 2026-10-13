/// Base of every raid incident. A child only needs an id/name/description and the id of a
/// raid profile (faction raid_id / GLOB.raid_faction_defs key); points, pacing and
/// availability are handled here.
/datum/storyteller_event/raid
	abstract_type = /datum/storyteller_event/raid
	category = STORY_EVENT_BAD
	threat = TRUE
	requires_colony = TRUE
	min_colonists = 1
	weight = 20
	/// Key into GLOB.raid_faction_defs (same as faction.raid_id).
	var/raid_def_id

/datum/storyteller_event/raid/proc/get_def()
	return GLOB.raid_faction_defs[raid_def_id]

/datum/storyteller_event/raid/is_available(datum/planet_cell/cell, datum/storyteller/storyteller)
	. = ..()
	if(!.)
		return FALSE
	var/datum/raid_faction_def/def = get_def()
	if(!def || !cell.is_loaded() || !def.is_available_for(cell))
		return FALSE
	// Do not start a raid the colony is too small to be offered.
	if(storyteller && storyteller.get_threat_points(cell) < def.min_points)
		return FALSE
	return TRUE

/// `difficulty` is the threat point budget here.
/// Budget is further adjusted by attacker tech level and living faction members.
/datum/storyteller_event/raid/execute(datum/planet_cell/cell, datum/storyteller/storyteller, difficulty)
	var/datum/raid_faction_def/def = get_def()
	if(!def || !cell?.is_loaded())
		return FALSE
	var/points = isnum(difficulty) ? difficulty : storyteller?.get_threat_points(cell)
	if(!points)
		return FALSE

	// Attacker strength modifiers.
	var/tech = def.get_attacker_tech_level(cell)
	var/member_bonus = def.get_attacker_member_bonus(cell)
	// Higher tech → slightly larger raids (up to +40%).
	points = round(points * (1 + tech * 0.08) + member_bonus)

	if(def.max_points > 0)
		points = min(points, def.max_points)
	points = max(points, def.min_points)

	var/datum/raid_group/group = new(cell, def, points)
	group.attacker_tech_level = tech
	if(!group.launch())
		qdel(group)
		return FALSE
	return TRUE

/datum/storyteller_event/raid/pirates
	id = "raid_pirates"
	name = "Pirate raid"
	description = "A band of pirates gathers and then assaults the colony."
	raid_def_id = "pirates"
	weight = 30

/datum/storyteller_event/raid/fierce_tribe
	id = "raid_fierce_tribe"
	name = "Tribal raid"
	description = "Warriors of a fierce tribe charge the colony."
	raid_def_id = "fierce_tribe"
	weight = 18

/datum/storyteller_event/raid/savage_tribe
	id = "raid_savage_tribe"
	name = "Savage raid"
	description = "Savages attack the colony and fight to the death."
	raid_def_id = "savage_tribe"
	weight = 12

/datum/storyteller_event/raid/mechanoids
	id = "raid_mechanoids"
	name = "Mechanoid cluster"
	description = "A group of mechanoids marches on the colony and does not stop."
	category = STORY_EVENT_MAJOR
	raid_def_id = "mechanoids"
	min_difficulty = 0.7
	weight = 10

/datum/storyteller_event/raid/insectoids
	id = "raid_insectoids"
	name = "Insectoid swarm"
	description = "A swarm of insectoids crawls out of the wilderness."
	category = STORY_EVENT_MAJOR
	raid_def_id = "insectoids"
	min_difficulty = 0.7
	weight = 10
