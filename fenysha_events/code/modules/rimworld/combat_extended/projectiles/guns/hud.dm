/datum/component/rw_gun_hud
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/obj/item/gun/rimworld/gun
	/// Current gun holder.
	var/mob/living/owner
	var/atom/movable/screen/rw_ammo/ammo
	var/atom/movable/screen/rw_cooldown/cooldown
	var/atom/movable/screen/rw_mode_button/aim/aim_button
	var/atom/movable/screen/rw_mode_button/fire/fire_button
	/// Temporary body-doll highlight overlays.
	var/list/hover_objs
	/// Currently hovered body zone.
	var/hover_choice
	var/atom/movable/screen/zone_sel/hover_source

/datum/component/rw_gun_hud/Initialize()
	. = ..()
	if(!istype(parent, /obj/item/gun/rimworld))
		return COMPONENT_INCOMPATIBLE
	gun = parent
	ammo = new(null, null)
	cooldown = new(null, null)
	aim_button = new(null, null)
	fire_button = new(null, null)
	ammo.rw_hud = src
	cooldown.rw_hud = src
	aim_button.rw_hud = src
	fire_button.rw_hud = src

/datum/component/rw_gun_hud/RegisterWithParent()
	RegisterSignal(parent, COMSIG_ITEM_EQUIPPED, PROC_REF(on_equipped))
	RegisterSignal(parent, COMSIG_ITEM_DROPPED, PROC_REF(on_dropped))

/datum/component/rw_gun_hud/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_ITEM_EQUIPPED, COMSIG_ITEM_DROPPED))

/datum/component/rw_gun_hud/Destroy()
	detach()
	QDEL_NULL(ammo)
	QDEL_NULL(cooldown)
	QDEL_NULL(aim_button)
	QDEL_NULL(fire_button)
	gun = null
	return ..()


/datum/component/rw_gun_hud/proc/on_equipped(datum/source, mob/equipper, slot)
	SIGNAL_HANDLER
	detach()
	if(!(slot & ITEM_SLOT_HANDS) || !isliving(equipper))
		return
	attach(equipper)

/datum/component/rw_gun_hud/proc/on_dropped(datum/source, mob/user)
	SIGNAL_HANDLER
	detach()

/datum/component/rw_gun_hud/proc/on_owner_deleted(datum/source)
	SIGNAL_HANDLER
	detach()

/datum/component/rw_gun_hud/proc/attach(mob/living/new_owner)
	owner = new_owner
	owner.rw_gun_hud = src
	RegisterSignal(owner, COMSIG_QDELETING, PROC_REF(on_owner_deleted))
	if(owner.client)
		owner.client.screen += list(ammo, cooldown, aim_button, fire_button)
	update_all()

/datum/component/rw_gun_hud/proc/detach()
	if(!owner)
		return
	var/mob/living/old_owner = owner
	var/atom/movable/screen/zone_sel/doll = get_zone_select()
	clear_zone_hover(doll)
	if(old_owner.client)
		old_owner.client.screen -= list(ammo, cooldown, aim_button, fire_button)
	if(old_owner.rw_gun_hud == src)
		old_owner.rw_gun_hud = null
	UnregisterSignal(old_owner, COMSIG_QDELETING)
	owner = null
	// Restore the standard body-doll appearance.
	doll?.update_appearance()

/datum/component/rw_gun_hud/proc/update_all()
	if(QDELETED(gun) || !owner)
		return
	ammo.update_count(gun)
	aim_button.update_state(gun)
	fire_button.update_state(gun)
	cooldown.update_state(gun)
	get_zone_select()?.update_appearance()

/datum/component/rw_gun_hud/proc/get_zone_select()
	RETURN_TYPE(/atom/movable/screen/zone_sel)
	var/datum/hud/owner_hud = owner?.hud_used
	if(!owner_hud)
		return null
	return locate(/atom/movable/screen/zone_sel) in owner_hud.screen_objects

