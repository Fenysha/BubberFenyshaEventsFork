/**
 * A single mood-affecting factor attached to a psychology datum.
 */
/datum/psychology_factor
	var/category
	var/id
	var/mood_change = 0
	var/description = ""
	/// world.time when this factor expires (0 = never)
	var/timeout = 0
	var/permanent = FALSE
