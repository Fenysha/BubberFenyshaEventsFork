#ifndef OLD_COMBAT_SYSTEM
// MARK: Melee Recoil
/datum/status_effect/rw_melee_recoil
	id = "rw_melee_recoil"
	duration = RW_MELEE_SLOWDOWN_DURATION
	status_type = STATUS_EFFECT_REFRESH
	alert_type = null
	tick_interval = STATUS_EFFECT_NO_TICK
	var/stacks = 1

/datum/status_effect/rw_melee_recoil/on_creation(mob/living/new_owner, starting_stacks = 1)
	stacks = clamp(starting_stacks, 1, RW_MELEE_SLOWDOWN_MAX)
	return ..()

/datum/status_effect/rw_melee_recoil/on_apply()
	. = ..()
	if(!.)
		return
	if(HAS_TRAIT(owner, TRAIT_COMBAT_SLOWDOWN_IMMUNE))
		return FALSE
	rw_update_movespeed()

/datum/status_effect/rw_melee_recoil/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/rw_melee_recoil)
	return ..()

/datum/status_effect/rw_melee_recoil/refresh(effect, starting_stacks = 1)
	if(HAS_TRAIT(owner, TRAIT_COMBAT_SLOWDOWN_IMMUNE))
		return
	stacks = min(stacks + starting_stacks, RW_MELEE_SLOWDOWN_MAX)
	duration = RW_MELEE_SLOWDOWN_DURATION
	rw_update_movespeed()

/datum/status_effect/rw_melee_recoil/proc/rw_update_movespeed()
	if(QDELETED(owner))
		return
	var/multiplier = HAS_TRAIT(owner, TRAIT_COMBAT_SLOWDOWN_RESISTANT) ? 0.5 : 1
	owner.add_or_update_variable_movespeed_modifier(
		/datum/movespeed_modifier/rw_melee_recoil,
		multiplicative_slowdown = RW_MELEE_SLOWDOWN * stacks * multiplier
	)

/datum/movespeed_modifier/rw_melee_recoil
	variable = TRUE
	multiplicative_slowdown = RW_MELEE_SLOWDOWN
	id = MOVESPEED_ID_RW_MELEE_RECOIL
	priority = 100

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


/**
 * Projectile damage application.
 */
/mob/living/proc/apply_projectile_effects(obj/projectile/proj, def_zone, armor_check)
	if(proj.is_hostile_projectile() && try_dodge(proj.firer, "\the [proj]", PROJECTILE_ATTACK))
		return

	var/damage_dealt = apply_damage(
		damage = proj.damage,
		damagetype = proj.damage_type,
		def_zone = def_zone,
		blocked = 0,
		wound_bonus = proj.wound_bonus,
		exposed_wound_bonus = proj.exposed_wound_bonus,
		sharpness = proj.sharpness,
		attack_direction = get_dir(proj.starting, src),
		attacking_item = proj,
	)

	if(damage_dealt > 0)
		apply_status_effect(/datum/status_effect/rw_melee_recoil, 1)

	apply_effects(
		stun = proj.stun,
		knockdown = proj.knockdown,
		unconscious = proj.unconscious,
		slur = (mob_biotypes & MOB_ROBOTIC) ? 0 SECONDS : proj.slur,
		stutter = (mob_biotypes & MOB_ROBOTIC) ? 0 SECONDS : proj.stutter,
		eyeblur = proj.eyeblur,
		drowsy = proj.drowsy,
		blocked = 0,
		stamina = proj.stamina,
		jitter = (mob_biotypes & MOB_ROBOTIC) ? 0 SECONDS : proj.jitter,
		paralyze = proj.paralyze,
		immobilize = proj.immobilize,
	)

	if(proj.dismemberment)
		check_projectile_dismemberment(proj, def_zone)

	if(proj.damage && armor_check < 100)
		create_projectile_hit_effects(proj, def_zone, armor_check)

	if(proj.fired_from)
		SEND_SIGNAL(proj.fired_from, COMSIG_PROJECTILE_POST_HIT_LIVING, src, def_zone, armor_check)
	SEND_SIGNAL(proj, COMSIG_PROJECTILE_SELF_POST_HIT_LIVING, src, def_zone, armor_check)
	return damage_dealt

