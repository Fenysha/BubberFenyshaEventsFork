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
