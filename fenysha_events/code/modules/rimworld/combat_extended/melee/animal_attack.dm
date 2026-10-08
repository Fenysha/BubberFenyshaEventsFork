#ifndef OLD_COMBAT_SYSTEM
/**
 * Simple animal melee.
 */
/mob/living/attack_animal(mob/living/simple_animal/user, list/modifiers)
	. = ..()
	if(.)
		return FALSE

	if(user.melee_damage_upper == 0)
		if(user != src)
			visible_message(
				span_notice("[user] [user.friendly_verb_continuous] [src]!"),
				span_notice("[user] [user.friendly_verb_continuous] you!"),
				vision_distance = COMBAT_MESSAGE_RANGE,
				ignored_mobs = user,
			)
			to_chat(user, span_notice("You [user.friendly_verb_simple] [src]!"))
		return FALSE

	if(HAS_TRAIT(user, TRAIT_PACIFISM))
		to_chat(user, span_warning("You don't want to hurt anyone!"))
		return FALSE

	var/damage = rand(user.melee_damage_lower, user.melee_damage_upper)
	apply_status_effect(/datum/status_effect/rw_melee_recoil, 1)
	if(user != src)
		user.apply_status_effect(/datum/status_effect/rw_melee_recoil, 1)

	if(check_block(user, damage, "[user]'s [user.attack_verb_simple]", UNARMED_ATTACK, user.armour_penetration, user.melee_damage_type))
		return FALSE

	if(try_dodge(user, "[user]'s attack", UNARMED_ATTACK))
		return FALSE

	if(user.attack_sound)
		playsound(src, user.attack_sound, 50, TRUE, TRUE)

	user.do_attack_animation(src)
	visible_message(
		span_danger("[user] [user.attack_verb_continuous] [src]!"),
		span_userdanger("[user] [user.attack_verb_continuous] you!"),
		null,
		COMBAT_MESSAGE_RANGE,
		user,
	)

	var/dam_zone = dismembering_strike(user, pick(BODY_ZONE_CHEST, BODY_ZONE_PRECISE_L_HAND, BODY_ZONE_PRECISE_R_HAND, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG))
	if(!dam_zone)
		return FALSE

	to_chat(user, span_danger("You [user.attack_verb_simple] [src]!"))
	var/damage_done = apply_damage(
		damage = damage,
		damagetype = user.melee_damage_type,
		def_zone = user.zone_selected,
		blocked = 0,
		wound_bonus = user.wound_bonus,
		exposed_wound_bonus = user.exposed_wound_bonus,
		sharpness = user.sharpness,
		attack_direction = get_dir(user, src),
	)

	log_combat(user, src, "attacked")
	return damage_done
#endif
