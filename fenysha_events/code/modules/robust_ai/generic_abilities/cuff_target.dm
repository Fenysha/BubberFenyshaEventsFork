

/datum/action/cooldown/mob_cooldown/restrain_target
	name = "Restrain target"
	desc = "Restrain an incapacitated target."

	cooldown_time = 10 SECONDS
	shared_cooldown = null

	button_icon = 'icons/obj/weapons/restraints.dmi'
	button_icon_state = "cuff"

	var/restrain_time = 5 SECONDS
	var/restrain_type = /obj/item/restraints/handcuffs/cable


/datum/action/cooldown/mob_cooldown/restrain_target/Activate(atom/target)

	var/mob/living/user = owner

	if(QDELETED(user) || QDELETED(target))
		return

	if(!iscarbon(target))
		return

	var/mob/living/carbon/carbon_target = target

	if(carbon_target == user)
		return

	if(carbon_target.stat == DEAD)
		return

	if(carbon_target.handcuffed)
		return

	if(!carbon_target.canBeHandcuffed())
		return

	if(carbon_target.staminaloss < carbon_target.max_stamina)
		return

	if(get_dist(user, carbon_target) > 1)
		return

	if(!do_after(
		user,
		restrain_time,
		carbon_target
	))
		StartCooldown(2 SECONDS)
		return

	if(QDELETED(carbon_target))
		return

	if(carbon_target.stat == DEAD)
		return

	if(carbon_target.handcuffed)
		return

	if(!carbon_target.canBeHandcuffed())
		return

	carbon_target.set_handcuffed(
		new restrain_type(carbon_target)
	)

	carbon_target.update_handcuffed()

	return ..()
