#ifndef OLD_COMBAT_SYSTEM
/mob/living/carbon/proc/apply_shock_impulse(amount, source = null)
	if(amount <= 0)
		return
	shock_base = clamp(shock_base + amount, 0, SHOCK_MAX * 2)
	recalculate_medical_state()

/// Shock that cannot recover while the mob is hypovolemic.
/mob/living/carbon/proc/get_hypovolemic_shock_floor()
	if(!CAN_HAVE_BLOOD(src))
		return 0
	var/blood_ratio = get_blood_ratio()
	if(blood_ratio >= SHOCK_BLOOD_START)
		return 0
	return ce_curve_lerp(blood_ratio, SHOCK_BLOOD_START, SHOCK_BLOOD_FULL, 0, SHOCK_BLOOD_FLOOR_MAX)

/**
 * Returns the current shock level.
 */
/mob/living/carbon/proc/get_shock()
	return shock

/**
 * Returns TRUE if the mob is experiencing significant shock.
 */
/mob/living/carbon/proc/in_shock()
	return shock >= SHOCK_MILD
#endif
