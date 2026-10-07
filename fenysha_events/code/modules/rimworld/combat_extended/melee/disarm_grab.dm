#ifndef OLD_COMBAT_SYSTEM
/mob/living/proc/disarm(mob/living/target, obj/item/weapon)
	if(!can_disarm(target))
		return

	do_attack_animation(target, ATTACK_EFFECT_DISARM)
	playsound(target, 'sound/items/weapons/thudswoosh.ogg', 50, TRUE, -1)

	var/attacker_skill = get_combat_melee_skill()
	var/defender_skill = target.get_combat_melee_skill()
	var/skill_diff = attacker_skill - defender_skill

	var/attacker_mod = get_combat_damage_mod()
	var/defender_mod = target.get_combat_block_mod()

	var/success_chance = RW_DISARM_BASE_CHANCE + (skill_diff * RW_DISARM_PER_SKILL)
	success_chance *= attacker_mod / max(defender_mod, 0.2)
	success_chance = clamp(success_chance, 5, 92)

	var/knockdown_chance = RW_DISARM_KNOCKDOWN_CHANCE_BASE + (skill_diff * 3.5)
	if(defender_skill >= RW_DISARM_KNOCKDOWN_SKILL_THRESHOLD)
		knockdown_chance *= 0.15
	knockdown_chance = clamp(knockdown_chance, 0, 55)

	if(prob(success_chance))
		var/obj/item/held = target.get_active_held_item()
		if(held && !(held.item_flags & ABSTRACT) && target.dropItemToGround(held))
			target.visible_message(span_danger("[src] disarms [target]!"), span_userdanger("[src] disarms you!"))
			to_chat(src, span_danger("You disarm [target]!"))
			log_combat(src, target, "disarmed")
		else
			target.visible_message(span_warning("[src] tries to disarm [target], but fails to find anything!"), \
				span_warning("[src] tries to disarm you!"))
	else if(prob(knockdown_chance))
		target.Knockdown(1.6 SECONDS)
		target.visible_message(span_danger("[src] sweeps [target]'s legs!"), span_userdanger("[src] sweeps your legs!"))
		to_chat(src, span_danger("You sweep [target]'s legs!"))
		log_combat(src, target, "leg-swept")
	else
		target.visible_message(span_warning("[src] tries to disarm [target]!"), span_warning("[src] tries to disarm you!"))
		to_chat(src, span_warning("You fail to disarm [target]!"))

	apply_status_effect(/datum/status_effect/rw_melee_recoil, 1)
	target.apply_status_effect(/datum/status_effect/rw_melee_recoil, 1)

/**
 * Called when a mob is grabbing another mob.
 */
/mob/living/proc/grab(mob/living/target)
	if(!istype(target))
		return GRAB_SKIP
	if(SEND_SIGNAL(src, COMSIG_LIVING_GRAB, target) & (COMPONENT_CANCEL_ATTACK_CHAIN|COMPONENT_SKIP_ATTACK))
		return GRAB_FAILURE
	if(target.check_block(src, 0, "[src]'s grab", UNARMED_ATTACK))
		return GRAB_FAILURE
	if(target.combat_mode && !can_grab_target(target))
		to_chat(src, span_warning("[target] is too skilled to be grabbed easily!"))
		target.visible_message(span_warning("[src] fails to get a solid grip on [target]!"))
		return GRAB_FAILURE
	target.grabbedby(src)
	return GRAB_SUCCESS

/mob/living/proc/can_grab_target(mob/living/target)
	var/attacker_skill = get_combat_melee_skill()
	var/defender_skill = target.get_combat_melee_skill()
	var/diff = attacker_skill - defender_skill

	var/chance = 70 + (diff * RW_GRAB_SKILL_DIFF_MULT)
	chance *= get_combat_damage_mod() / max(target.get_combat_block_mod(), 0.15)
	chance = clamp(chance, 8, 95)

	return prob(chance)
#endif
