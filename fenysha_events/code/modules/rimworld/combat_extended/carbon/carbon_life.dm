#ifndef OLD_COMBAT_SYSTEM
/proc/ce_curve_lerp(value, from_min, from_max, to_min, to_max)
	if(from_max == from_min)
		return to_max
	return to_min + (to_max - to_min) * clamp((value - from_min) / (from_max - from_min), 0, 1)

/mob/living/carbon/Life(seconds_per_tick = SSMOBS_DT)
	if(HAS_TRAIT(src, TRAIT_NO_TRANSFORM))
		return

	if(damageoverlaytemp)
		damageoverlaytemp = 0
		update_damage_hud()

	if(!HAS_TRAIT(src, TRAIT_STASIS))
		for(var/datum/injury/injury as anything in all_injuries)
			if(injury.processes)
				injury.handle_process(seconds_per_tick)

	if(HAS_TRAIT(src, TRAIT_STASIS))
		. = ..()

		if(QDELETED(src))
			return

		reagents?.handle_stasis_chems(src, seconds_per_tick)
	else
		if(stat != DEAD)
			update_blood_pressure()
			handle_lungless_oxygenation(seconds_per_tick)

		handle_dead_metabolization(seconds_per_tick)
		handle_organs(seconds_per_tick)

		. = ..()

		if(QDELETED(src))
			return

		if(.)
			if(stat != DEAD)
				update_blood_pressure()

			handle_blood(seconds_per_tick)

		if(stat != DEAD)
			// Blood loss from this tick has now been applied, so refresh
			// bleeding and circulatory state before processing the brain.
			update_injury_effects(seconds_per_tick)
			update_blood_pressure()

			var/obj/item/organ/brain/brain = get_organ_slot(ORGAN_SLOT_BRAIN)
			brain?.process_cerebral_oxygenation(seconds_per_tick)

			// Pain, shock, and consciousness are calculated last so they
			// include the physiological changes from the current tick.
			process_medical_response(seconds_per_tick)

			for(var/key in mind?.addiction_points)
				GLOB.addictions[key].process_addiction(src, seconds_per_tick)

			handle_brain_damage(seconds_per_tick)

	if(stat != DEAD)
		return TRUE

/**
 * Per-tick medical update. This is the ONLY place where time-based medical
 * processes happen (shock build-up, consciousness slew, pain side effects).
 * Impulses and modifier changes only change values and never advance time.
 */
/mob/living/carbon/proc/process_medical_response(seconds_per_tick)
	acute_pain = max(
		acute_pain - ACUTE_PAIN_RECOVERY_RATE * seconds_per_tick,
		0
	)

	shock_base = max(
		shock_base - SHOCK_RECOVERY_RATE * shock_recovery_mod * seconds_per_tick,
		0
	)

	var/pain_over = pain - PAIN_SHOCK_PUSH_THRESHOLD
	if(pain_over > 0)
		shock_base = min(shock_base + pain_over * PAIN_SHOCK_RATE * seconds_per_tick, SHOCK_MAX * 2)
	shock_base = max(shock_base, get_hypovolemic_shock_floor())

	consciousness_stun = max(
		consciousness_stun - CONSCIOUSNESS_STUN_RECOVERY_RATE * consciousness_recovery_mod * seconds_per_tick,
		0
	)

	recalculate_medical_state()
	step_consciousness(seconds_per_tick)
	process_pain_effects(seconds_per_tick)

/**
 * Rebuilds displayed pain and shock from their sources.
 * Pure recalculation: does not advance time and has no side effects,
 * so it is safe to call from impulses, modifiers and limb updates.
 */
/mob/living/carbon/proc/recalculate_medical_state()
	pain = clamp(
		(pain_base + pain_misc + acute_pain) * pain_mod,
		0,
		pain_limit
	)

	shock = clamp(
		shock_base * shock_mod,
		0,
		shock_limit
	)
#endif
