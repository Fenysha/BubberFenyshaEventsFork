/datum/action/cooldown/mob_cooldown/throw_grenade
	name = "Throw Grenade"
	desc = "Throw grande at target."

	cooldown_time = 30 SECONDS
	shared_cooldown = null

	var/obj/item/grenade/grenade_type = /obj/item/grenade/syndieminibomb/concussion
	button_icon = 'icons/obj/weapons/grenade.dmi'
	button_icon_state = "concussion"

/datum/action/cooldown/mob_cooldown/throw_grenade/Activate(atom/target)
	var/mob/living/user = owner

	if(QDELETED(user))
		return

	user.visible_message(span_userdanger("[user] is preparing to throw grenade at [target]!"))
	if(!do_after(user, 1.5 SECONDS, user, max_interact_count = 1))
		StartCooldown(3 SECONDS)
		return

	var/obj/item/grenade/G = new grenade_type(get_turf(user))
	G.arm_grenade(user)
	G.throw_at(target, get_dist(user, target), 3, user, TRUE)
	return ..()

