#ifndef OLD_COMBAT_SYSTEM
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
#endif
