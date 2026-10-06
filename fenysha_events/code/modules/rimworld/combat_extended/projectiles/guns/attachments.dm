/obj/item/gun/rimworld
	/// Attachment typepaths accepted by this gun.
	var/list/rw_attachable_allowed
	/// Sprite anchor positions for attachment slots.
	var/list/rw_attachable_offset
	/// Attachments installed during initialization.
	var/list/rw_starting_attachments
	/// slot -> /obj/item/rw_attachment
	var/list/rw_attachments

	/// Base values used to recalculate attachment modifiers from scratch.
	var/rw_base_force
	var/rw_base_w_class


	var/rw_att_spread = 0
	var/rw_att_recoil_spread_mult = 1
	var/rw_att_moving_spread_mult = 1
	var/rw_att_cooldown_mult = 1
	var/rw_att_burst_delay_mult = 1
	var/rw_att_burst_add = 0
	var/rw_att_wield_mult = 1
	var/rw_att_range_mult = 1
	var/rw_att_damage_mult = 1
	var/rw_att_speed_mult = 1
	var/rw_att_miss_add = 0
	var/rw_att_zone_acc_add = 0
	var/rw_att_camera_recoil = 0
	var/rw_att_melee = 0
	var/rw_att_size = 0
	var/rw_att_silenced = FALSE
	var/list/rw_att_fire_modes
	var/rw_att_scope_zoom = 0
	var/rw_att_light_range = 0

	var/rw_applied_scope_zoom = 0
	var/rw_applied_light_range = 0


/obj/item/gun/rimworld/proc/rw_init_attachments()
	rw_base_force = force
	rw_base_w_class = w_class
	rw_attachments = list()
	for(var/att_path in rw_starting_attachments)
		var/obj/item/rw_attachment/att = new att_path(src)
		rw_attach(att, null, silent = TRUE)
	rw_recalc_attachments()
	update_appearance()


/obj/item/gun/rimworld/Destroy()
	rw_attachments = null
	QDEL_NULL(rw_muzzle_flash)
	return ..()


/obj/item/gun/rimworld/proc/rw_recalc_attachments(mob/living/user)
	if(QDELETED(src))
		return
	rw_att_spread = 0
	rw_att_recoil_spread_mult = 1
	rw_att_moving_spread_mult = 1
	rw_att_cooldown_mult = 1
	rw_att_burst_delay_mult = 1
	rw_att_burst_add = 0
	rw_att_wield_mult = 1
	rw_att_range_mult = 1
	rw_att_damage_mult = 1
	rw_att_speed_mult = 1
	rw_att_miss_add = 0
	rw_att_zone_acc_add = 0
	rw_att_camera_recoil = 0
	rw_att_melee = 0
	rw_att_size = 0
	rw_att_silenced = FALSE
	rw_att_fire_modes = null
	rw_att_scope_zoom = 0
	rw_att_light_range = 0

	if(!user && isliving(loc))
		user = loc
	var/skill = user ? rw_ranged_skill(user) : RW_ATT_UNHELD_SKILL

	for(var/slot in rw_attachments)
		var/obj/item/rw_attachment/att = rw_attachments[slot]
		if(att)
			att.accumulate_mods(src, skill)

	rw_att_cooldown_mult = clamp(rw_att_cooldown_mult, 0.3, 3)
	rw_att_range_mult = clamp(rw_att_range_mult, 0.3, 3)
	rw_att_damage_mult = clamp(rw_att_damage_mult, 0.2, 3)
	rw_att_speed_mult = clamp(rw_att_speed_mult, 0.3, 3)
	rw_att_wield_mult = clamp(rw_att_wield_mult, 0.3, 3)


	force = max(0, rw_base_force + rw_att_melee)
	var/new_w_class = clamp(rw_base_w_class + rw_att_size, WEIGHT_CLASS_TINY, WEIGHT_CLASS_HUGE)
	if(new_w_class != w_class)
		update_weight_class(new_w_class)

	rw_sync_scope()
	rw_sync_light()

	if(!rw_can_use_fire_mode(rw_fire_mode))
		rw_fire_mode = RW_FIRE_SINGLE
	rw_refresh_hud()


