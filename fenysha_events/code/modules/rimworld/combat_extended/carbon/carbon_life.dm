#ifndef OLD_COMBAT_SYSTEM

/mob/living/carbon/Life(seconds_per_tick = SSMOBS_DT)
	if(HAS_TRAIT(src, TRAIT_NO_TRANSFORM))
		return

	if(damageoverlaytemp)
		damageoverlaytemp = 0
		update_damage_hud()

	for(var/datum/injury/injury as anything in all_injuries)
		if(injury.processes)
			injury.handle_process(seconds_per_tick)

	update_injury_effects(seconds_per_tick)

	if(HAS_TRAIT(src, TRAIT_STASIS))
		. = ..()
		if(QDELETED(src))
			return
		reagents?.handle_stasis_chems(src, seconds_per_tick)
	else
		handle_dead_metabolization(seconds_per_tick)
		handle_organs(seconds_per_tick)

		. = ..()
		if(QDELETED(src))
			return

		if(.)
			handle_blood(seconds_per_tick)

		if(stat != DEAD)
			for(var/key in mind?.addiction_points)
				GLOB.addictions[key].process_addiction(src, seconds_per_tick)
			handle_brain_damage(seconds_per_tick)

	if(stat != DEAD)
		return TRUE

#endif

// ========================
// PAIN / SHOCK / CONSCIOUSNESS
// ========================

/**
 * Called by a bodypart when its pain contribution changes.
 * Recalculates total pain from all limbs.
 */
/mob/living/carbon/proc/update_pain_from_limb(obj/item/bodypart/source_limb)
	var/total = 0
	for(var/obj/item/bodypart/BP as anything in bodyparts)
		total += BP.current_pain
	set_pain(total)

/**
 * Sets pain and triggers shock/consciousness recalculation.
 */
/mob/living/carbon/proc/set_pain(new_pain)
	new_pain = clamp(new_pain, 0, PAIN_MAX)
	if(pain == new_pain)
		return
	var/old_pain = pain
	pain = new_pain
	on_pain_change(old_pain, pain)

/**
 * Adjusts pain by the given amount (can be negative).
 */
/mob/living/carbon/proc/adjust_pain(amount)
	set_pain(pain + amount)

/**
 * Reaction to pain level change.
 */
/mob/living/carbon/proc/on_pain_change(old_pain, new_pain)
	update_shock_and_consciousness()

/**
 * Main recalculation of shock and consciousness based on pain and bleeding.
 */
/mob/living/carbon/proc/update_shock_and_consciousness(seconds_per_tick = 1)
	var/shock_gain = 0

	if(pain >= PAIN_SHOCK_THRESHOLD)
		shock_gain += (pain - PAIN_SHOCK_THRESHOLD) * 0.12

	if(total_bleed_rate > 1.0)
		shock_gain += total_bleed_rate * 2.5

	if(shock_gain > 0)
		shock = min(shock + shock_gain * seconds_per_tick, SHOCK_MAX)
	else if(pain < PAIN_SHOCK_THRESHOLD * 0.7)
		shock = max(shock - 6 * seconds_per_tick, 0)

	var/consciousness_target = CONSCIOUSNESS_MAX

	if(pain > PAIN_CRIT_THRESHOLD)
		consciousness_target -= (pain - PAIN_CRIT_THRESHOLD) * 0.9
	if(pain > PAIN_UNCONSCIOUS_THRESHOLD)
		consciousness_target -= (pain - PAIN_UNCONSCIOUS_THRESHOLD) * 1.4

	if(shock > SHOCK_MILD)
		consciousness_target -= (shock - SHOCK_MILD) * 0.7
	if(shock > SHOCK_SEVERE)
		consciousness_target -= (shock - SHOCK_SEVERE) * 1.1

	consciousness = clamp(consciousness_target, 0, CONSCIOUSNESS_MAX)
	apply_pain_effects()

/**
 * Applies gameplay effects from current pain, shock and consciousness levels.
 */
/mob/living/carbon/proc/apply_pain_effects()
	// Unconsciousness
	if(consciousness <= 0)
		Unconscious(3 SECONDS)
		return

	// Drop items on very high pain spikes
	if(pain >= PAIN_UNCONSCIOUS_THRESHOLD && prob(12))
		var/obj/item/held = get_active_held_item()
		if(held)
			dropItemToGround(held)
			visible_message(span_warning("[src] drops [held] in pain!"), \
				span_userdanger("You drop [held] from the pain!"))

	/*
	// Emotes
	if(pain >= PAIN_CRIT_THRESHOLD && prob(8))
		emote(pick("scream", "whimper", "groan"))
	else if(pain >= PAIN_SHOCK_THRESHOLD && prob(5))
		emote(pick("groan", "moan", "whimper"))
	*/
	// Movement slowdown via movespeed modifier
	update_pain_movespeed()

/**
 * Updates movespeed modifiers based on pain and consciousness.
 */
/datum/movespeed_modifier/pain
	variable = TRUE
	blacklisted_movetypes = FLOATING|FLYING

/mob/living/carbon/proc/update_pain_movespeed()
	remove_movespeed_modifier(/datum/movespeed_modifier/pain)

	var/slowdown = 0

	if(pain >= PAIN_CRIT_THRESHOLD)
		slowdown += 0.6
	else if(pain >= PAIN_SHOCK_THRESHOLD)
		slowdown += 0.3

	if(consciousness <= CONSCIOUSNESS_HEAVY)
		slowdown += 0.8
	else if(consciousness <= CONSCIOUSNESS_IMPAIRED)
		slowdown += 0.4

	if(shock >= SHOCK_SEVERE)
		slowdown += 0.5
	else if(shock >= SHOCK_MODERATE)
		slowdown += 0.25

	if(slowdown > 0)
		add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/pain, multiplicative_slowdown = slowdown)

/**
 * Called every Life tick. Handles bleeding aggregation and shock/consciousness.
 */
/mob/living/carbon/proc/update_injury_effects(seconds_per_tick = 1)
	var/old_bleed = total_bleed_rate
	total_bleed_rate = 0

	for(var/datum/injury/injury as anything in all_injuries)
		total_bleed_rate += injury.get_bleed_rate()

	update_shock_and_consciousness(seconds_per_tick)

	if(abs(old_bleed - total_bleed_rate) > 0.3)
		update_bleed_effects()

/**
 * Handles bleeding-related feedback (messages, overlays, etc).
 */
/mob/living/carbon/proc/update_bleed_effects()
	return

/**
 * Returns total bleed rate from all injuries.
 */
/mob/living/carbon/get_total_bleed_rate()
	return total_bleed_rate

/**
 * Returns current pain level.
 */
/mob/living/carbon/proc/get_pain()
	return pain

/**
 * Returns current shock level.
 */
/mob/living/carbon/proc/get_shock()
	return shock

/**
 * Returns current consciousness level.
 */
/mob/living/carbon/proc/get_consciousness()
	return consciousness

/**
 * Returns TRUE if the mob is in significant pain.
 */
/mob/living/carbon/proc/in_pain()
	return pain >= PAIN_SHOCK_THRESHOLD

/**
 * Returns TRUE if the mob is in shock.
 */
/mob/living/carbon/proc/in_shock()
	return shock >= SHOCK_MILD

/**
 * Rebuilds all_injuries list from bodyparts (safety/resync).
 */
/mob/living/carbon/proc/rebuild_all_injuries()
	all_injuries = list()
	for(var/obj/item/bodypart/BP as anything in bodyparts)
		for(var/datum/injury/injury as anything in BP.injuries)
			all_injuries += injury

/mob/living/carbon/proc/update_injury_hud()
	return
