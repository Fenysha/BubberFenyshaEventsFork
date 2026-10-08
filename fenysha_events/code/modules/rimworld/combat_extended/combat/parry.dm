#ifndef OLD_COMBAT_SYSTEM
// MARK: Parry Stance
/datum/status_effect/rw_parrying
	id = "rw_parrying"
	duration = RW_PARRY_DURATION
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = /atom/movable/screen/alert/status_effect/rw_parrying
	tick_interval = STATUS_EFFECT_NO_TICK
	var/perfect_window_end = 0
	var/strike_received = FALSE

/datum/status_effect/rw_parrying/on_creation(mob/living/new_owner)
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
	if(!strike_received)
		owner.Stun(RW_PARRY_FAIL_STUN)
		owner.visible_message(span_warning("[owner] lowers [owner.p_their()] guard too late and is left vulnerable!"), \
			span_userdanger("You hold your guard too long and leave yourself vulnerable!"))
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
	var/mob/living/counter_target

/datum/status_effect/rw_perfect_parry/on_creation(mob/living/new_owner, quality = 1.0, mob/living/new_counter_target)
	parry_quality = quality
	counter_target = new_counter_target
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

	apply_status_effect(/datum/status_effect/rw_parrying)
	return TRUE

/**
 * Called when an attack reaches a mob with its parry stance active.
 * Returns SUCCESSFUL_BLOCK for a perfect parry, RW_PARRY_PARTIAL_BLOCK for a late parry,
 * and FAILED_BLOCK when there was no active stance.
 */
/mob/living/proc/try_parry_attack(mob/living/attacker, damage, attack_text = "the attack")
	var/datum/status_effect/rw_parrying/parry = has_status_effect(/datum/status_effect/rw_parrying)
	if(!parry || damage <= 0)
		return FAILED_BLOCK

	var/was_perfect = parry.is_perfect()
	parry.strike_received = TRUE
	remove_status_effect(/datum/status_effect/rw_parrying)

	if(was_perfect)
		visible_message(span_danger("[src] perfectly parries [attack_text]!"), span_userdanger("You perfectly parry [attack_text]!"))
	else
		visible_message(span_warning("[src] partially deflects [attack_text]!"), span_userdanger("You partially deflect [attack_text]!"))
	playsound(src, 'fenysha_events/sounds/effects/parry.ogg', 65, TRUE)

	if(was_perfect)
		remove_status_effect(/datum/status_effect/rw_parry_cooldown)
		apply_status_effect(/datum/status_effect/rw_perfect_parry, 1.0, attacker)
		create_floating_combat_text(src, "Perfect Parry", "#73FF9A")
		attacker.Stun(1.2 SECONDS)
		to_chat(src, span_nicegreen("Perfect parry!"))
	else
		apply_status_effect(/datum/status_effect/rw_parry_cooldown)
		create_floating_combat_text(src, "Parry", "#A7D8FF")

	if(client)
		rw_train_skill(src, RW_SKILL_MELEE, was_perfect ? RW_SKILL_POINTS_NORMAL : RW_SKILL_POINTS_MINOR)
	if(attacker.client)
		rw_train_skill(attacker, RW_SKILL_MELEE, RW_SKILL_POINTS_MINOR)

	return was_perfect ? SUCCESSFUL_BLOCK : RW_PARRY_PARTIAL_BLOCK


/mob/living/proc/try_counter_attack(mob/living/target, damage, damage_type = BRUTE, sharpness = NONE, obj/item/weapon, hit_zone)
	var/datum/status_effect/rw_perfect_parry/parry = has_status_effect(/datum/status_effect/rw_perfect_parry)
	if(!target || !parry || parry.counter_target != target || damage <= 0)
		return FALSE

	remove_status_effect(/datum/status_effect/rw_perfect_parry)
	if(istype(weapon, /obj/item/bodypart))
		do_attack_animation(target, ATTACK_EFFECT_PUNCH)
	else
		do_attack_animation(target, used_item = weapon)
	visible_message(span_danger("[src] counters [target]!"), span_userdanger("You counter [target]!"), null, COMBAT_MESSAGE_RANGE, src)
	playsound(target, 'fenysha_events/sounds/effects/parry.ogg', 60, TRUE)

	var/resolved_zone = hit_zone || target.get_random_valid_zone(zone_selected)
	var/damage_dealt = target.apply_damage(
		damage = damage,
		damagetype = damage_type,
		def_zone = resolved_zone,
		blocked = 0,
		wound_bonus = weapon?.wound_bonus || 0,
		exposed_wound_bonus = weapon?.exposed_wound_bonus || 0,
		sharpness = sharpness,
		attack_direction = get_dir(src, target),
		attacking_item = weapon,
	)
	if(QDELETED(target))
		return TRUE
	if(istype(weapon, /obj/item) && !istype(weapon, /obj/item/bodypart))
		SEND_SIGNAL(weapon, COMSIG_ITEM_ATTACK_ZONE, target, src, resolved_zone)
		target.attack_effects(damage_dealt, resolved_zone, 0, weapon, src)
	else if(istype(weapon, /obj/item/bodypart) && ishuman(src) && ishuman(target))
		var/obj/item/bodypart/hit_bodypart = target.get_bodypart(resolved_zone)
		SEND_SIGNAL(target, COMSIG_HUMAN_GOT_PUNCHED, src, damage, damage_type, hit_bodypart, 0, FALSE, sharpness)
		SEND_SIGNAL(src, COMSIG_HUMAN_PUNCHED, target, damage, damage_type, hit_bodypart, 0, FALSE, sharpness)
	target.apply_status_effect(/datum/status_effect/rw_melee_recoil, 2)
	apply_status_effect(/datum/status_effect/rw_melee_recoil, 1)
	log_combat(src, target, "counter-attacked", weapon)

	if(client)
		rw_train_skill(src, RW_SKILL_MELEE, RW_SKILL_POINTS_NORMAL)
	if(target.client)
		rw_train_skill(target, RW_SKILL_MELEE, RW_SKILL_POINTS_MINOR)
	return TRUE

