#ifndef OLD_COMBAT_SYSTEM
/// Knocks consciousness down immediately (it then recovers at CONSCIOUSNESS_RISE_RATE).
/mob/living/carbon/proc/apply_consciousness_impulse(amount, source = null)
	if(amount <= 0 || stat == DEAD)
		return
	consciousness = max(consciousness - amount * get_consciousness_mod(), 0)
	update_blackout_state()
	refresh_medical_feedback()

/**
 * Consciousness is derived in two layers:
 *
 * 1) A physiological CAP from brain O2 and cerebral perfusion
 *    (you cannot be more awake than the brain currently allows).
 * 2) Continuous LOSS from pain and shock under that cap.
 *
 * Pain is counted exactly once (in the loss layer, never in the cap).
 * Critical loss of brain perfusion can independently cause syncope.
 */
/mob/living/carbon/proc/get_consciousness_target()
	var/target = get_physiological_consciousness_cap() - get_consciousness_soft_loss() * get_consciousness_mod()
	return clamp(target, 0, CONSCIOUSNESS_MAX)

/mob/living/carbon/proc/step_consciousness(seconds_per_tick = 1)
	if(stat == DEAD)
		consciousness = 0
		consciousness_blackout = FALSE
		return

	var/old_consciousness = consciousness
	var/delta = get_consciousness_target() - consciousness
	var/max_step = (delta < 0 ? CONSCIOUSNESS_FALL_RATE : CONSCIOUSNESS_RISE_RATE) * seconds_per_tick
	consciousness = clamp(
		consciousness + clamp(delta, -max_step, max_step),
		0,
		CONSCIOUSNESS_MAX
	)

	update_blackout_state()
	if(round(old_consciousness / 5) != round(consciousness / 5))
		update_damage_hud()

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
 * A ceiling, not a subtraction. Moderate hypoxia and low perfusion lower the
 * ceiling gradually; only critically low perfusion or near-zero brain oxygen forces syncope.
 */
/mob/living/carbon/proc/get_physiological_consciousness_cap()
	var/cap = CONSCIOUSNESS_MAX

	var/brain_o2 = get_brain_oxygen()
	if(brain_o2 < 25)
		var/o2_factor
		if(brain_o2 >= 12)
			o2_factor = ce_curve_lerp(brain_o2, 12, 25, 0.55, 1.0)
		else
			o2_factor = ce_curve_lerp(brain_o2, 0, 12, 0.15, 0.55)
		cap = min(cap, CONSCIOUSNESS_MAX * o2_factor)

	var/perfusion = get_brain_perfusion()
	if(perfusion <= PERFUSION_SYNCOPE)
		return 0

	var/perf_cap = CONSCIOUSNESS_MAX
	if(perfusion <= 0.35)
		perf_cap = ce_curve_lerp(perfusion, PERFUSION_SYNCOPE, 0.35, 0, 35)
	else if(perfusion <= 0.55)
		perf_cap = ce_curve_lerp(perfusion, 0.35, 0.55, 35, 70)
	else if(perfusion < 0.80)
		perf_cap = ce_curve_lerp(perfusion, 0.55, 0.80, 70, CONSCIOUSNESS_MAX)
	cap = min(cap, perf_cap)

	return clamp(cap, 0, CONSCIOUSNESS_MAX)

/**
 * Consciousness lost to pain, continuous (no steps) and monotonic:
 *   pain 130 -> 0, 140 -> 20, 150 -> 45, 160 -> 100 (= blackout).
 */
/mob/living/carbon/proc/get_pain_consciousness_loss()
	if(pain <= PAIN_SHOCK_THRESHOLD)
		return 0
	if(pain <= PAIN_DROP_THRESHOLD)
		return ce_curve_lerp(pain, PAIN_SHOCK_THRESHOLD, PAIN_DROP_THRESHOLD, 0, 20)

	var/critical_threshold = max(PAIN_SHOCK_PUSH_THRESHOLD, PAIN_CRIT_THRESHOLD)
	if(pain <= critical_threshold)
		return ce_curve_lerp(pain, PAIN_DROP_THRESHOLD, critical_threshold, 20, 45)
	if(pain <= PAIN_UNCONSCIOUS_THRESHOLD)
		return ce_curve_lerp(pain, critical_threshold, PAIN_UNCONSCIOUS_THRESHOLD, 45, 100)
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
