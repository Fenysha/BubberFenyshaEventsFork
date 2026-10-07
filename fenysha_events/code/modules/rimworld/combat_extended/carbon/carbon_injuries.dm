#ifndef OLD_COMBAT_SYSTEM
/**
 * Called every Life tick.
 * Aggregates bleeding from all active injuries and refreshes the cached bleed rate.
 */
/mob/living/carbon/proc/update_injury_effects(seconds_per_tick = 1)
	var/old_bleed = total_bleed_rate
	total_bleed_rate = 0

	for(var/datum/injury/injury as anything in all_injuries)
		// Internal bleeding drains blood in injury.process_internal_bleeding().
		// Counting it here would make handle_blood() drip it onto the floor.
		if(injury.is_internal_bleeder())
			continue
		total_bleed_rate += injury.get_bleed_rate()

	if(abs(old_bleed - total_bleed_rate) > 0.3)
		update_bleed_effects()

/**
 * Handles bleeding-related feedback such as messages and overlays.
 */
/mob/living/carbon/proc/update_bleed_effects()
	return

/**
 * Returns the current total bleeding rate from all injuries.
 */
/mob/living/carbon/get_total_bleed_rate()
	return total_bleed_rate

/**
 * Rebuilds the all_injuries list from all bodyparts.
 * This is primarily a safety/resynchronization mechanism.
 */
/mob/living/carbon/proc/rebuild_all_injuries()
	all_injuries = list()

	for(var/obj/item/bodypart/BP as anything in bodyparts)
		for(var/datum/injury/injury as anything in BP.injuries)
			all_injuries += injury

/mob/living/carbon/proc/update_injury_hud()
	return

/mob/living/carbon/get_bleed_rate()
	if(HAS_TRAIT(src, TRAIT_GODMODE) || !can_bleed())
		return 0

	. = total_bleed_rate
	return .
#endif
