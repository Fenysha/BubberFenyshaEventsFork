#ifndef OLD_COMBAT_SYSTEM
/mob/living/proc/get_combat_melee_skill()
	return rw_get_skill(src, RW_SKILL_MELEE)

/// 0.0 - 1.0+ multiplier for outgoing melee/weapon damage
/mob/living/proc/get_combat_damage_mod()
	return 1.0

/mob/living/carbon/get_combat_damage_mod()
	var/manip = get_manipulation_capacity()
	var/consc = get_consciousness_capacity()
	var/pain = get_pain_capacity()
	var/shock = get_shock_capacity()

	// Pain & shock share the remaining weight
	var/pain_shock = min(pain, shock)

	var/mod = (manip * COMBAT_DAMAGE_MANIP_WEIGHT) + \
			  (consc * COMBAT_DAMAGE_CONSC_WEIGHT) + \
			  (pain_shock * COMBAT_DAMAGE_PAIN_WEIGHT)

	return clamp(mod, 0.15, 1.45)

/mob/living/proc/get_combat_accuracy_mod()
	return 1.0

/mob/living/carbon/get_combat_accuracy_mod()
	var/manip = get_manipulation_capacity()
	var/consc = get_consciousness_capacity()
	var/move = get_moving_capacity()

	var/mod = (manip * COMBAT_ACCURACY_MANIP_WEIGHT) + \
			  (consc * COMBAT_ACCURACY_CONSC_WEIGHT) + \
			  (move * COMBAT_ACCURACY_MOVE_WEIGHT)

	return clamp(mod, 0.20, 1.15)

/mob/living/proc/get_combat_dodge_mod()
	return 1.0

/mob/living/carbon/get_combat_dodge_mod()
	var/move = get_moving_capacity()
	var/consc = get_consciousness_capacity()
	var/pain = get_pain_capacity()
	var/shock = get_shock_capacity()
	var/pain_shock = min(pain, shock)

	var/mod = (move * COMBAT_DODGE_MOVE_WEIGHT) + \
			  (consc * COMBAT_DODGE_CONSC_WEIGHT) + \
			  (pain_shock * COMBAT_DODGE_PAIN_WEIGHT)

	return clamp(mod, 0.05, 1.20)

/// 0.0-1.0+ how well this mob can block right now
/mob/living/proc/get_combat_block_mod()
	return 1.0

/mob/living/carbon/get_combat_block_mod()
	var/manip = get_manipulation_capacity()
	var/consc = get_consciousness_capacity()
	var/pain = get_pain_capacity()
	var/shock = get_shock_capacity()
	var/pain_shock = min(pain, shock)

	var/mod = (manip * 0.40) + (consc * 0.35) + (pain_shock * 0.25)
	return clamp(mod, 0.10, 1.20)
#endif