/**
 * Thrown items
 */
/mob/living/hitby(atom/movable/AM, skipcatch, hitpush = TRUE, blocked = FALSE, datum/thrownthing/throwingdatum)
	if(!isitem(AM))
		if(check_block(AM, 30, "\the [AM.name]", THROWN_PROJECTILE_ATTACK, 0, BRUTE) & SUCCESSFUL_BLOCK)
			hitpush = FALSE
			skipcatch = TRUE
			blocked = TRUE
			return SUCCESSFUL_BLOCK
		else
			playsound(loc, 'sound/items/weapons/genhit.ogg', 50, TRUE, -1)
			if(!isvendor(AM) && !iscarbon(AM))
				visible_message(span_danger("[src] is hit by [AM]!"), \
							span_userdanger("You're hit by [AM]!"))
		log_combat(AM, src, "hit ")
		return ..()

	var/obj/item/thrown_item = AM
	var/mob/thrown_by = throwingdatum?.get_thrower()

	if(thrown_by != src)
		if(check_block(AM, thrown_item.throwforce, "\the [thrown_item.name]", THROWN_PROJECTILE_ATTACK, 0, thrown_item.damtype))
			hitpush = FALSE
			skipcatch = TRUE
			blocked = TRUE

	var/zone = get_random_valid_zone(BODY_ZONE_CHEST, 65)
	var/nosell_hit = (SEND_SIGNAL(thrown_item, COMSIG_MOVABLE_IMPACT_ZONE, src, zone, blocked, throwingdatum) & MOVABLE_IMPACT_ZONE_OVERRIDE)
	if(nosell_hit)
		skipcatch = TRUE
		hitpush = FALSE

	if(blocked)
		return SUCCESSFUL_BLOCK

	if(nosell_hit)
		log_hit_combat(thrown_by, thrown_item)
		return ..()

	if(try_dodge(thrown_by, "\the [thrown_item]", THROWN_PROJECTILE_ATTACK))
		return SUCCESSFUL_BLOCK

	visible_message(span_danger("[src] is hit by [thrown_item]!"),
		span_userdanger("You're hit by [thrown_item]!"))
	if(!thrown_item.throwforce)
		log_hit_combat(thrown_by, thrown_item)
		return

	run_armor_check(
		zone,
		MELEE,
		"Your armor has protected your [parse_zone_with_bodypart(zone)].",
		"Your armor has softened hit to your [parse_zone_with_bodypart(zone)].",
		thrown_item.armour_penetration,
		"",
		FALSE,
		thrown_item.weak_against_armour,
	)

	var/damage_dealt = apply_damage(
		thrown_item.throwforce,
		thrown_item.damtype,
		zone,
		blocked = 0,
		sharpness = thrown_item.get_sharpness(),
		wound_bonus = (nosell_hit * CANT_WOUND),
		attacking_item = thrown_item,
	)

	if(damage_dealt > 0)
		apply_status_effect(/datum/status_effect/rw_melee_recoil, 1)

	log_hit_combat(thrown_by, thrown_item)

	if(QDELETED(src))
		return
	if(body_position == LYING_DOWN)
		hitpush = FALSE

	return ..()


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

	if(damage_done > 0)
		apply_status_effect(/datum/status_effect/rw_melee_recoil, 1)

	log_combat(user, src, "attacked")
	return damage_done

/mob/living/carbon/human/attack_effects(damage_done, hit_zone, armor_block, obj/item/attacking_item, mob/living/attacker)
	. = ..()
	return .

#endif
