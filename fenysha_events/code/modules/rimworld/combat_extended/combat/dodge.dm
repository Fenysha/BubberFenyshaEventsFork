#ifndef OLD_COMBAT_SYSTEM
/**
 * Dodge chance 0-100 against attacker for the given attack_type.
 */
/mob/living/proc/get_melee_dodge_chance(atom/attacker, attack_type = MELEE_ATTACK)
	if(body_position == LYING_DOWN)
		return 0
	if(HAS_TRAIT(src, TRAIT_IMMOBILIZED) || HAS_TRAIT(src, TRAIT_KNOCKEDOUT))
		return 0

	var/defender_skill = get_combat_melee_skill()
	var/attacker_skill = DODGE_DEFAULT_ATTACKER_SKILL
	if(isliving(attacker))
		var/mob/living/living_attacker = attacker
		attacker_skill = living_attacker.get_combat_melee_skill()

	var/chance = DODGE_BASE_CHANCE
	chance += defender_skill * DODGE_PER_DEFENDER_MELEE
	chance -= attacker_skill * DODGE_PER_ATTACKER_MELEE

	// Capacity modifier (movement is the biggest factor)
	chance *= get_combat_dodge_mod()

	if(HAS_TRAIT(src, TRAIT_FLOORED))
		chance *= 0.25
	if(IsStun() || IsParalyzed())
		chance *= 0.2

	switch(attack_type)
		if(PROJECTILE_ATTACK)
			chance *= DODGE_PROJECTILE_MULT
		if(THROWN_PROJECTILE_ATTACK)
			chance *= DODGE_THROWN_MULT

	return clamp(chance, DODGE_CHANCE_MIN, DODGE_CHANCE_MAX)

/**
 * Returns TRUE if the attack is fully avoided.
 */
/mob/living/proc/try_dodge(atom/attacker, attack_text = "the attack", attack_type = MELEE_ATTACK, silent = FALSE)
	var/chance = get_melee_dodge_chance(attacker, attack_type)
	if(chance <= 0)
		return FALSE

	if(!prob(chance))
		if(isliving(attacker) && client)
			rw_train_skill(src, RW_SKILL_MELEE, RW_SKILL_POINTS_MINOR)
		return FALSE

	if(!silent)
		visible_message(
			span_danger("[src] dodges [attack_text]!"),
			span_userdanger("You dodge [attack_text]!"),
			span_hear("You hear a quick shuffle!"),
			COMBAT_MESSAGE_RANGE,
			attacker,
		)
		if(isliving(attacker))
			to_chat(attacker, span_warning("[src] dodges [attack_text]!"))
	playsound(src, 'fenysha_events/sounds/effects/dodge.ogg', 65, TRUE)
	if(client)
		rw_train_skill(src, RW_SKILL_MELEE, RW_SKILL_POINTS_NORMAL)
	if(isliving(attacker))
		var/mob/living/living_attacker = attacker
		if(living_attacker.client)
			rw_train_skill(living_attacker, RW_SKILL_MELEE, RW_SKILL_POINTS_MINOR)

	return TRUE
#endif