/mob/living/proc/get_counter_parry(mob/living/target)
	if(!target)
		return
	var/datum/status_effect/rw_perfect_parry/parry = has_status_effect(/datum/status_effect/rw_perfect_parry)
	if(parry?.counter_target == target)
		return parry

/mob/living/proc/try_counter_shove(mob/living/target, obj/item/weapon)
	var/datum/status_effect/rw_perfect_parry/parry = get_counter_parry(target)
	if(!parry || !target || !can_disarm(target))
		return FALSE

	var/shove_flags = target.get_shove_flags(src, weapon)
	var/shove_dir = get_dir(loc, target.loc)
	var/turf/target_turf = get_turf(target)
	var/turf/shove_turf = get_step(target_turf, shove_dir)
	var/shove_blocked = !(shove_flags & SHOVE_CAN_MOVE) || !shove_turf
	var/knockdown_chance = clamp(35 + (get_combat_melee_skill() - target.get_combat_melee_skill()) * 8, 5, 90)
	var/knockdown_attempt = prob(knockdown_chance) && !(shove_flags & SHOVE_KNOCKDOWN_BLOCKED)

	if(!shove_blocked)
		if(SEND_SIGNAL(shove_turf, COMSIG_LIVING_DISARM_PRESHOVE, src, target, weapon) & COMSIG_LIVING_ACT_SOLID)
			shove_blocked = TRUE
		else
			target.Move(shove_turf, shove_dir)
			shove_blocked = get_turf(target) == target_turf

	if(shove_blocked && (shove_flags & SHOVE_CAN_HIT_SOMETHING) && shove_turf)
		var/collision_flags = shove_flags | SHOVE_BLOCKED
		if(!knockdown_attempt)
			collision_flags |= SHOVE_KNOCKDOWN_BLOCKED
		if(SEND_SIGNAL(shove_turf, COMSIG_LIVING_DISARM_COLLIDE, src, target, collision_flags, weapon) & COMSIG_LIVING_SHOVE_HANDLED)
			if(!knockdown_attempt)
				target.Stun(1.2 SECONDS)
			remove_status_effect(/datum/status_effect/rw_perfect_parry)
			target.apply_status_effect(/datum/status_effect/rw_melee_recoil, 2)
			apply_status_effect(/datum/status_effect/rw_melee_recoil, 1)
			log_combat(src, target, "counter-shoved", weapon)
			return TRUE

	remove_status_effect(/datum/status_effect/rw_perfect_parry)
	do_attack_animation(target, weapon ? null : ATTACK_EFFECT_DISARM, weapon)
	playsound(target, 'sound/items/weapons/thudswoosh.ogg', 50, TRUE, -1)
	if(knockdown_attempt)
		if(!target.Knockdown(1.6 SECONDS))
			target.Stun(1.2 SECONDS)
	else
		target.Stun(1.2 SECONDS)
	if(shove_flags & SHOVE_CAN_STAGGER)
		target.adjust_staggered_up_to(STAGGERED_SLOWDOWN_LENGTH, 10 SECONDS)
	target.visible_message(span_danger("[src] shoves [target] back!"), span_userdanger("[src] shoves you back!"), null, COMBAT_MESSAGE_RANGE, src)
	target.apply_status_effect(/datum/status_effect/rw_melee_recoil, 2)
	log_combat(src, target, "counter-shoved", weapon)
	return TRUE

/mob/living/proc/try_counter_grab(mob/living/target)
	var/datum/status_effect/rw_perfect_parry/parry = get_counter_parry(target)
	if(!parry || !target || target == src || target.anchored)
		return FALSE

	if(!start_pulling(target, GRAB_AGGRESSIVE, supress_message = TRUE))
		return FALSE

	remove_status_effect(/datum/status_effect/rw_perfect_parry)
	target.visible_message(span_danger("[src] grabs [target] aggressively!"), span_userdanger("[src] grabs you aggressively!"), null, COMBAT_MESSAGE_RANGE, src)
	to_chat(src, span_danger("You grab [target] aggressively!"))
	log_combat(src, target, "grabbed", addition = "perfect-parry counter grab")
	return TRUE
#endif
