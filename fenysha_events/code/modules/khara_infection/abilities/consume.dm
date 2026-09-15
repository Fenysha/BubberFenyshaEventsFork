/datum/action/cooldown/mob_cooldown/consume
	name = "Devour"
	desc = "Devour the target's body parts and innards, shredding them to pieces.."
	button_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "berserk_mode"

	var/base_amputation_chance = 30
	var/complicated_limb_amputation_chance = 20
	var/base_damage_min = 40
	var/base_damage_max = 60
	var/wound_bonus = 40
	var/do_after_delay = 4 SECONDS
	var/max_uses_on_down = 3

/datum/action/cooldown/mob_cooldown/consume/Activate(atom/target)
	if(!iscarbon(target))
		return FALSE
	var/mob/living/carbon/carbon_target = target
	if(get_dist(owner, carbon_target) > 1)
		owner.balloon_alert(owner, "too far!")
		return FALSE

	var/amputation_chance = base_amputation_chance
	if(carbon_target.stat != STABLE)
		amputation_chance += 100

	StartCooldown()
	INVOKE_ASYNC(src, PROC_REF(perform_decup), carbon_target, amputation_chance)

/datum/action/cooldown/mob_cooldown/consume/proc/perform_decup(mob/living/carbon/target, amputation_chance)
	if(!length(target.bodyparts))
		owner.balloon_alert(owner, "No limbs to consume!")
		return

	var/list/valid_limbs = list()
	var/list/complicated_limbs = list()
	for(var/obj/item/bodypart/limb in target.bodyparts)
		if(limb.body_zone == BODY_ZONE_CHEST || limb.body_zone == BODY_ZONE_HEAD)
			complicated_limbs += limb
		else
			valid_limbs += limb

	var/obj/item/bodypart/chosen_limb = length(valid_limbs) ? pick(valid_limbs) : pick(complicated_limbs)
	var/is_complicated_limb = (chosen_limb.body_zone == BODY_ZONE_CHEST || chosen_limb.body_zone == BODY_ZONE_HEAD)

	var/effective_amputation_chance = is_complicated_limb ? complicated_limb_amputation_chance : amputation_chance

	owner.visible_message(
		span_danger("[owner] lunges at [target]'s [chosen_limb.name], baring its teeth to tear it off!"),
		span_danger("You sink your teeth into [target]'s [chosen_limb.name]!"),
	)
	playsound(target, 'sound/effects/magic/demon_attack1.ogg', 50, TRUE)

	if(!do_after(owner, do_after_delay, target))
		owner.balloon_alert(owner, "Consumption interrupted!")
		return

	playsound(target, 'sound/effects/magic/demon_consume.ogg', 75, TRUE)
	owner.balloon_alert(owner, "Consumed [chosen_limb.name]!")

	if(effective_amputation_chance >= 100 || prob(effective_amputation_chance))
		if(!is_complicated_limb)
			chosen_limb.forced_removal(TRUE, TRUE, FALSE)
			target.spawn_gibs()
			owner.visible_message(
				span_danger("[owner] tears off [target]'s [chosen_limb.name] entirely with savage fury!"),
				span_danger("You tear off [target]'s [chosen_limb.name]!"),
			)
			qdel(chosen_limb)
		else
			var/obj/item/organ/to_remove = null
			if(chosen_limb.body_zone == BODY_ZONE_CHEST)
				to_remove = target.get_organ_slot(pick(ORGAN_SLOT_HEART, ORGAN_SLOT_LIVER, ORGAN_SLOT_LUNGS, ORGAN_SLOT_STOMACH))
			else
				to_remove = target.get_organ_slot(pick(ORGAN_SLOT_EARS, ORGAN_SLOT_EYES, ORGAN_SLOT_BRAIN))
			if(to_remove)
				to_remove.bodypart_remove(chosen_limb, target)
				owner.visible_message(
					span_danger("[owner] rips out [target]'s [to_remove.name] with a disgusting crunch!"),
					span_danger("You rip out [target]'s [to_remove.name]!"),
				)
				target.spawn_gibs()
			else
				target.apply_damage(rand(base_damage_min * 1.5, base_damage_max * 1.5), BRUTE, chosen_limb.body_zone, FALSE, wound_bonus = wound_bonus)
	else
		target.apply_damage(rand(base_damage_min, base_damage_max), BRUTE, chosen_limb.body_zone, FALSE, wound_bonus = wound_bonus)
		owner.visible_message(
			span_danger("[owner] brutally tears and shreds [target]'s [chosen_limb.name]!"),
			span_danger("You savagely tear apart [target]'s [chosen_limb.name]!"),
		)

	INVOKE_ASYNC(src, PROC_REF(perform_decup), target, amputation_chance)
