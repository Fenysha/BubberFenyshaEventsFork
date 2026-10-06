/obj/item/gun/rimworld/ballistic
	name = "rimworld ballistic gun"
	desc = "A firearm that accepts detachable magazines of a specific caliber."
	abstract_type = /obj/item/gun/rimworld/ballistic

	/// Barrel caliber. Magazines must use the same caliber.
	var/rw_caliber = RW_CALIBER_9MM

	/// Primary accepted magazine type.
	var/obj/item/ammo_box/magazine/rw_accepted_magazine_type = /obj/item/ammo_box/magazine/rimworld

	/// Additional accepted magazine types.
	var/list/rw_extra_magazine_types

	/// Magazine type to spawn with.
	var/obj/item/ammo_box/magazine/rw_spawn_magazine_type

	/// Draw a magazine overlay while a detachable magazine is inserted.
	var/rw_mag_display = TRUE
	/// Magazine overlay icon state. Null derives it from base_icon_state.
	var/rw_mag_icon_state
	/// Optional icon file override. Null uses the gun icon.
	var/rw_magazine_icon
	/// Magazine overlay X offset.
	var/rw_mag_x_offset = 0
	/// Magazine overlay Y offset.
	var/rw_mag_y_offset = 0


/obj/item/gun/rimworld/ballistic/Initialize(mapload)
	if(rw_accepted_magazine_type)
		accepted_magazine_type = rw_accepted_magazine_type
	if(!rw_spawn_magazine_type)
		rw_spawn_magazine_type = rw_accepted_magazine_type
	if(rw_spawn_magazine_type && !spawn_magazine_type)
		spawn_magazine_type = rw_spawn_magazine_type

	// Derive the magazine overlay state when a subtype does not provide one.
	if(isnull(rw_mag_icon_state) && base_icon_state)
		rw_mag_icon_state = "[base_icon_state]_mag"

	. = ..()

	if(magazine && !rw_can_accept_magazine(magazine))
		stack_trace("[src] spawned with illegal magazine [magazine.type] for caliber [rw_caliber].")
		QDEL_NULL(magazine)


/// Resolve the icon used for the magazine overlay.
/obj/item/gun/rimworld/ballistic/proc/rw_get_magazine_icon()
	return rw_magazine_icon || icon

/// Resolve the magazine overlay icon state.
/obj/item/gun/rimworld/ballistic/proc/rw_get_magazine_icon_state()
	if(rw_mag_icon_state)
		return rw_mag_icon_state
	if(base_icon_state)
		return "[base_icon_state]_mag"
	return "[icon_state]_mag"

/// Return TRUE when the detachable magazine should be shown.
/obj/item/gun/rimworld/ballistic/proc/rw_should_show_mag_overlay()
	return rw_mag_display && !internal_magazine && !!magazine

/obj/item/gun/rimworld/ballistic/update_overlays()
	. = ..()
	if(!rw_should_show_mag_overlay())
		return
	var/mutable_appearance/mag_overlay = mutable_appearance(
		rw_get_magazine_icon(),
		rw_get_magazine_icon_state(),
		layer = layer,
	)
	mag_overlay.pixel_x = rw_mag_x_offset
	mag_overlay.pixel_y = rw_mag_y_offset
	. += mag_overlay


/obj/item/gun/rimworld/ballistic/rw_get_ammo_count()
	if(internal_magazine)
		return get_ammo()
	return magazine ? magazine.ammo_count() : 0

/obj/item/gun/rimworld/ballistic/rw_get_ammo_max()
	if(internal_magazine)
		return magazine.max_ammo
	return magazine ? magazine.max_ammo : 0


/obj/item/gun/rimworld/ballistic/update_appearance(updates = ALL)
	. = ..()
	rw_refresh_hud()


/obj/item/gun/rimworld/ballistic/proc/rw_can_accept_magazine(obj/item/ammo_box/magazine/rimworld/mag)
	if(!istype(mag))
		return FALSE
	if(rw_caliber)
		var/mag_cal = mag.rw_caliber
		if(mag_cal && (mag_cal != rw_caliber))
			return FALSE
	if(rw_accepted_magazine_type && istype(mag, rw_accepted_magazine_type))
		return TRUE
	for(var/path in rw_extra_magazine_types)
		if(istype(mag, path))
			return TRUE
	return FALSE

/obj/item/gun/rimworld/ballistic/proc/rw_magazine_reject_reason(obj/item/ammo_box/magazine/rimworld/mag)
	if(!istype(mag))
		return "not a magazine!"
	if(rw_caliber && mag.rw_caliber && mag.rw_caliber != rw_caliber)
		return "wrong caliber ([mag.rw_caliber])!"
	return "incompatible magazine!"


/obj/item/gun/rimworld/ballistic/proc/rw_mag_swap_duration(mob/living/user)
	var/skill = rw_ranged_skill(user)
	var/manip = clamp(rw_manipulation(user), 0.3, 1)
	return max(0.4 SECONDS, round(RW_MAG_SWAP_TIME * clamp(1.35 - 0.035 * skill, 0.4, 1.35) / manip))

/obj/item/gun/rimworld/ballistic/proc/rw_service(mob/living/user)
	if(rw_wield_busy)
		return FALSE
	if(!internal_magazine && magazine && !magazine.ammo_count())
		eject_magazine(user)
		return TRUE
	if(bolt_type == BOLT_TYPE_NO_BOLT)
		unload_ammo(user)
		return TRUE
	if(bolt_type == BOLT_TYPE_LOCKING && bolt_locked)
		drop_bolt(user)
		return TRUE
	if(recent_rack > world.time)
		return TRUE
	recent_rack = world.time + rack_delay
	rack(user)
	return TRUE


