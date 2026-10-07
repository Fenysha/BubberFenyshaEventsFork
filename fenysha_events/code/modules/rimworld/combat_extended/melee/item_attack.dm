#ifndef OLD_COMBAT_SYSTEM
/**
 * Zone resolve, messages, block, dodge, then apply_damage with blocked=0.
 */
/mob/living/attacked_by(obj/item/attacking_item, mob/living/user, list/modifiers, list/attack_modifiers)
	var/targeting = check_zone(user.zone_selected)

	// === Skill + Capacity accuracy ===
	var/attacker_skill = user.get_combat_melee_skill()
	var/defender_skill = get_combat_melee_skill()
	var/skill_diff = attacker_skill - defender_skill

	var/accuracy_mod = user.get_combat_accuracy_mod()

	// Полный промах
	var/miss_chance = MELEE_MISS_BASE - (skill_diff * MELEE_MISS_PER_SKILL_DIFF)
	miss_chance /= max(accuracy_mod, 0.15) // низкая ёмкость → больше промахов
	miss_chance = clamp(miss_chance, MELEE_MISS_MIN, MELEE_MISS_MAX)

	if(body_position == LYING_DOWN || has_status_effect(/datum/status_effect/staggered) || HAS_TRAIT(user, TRAIT_PERFECT_ATTACKER))
		miss_chance *= 0.35

	if(prob(miss_chance))
		if(!LAZYACCESS(attack_modifiers, SILENCE_DEFAULT_MESSAGES))
			visible_message(
				span_danger("[user]'s attack with [attacking_item] misses [src]!"),
				span_danger("You avoid [user]'s [attacking_item]!"),
				span_hear("You hear a whoosh!"),
				COMBAT_MESSAGE_RANGE,
				user
			)
			to_chat(user, span_warning("Your attack with [attacking_item] misses [src]!"))
		if(client)
			rw_train_skill(src, RW_SKILL_MELEE, RW_SKILL_POINTS_MINOR)
		if(user.client)
			rw_train_skill(user, RW_SKILL_MELEE, RW_SKILL_POINTS_MINOR)
		return ATTACK_FAILED

	var/zone_hit_chance = MELEE_ZONE_HIT_BASE + (skill_diff * MELEE_ZONE_HIT_PER_SKILL)
	zone_hit_chance *= accuracy_mod
	if(body_position == LYING_DOWN)
		zone_hit_chance += 12
	zone_hit_chance = clamp(zone_hit_chance, 30, 96)

	if(user != src)
		targeting = get_random_valid_zone(targeting, zone_hit_chance)

	var/targeting_human_readable = parse_zone_with_bodypart(targeting)

	if(!LAZYACCESS(attack_modifiers, SILENCE_DEFAULT_MESSAGES))
		send_item_attack_message(attacking_item, user, targeting_human_readable, targeting)

	var/armor_block = min(run_armor_check(
			def_zone = targeting,
			attack_flag = MELEE,
			absorb_text = span_notice("Your armor has protected your [targeting_human_readable]!"),
			soften_text = span_warning("Your armor has softened a hit to your [targeting_human_readable]!"),
			armour_penetration = attacking_item.armour_penetration,
			weak_against_armour = attacking_item.weak_against_armour,
			silent = TRUE,
		), ARMOR_MAX_BLOCK)

	if(armor_block >= 100)
		to_chat(src, span_notice("Your armor has protected your [targeting_human_readable]!"))
	else if(armor_block >= 50)
		to_chat(src, span_warning("Your armor has softened a hit to your [targeting_human_readable]!"))

	var/final_force = CALCULATE_FORCE(attacking_item, attack_modifiers)

	// Capacity damage mod
	final_force *= user.get_combat_damage_mod()

	if(mob_biotypes & (MOB_ROBOTIC | MOB_MINERAL | MOB_SKELETAL))
		final_force *= attacking_item.get_demolition_modifier(src)

	var/wounding = attacking_item.wound_bonus
	if((attacking_item.item_flags & SURGICAL_TOOL) && !user.combat_mode && HAS_TRAIT(user, TRAIT_READY_TO_OPERATE))
		wounding = CANT_WOUND

	if(user != src)
		var/parry_result = try_parry_attack(user, final_force, "\the [attacking_item]")
		if(parry_result == SUCCESSFUL_BLOCK)
			return ATTACK_FAILED

	if(user != src)
		if(check_block(
			attacking_item,
			final_force,
			"\the [attacking_item]",
			MELEE_ATTACK,
			attacking_item.armour_penetration,
			attacking_item.damtype,
		))
			return ATTACK_FAILED

		if(try_dodge(user, "\the [attacking_item]", MELEE_ATTACK))
			return ATTACK_FAILED

	SEND_SIGNAL(attacking_item, COMSIG_ITEM_ATTACK_ZONE, src, user, targeting)

	if(final_force <= 0)
		return 0

	if(ishuman(src) || client)
		SSblackbox.record_feedback("nested tally", "item_used_for_combat", 1, list("[attacking_item.force]", "[attacking_item.type]"))
		SSblackbox.record_feedback("tally", "zone_targeted", 1, user.zone_selected)

	var/damage_done = apply_damage(
		damage = final_force,
		damagetype = attacking_item.damtype,
		def_zone = targeting,
		blocked = 0,
		wound_bonus = wounding,
		exposed_wound_bonus = attacking_item.exposed_wound_bonus,
		sharpness = attacking_item.get_sharpness(),
		attack_direction = get_dir(user, src),
		attacking_item = attacking_item,
	)

	apply_status_effect(/datum/status_effect/rw_melee_recoil, 1)
	if(user != src)
		user.apply_status_effect(/datum/status_effect/rw_melee_recoil, 1)

	attack_effects(damage_done, targeting, armor_block, attacking_item, user)

	if(client)
		rw_train_skill(src, RW_SKILL_MELEE, RW_SKILL_POINTS_NORMAL)
	if(user.client)
		rw_train_skill(user, RW_SKILL_MELEE, RW_SKILL_POINTS_MINOR)

	return damage_done

/mob/living/carbon/human/attack_effects(damage_done, hit_zone, armor_block, obj/item/attacking_item, mob/living/attacker)
	. = ..()
	return .
#endif
