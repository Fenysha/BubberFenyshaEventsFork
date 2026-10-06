/obj/item/gun/rimworld/equipped(mob/user, slot, initial = FALSE)
	. = ..()
	if(!(slot & ITEM_SLOT_HANDS) || !isliving(user))
		rw_unwield(null, silent = TRUE)
		return
	RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(rw_on_user_moved), override = TRUE)
	rw_last_move = world.time
	if(rw_biocode_enabled && rw_biocode_on_equip && !rw_is_biocoded())
		rw_biocode_to(user)
	rw_sanitize_modes(user)
	rw_recalc_attachments(user)
	rw_refresh_hud()


/obj/item/gun/rimworld/dropped(mob/user, silent = FALSE)
	. = ..()
	rw_wield_busy = FALSE
	rw_unwield(user, silent = TRUE)
	if(user)
		UnregisterSignal(user, COMSIG_MOVABLE_MOVED)


/obj/item/gun/rimworld/proc/rw_on_user_moved(datum/source)
	SIGNAL_HANDLER
	rw_last_move = world.time


/obj/item/gun/rimworld/proc/rw_refresh_hud()
	rw_hud?.update_all()


/obj/item/gun/rimworld/proc/rw_is_biocoded()
	return !isnull(rw_biocode_mind)


/obj/item/gun/rimworld/proc/rw_biocode_allows(mob/living/user)
	if(!rw_biocode_enabled || !rw_is_biocoded())
		return TRUE
	return user?.mind && rw_biocode_mind.resolve() == user.mind


/obj/item/gun/rimworld/proc/rw_biocode_to(mob/living/user)
	if(!user?.mind)
		return FALSE
	rw_biocode_mind = WEAKREF(user.mind)
	rw_biocode_name = user.real_name
	to_chat(user, span_notice("[src] chirps: biocoded to [rw_biocode_name]."))
	return TRUE


/obj/item/gun/rimworld/proc/rw_clear_biocode()
	rw_biocode_mind = null
	rw_biocode_name = null


/// Replaces the normal firing-pin check with the biocode lock.
/obj/item/gun/rimworld/handle_pins(mob/living/user)
	if(rw_biocode_allows(user))
		return TRUE
	balloon_alert(user, "biocoded to [rw_biocode_name]!")
	to_chat(user, span_warning("[src]'s trigger is locked. It is biocoded to [rw_biocode_name]."))
	return FALSE


/obj/item/gun/rimworld/proc/rw_on_ready_again()
	rw_refresh_hud()
	rw_update_ready_overlay()


/// Show / hide the "busy" overlay while the gun cannot fire.
/obj/item/gun/rimworld/proc/rw_update_ready_overlay()
	var/should_show = !rw_can_fire_now()
	if(should_show)
		if(!rw_not_ready_overlay)
			rw_not_ready_overlay = mutable_appearance(rw_not_ready_overlay_icon, rw_not_ready_overlay_state)
			rw_not_ready_overlay.appearance_flags = RESET_COLOR | KEEP_APART
		add_overlay(rw_not_ready_overlay)
	else if(rw_not_ready_overlay)
		cut_overlay(rw_not_ready_overlay)


/// Right-click in hand: bind or clear biocode (3 s do_after).
/obj/item/gun/rimworld/attack_self_secondary(mob/user, modifiers)
	if(!rw_biocode_enabled || !isliving(user))
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	if(rw_is_biocoded())
		if(!rw_biocode_allows(user))
			balloon_alert(user, "biocoded to [rw_biocode_name]!")
			return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
		balloon_alert(user, "clearing biocode...")
		if(do_after(user, 3 SECONDS, src))
			rw_clear_biocode()
			balloon_alert(user, "biocode cleared")
	else
		balloon_alert(user, "biocoding...")
		if(do_after(user, 3 SECONDS, src))
			rw_biocode_to(user)
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN


/obj/item/gun/rimworld/emag_act(mob/user, obj/item/card/emag/emag_card)
	. = ..()
	if(!rw_is_biocoded())
		return
	rw_clear_biocode()
	balloon_alert(user, "biocode fried")
	return TRUE


/obj/item/gun/rimworld/examine(mob/user)
	. = ..()
	if(rw_is_biocoded())
		. += span_notice("It is biocoded to <b>[rw_biocode_name]</b>. Right-click it in hand to re-code or clear.")
	else if(rw_biocode_enabled)
		. += span_notice("It is not biocoded. Right-click it in hand to bind it to yourself.")
	. += span_notice("Press <b>Z</b> to grip it with both hands. Effective range: <b>[rw_effective_range] tiles</b>.")
	. += span_notice("Aimed mode needs Shooting [RW_REQ_SKILL_AIMED]+, suppression needs [RW_REQ_SKILL_SUPPRESS]+, limb targeting needs [RW_REQ_SKILL_LIMB]+.")
	. += span_notice("Tactical reload (mag on loaded gun / gun on mag) needs Shooting [RW_REQ_SKILL_TACTICAL_RELOAD]+.")
	. += rw_attachment_examine_lines(user)