/obj/item/gun/rimworld/ballistic/eject_magazine(mob/user, display_message = TRUE, obj/item/ammo_box/magazine/tac_load = null)
	if(!magazine)
		return
	if(rw_wield_busy)
		return

	var/duration = isliving(user) ? rw_mag_swap_duration(user) : RW_MAG_SWAP_TIME
	if(display_message && isliving(user))
		user.visible_message(
			span_notice("[user] starts ejecting the magazine from [src]..."),
			span_notice("You start ejecting the magazine..."),
		)
		if(!do_after(user, duration, src))
			return

	. = ..()
	update_appearance()
	rw_refresh_hud()


/obj/item/gun/rimworld/ballistic/insert_magazine(mob/user, obj/item/ammo_box/magazine/AM, display_message = TRUE)
	if(rw_wield_busy)
		return FALSE
	if(!rw_can_accept_magazine(AM))
		if(isliving(user))
			balloon_alert(user, rw_magazine_reject_reason(AM))
		return FALSE

	if(display_message && isliving(user))
		var/duration = rw_mag_swap_duration(user)
		user.visible_message(
			span_notice("[user] starts loading a magazine into [src]..."),
			span_notice("You start loading the magazine..."),
		)
		if(!do_after(user, duration, src))
			return FALSE

	. = ..()
	update_appearance()
	rw_refresh_hud()
	return .


/obj/item/gun/rimworld/ballistic/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(istype(tool, /obj/item/ammo_box/magazine))
		if(magazine)
			return rw_try_tactical_reload(user, tool)
		return insert_magazine(user, tool) ? ITEM_INTERACT_SUCCESS : ITEM_INTERACT_BLOCKING
	return ..()


/obj/item/gun/rimworld/ballistic/proc/rw_try_tactical_reload(mob/living/user, obj/item/ammo_box/magazine/new_mag)
	if(!magazine)
		return ITEM_INTERACT_BLOCKING
	if(rw_ranged_skill(user) < RW_REQ_SKILL_TACTICAL_RELOAD)
		balloon_alert(user, "need Shooting [RW_REQ_SKILL_TACTICAL_RELOAD]+ for tactical reload!")
		return ITEM_INTERACT_BLOCKING
	if(!rw_can_accept_magazine(new_mag))
		balloon_alert(user, rw_magazine_reject_reason(new_mag))
		return ITEM_INTERACT_BLOCKING
	if(rw_wield_busy)
		return ITEM_INTERACT_BLOCKING

	var/duration = rw_mag_swap_duration(user) * 0.7
	user.visible_message(
		span_notice("[user] starts a tactical reload on [src]..."),
		span_notice("You start a tactical reload..."),
	)
	if(!do_after(user, duration, src))
		return ITEM_INTERACT_BLOCKING

	var/obj/item/ammo_box/magazine/old = magazine
	magazine = null
	old.forceMove(drop_location())
	user.put_in_hands(old)

	if(!insert_magazine(user, new_mag, display_message = FALSE))
		if(!QDELETED(old))
			magazine = old
			if(user.is_holding(old))
				user.dropItemToGround(old)
			old.forceMove(src)
		update_appearance()
		rw_refresh_hud()
		return ITEM_INTERACT_BLOCKING

	playsound(src, load_sound, 50, TRUE)
	balloon_alert(user, "tactical reload!")
	update_appearance()
	rw_refresh_hud()
	return ITEM_INTERACT_SUCCESS


/obj/item/gun/rimworld/ballistic/examine(mob/user)
	. = ..()
	. += span_notice("Caliber: <b>[rw_caliber]</b>.")
	if(internal_magazine)
		. += span_notice("Internal magazine: [rw_get_ammo_count()]/[rw_get_ammo_max()].")
	else if(magazine)
		. += span_notice("Magazine: [magazine.name] ([rw_get_ammo_count()]/[rw_get_ammo_max()]).")
	else
		. += span_warning("No magazine loaded.")


/obj/item/ammo_box/magazine/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(istype(tool, /obj/item/gun/rimworld/ballistic))
		var/obj/item/gun/rimworld/ballistic/G = tool
		if(G.magazine)
			return G.rw_try_tactical_reload(user, src)
		return G.insert_magazine(user, src) ? ITEM_INTERACT_SUCCESS : ITEM_INTERACT_BLOCKING
	return ..()


/datum/keybinding/mob/rw_rack_gun
	hotkey_keys = list("Space")
	name = "rw_rack_gun"
	full_name = "Rack / Service Gun"
	description = "Racks the bolt, releases a locked bolt or ejects an empty magazine on the RimWorld-style gun in your hands."
	keybind_signal = COMSIG_KB_MOB_RW_RACK_DOWN

/datum/keybinding/mob/rw_rack_gun/down(client/user, turf/target, mousepos_x, mousepos_y)
	. = ..()
	if(.)
		return

	var/mob/living/user_mob = user.mob
	if(!isliving(user_mob))
		return FALSE

	for(var/obj/item/gun/rimworld/ballistic/held_gun in list(user_mob.get_active_held_item(), user_mob.get_inactive_held_item()))
		if(held_gun.rw_service(user_mob))
			return TRUE
	return FALSE


/obj/item/ammo_casing/rimworld
	name = "rimworld casing"
	projectile_type = /obj/projectile/rimworld
