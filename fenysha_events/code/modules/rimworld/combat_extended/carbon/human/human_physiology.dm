/// Owner side of /datum/physiology: changes a layer, then refreshes whatever reads the stat.

/datum/movespeed_modifier/physiology_slowdown
	variable = TRUE
	multiplicative_slowdown = 0

/// Humans own a physiology datum; other carbons have none, so every layer call below is a no-op for them.
/mob/living/carbon/proc/get_medical_physiology()
	RETURN_TYPE(/datum/physiology)
	return null

/mob/living/carbon/human/get_medical_physiology()
	return physiology

/mob/living/carbon/proc/set_physiology_multiplier(stat, source, value)
	if(get_medical_physiology()?.set_multiplier(stat, source, value))
		on_physiology_changed(stat)

/mob/living/carbon/proc/remove_physiology_multiplier(stat, source)
	if(get_medical_physiology()?.remove_multiplier(stat, source))
		on_physiology_changed(stat)

/mob/living/carbon/proc/set_physiology_limit(stat, source, value)
	if(get_medical_physiology()?.set_limit(stat, source, value))
		on_physiology_changed(stat)

/mob/living/carbon/proc/remove_physiology_limit(stat, source)
	if(get_medical_physiology()?.remove_limit(stat, source))
		on_physiology_changed(stat)

/mob/living/carbon/proc/set_physiology_additive(stat, source, value)
	if(get_medical_physiology()?.set_additive(stat, source, value))
		on_physiology_changed(stat)

/mob/living/carbon/proc/remove_physiology_additive(stat, source)
	if(get_medical_physiology()?.remove_additive(stat, source))
		on_physiology_changed(stat)

/mob/living/carbon/proc/remove_physiology_source(source)
	for(var/stat in get_medical_physiology()?.remove_source(source))
		on_physiology_changed(stat)

/// Refreshes whatever reads the stat. Carbon handles the medical state, humans extend it.
/mob/living/carbon/proc/on_physiology_changed(stat)
	switch(stat)
		if("pain_mod", "shock_mod", "consciousness_mod", "shock_recovery_mod", "consciousness_recovery_mod", "pain_limit", "shock_limit")
#ifndef OLD_COMBAT_SYSTEM
			recalculate_medical_state()
			refresh_medical_feedback()
#endif

/mob/living/carbon/human/on_physiology_changed(stat)
	. = ..()
	switch(stat)
		if("maxhealth_mod")
			refresh_max_health()
		if("movespeed_slowdown")
			refresh_physiology_movespeed()

/mob/living/carbon/human/proc/refresh_physiology_movespeed()
	if(physiology.movespeed_slowdown)
		add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/physiology_slowdown, multiplicative_slowdown = physiology.movespeed_slowdown)
	else
		remove_movespeed_modifier(/datum/movespeed_modifier/physiology_slowdown)

/mob/living/carbon/human/proc/refresh_max_health()
	if(isnull(physiology.cached_max_health))
		physiology.cached_max_health = maxHealth
	if(physiology.maxhealth_mod == 1)
		maxHealth = physiology.cached_max_health
		physiology.cached_max_health = null
	else
		maxHealth = max(1, round(physiology.cached_max_health * physiology.maxhealth_mod, 1))
	updatehealth()

/// Multiplier getters used by combat_extended. Only humans have a physiology, everyone else is neutral.
/mob/living/proc/get_rw_brute_taken_mult()
	return 1
/mob/living/carbon/human/get_rw_brute_taken_mult()
	return physiology.brute_taken_mod

/mob/living/proc/get_rw_burn_taken_mult()
	return 1
/mob/living/carbon/human/get_rw_burn_taken_mult()
	return physiology.burn_taken_mod

/mob/living/proc/get_rw_tox_mult()
	return 1
/mob/living/carbon/human/get_rw_tox_mult()
	return physiology.tox_taken_mod

/mob/living/proc/get_rw_bleed_mult()
	return 1
/mob/living/carbon/human/get_rw_bleed_mult()
	return physiology.bleed_rate_mod

/mob/living/proc/get_rw_wound_heal_mult()
	return 1
/mob/living/carbon/human/get_rw_wound_heal_mult()
	return physiology.wound_heal_mod

/mob/living/proc/get_rw_immunity_mult()
	return 1
/mob/living/carbon/human/get_rw_immunity_mult()
	return physiology.immunity_mod

/mob/living/proc/get_rw_melee_damage_mult()
	return 1
/mob/living/carbon/human/get_rw_melee_damage_mult()
	return physiology.melee_damage_mod

/mob/living/proc/get_rw_ranged_spread_mult()
	return 1
/mob/living/carbon/human/get_rw_ranged_spread_mult()
	return physiology.ranged_spread_mod

/mob/living/proc/get_rw_manipulation_mult()
	return 1
/mob/living/carbon/human/get_rw_manipulation_mult()
	return physiology.manipulation_mod

/mob/living/carbon/adjust_tox_loss(amount, updating_health = TRUE, forced = FALSE, required_biotype = ALL)
	if(!forced && amount > 0)
		amount *= get_rw_tox_mult()
	return ..()

/mob/living/carbon/human/get_body_temp_heat_damage_limit()
	return dna.species.bodytemp_heat_damage_limit + physiology.heat_limit_mod

/mob/living/carbon/human/get_body_temp_cold_damage_limit()
	return dna.species.bodytemp_cold_damage_limit + physiology.cold_limit_mod
