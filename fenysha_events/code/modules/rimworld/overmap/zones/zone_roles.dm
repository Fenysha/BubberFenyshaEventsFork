/**
 * Room roles (RimWorld RoomRoleDef).
 *
 * A role scores the zone from the tag counts gathered in rw_recalculate_stats().
 * The role with the highest score wins; score <= 0 means "not this role".
 * `priority` breaks ties (higher wins).
 *
 * To add a role: make a subtype of /datum/rw_room_role, override get_score().
 */
GLOBAL_LIST_INIT(rw_room_roles, init_rw_room_roles())

/proc/init_rw_room_roles()
	var/list/out = list()
	for(var/path in subtypesof(/datum/rw_room_role))
		var/datum/rw_room_role/R = new path
		if(R.abstract)
			qdel(R)
			continue
		out[path] = R
	// Parents are not "abstract" for subtypesof, so make sure the base none exists.
	return out

/datum/rw_room_role
	var/name = "Room"
	var/abstract = FALSE
	var/priority = 0
	/// Mood / needs hooks other systems can read (e.g. "sleeping spot", "eating spot").
	var/list/flags

/// Return a score > 0 when `zone` qualifies. `tags` is tag -> count.
/datum/rw_room_role/proc/get_score(list/tags, area/rimworld/zone/zone)
	return 0

/datum/rw_room_role/none
	name = "Room"
	priority = -100

/datum/rw_room_role/none/get_score(list/tags, area/rimworld/zone/zone)
	return 0.001

/datum/rw_room_role/bedroom
	name = "Bedroom"
	priority = 40
	flags = list("sleep")

/datum/rw_room_role/bedroom/get_score(list/tags, area/rimworld/zone/zone)
	// Exactly one regular bed = a personal bedroom.
	return tags[RW_TAG_BED] == 1 ? 50 : 0

/datum/rw_room_role/barracks
	name = "Barracks"
	priority = 40
	flags = list("sleep")

/datum/rw_room_role/barracks/get_score(list/tags, area/rimworld/zone/zone)
	return tags[RW_TAG_BED] >= 2 ? 50 + tags[RW_TAG_BED] : 0

/datum/rw_room_role/hospital
	name = "Hospital"
	priority = 60
	flags = list("medical")

/datum/rw_room_role/hospital/get_score(list/tags, area/rimworld/zone/zone)
	return tags[RW_TAG_MEDICAL_BED] ? 60 + tags[RW_TAG_MEDICAL_BED] * 5 : 0

/datum/rw_room_role/prison
	name = "Prison cell"
	priority = 70
	flags = list("prison")

/datum/rw_room_role/prison/get_score(list/tags, area/rimworld/zone/zone)
	return tags[RW_TAG_PRISON_BED] ? 70 + tags[RW_TAG_PRISON_BED] : 0

/datum/rw_room_role/kitchen
	name = "Kitchen"
	priority = 45

/datum/rw_room_role/kitchen/get_score(list/tags, area/rimworld/zone/zone)
	if(!tags[RW_TAG_STOVE])
		return 0
	// A stove with lots of tables and chairs is more of a dining hall.
	var/dining = min(tags[RW_TAG_TABLE], tags[RW_TAG_CHAIR])
	return max(0, 55 + tags[RW_TAG_STOVE] * 4 + tags[RW_TAG_FRIDGE] * 2 - dining * 3)

/datum/rw_room_role/dining
	name = "Dining room"
	priority = 35
	flags = list("eat")

/datum/rw_room_role/dining/get_score(list/tags, area/rimworld/zone/zone)
	var/seats = min(tags[RW_TAG_TABLE], tags[RW_TAG_CHAIR])
	if(seats < 1 || tags[RW_TAG_BED])
		return 0
	return 40 + seats * 3 - tags[RW_TAG_STOVE] * 2

/datum/rw_room_role/recreation
	name = "Recreation room"
	priority = 38
	flags = list("recreation")

/datum/rw_room_role/recreation/get_score(list/tags, area/rimworld/zone/zone)
	return tags[RW_TAG_RECREATION] ? 45 + tags[RW_TAG_RECREATION] * 4 : 0

/datum/rw_room_role/laboratory
	name = "Laboratory"
	priority = 50

/datum/rw_room_role/laboratory/get_score(list/tags, area/rimworld/zone/zone)
	return tags[RW_TAG_RESEARCH] ? 55 + tags[RW_TAG_RESEARCH] * 3 : 0

/datum/rw_room_role/workshop
	name = "Workshop"
	priority = 30

/datum/rw_room_role/workshop/get_score(list/tags, area/rimworld/zone/zone)
	return tags[RW_TAG_WORKBENCH] ? 35 + tags[RW_TAG_WORKBENCH] * 3 : 0

/datum/rw_room_role/throne_room
	name = "Throne room"
	priority = 80

/datum/rw_room_role/throne_room/get_score(list/tags, area/rimworld/zone/zone)
	return tags[RW_TAG_THRONE] ? 90 : 0

/datum/rw_room_role/tomb
	name = "Tomb"
	priority = 55

/datum/rw_room_role/tomb/get_score(list/tags, area/rimworld/zone/zone)
	return tags[RW_TAG_GRAVE] ? 50 + tags[RW_TAG_GRAVE] : 0

/datum/rw_room_role/storeroom
	name = "Storeroom"
	priority = 20

/datum/rw_room_role/storeroom/get_score(list/tags, area/rimworld/zone/zone)
	return tags[RW_TAG_SHELF] >= 2 ? 25 + tags[RW_TAG_SHELF] : 0

/datum/rw_room_role/greenhouse
	name = "Greenhouse"
	priority = 25

/datum/rw_room_role/greenhouse/get_score(list/tags, area/rimworld/zone/zone)
	return tags[RW_TAG_PLANT] >= 3 ? 30 + tags[RW_TAG_PLANT] : 0

/// Picks the best role for the current tag counts.
/area/rimworld/zone/proc/rw_detect_role()
	var/datum/rw_room_role/best
	var/best_score = 0
	for(var/path in GLOB.rw_room_roles)
		var/datum/rw_room_role/R = GLOB.rw_room_roles[path]
		var/score = R.get_score(rw_tag_counts, src)
		if(score <= 0)
			continue
		// priority only matters when scores are equal-ish
		score += R.priority * 0.001
		if(score > best_score)
			best_score = score
			best = R
	if(!best)
		best = GLOB.rw_room_roles[/datum/rw_room_role/none]
	if(best != rw_role)
		rw_role = best
		rw_refresh_name()
	return best