/// Zones permanently highlighted on the body doll.
/datum/component/rw_gun_hud/proc/get_highlighted_zones()
	if(!owner || QDELETED(gun))
		return null
	if(gun.rw_aim_mode == RW_AIM_SUPPRESS)
		return GLOB.rw_area_zones[RW_AREA_HEAD] + GLOB.rw_area_zones[RW_AREA_TORSO] + GLOB.rw_area_zones[RW_AREA_LEGS]
	if(owner.rw_aim_area)
		return GLOB.rw_area_zones[owner.rw_aim_area]
	return list(owner.zone_selected)

/// Zones represented by a hover choice.
/datum/component/rw_gun_hud/proc/get_hover_zones(choice)
	if(!owner || QDELETED(gun) || !choice)
		return null
	if(gun.rw_aim_mode == RW_AIM_SUPPRESS)
		return GLOB.rw_area_zones[RW_AREA_HEAD] + GLOB.rw_area_zones[RW_AREA_TORSO] + GLOB.rw_area_zones[RW_AREA_LEGS]
	if(gun.rw_ranged_skill(owner) >= RW_REQ_SKILL_LIMB)
		return list(choice)
	return GLOB.rw_area_zones[rw_area_of_zone(choice)]


/// Handle a body-doll click. Return TRUE when consumed.
/datum/component/rw_gun_hud/proc/on_zone_click(choice, atom/movable/screen/zone_sel/source)
	if(usr != owner || QDELETED(gun))
		return FALSE
	if(gun.rw_aim_mode == RW_AIM_SUPPRESS)
		owner.balloon_alert(owner, "suppressive fire - no target zone")
		return TRUE
	if(gun.rw_ranged_skill(owner) >= RW_REQ_SKILL_LIMB)
		owner.rw_aim_area = null
		owner.zone_selected = choice
	else
		owner.rw_aim_area = rw_area_of_zone(choice)
	source.update_appearance()
	return TRUE


/// Handle body-doll hover.
/datum/component/rw_gun_hud/proc/on_zone_hover(atom/movable/screen/zone_sel/source, choice)
	if(usr != owner)
		return FALSE
	var/list/zones = get_hover_zones(choice)
	if(isnull(zones))
		clear_zone_hover(source)
		return FALSE
	// Remove the standard single-zone hover overlay.
	if(source.hovering)
		source.vis_contents -= source.hover_overlays_cache[source.hovering]
		source.hovering = null
	if(hover_choice == choice)
		return TRUE
	clear_zone_hover(source)
	hover_choice = choice
	hover_source = source
	for(var/zone in zones)
		var/obj/effect/overlay/zone_sel/highlight = new
		highlight.icon_state = "[zone]"
		source.vis_contents += highlight
		LAZYADD(hover_objs, highlight)
	return TRUE

/// Clear temporary body-doll hover overlays.
/datum/component/rw_gun_hud/proc/clear_zone_hover(atom/movable/screen/zone_sel/source = hover_source)
	if(source)
		for(var/obj/effect/overlay/zone_sel/highlight as anything in hover_objs)
			source.vis_contents -= highlight
	QDEL_LIST(hover_objs)
	hover_choice = null
	hover_source = null


/atom/movable/screen/rw_hud_element
	icon = 'fenysha_events/icons/ui/hud/gun_gui.dmi'
	plane = HUD_PLANE
	mouse_over_pointer = MOUSE_HAND_POINTER
	var/datum/component/rw_gun_hud/rw_hud

/atom/movable/screen/rw_hud_element/Destroy()
	rw_hud = null
	return ..()

/// Magazine ammo counter.
/atom/movable/screen/rw_ammo
	parent_type = /atom/movable/screen/rw_hud_element
	name = "ammo"
	icon = null // maptext only
	screen_loc = ui_rw_ammo
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	maptext_width = 192
	maptext_height = 192
	maptext_x = 0
	maptext_y = 0

