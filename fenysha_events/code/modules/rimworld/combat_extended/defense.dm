#ifndef OLD_COMBAT_SYSTEM
/datum/keybinding/mob/toggle_parry
	hotkey_keys = list("C")
	name = "toggle_parry"
	full_name = "Toggle Parry / Block"
	description = "Enter a defensive parry stance. You become immobilized, but the next melee attack against you can be parried."
	keybind_signal = COMSIG_KB_MOB_TOGGLE_PARRY_DOWN

/datum/keybinding/mob/toggle_parry/down(client/user)
	. = ..()
	if(.)
		return
	var/mob/living/user_mob = user.mob
	if(!isliving(user_mob))
		return TRUE
	user_mob.try_toggle_parry()
	return TRUE


// MARK: Parry Stance
/datum/status_effect/rw_parrying
	id = "rw_parrying"
	duration = RW_PARRY_DURATION
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = /atom/movable/screen/alert/status_effect/rw_parrying
	tick_interval = STATUS_EFFECT_NO_TICK
	var/perfect_window_end = 0
	var/parry_power = 50
	var/failed = FALSE

/datum/status_effect/rw_parrying/on_creation(mob/living/new_owner, power = 50)
	parry_power = power
	perfect_window_end = world.time + RW_PERFECT_PARRY_WINDOW
	return ..()

/datum/status_effect/rw_parrying/on_apply()
	. = ..()
	if(!.)
		return
	owner.add_traits(list(TRAIT_IMMOBILIZED, TRAIT_HANDS_BLOCKED), TRAIT_STATUS_EFFECT(id))
	owner.add_overlay(mutable_appearance('icons/effects/effects.dmi', "mech_sparks", -BODY_LAYER))
	owner.visible_message(span_warning("[owner] takes a defensive stance!"), span_notice("You enter a parry stance."))

/datum/status_effect/rw_parrying/on_remove()
	owner.remove_traits(list(TRAIT_IMMOBILIZED, TRAIT_HANDS_BLOCKED), TRAIT_STATUS_EFFECT(id))
	owner.cut_overlay(mutable_appearance('icons/effects/effects.dmi', "mech_sparks", -BODY_LAYER))
	if(failed)
		owner.Stun(RW_PARRY_FAIL_STUN)
		owner.visible_message(span_warning("[owner] fails to capitalize on the opening and is left vulnerable!"), \
			span_userdanger("You mistimed the parry and are left open!"))
	return ..()

/datum/status_effect/rw_parrying/proc/is_perfect()
	return world.time <= perfect_window_end

/atom/movable/screen/alert/status_effect/rw_parrying
	name = "Parrying"
	desc = "You are in a defensive stance. The next melee attack can be parried."
	icon_state = "guard"


// MARK: Perfect Parry Window (after successful parry)
/datum/status_effect/rw_perfect_parry
	id = "rw_perfect_parry"
	duration = 1.4 SECONDS
	status_type = STATUS_EFFECT_REPLACE
	alert_type = null
	tick_interval = STATUS_EFFECT_NO_TICK
	var/parry_quality = 1.0

/datum/status_effect/rw_perfect_parry/on_creation(mob/living/new_owner, quality = 1.0)
	parry_quality = quality
	return ..()


// MARK: Parry Cooldown
/datum/status_effect/rw_parry_cooldown
	id = "rw_parry_cooldown"
	duration = RW_PARRY_COOLDOWN
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = null


/mob/living/proc/try_toggle_parry()
	if(has_status_effect(/datum/status_effect/rw_parry_cooldown))
		to_chat(src, span_warning("You are not ready to parry again yet!"))
		return FALSE
	if(has_status_effect(/datum/status_effect/rw_parrying))
		remove_status_effect(/datum/status_effect/rw_parrying)
		return FALSE
	if(!combat_mode)
		to_chat(src, span_warning("You need to be in combat mode to parry!"))
		return FALSE

	var/power = RW_PARRY_BASE_POWER + (get_combat_melee_skill() * RW_PARRY_PER_SKILL)
	power *= get_combat_block_mod() // capacity
	power = clamp(power, 15, 95)

	apply_status_effect(/datum/status_effect/rw_parrying, power)
	return TRUE

/**
 * Called when we are attacked while parrying.
 * Returns SUCCESSFUL_BLOCK (full parry) or FAILED_BLOCK.
 */
/mob/living/proc/try_parry_attack(mob/living/attacker, damage, attack_text = "the attack")
	var/datum/status_effect/rw_parrying/parry = has_status_effect(/datum/status_effect/rw_parrying)
	if(!parry)
		return FAILED_BLOCK

	var/chance = parry.parry_power
	var/attacker_skill = attacker.get_combat_melee_skill()
	var/defender_skill = get_combat_melee_skill()
	chance += (defender_skill - attacker_skill) * 4.0
	chance = clamp(chance, 8, 97)

	var/was_perfect = parry.is_perfect()
	parry.failed = !was_perfect
	remove_status_effect(/datum/status_effect/rw_parrying)

	if(!prob(chance))
		apply_status_effect(/datum/status_effect/rw_parry_cooldown)
		return FAILED_BLOCK

	visible_message(span_danger("[src] parries [attack_text]!"), span_userdanger("You parry [attack_text]!"))
	playsound(src, 'fenysha_events/sounds/effects/parry.ogg', 65, TRUE)

	if(was_perfect)
		remove_status_effect(/datum/status_effect/rw_parry_cooldown)
		apply_status_effect(/datum/status_effect/rw_perfect_parry, 1.0)
		to_chat(src, span_nicegreen("Perfect parry!"))
	else
		apply_status_effect(/datum/status_effect/rw_parry_cooldown)
		apply_status_effect(/datum/status_effect/rw_perfect_parry, 0.55)

	if(client)
		rw_train_skill(src, RW_SKILL_MELEE, was_perfect ? RW_SKILL_POINTS_NORMAL : RW_SKILL_POINTS_MINOR)
	if(attacker.client)
		rw_train_skill(attacker, RW_SKILL_MELEE, RW_SKILL_POINTS_MINOR)

	return SUCCESSFUL_BLOCK


/mob/living/proc/try_counter_attack(mob/living/target)
	var/datum/status_effect/rw_perfect_parry/parry = target.has_status_effect(/datum/status_effect/rw_perfect_parry)
	if(!parry)
		return FALSE

	var/quality = parry.parry_quality
	target.remove_status_effect(/datum/status_effect/rw_perfect_parry)

	visible_message(span_danger("[src] counters [target]!"), span_userdanger("You counter [target]!"))
	playsound(src, 'fenysha_events/sounds/effects/parry.ogg', 60, TRUE)

	if(quality >= 0.9)
		if(ishuman(target))
			target.Knockdown(2.4 SECONDS)
		else if(iscarbon(target))
			target.Stun(1.8 SECONDS)
		else
			target.Stun(1.2 SECONDS)
		target.apply_status_effect(/datum/status_effect/rw_melee_recoil, 2)
	else
		target.apply_status_effect(/datum/status_effect/rw_melee_recoil, 2)
		if(iscarbon(target))
			target.Stun(0.6 SECONDS)

	if(client)
		rw_train_skill(src, RW_SKILL_MELEE, RW_SKILL_POINTS_NORMAL)
	return TRUE


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
