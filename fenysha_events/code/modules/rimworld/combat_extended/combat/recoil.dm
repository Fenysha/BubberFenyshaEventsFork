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
#endif