/obj/item/gun/rimworld/proc/rw_sync_scope()
	if(rw_att_scope_zoom == rw_applied_scope_zoom)
		return
	if(rw_applied_scope_zoom)
		qdel(GetComponent(/datum/component/scope))
	if(rw_att_scope_zoom > 0)
		AddComponent(/datum/component/scope, range_modifier = rw_att_scope_zoom, zoom_method = ZOOM_METHOD_WIELD)
	rw_applied_scope_zoom = rw_att_scope_zoom


/obj/item/gun/rimworld/proc/rw_sync_light()
	if(rw_att_light_range == rw_applied_light_range)
		return
	if(rw_att_light_range > 0)
		set_light(rw_att_light_range, 1, "#fff4d6", l_on = TRUE)
	else
		set_light(0, 0, l_on = FALSE)
	rw_applied_light_range = rw_att_light_range


/obj/item/gun/rimworld/proc/rw_attachment_allowed(obj/item/rw_attachment/att)
	for(var/allowed_path in rw_attachable_allowed)
		if(istype(att, allowed_path))
			return TRUE
	return FALSE

/obj/item/gun/rimworld/proc/rw_attachment_reject_reason(obj/item/rw_attachment/att, mob/living/user)
	if(!rw_attachment_allowed(att))
		return "doesn't fit!"
	if(rw_attachments?[att.slot])
		return "[att.slot] slot is taken!"
	if(firing_burst || rw_wield_busy)
		return "gun is busy!"
	return att.can_attach_reason(src, user)


/obj/item/gun/rimworld/proc/rw_attach_duration(mob/living/user, base_time)
	var/skill = rw_ranged_skill(user)
	var/manip = clamp(rw_manipulation(user), 0.3, 1)
	return max(0.3 SECONDS, round(base_time * clamp(1.4 - 0.04 * skill, 0.5, 1.4) / manip))


/obj/item/gun/rimworld/proc/rw_try_attach(mob/living/user, obj/item/rw_attachment/att)
	var/reason = rw_attachment_reject_reason(att, user)
	if(reason)
		balloon_alert(user, reason)
		return FALSE
	user.visible_message(
		span_notice("[user] starts fitting [att] onto [src]..."),
		span_notice("You start fitting [att] onto [src]..."),
	)
	if(!do_after(user, rw_attach_duration(user, att.attach_delay), src))
		return FALSE

	if(QDELETED(att) || QDELETED(src) || rw_attachment_reject_reason(att, user))
		return FALSE
	if(!user.transferItemToLoc(att, src))
		return FALSE
	rw_attach(att, user)
	RW_TRAIN_SKILL(user, RW_SKILL_RANGED, RW_SKILL_POINTS_TINY)
	return TRUE


/obj/item/gun/rimworld/proc/rw_try_detach(mob/living/user, obj/item/rw_attachment/att)
	if(!(att.attach_flags & RW_ATT_REMOVABLE))
		balloon_alert(user, "can't be removed!")
		return FALSE
	if(firing_burst || rw_wield_busy)
		balloon_alert(user, "gun is busy!")
		return FALSE
	user.visible_message(
		span_notice("[user] starts removing [att] from [src]..."),
		span_notice("You start removing [att] from [src]..."),
	)
	if(!do_after(user, rw_attach_duration(user, att.detach_delay), src))
		return FALSE
	if(QDELETED(att) || QDELETED(src) || att.master_gun != src)
		return FALSE
	rw_detach(att, user)
	RW_TRAIN_SKILL(user, RW_SKILL_RANGED, RW_SKILL_POINTS_TINY)
	return TRUE


/obj/item/gun/rimworld/proc/rw_attach(obj/item/rw_attachment/att, mob/living/user, silent = FALSE)
	if(att.loc != src)
		att.forceMove(src)
	LAZYSET(rw_attachments, att.slot, att)
	att.master_gun = src
	RegisterSignal(att, COMSIG_QDELETING, PROC_REF(rw_on_attachment_qdel))
	att.on_attach(src, user)
	rw_recalc_attachments(user)
	update_appearance()
	if(!silent)
		playsound(src, att.attach_sound, 40, TRUE)
	return TRUE


