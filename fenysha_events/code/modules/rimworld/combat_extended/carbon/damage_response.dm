#ifndef OLD_COMBAT_SYSTEM
/mob/living/carbon/proc/apply_combat_impact_response(damage, body_zone, damage_type = BRUTE, source = null)
	if(damage <= 0 || stat == DEAD)
		return

	var/impact = max(damage - IMPACT_PAIN_THRESHOLD, 0)
	if(impact <= 0)
		return

	var/zone_shock_mult = IMPACT_LIMB_MULT
	var/zone_pain_mult = IMPACT_LIMB_MULT
	var/zone_consciousness_mult = IMPACT_LIMB_MULT

	switch(body_zone)
		if(BODY_ZONE_HEAD)
			zone_shock_mult = IMPACT_HEAD_MULT
			zone_pain_mult = IMPACT_HEAD_MULT
			zone_consciousness_mult = IMPACT_HEAD_MULT
		if(BODY_ZONE_CHEST)
			zone_shock_mult = IMPACT_CHEST_MULT
			zone_pain_mult = IMPACT_CHEST_MULT
			zone_consciousness_mult = IMPACT_CHEST_MULT

	if(damage_type == BURN)
		zone_consciousness_mult *= 0.35
		zone_shock_mult *= 0.60

	// High single-instance trauma produces disproportionately more shock
	// (super-linear above ~25 damage) to model kinetic energy transfer.
	var/shock_scale = IMPACT_SHOCK_MULT
	if(impact >= 25)
		shock_scale *= 1.0 + (impact - 25) * 0.018
	if(impact >= 45)
		shock_scale *= 1.25

	apply_acute_pain(impact * IMPACT_PAIN_MULT * zone_pain_mult)
	apply_shock_impulse((impact ** 0.95) * shock_scale * zone_shock_mult, source)

	var/consciousness_impulse = (max(damage - IMPACT_CONSCIOUSNESS_THRESHOLD, 0) ** 1.20) \
		* IMPACT_CONSCIOUSNESS_MULT * zone_consciousness_mult
	if(impact >= 40)
		consciousness_impulse *= 1.35
	if(consciousness_impulse > 0)
		apply_consciousness_impulse(consciousness_impulse, source)

/mob/living/carbon/proc/apply_injury_response(datum/injury/injury)
	if(!injury || stat == DEAD)
		return
	var/shock_impulse = injury.get_initial_shock()
	var/consciousness_impulse = injury.get_initial_consciousness_impact()
	if(shock_impulse > 0)
		apply_shock_impulse(shock_impulse, injury)
	if(consciousness_impulse > 0)
		apply_consciousness_impulse(consciousness_impulse, injury)
#endif
