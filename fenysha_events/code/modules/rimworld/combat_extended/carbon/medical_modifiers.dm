#ifndef OLD_COMBAT_SYSTEM
/**
 * Medical modifier API. The data lives on /datum/physiology (humans only, see human_physiology.dm);
 * non-human carbons have no physiology, so every set_* is a no-op and every get_* is neutral.
 */
/mob/living/carbon/proc/get_pain_mod()
	var/datum/physiology/phys = get_medical_physiology()
	return phys ? phys.pain_mod : 1

/mob/living/carbon/proc/get_shock_mod()
	var/datum/physiology/phys = get_medical_physiology()
	return phys ? phys.shock_mod : 1

/mob/living/carbon/proc/get_consciousness_mod()
	var/datum/physiology/phys = get_medical_physiology()
	return phys ? phys.consciousness_mod : 1

/mob/living/carbon/proc/get_shock_recovery_mod()
	var/datum/physiology/phys = get_medical_physiology()
	return phys ? phys.shock_recovery_mod : 1

/mob/living/carbon/proc/get_consciousness_recovery_mod()
	var/datum/physiology/phys = get_medical_physiology()
	return phys ? phys.consciousness_recovery_mod : 1

/mob/living/carbon/proc/get_pain_limit()
	var/datum/physiology/phys = get_medical_physiology()
	return phys ? phys.pain_limit : PAIN_MAX

/mob/living/carbon/proc/get_shock_limit()
	var/datum/physiology/phys = get_medical_physiology()
	return phys ? phys.shock_limit : SHOCK_MAX

/mob/living/carbon/proc/set_pain_modifier(source, multiplier)
	set_physiology_multiplier("pain_mod", source, multiplier)

/mob/living/carbon/proc/remove_pain_modifier(source)
	remove_physiology_multiplier("pain_mod", source)

/mob/living/carbon/proc/set_shock_modifier(source, multiplier)
	set_physiology_multiplier("shock_mod", source, multiplier)

/mob/living/carbon/proc/remove_shock_modifier(source)
	remove_physiology_multiplier("shock_mod", source)

/mob/living/carbon/proc/set_consciousness_modifier(source, multiplier)
	set_physiology_multiplier("consciousness_mod", source, multiplier)

/mob/living/carbon/proc/remove_consciousness_modifier(source)
	remove_physiology_multiplier("consciousness_mod", source)

/mob/living/carbon/proc/set_shock_recovery_modifier(source, multiplier)
	set_physiology_multiplier("shock_recovery_mod", source, multiplier)

/mob/living/carbon/proc/remove_shock_recovery_modifier(source)
	remove_physiology_multiplier("shock_recovery_mod", source)

/mob/living/carbon/proc/set_consciousness_recovery_modifier(source, multiplier)
	set_physiology_multiplier("consciousness_recovery_mod", source, multiplier)

/mob/living/carbon/proc/remove_consciousness_recovery_modifier(source)
	remove_physiology_multiplier("consciousness_recovery_mod", source)

/mob/living/carbon/proc/set_pain_limit(source, limit)
	set_physiology_limit("pain_limit", source, limit)

/mob/living/carbon/proc/remove_pain_limit(source)
	remove_physiology_limit("pain_limit", source)

/mob/living/carbon/proc/set_shock_limit(source, limit)
	set_physiology_limit("shock_limit", source, limit)

/mob/living/carbon/proc/remove_shock_limit(source)
	remove_physiology_limit("shock_limit", source)
#endif
