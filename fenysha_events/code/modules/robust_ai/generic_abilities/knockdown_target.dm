/datum/action/cooldown/mob_cooldown/knockdown_target
	name = "Knockdown"
	button_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "legsweep"
	desc = "Use the spin move to knock the target off their feet."
	cooldown_time = 7 SECONDS
	shared_cooldown = null

	var/max_distance = 1
	var/knockdown_time = 3 SECONDS

/datum/action/cooldown/mob_cooldown/knockdown_target/PreActivate(atom/target)
	if(!isliving(target))
		return

	if(get_dist(owner, target) > max_distance)
		return
	. = ..()

/datum/action/cooldown/mob_cooldown/knockdown_target/Activate(atom/target)
	var/mob/living/user = owner
	var/mob/living/victim = target

	if(!user || !victim || victim == user)
		return

	if(victim.stat == DEAD)
		return

	user.visible_message(span_warning("[user] knocks [victim] off [victim.p_their()] feet!"))
	playsound(get_turf(user), 'sound/items/weapons/slam.ogg', 50, TRUE, -1)
	user.spin(3)
	victim.Knockdown(knockdown_time)
	return ..()

