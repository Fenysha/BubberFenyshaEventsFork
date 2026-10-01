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


/// Shock that cannot recover while the mob is hypovolemic.
/mob/living/carbon/proc/get_hypovolemic_shock_floor()
	if(!CAN_HAVE_BLOOD(src))
		return 0
	var/blood_ratio = get_blood_ratio()
	if(blood_ratio >= SHOCK_BLOOD_START)
		return 0
	return ce_curve_lerp(blood_ratio, SHOCK_BLOOD_START, SHOCK_BLOOD_FULL, 0, SHOCK_BLOOD_FLOOR_MAX)


/**
 * Consciousness is derived in two layers:
 *
 * 1) A physiological CAP from brain O2 and cerebral perfusion
 *    (you cannot be more awake than the brain currently allows).
 * 2) Continuous LOSS from pain and shock under that cap.
 *
 * Pain is counted exactly once (in the loss layer, never in the cap).
 */
/mob/living/carbon/proc/get_consciousness_target()
	var/target = get_physiological_consciousness_cap() - get_consciousness_soft_loss() * consciousness_mod
	return clamp(target, 0, CONSCIOUSNESS_MAX)


/mob/living/carbon/proc/step_consciousness(seconds_per_tick = 1)
	if(stat == DEAD)
		consciousness = 0
		consciousness_blackout = FALSE
		return

	var/delta = get_consciousness_target() - consciousness
	var/max_step = (delta < 0 ? CONSCIOUSNESS_FALL_RATE : CONSCIOUSNESS_RISE_RATE) * seconds_per_tick
	consciousness = clamp(
		consciousness + clamp(delta, -max_step, max_step),
		0,
		CONSCIOUSNESS_MAX
	)

	update_blackout_state()


/mob/living/carbon/proc/update_blackout_state()
	if(stat == DEAD)
		return

	if(!consciousness_blackout && consciousness <= CONSCIOUSNESS_BLACKOUT)
		consciousness_blackout = TRUE
		update_stat()
	else if(consciousness_blackout && consciousness >= CONSCIOUSNESS_WAKE)
		consciousness_blackout = FALSE
		update_stat()

	if(consciousness_blackout)
		Unconscious(3 SECONDS)
		clear_fullscreen("pain_spots")
	else if(stat == SOFT_CRIT || stat == HARD_CRIT)
		// Let update_stat() drop us back to STABLE once the knockout has expired.
		update_stat()


/**
 * How awake the brain is *allowed* to be given O2 and perfusion.
 * A ceiling, not a subtraction. There are no floors: zero oxygen or zero
 * perfusion drives the ceiling to PERFUSION_CONSCIOUSNESS_MIN(default 40)
 */
/mob/living/carbon/proc/get_physiological_consciousness_cap()
	var/cap = CONSCIOUSNESS_MAX

	var/brain_o2 = get_brain_oxygen()
	if(brain_o2 < BRAIN_O2_MAX)
		var/o2_ratio = clamp(brain_o2 / BRAIN_O2_MAX, 0, 1)
		var/o2_factor = o2_ratio * o2_ratio * (3 - 2 * o2_ratio)
		if(brain_o2 < BRAIN_O2_SEVERE)
			o2_factor *= 0.6 + 0.4 * (brain_o2 / BRAIN_O2_SEVERE)
		cap = min(cap, CONSCIOUSNESS_MAX * o2_factor)

	// Perfusion curve. Syncope perfusion = cap 0 (blackout).
	var/perfusion = get_brain_perfusion()
	var/perf_cap = CONSCIOUSNESS_MAX
	if(perfusion <= PERFUSION_SYNCOPE)
		perf_cap = 0
	else if(perfusion <= 0.55)
		perf_cap = ce_curve_lerp(perfusion, PERFUSION_SYNCOPE, 0.55, 0, 25)
	else if(perfusion <= 0.70)
		perf_cap = ce_curve_lerp(perfusion, 0.55, 0.70, 25, 65)
	else if(perfusion < 0.85)
		perf_cap = ce_curve_lerp(perfusion, 0.70, 0.85, 65, CONSCIOUSNESS_MAX)
	cap = min(cap, perf_cap)

	return clamp(cap, PERFUSION_CONSCIOUSNESS_MIN, CONSCIOUSNESS_MAX)


/**
 * Consciousness lost to pain, continuous (no steps) and monotonic:
 *   pain 45 -> 0, 70 -> 20, 90 -> 45, 110 -> 65, 140 -> 100 (= blackout).
 */