/atom/movable/screen/rw_ammo/proc/update_count(obj/item/gun/rimworld/gun)
	var/count = gun.rw_get_ammo_count()
	var/max_count = gun.rw_get_ammo_max()
	var/color = "#ffd37a"
	if(count <= 0)
		color = "#ff5555"
	else if(max_count && count <= max(1, round(max_count * 0.25)))
		color = "#ffaa44"
	maptext = MAPTEXT_TINY_UNICODE("<span style='font-size: 84px; color: [color]; -dm-text-outline: 2px black'>[count]</span>")

/// Not-ready overlay.
/atom/movable/screen/rw_cooldown
	parent_type = /atom/movable/screen/rw_hud_element
	name = "not ready"
	icon_state = "not_ready"
	screen_loc = ui_rw_ammo
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	invisibility = INVISIBILITY_ABSTRACT
	alpha = 160

/atom/movable/screen/rw_cooldown/proc/update_state(obj/item/gun/rimworld/gun)
	invisibility = gun.rw_can_fire_now() ? INVISIBILITY_ABSTRACT : 0

/atom/movable/screen/rw_mode_button
	parent_type = /atom/movable/screen/rw_hud_element

/atom/movable/screen/rw_mode_button/Click(location, control, params)
	if(!rw_hud || usr != rw_hud.owner || QDELETED(rw_hud.gun))
		return
	cycle(rw_hud.gun, usr)

/atom/movable/screen/rw_mode_button/proc/cycle(obj/item/gun/rimworld/gun, mob/living/user)
	return

/atom/movable/screen/rw_mode_button/proc/update_state(obj/item/gun/rimworld/gun)
	return

/atom/movable/screen/rw_mode_button/aim
	name = "aim mode"
	icon_state = "fire_mode_snap"
	screen_loc = ui_rw_aim_button

/atom/movable/screen/rw_mode_button/aim/cycle(obj/item/gun/rimworld/gun, mob/living/user)
	gun.rw_cycle_aim_mode(user)
	to_chat(user, span_notice("Aim mode: [gun.rw_aim_mode_name()]."))

/atom/movable/screen/rw_mode_button/aim/update_state(obj/item/gun/rimworld/gun)
	if(gun.rw_aim_mode == RW_AIM_AIMED)
		icon_state = "fire_mode_aimed"
	else if(gun.rw_aim_mode == RW_AIM_SUPPRESS)
		icon_state = "fire_mode_supress"
	else
		icon_state = "fire_mode_snap"
	name = "aim mode: [gun.rw_aim_mode_name()]"

/atom/movable/screen/rw_mode_button/fire
	name = "fire mode"
	icon_state = "fire_rate_single"
	screen_loc = ui_rw_fire_button

/atom/movable/screen/rw_mode_button/fire/cycle(obj/item/gun/rimworld/gun, mob/living/user)
	gun.rw_cycle_fire_mode(user)
	to_chat(user, span_notice("Fire mode: [gun.rw_fire_mode_name()]."))

/atom/movable/screen/rw_mode_button/fire/update_state(obj/item/gun/rimworld/gun)
	if(gun.rw_fire_mode == RW_FIRE_BURST)
		icon_state = "fire_rate_burst"
	else if(gun.rw_fire_mode == RW_FIRE_AUTO)
		icon_state = "fire_rate_auto"
	else
		icon_state = "fire_rate_single"
	name = "fire mode: [gun.rw_fire_mode_name()]"

/// Human-readable mode names.
/obj/item/gun/rimworld/proc/rw_aim_mode_name()
	switch(rw_aim_mode)
		if(RW_AIM_AIMED)
			return "aimed"
		if(RW_AIM_SUPPRESS)
			return "suppressive"
	return "snap shot"

/obj/item/gun/rimworld/proc/rw_fire_mode_name()
	switch(rw_fire_mode)
		if(RW_FIRE_BURST)
			return "burst"
		if(RW_FIRE_AUTO)
			return "full auto"
	return "single"
