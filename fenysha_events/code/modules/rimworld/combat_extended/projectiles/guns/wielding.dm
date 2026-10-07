/obj/item/gun/rimworld/proc/rw_on_wield(obj/item/source, mob/living/user)
	rw_wielded = TRUE
	update_appearance()
	user?.update_held_items()
	rw_refresh_hud()
	return NONE

/obj/item/gun/rimworld/proc/rw_on_unwield(obj/item/source, mob/living/user)
	rw_wielded = FALSE
	update_appearance()
	user?.update_held_items()
	rw_refresh_hud()
	return NONE

/obj/item/gun/rimworld/attack_self(mob/living/user)
	if(rw_wield_busy)
		return
	var/datum/component/two_handed/th = GetComponent(/datum/component/two_handed)
	if(!th)
		return
	if(th.wielded)
		th.unwield(user)
		return
	rw_try_wield(user)

/// Time (ds) required to finish the two-handed grip do_after.
/obj/item/gun/rimworld/proc/rw_wield_duration(mob/living/user)
	var/skill = rw_ranged_skill(user)
	var/manip = clamp(rw_manipulation(user), 0.3, 1)
	// Floor of 2 ds so the do_after never becomes instant.
	return max(2, round(rw_wield_time * rw_att_wield_mult * clamp(1.4 - 0.03 * skill, 0.8, 1.4) / manip))

/// Start the do_after that ends in a proper two-handed wield.
/obj/item/gun/rimworld/proc/rw_try_wield(mob/living/user)
	if(!user.is_holding(src))
		return
	if(user.get_inactive_held_item())
		balloon_alert(user, "free your other hand!")
		return
	if(HAS_TRAIT(user, TRAIT_HANDS_BLOCKED) || HAS_TRAIT(user, TRAIT_NO_TWOHANDING))
		balloon_alert(user, "can't use two hands!")
		return
	if(user.usable_hands < 2)
		balloon_alert(user, "not enough hands!")
		return

	rw_wield_busy = TRUE
	user.visible_message(
		span_notice("[user] begins to bring [src] up in a two-handed grip."),
		span_notice("You start gripping [src] with both hands..."),
	)
	var/ok = do_after(user, rw_wield_duration(user), src, IGNORE_USER_LOC_CHANGE)
	rw_wield_busy = FALSE
	if(!ok || QDELETED(src) || !user.is_holding(src) || user.get_inactive_held_item())
		return

	var/datum/component/two_handed/th = GetComponent(/datum/component/two_handed)
	if(th)
		th.wield(user)

/obj/item/gun/rimworld/proc/rw_unwield(mob/living/user, silent = FALSE)
	var/datum/component/two_handed/th = GetComponent(/datum/component/two_handed)
	if(th?.wielded)
		th.unwield(user, show_message = !silent)
