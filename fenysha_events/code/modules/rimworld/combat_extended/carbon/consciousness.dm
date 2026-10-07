#ifndef OLD_COMBAT_SYSTEM
/// Knocks consciousness down immediately (it then recovers at CONSCIOUSNESS_RISE_RATE).
/mob/living/carbon/proc/apply_consciousness_impulse(amount, source = null)
	if(amount <= 0 || stat == DEAD)
		return
	consciousness = max(consciousness - amount * consciousness_mod, 0)
	update_blackout_state()

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

/**
 * Returns the current consciousness level.
 */
/mob/living/carbon/proc/get_consciousness()
	return consciousness
#endif
