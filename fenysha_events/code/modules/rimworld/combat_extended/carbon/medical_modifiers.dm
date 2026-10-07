#ifndef OLD_COMBAT_SYSTEM
/mob/living/carbon/proc/get_medical_multiplier(list/modifiers)
	if(!length(modifiers))
		return 1.0
	var/result = 1.0
	for(var/source in modifiers)
		var/value = modifiers[source]
		if(isnum(value))
			result *= value
	return max(result, 0)

/mob/living/carbon/proc/get_medical_limit(list/limits, default_limit)
	if(!length(limits))
		return default_limit
	var/result = default_limit
	for(var/source in limits)
		var/value = limits[source]
		if(isnum(value))
			result = min(result, value)
	return max(result, 0)

/mob/living/carbon/proc/recalculate_medical_modifiers()
	pain_mod = get_medical_multiplier(pain_modifiers)
	shock_mod = get_medical_multiplier(shock_modifiers)
	consciousness_mod = get_medical_multiplier(consciousness_modifiers)
	shock_recovery_mod = get_medical_multiplier(shock_recovery_modifiers)
	consciousness_recovery_mod = get_medical_multiplier(consciousness_recovery_modifiers)
	pain_limit = get_medical_limit(pain_limit_modifiers, PAIN_MAX)
	shock_limit = get_medical_limit(shock_limit_modifiers, SHOCK_MAX)
	recalculate_medical_state()

/mob/living/carbon/proc/set_pain_modifier(source, multiplier)
	if(isnull(source))
		return
	LAZYSET(pain_modifiers, source, max(multiplier, 0))
	recalculate_medical_modifiers()

/mob/living/carbon/proc/remove_pain_modifier(source)
	LAZYREMOVE(pain_modifiers, source)
	recalculate_medical_modifiers()

/mob/living/carbon/proc/set_shock_modifier(source, multiplier)
	if(isnull(source))
		return
	LAZYSET(shock_modifiers, source, max(multiplier, 0))
	recalculate_medical_modifiers()

/mob/living/carbon/proc/remove_shock_modifier(source)
	LAZYREMOVE(shock_modifiers, source)
	recalculate_medical_modifiers()

/mob/living/carbon/proc/set_consciousness_modifier(source, multiplier)
	if(isnull(source))
		return
	LAZYSET(consciousness_modifiers, source, max(multiplier, 0))
	recalculate_medical_modifiers()

/mob/living/carbon/proc/remove_consciousness_modifier(source)
	LAZYREMOVE(consciousness_modifiers, source)
	recalculate_medical_modifiers()

/mob/living/carbon/proc/set_shock_recovery_modifier(source, multiplier)
	if(isnull(source))
		return
	LAZYSET(shock_recovery_modifiers, source, max(multiplier, 0))
	recalculate_medical_modifiers()

/mob/living/carbon/proc/remove_shock_recovery_modifier(source)
	LAZYREMOVE(shock_recovery_modifiers, source)
	recalculate_medical_modifiers()

/mob/living/carbon/proc/set_consciousness_recovery_modifier(source, multiplier)
	if(isnull(source))
		return
	LAZYSET(consciousness_recovery_modifiers, source, max(multiplier, 0))
	recalculate_medical_modifiers()

/mob/living/carbon/proc/remove_consciousness_recovery_modifier(source)
	LAZYREMOVE(consciousness_recovery_modifiers, source)
	recalculate_medical_modifiers()

/mob/living/carbon/proc/set_pain_limit(source, limit)
	if(isnull(source))
		return
	LAZYSET(pain_limit_modifiers, source, max(limit, 0))
	recalculate_medical_modifiers()

/mob/living/carbon/proc/remove_pain_limit(source)
	LAZYREMOVE(pain_limit_modifiers, source)
	recalculate_medical_modifiers()

/mob/living/carbon/proc/set_shock_limit(source, limit)
	if(isnull(source))
		return
	LAZYSET(shock_limit_modifiers, source, max(limit, 0))
	recalculate_medical_modifiers()

/mob/living/carbon/proc/remove_shock_limit(source)
	LAZYREMOVE(shock_limit_modifiers, source)
	recalculate_medical_modifiers()
#endif
