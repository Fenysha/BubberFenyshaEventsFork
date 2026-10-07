// MARK: Recoil
/datum/status_effect/rw_fire_recoil
	id = "rw_fire_recoil"
	duration = RW_FIRE_SLOWDOWN_DURATION
	status_type = STATUS_EFFECT_REFRESH
	alert_type = null
	tick_interval = STATUS_EFFECT_NO_TICK
	var/stacks = 1

/datum/status_effect/rw_fire_recoil/on_creation(mob/living/new_owner, starting_stacks = 1)
	stacks = clamp(starting_stacks, 1, RW_FIRE_SLOWDOWN_MAX)
	return ..()

/datum/status_effect/rw_fire_recoil/on_apply()
	. = ..()
	if(!.)
		return
	rw_update_movespeed()

/datum/status_effect/rw_fire_recoil/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/rw_fire_recoil)
	return ..()

/datum/status_effect/rw_fire_recoil/refresh(effect, starting_stacks = 1)
	stacks = min(stacks + 1, RW_FIRE_SLOWDOWN_MAX)
	duration = RW_FIRE_SLOWDOWN_DURATION
	rw_update_movespeed()

/datum/status_effect/rw_fire_recoil/proc/rw_update_movespeed()
	if(QDELETED(owner))
		return
	owner.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/rw_fire_recoil, multiplicative_slowdown = RW_FIRE_SLOWDOWN * stacks)

/datum/movespeed_modifier/rw_fire_recoil
	variable = TRUE
	multiplicative_slowdown = RW_FIRE_SLOWDOWN
	id = MOVESPEED_ID_RW_FIRE_RECOIL
	priority = 100

/obj/item/gun/rimworld/proc/rw_apply_fire_slowdown(mob/living/user)
	if(!user)
		return

	user.apply_status_effect(/datum/status_effect/rw_fire_recoil)
