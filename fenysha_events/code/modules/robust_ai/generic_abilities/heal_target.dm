
/datum/action/cooldown/mob_cooldown/heal_target

	name = "Heal target"
	desc = "Heal the target."

	cooldown_time = 6 SECONDS
	shared_cooldown = null

	button_icon = 'icons/obj/storage/medkit.dmi'
	button_icon_state = "medbriefcase"

	var/heal_amount = 15
	var/heal_delay = 2 SECONDS
	var/minimum_damage = 5

	/// Wounds can be treated after ordinary damage.
	var/treat_wounds = TRUE


/datum/action/cooldown/mob_cooldown/heal_target/Activate(atom/target)

	var/mob/living/user = owner

	if(QDELETED(user) || QDELETED(target))
		return

	if(!isliving(target))
		return

	var/mob/living/living_target = target

	if(living_target == user)
		return

	if(living_target.stat == DEAD)
		return

	if(get_dist(user, living_target) > 2)
		return

	if(!can_see(user, living_target, 2))
		return

	if((living_target.get_total_damage() < minimum_damage) && !(treat_wounds && has_treatable_wounds(living_target)))
		return

	if(!do_after(
		user,
		heal_delay,
		living_target,
		max_interact_count = 1
	))
		StartCooldown(1 SECONDS)
		return

	if(QDELETED(living_target))
		return

	if(living_target.stat == DEAD)
		return

	// Heal ordinary damage first.
	if(living_target.get_total_damage() >= minimum_damage)
		living_target.heal_ordered_damage(
			amount = heal_amount,
			damage_types = list(BRUTE, BURN, TOX, OXY)
		)

	// Then attempt to treat wounds.
	if(treat_wounds)
		treat_wounds(living_target)

	return ..()


/datum/action/cooldown/mob_cooldown/heal_target/proc/has_treatable_wounds(
	mob/living/target
)
	if(!iscarbon(target))
		return FALSE

	var/mob/living/carbon/carbon_target = target

	for(var/obj/item/bodypart/part as anything in carbon_target.bodyparts)
		if(part.wounds)
			return TRUE

	return FALSE


/datum/action/cooldown/mob_cooldown/heal_target/proc/treat_wounds(
	mob/living/target
)
	if(!iscarbon(target))
		return

	var/mob/living/carbon/carbon_target = target

	for(var/obj/item/bodypart/part as anything in carbon_target.bodyparts)

		if(!part.wounds)
			continue
		heal_wound(part)
		return


/datum/action/cooldown/mob_cooldown/heal_target/proc/heal_wound(
	obj/item/bodypart/part
)
	return
