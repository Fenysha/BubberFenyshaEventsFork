#ifndef OLD_COMBAT_SYSTEM
/datum/species/proc/harm(mob/living/carbon/human/user, mob/living/carbon/human/target, datum/martial_art/attacker_style)
	if(HAS_TRAIT(user, TRAIT_PACIFISM) && !attacker_style?.pacifist_style)
		to_chat(user, span_warning("You don't want to harm [target]!"))
		return FALSE

	var/obj/item/organ/brain/brain = user.get_organ_slot(ORGAN_SLOT_BRAIN)
	var/obj/item/bodypart/attacking_bodypart = attacker_style?.get_attacking_limb(user, target) || brain?.get_attacking_limb(target) || user.get_active_hand()

	var/biting = FALSE

	var/atk_verb_index = rand(1, length(attacking_bodypart.unarmed_attack_verbs))
	var/atk_verb = attacking_bodypart.unarmed_attack_verbs[atk_verb_index]
	var/atk_verb_continuous = "[atk_verb]s"
	if(length(attacking_bodypart.unarmed_attack_verbs_continuous) >= atk_verb_index)
		atk_verb_continuous = attacking_bodypart.unarmed_attack_verbs_continuous[atk_verb_index]

	var/atk_effect = attacking_bodypart.unarmed_attack_effect

	if(atk_effect == ATTACK_EFFECT_BITE)
		if(!user.is_mouth_covered(ITEM_SLOT_MASK))
			biting = TRUE
		else if(user.get_active_hand())
			attacking_bodypart = user.get_active_hand()
			atk_verb_index = rand(1, length(attacking_bodypart.unarmed_attack_verbs))
			atk_verb = attacking_bodypart.unarmed_attack_verbs[atk_verb_index]
			atk_verb_continuous = "[atk_verb]s"
			if(length(attacking_bodypart.unarmed_attack_verbs_continuous) >= atk_verb_index)
				atk_verb_continuous = attacking_bodypart.unarmed_attack_verbs_continuous[atk_verb_index]
			atk_effect = attacking_bodypart.unarmed_attack_effect
		else
			user.balloon_alert(user, "can't attack!")
			return FALSE

	user.do_attack_animation(target, atk_effect)

	var/staggered = target.has_status_effect(/datum/status_effect/staggered)
	var/grappled = (target.pulledby && target.pulledby.grab_state >= GRAB_AGGRESSIVE)

	var/lower_unarmed_damage = attacking_bodypart.unarmed_damage_low
	var/upper_unarmed_damage = attacking_bodypart.unarmed_damage_high

	upper_unarmed_damage += HAS_TRAIT(user, TRAIT_STRENGTH) ? 2 : 0

	// Skill bonus
	var/skill_bonus = user.get_combat_melee_skill()
	if(!skill_bonus)
		skill_bonus = user.mind?.get_skill_level(/datum/skill/athletics) || 0
	lower_unarmed_damage = min(lower_unarmed_damage + skill_bonus, upper_unarmed_damage)

	var/damage = rand(lower_unarmed_damage, upper_unarmed_damage)

	// Capacity damage mod ===
	damage *= user.get_combat_damage_mod()

	var/limb_accuracy = attacking_bodypart.unarmed_effectiveness
	var/limb_sharpness = attacking_bodypart.unarmed_sharpness

	if(grappled)
		var/pummel_bonus = attacking_bodypart.unarmed_pummeling_bonus
		damage = floor(damage * pummel_bonus)
		limb_accuracy = floor(limb_accuracy * pummel_bonus)

	var/puncher_brute_and_burn = (user.get_fire_loss() + user.get_brute_loss())
	var/target_brute_and_burn = (target.get_fire_loss() + target.get_brute_loss())

	var/user_drunkenness = user.get_drunk_amount()
	if(user_drunkenness)
		if(HAS_TRAIT(user, TRAIT_DRUNKEN_BRAWLER))
			limb_accuracy += clamp(puncher_brute_and_burn / 2, 10, 200)
			damage += damage * clamp(puncher_brute_and_burn / 100, 0.3, 2)
			var/drunken_martial_descriptor = pick("Drunken", "Intoxicated", "Tipsy", "Inebriated", "Delirious", "Day-Drinker's", "Firegut", "Blackout")
			atk_verb = "[drunken_martial_descriptor] [capitalize(atk_verb)]"
			atk_verb_continuous = "[drunken_martial_descriptor] [capitalize(atk_verb_continuous)]"
		else if(user_drunkenness >= 60)
			limb_accuracy = -limb_accuracy
			user.adjust_disgust(5)
		else if(user_drunkenness >= 30)
			limb_accuracy *= 1.2
			user.adjust_disgust(2)

	var/hit_zone = target.get_random_valid_zone(user.zone_selected, blacklisted_parts = (user == target ? list(attacking_bodypart.body_zone) : null))
	var/obj/item/bodypart/affecting = target.get_bodypart(hit_zone)

	// Skill + Capacity miss roll
	var/attacker_skill = user.get_combat_melee_skill()
	var/defender_skill = target.get_combat_melee_skill()
	var/skill_diff = attacker_skill - defender_skill
	var/accuracy_mod = user.get_combat_accuracy_mod()

	var/miss_chance = 100
	if(lower_unarmed_damage)
		if((target.body_position == LYING_DOWN) || HAS_TRAIT(user, TRAIT_PERFECT_ATTACKER) || staggered || (user_drunkenness && HAS_TRAIT(user, TRAIT_DRUNKEN_BRAWLER)))
			miss_chance = 0
		else
			miss_chance = clamp(
				(UNARMED_MISS_CHANCE_BASE - limb_accuracy - (skill_diff * 3.5) + (puncher_brute_and_burn / 2)) / max(accuracy_mod, 0.15),
				0,
				UNARMED_MISS_CHANCE_MAX
			)

	if(!damage || !affecting || prob(miss_chance))
		playsound(target.loc, attacking_bodypart.unarmed_miss_sound, 25, TRUE, -1)
		target.visible_message(span_danger("[user]'s [atk_verb] misses [target]!"), \
						span_danger("You avoid [user]'s [atk_verb]!"), span_hear("You hear a swoosh!"), COMBAT_MESSAGE_RANGE, user)
		to_chat(user, span_warning("Your [atk_verb] misses [target]!"))
		log_combat(user, target, "attempted to punch")
		return FALSE

	if(target.check_block(user, damage, "[user]'s [atk_verb]", UNARMED_ATTACK, 0, BRUTE))
		return FALSE

	if(target.try_dodge(user, "[user]'s [atk_verb]", UNARMED_ATTACK))
		return FALSE

	if(user != target)
		var/parry_result = target.try_parry_attack(user, damage, "bare hands")
		if(parry_result == SUCCESSFUL_BLOCK)
			return ATTACK_FAILED

	var/armor_block = target.run_armor_check(affecting, MELEE, silent = TRUE)
	if(armor_block >= 100)
		to_chat(target, span_notice("Your armor absorbs the blow!"))
	else if(armor_block >= 50)
		to_chat(target, span_warning("Your armor softens the blow!"))

	var/target_drunkenness = target.get_drunk_amount()
	if(target_drunkenness)
		if(HAS_TRAIT(target, TRAIT_DRUNKEN_BRAWLER))
			armor_block += 20
		else if(target_drunkenness >= 60)
			armor_block *= 0.5
			target.adjust_disgust(5)
		else if(target_drunkenness >= 30)
			armor_block += 10
			target.adjust_disgust(2)

	playsound(target.loc, attacking_bodypart.unarmed_attack_sound, 25, TRUE, -1)

	if(grappled && attacking_bodypart.grappled_attack_verb)
		atk_verb = attacking_bodypart.grappled_attack_verb
		atk_verb_continuous = attacking_bodypart.grappled_attack_verb_continuous

	target.visible_message(span_danger("[user] [atk_verb_continuous] [target]!"), \
					span_userdanger("[user] [atk_verb_continuous] you!"), span_hear("You hear a sickening sound of flesh hitting flesh!"), COMBAT_MESSAGE_RANGE, user)
	to_chat(user, span_danger("You [atk_verb] [target]!"))

	target.lastattacker = user.real_name
	target.lastattackerckey = user.ckey

	if(user.limb_destroyer)
		target.dismembering_strike(user, affecting.body_zone)

	var/attack_direction = get_dir(user, target)
	var/attack_type = attacking_bodypart.attack_type
	var/kicking = (atk_effect == ATTACK_EFFECT_KICK)

	target.apply_damage(
		damage,
		attack_type,
		affecting,
		blocked = 0,
		attack_direction = attack_direction,
		sharpness = limb_sharpness,
	)

	// Mutual slowdown
	target.apply_status_effect(/datum/status_effect/rw_melee_recoil, 1)
	if(user != target)
		user.apply_status_effect(/datum/status_effect/rw_melee_recoil, 1)

	if(damage >= 12 || (damage >= 9 && prob(66)))
		target.force_say()
	log_combat(user, target, grappled ? "grapple punched" : (kicking ? "kicked" : "punched"))

	if(user != target && biting && (target.mob_biotypes & MOB_ORGANIC))
		var/datum/reagents/tasty_meal = new()
		tasty_meal.add_reagent(/datum/reagent/consumable/nutriment/protein, round(damage / 3, 1))
		tasty_meal.trans_to(user, tasty_meal.total_volume, transferred_by = user, methods = INGEST)

	SEND_SIGNAL(target, COMSIG_HUMAN_GOT_PUNCHED, user, damage, attack_type, affecting, armor_block, kicking, limb_sharpness)
	SEND_SIGNAL(user, COMSIG_HUMAN_PUNCHED, target, damage, attack_type, affecting, armor_block, kicking, limb_sharpness)

	if(user.client)
		rw_train_skill(user, RW_SKILL_MELEE, RW_SKILL_POINTS_MINOR)
	if(target.client)
		rw_train_skill(target, RW_SKILL_MELEE, RW_SKILL_POINTS_MINOR)

	if(HAS_TRAIT(target, TRAIT_BRAWLING_KNOCKDOWN_BLOCKED) || target.stat == DEAD)
		return

	var/effective_armor = max(armor_block, UNARMED_COMBO_HIT_HEALTH_BASE) - limb_accuracy
	if(staggered && target_brute_and_burn >= clamp(effective_armor, 0, 200))
		stagger_combo(user, target, atk_verb, limb_accuracy, armor_block)

