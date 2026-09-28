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

			sync_oxyloss()

			for(var/key in mind?.addiction_points)
				GLOB.addictions[key].process_addiction(src, seconds_per_tick)

			handle_brain_damage(seconds_per_tick)

	if(stat != DEAD)
		return TRUE


#endif

// ========================
// PAIN / SHOCK / CONSCIOUSNESS
// ========================

/mob/living/carbon/proc/process_medical_response(seconds_per_tick)
	acute_pain = max(
		acute_pain - ACUTE_PAIN_RECOVERY_RATE * seconds_per_tick,
		0
	)

	shock_base = max(
		shock_base - SHOCK_RECOVERY_RATE * shock_recovery_mod * seconds_per_tick,
		0
	)

	consciousness_stun = max(
		consciousness_stun - CONSCIOUSNESS_STUN_RECOVERY_RATE * consciousness_recovery_mod * seconds_per_tick,
		0
	)

	recalculate_medical_state()


/mob/living/carbon/proc/recalculate_medical_state()
	pain = clamp(
		(pain_base + acute_pain) * pain_mod,
		0,
		pain_limit
	)

	shock = clamp(
		shock_base * shock_mod,
		0,
		shock_limit
	)

	update_consciousness_from_state()


/mob/living/carbon/proc/update_consciousness_from_state()
	if(stat == DEAD)
		consciousness = 0
		return

	var/consciousness_loss = 0

	// Severe pain begins impairing consciousness.
	if(pain > PAIN_CRIT_THRESHOLD)
		consciousness_loss += (pain - PAIN_CRIT_THRESHOLD) * 0.25

	// Extremely high pain has an additional, stronger effect.
	if(pain > PAIN_UNCONSCIOUS_THRESHOLD)
		consciousness_loss += (pain - PAIN_UNCONSCIOUS_THRESHOLD) * 0.55

	// Shock progressively reduces consciousness.
	if(shock > SHOCK_MILD)
		consciousness_loss += (shock - SHOCK_MILD) * 0.30

	if(shock > SHOCK_SEVERE)
		consciousness_loss += (shock - SHOCK_SEVERE) * 0.55

	// Insufficient cerebral perfusion can cause syncope.
	var/perfusion = get_brain_perfusion()
	if(perfusion < PERFUSION_SYNCOPE)
		consciousness_loss += (PERFUSION_SYNCOPE - perfusion) * 200

	// Cerebral hypoxia directly impairs consciousness.
	var/brain_o2 = get_brain_oxygen()
	if(brain_o2 < BRAIN_O2_HYPOXIA)
		consciousness_loss += (BRAIN_O2_HYPOXIA - brain_o2) * 2.2

	consciousness_loss += consciousness_stun

	consciousness = clamp(
		CONSCIOUSNESS_MAX - consciousness_loss * consciousness_mod,
		0,
		CONSCIOUSNESS_MAX
	)

	apply_pain_effects()


/**
 * Applies gameplay effects from the current pain, shock, and consciousness levels.
 */
/mob/living/carbon/proc/apply_pain_effects()
	// Loss of consciousness.
	if(consciousness <= 0)
		Unconscious(3 SECONDS)
		return

	// Severe acute pain can cause involuntary loss of held items.
	if(pain >= PAIN_UNCONSCIOUS_THRESHOLD && prob(12))
		var/obj/item/held = get_active_held_item()

		if(held)
			dropItemToGround(held)
			visible_message(
				span_warning("[src] drops [held] in pain!"),
				span_userdanger("You drop [held] from the pain!")
			)

	update_pain_movespeed()


/**
 * Updates movement speed modifiers based on pain, shock, and consciousness.
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
		add_or_update_variable_movespeed_modifier(
			/datum/movespeed_modifier/pain,
			multiplicative_slowdown = slowdown
	)


/**
 * Called every Life tick.
 * Aggregates bleeding from all active injuries and refreshes the cached bleed rate.
 */
/mob/living/carbon/proc/update_injury_effects(seconds_per_tick = 1)
	var/old_bleed = total_bleed_rate
	total_bleed_rate = 0

	for(var/datum/injury/injury as anything in all_injuries)
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
 * Returns the current pain level.
 */
/mob/living/carbon/proc/get_pain()
	return pain


/**
 * Returns the current shock level.
 */
/mob/living/carbon/proc/get_shock()
	return shock


/**
 * Returns the current consciousness level.
 */
/mob/living/carbon/proc/get_consciousness()
	return consciousness


/**
 * Returns TRUE if the mob is experiencing significant pain.
 */
/mob/living/carbon/proc/in_pain()
	return pain >= PAIN_SHOCK_THRESHOLD


/**
 * Returns TRUE if the mob is experiencing significant shock.
 */
/mob/living/carbon/proc/in_shock()
	return shock >= SHOCK_MILD


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