/mob/living/carbon/proc/get_pain_consciousness_loss()
	if(pain <= PAIN_SHOCK_THRESHOLD)
		return 0
	if(pain <= PAIN_SHOCK_PUSH_THRESHOLD)
		return ce_curve_lerp(pain, PAIN_SHOCK_THRESHOLD, PAIN_SHOCK_PUSH_THRESHOLD, 0, 20)
	if(pain <= PAIN_CRIT_THRESHOLD)
		return ce_curve_lerp(pain, PAIN_SHOCK_PUSH_THRESHOLD, PAIN_CRIT_THRESHOLD, 20, 45)
	if(pain <= PAIN_DROP_THRESHOLD)
		return ce_curve_lerp(pain, PAIN_CRIT_THRESHOLD, PAIN_DROP_THRESHOLD, 45, 65)
	if(pain <= PAIN_UNCONSCIOUS_THRESHOLD)
		return ce_curve_lerp(pain, PAIN_DROP_THRESHOLD, PAIN_UNCONSCIOUS_THRESHOLD, 65, 100)
	return 100 + (pain - PAIN_UNCONSCIOUS_THRESHOLD)


/**
 * Pain / shock contributions only.
 * Brain O2 and perfusion are handled as a physiological cap, not here.
 */
/mob/living/carbon/proc/get_consciousness_soft_loss()
	var/loss = get_pain_consciousness_loss()

	if(shock > SHOCK_MILD)
		loss += (shock - SHOCK_MILD) * 0.22
	if(shock > SHOCK_SEVERE)
		loss += (shock - SHOCK_SEVERE) * 0.40

	loss += consciousness_stun
	return loss



/atom/movable/screen/fullscreen/pain_spots
	icon = 'icons/hud/screen_full.dmi'
	icon_state = "brutedamageoverlay"
	layer = UI_DAMAGE_LAYER
	plane = FULLSCREEN_PLANE
	alpha = 0
	color = list(
		1.1, 0.05, 0.05, 0,
		0.15, 0.4, 0.1, 0,
		0.1, 0.05, 0.35, 0,
		0, 0, 0, 0.85,
		0, 0, 0, 0
	)

/atom/movable/screen/fullscreen/pain_spots/update_for_view(client_view)
	. = ..()
	animate(src, alpha = alpha, time = 0)
	animate(alpha = min(255, alpha + 40), time = 1.2 SECONDS, loop = -1, easing = SINE_EASING)
	animate(alpha = max(0, alpha - 30), time = 1.4 SECONDS, easing = SINE_EASING)


/**
 * Side effects of pain. Called once per Life tick,
 * all chances are per second and scaled by seconds_per_tick.
 */
/mob/living/carbon/proc/process_pain_effects(seconds_per_tick = 1)
	if(pain >= PAIN_FIBRILLATION_THRESHOLD && needs_heart())
		var/obj/item/organ/heart/heart = get_organ_slot(ORGAN_SLOT_HEART)
		if(heart && !heart.fibrillating && heart.is_beating())
			var/fib_chance = abs((pain - PAIN_FIBRILLATION_THRESHOLD) * 0.01)
			if(SPT_PROB(fib_chance, seconds_per_tick))
				if(heart.enter_fibrillation())
					to_chat(src, span_userdanger("Agony tears through your chest — your heart stumbles into chaos!"))
					visible_message(span_danger("[src] clutches at [src.p_their()] chest, face contorted in pure agony!"))

	if(consciousness_blackout)
		clear_fullscreen("pain_spots")
		update_pain_movespeed()
		return

	if(pain >= PAIN_BLUR_THRESHOLD)
		var/blur_strength = min(PAIN_BLUR_MAX, (pain - PAIN_BLUR_THRESHOLD) * 0.045 SECONDS)
		set_eye_blur_if_lower(blur_strength)

	if(pain >= PAIN_SPOTS_THRESHOLD)
		var/severity = clamp(round((pain - PAIN_SPOTS_THRESHOLD) / 18), 1, PAIN_SPOTS_MAX_SEVERITY)
		var/atom/movable/screen/fullscreen/pain_spots/spots = overlay_fullscreen("pain_spots", /atom/movable/screen/fullscreen/pain_spots, severity)
		spots.alpha = clamp(40 + severity * 28, 40, 220)
	else
		clear_fullscreen("pain_spots", animated = 8)

	if(pain >= PAIN_DROP_THRESHOLD)
		var/drop_chance = min(4 + (pain - PAIN_DROP_THRESHOLD) * 0.06, 18)
		if(SPT_PROB(drop_chance, seconds_per_tick))
			var/obj/item/held = get_active_held_item()
			if(held)
				dropItemToGround(held)
				visible_message(
					span_warning("[src] drops [held] in pain!"),
					span_userdanger("You drop [held] from the pain!")
				)
			if(pain >= PAIN_UNCONSCIOUS_THRESHOLD && prob(25))
				var/obj/item/offhand = get_inactive_held_item()
				if(offhand)
					dropItemToGround(offhand)

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
		slowdown += 1.2
	else if(pain >= PAIN_SHOCK_THRESHOLD)
		slowdown += 0.6

	if(consciousness <= CONSCIOUSNESS_HEAVY)
		slowdown += 1.6
	else if(consciousness <= CONSCIOUSNESS_IMPAIRED)
		slowdown += 0.8

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


/mob/living/carbon/get_bleed_rate()
	if(HAS_TRAIT(src, TRAIT_GODMODE) || !can_bleed())
		return 0

	. = total_bleed_rate
	return .
#endif