/datum/species/proc/spec_attack_hand(mob/living/carbon/human/owner, mob/living/carbon/human/target, datum/martial_art/attacker_style, modifiers)
	if(!istype(owner))
		return
	CHECK_DNA_AND_SPECIES(owner)
	CHECK_DNA_AND_SPECIES(target)

	if(!istype(owner))
		return
	if(owner.mind)
		attacker_style = GET_ACTIVE_MARTIAL_ART(owner)
	if((owner != target) && target.check_block(owner, 0, owner.name, attack_type = UNARMED_ATTACK))
		log_combat(owner, target, "attempted to touch")
		target.visible_message(span_warning("[owner] attempts to touch [target]!"), \
						span_danger("[owner] attempts to touch you!"), span_hear("You hear a swoosh!"), COMBAT_MESSAGE_RANGE, owner)
		to_chat(owner, span_warning("You attempt to touch [target]!"))
		return

	SEND_SIGNAL(owner, COMSIG_MOB_ATTACK_HAND, owner, target, attacker_style, modifiers)

	if(LAZYACCESS(modifiers, RIGHT_CLICK))
		disarm(owner, target, attacker_style)
		return
	if(owner.combat_mode)
		harm(owner, target, attacker_style)
	else
		help(owner, target, attacker_style)
#endif