/obj/item/gun/rimworld/proc/rw_detach(obj/item/rw_attachment/att, mob/living/user, silent = FALSE)
	if(att.master_gun != src)
		return FALSE
	att.on_detach(src, user)
	rw_attachments[att.slot] = null
	UnregisterSignal(att, COMSIG_QDELETING)
	att.master_gun = null
	att.forceMove(drop_location())
	if(user)
		user.put_in_hands(att)
	rw_recalc_attachments(user)
	update_appearance()
	if(!silent)
		playsound(src, att.attach_sound, 40, TRUE)
	return TRUE

/obj/item/gun/rimworld/proc/rw_on_attachment_qdel(obj/item/rw_attachment/source)
	SIGNAL_HANDLER
	if(QDELETED(src))
		return
	rw_attachments[source.slot] = null
	source.master_gun = null
	rw_recalc_attachments()
	update_appearance()


/obj/item/gun/rimworld/proc/rw_activate_attachment(obj/item/rw_attachment/att, mob/living/user)
	if(!(att.attach_flags & RW_ATT_ACTIVATION))
		return FALSE
	if(!user.is_holding(src))
		balloon_alert(user, "hold it first!")
		return FALSE
	return att.activate(user)


/obj/item/gun/rimworld/update_overlays()
	. = ..()
	for(var/slot in GLOB.rw_attachment_slots)
		var/obj/item/rw_attachment/att = rw_attachments?[slot]
		if(!att)
			continue
		var/mutable_appearance/att_overlay = att.build_gun_overlay(src)
		if(att_overlay)
			. += att_overlay


/obj/item/gun/rimworld/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(istype(tool, /obj/item/rw_attachment))
		return rw_try_attach(user, tool) ? ITEM_INTERACT_SUCCESS : ITEM_INTERACT_BLOCKING
	return ..()

/obj/item/gun/rimworld/click_alt(mob/user)
	if(!isliving(user) || !user.can_perform_action(src, NEED_DEXTERITY))
		return ..()
	var/list/choices = list()
	var/list/lookup = list()
	for(var/slot in GLOB.rw_attachment_slots)
		var/obj/item/rw_attachment/att = rw_attachments?[slot]
		if(!att)
			continue
		if(att.attach_flags & RW_ATT_ACTIVATION)
			var/use_key = "Use [att.name]"
			choices[use_key] = image(icon = att.icon, icon_state = att.icon_state)
			lookup[use_key] = list(att, FALSE)
		if(att.attach_flags & RW_ATT_REMOVABLE)
			var/detach_key = "Detach [att.name]"
			choices[detach_key] = image(icon = att.icon, icon_state = att.icon_state)
			lookup[detach_key] = list(att, TRUE)
	if(!length(choices))
		return ..()
	var/choice = show_radial_menu(user, src, choices, require_near = TRUE, tooltips = TRUE)
	if(!choice || QDELETED(src) || !user.can_perform_action(src, NEED_DEXTERITY))
		return CLICK_ACTION_BLOCKING
	var/list/entry = lookup[choice]
	var/obj/item/rw_attachment/picked = entry[1]
	if(QDELETED(picked) || picked.master_gun != src)
		return CLICK_ACTION_BLOCKING
	if(entry[2])
		rw_try_detach(user, picked)
	else
		rw_activate_attachment(picked, user)
	return CLICK_ACTION_SUCCESS


/obj/item/gun/rimworld/proc/rw_attachment_examine_lines(mob/user)
	. = list()
	var/any_interactive = FALSE
	for(var/slot in GLOB.rw_attachment_slots)
		var/obj/item/rw_attachment/att = rw_attachments?[slot]
		if(!att)
			continue
		. += span_notice("[icon2html(att, user)] [att] is fitted to the [slot].")
		if(att.attach_flags & (RW_ATT_REMOVABLE|RW_ATT_ACTIVATION))
			any_interactive = TRUE
	if(any_interactive)
		. += span_notice("<b>Alt-click</b> it to detach or use an attachment.")
	if(length(rw_attachable_allowed))
		. += span_notice("It has mounting points for attachments. Click it with one to fit it.")
