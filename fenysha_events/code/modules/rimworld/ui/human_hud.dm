/datum/hud/human
	default_inventory_slots = /datum/inventory_slot/human

/datum/hud/human/initialize_screen_objects()
	var/atom/movable/screen/using

	// Static elements
	add_screen_object(/atom/movable/screen/language_menu, HUD_MOB_LANGUAGE_MENU, HUD_GROUP_STATIC, ui_style, ui_human_language)
	add_screen_object(/atom/movable/screen/navigate, HUD_MOB_NAVIGATE_MENU, HUD_GROUP_STATIC, ui_style, ui_human_navigate)
	//add_screen_object(/atom/movable/screen/area_creator, HUD_MOB_AREA_CREATOR, HUD_GROUP_STATIC, ui_style, ui_human_area)
	add_screen_object(/atom/movable/screen/combattoggle/flashy, HUD_MOB_INTENTS, HUD_GROUP_INFO, ui_style)
	add_screen_object(/atom/movable/screen/floor_changer/vertical, HUD_MOB_FLOOR_CHANGER, HUD_GROUP_STATIC, ui_style, ui_human_floor_changer)
	add_screen_object(/atom/movable/screen/mov_intent, HUD_MOB_MOVE_INTENT, HUD_GROUP_STATIC, ui_style)
	add_screen_object(/atom/movable/screen/drop, HUD_MOB_DROP, HUD_GROUP_STATIC, ui_style, ui_swaphand_position(mymob, 1))
	add_screen_object(/atom/movable/screen/human/toggle, HUD_HUMAN_TOGGLE_INVENTORY, HUD_GROUP_STATIC, ui_style)
	add_screen_object(/atom/movable/screen/rest, HUD_MOB_REST, HUD_GROUP_HOTKEYS, ui_style)
	add_screen_object(/atom/movable/screen/sleep, HUD_MOB_SLEEP, HUD_GROUP_HOTKEYS, ui_style, ui_above_throw)
	add_screen_object(/atom/movable/screen/pull, HUD_MOB_PULL, HUD_GROUP_STATIC, ui_style, ui_above_movement_top)
	add_screen_object(/atom/movable/screen/zone_sel, HUD_MOB_ZONE_SELECTOR, HUD_GROUP_STATIC, ui_style)
	//add_screen_object(/atom/movable/screen/memories, HUD_MOB_MEMORIES, HUD_GROUP_STATIC, ui_style, ui_human_memories_menu)
	build_hand_slots()

	using = add_screen_object(
		/atom/movable/screen/swap_hand,
		HUD_MOB_SWAPHAND_2,
		HUD_GROUP_STATIC,
		ui_style,
		ui_swaphand_position(mymob, 2)
	)
	using.icon_state = "act_swap"

	// Hotkey buttons
	add_screen_object(/atom/movable/screen/resist, HUD_MOB_RESIST, HUD_GROUP_HOTKEYS, ui_style)
	add_screen_object(/atom/movable/screen/throw_catch, HUD_MOB_THROW, HUD_GROUP_HOTKEYS, ui_style)

	// Info
	add_screen_object(/atom/movable/screen/spacesuit, HUD_MOB_SPACESUIT, HUD_GROUP_INFO)
	add_screen_object(/atom/movable/screen/healthdoll/human, HUD_MOB_HEALTHDOLL, HUD_GROUP_INFO)
	//add_screen_object(/atom/movable/screen/stamina, HUD_MOB_STAMINA, HUD_GROUP_INFO)
	add_screen_object(/atom/movable/screen/healths, HUD_MOB_HEALTH, HUD_GROUP_INFO)
	add_screen_object(/atom/movable/screen/hunger, HUD_MOB_HUNGER, HUD_GROUP_INFO)
	add_screen_object(/atom/movable/screen/ammo_counter, HUD_MOB_AMMO_COUNTER, HUD_GROUP_INFO)

	// Architect buttons.
	var/list/architector_buttons = subtypesof(/atom/movable/screen/human/architector_button)

	// Explicitly sort buttons by their configured sort order.
	sortTim(architector_buttons, /proc/cmp_architector_button)

	for(var/i in 1 to length(architector_buttons))
		add_screen_object(
			architector_buttons[i],
			HUD_KEY_ARCHITECTOR_BUTTON(i),
			ui_loc = position_architector_button(i - 1)
		)

/datum/hud/human/proc/position_architector_button(index)
	return "EAST,SOUTH:[6 + (index * 16)]"


/proc/cmp_architector_button(
	atom/movable/screen/human/architector_button/a,
	atom/movable/screen/human/architector_button/b)
	return initial(b.sort_order) - initial(a.sort_order)


/atom/movable/screen/human/architector_button
	name = "architect"
	icon = 'fenysha_events/icons/ui/hud/screen_midnight_addictions.dmi'
	icon_state = "template"
	mouse_over_pointer = MOUSE_HAND_POINTER
	hud_group_key = HUD_GROUP_TOGGLEABLE_INVENTORY

	/// Determines the display order of architect HUD buttons.
	var/sort_order = 100


/atom/movable/screen/human/architector_button/architect
	name = "Open architect window"
	icon_state = "architect"
	sort_order = 10

/atom/movable/screen/human/architector_button/architect/Click(location, control, params)
	. = ..()
	if(.)
		return
	var/mob/living/user = hud?.mymob
	if(!isliving(user))
		return
	if(user.stat || user.incapacitated)
		return
	user.open_architect_menu()


/atom/movable/screen/human/architector_button/research
	name = "Open research window"
	icon_state = "research"
	sort_order = 20

/atom/movable/screen/human/architector_button/research/Click(location, control, params)
	if(isobserver(usr))
		return

	var/mob/living/carbon/human/H = usr
	var/datum/rw_faction/player/faction = H.rw_faction
	if(istype(faction))
		faction.techweb.ui_interact(H, null)

/atom/movable/screen/human/architector_button/faction
	name = "Open faction window"
	icon_state = "faction"
	sort_order = 30

/atom/movable/screen/human/architector_button/faction/Click(location, control, params)
	if(isobserver(usr))
		return

	var/mob/living/carbon/human/H = usr
	var/datum/rw_faction/player/faction = H.rw_faction
	if(istype(faction))
		faction.ui_interact(H, null)



/atom/movable/screen/human/architector_button/roof
	name = "Roof mode"
	desc = "Toggle roof building mode"
	icon_state = "roof_mode"
	sort_order = 40

/atom/movable/screen/human/architector_button/roof/Click(location, control, params)
	if(isobserver(usr))
		return

	var/mob/living/carbon/human/H = usr
	H.toggle_roof_building_mode()

	if(H.roof_building_mode)
		icon_state = "roof_mode_on"
	else
		icon_state = "roof_mode"

/atom/movable/screen/human/architector_button/map
	name = "Map"
	icon_state = "map"
	sort_order = 50

/atom/movable/screen/human/architector_button/map/Click(location, control, params)
	if(isobserver(usr))
		return

	var/mob/living/carbon/human/H = usr
	SSrimworld_planetmap.open_overview(H)


/atom/movable/screen/human/architector_button/personal
	name = "Skills"
	icon_state = "persona"
	sort_order = 60

/atom/movable/screen/human/architector_button/personal/Click(location, control, params)
	if(isobserver(usr))
		return

	var/mob/living/carbon/human/H = usr
	H.view_psychology()


/atom/movable/screen/human/architector_button/mission
	name = "Missions"
	icon_state = "mission"
	sort_order = 70



/atom/movable/screen/zone_sel
	name = "damage zone"
	icon_state = "zone_sel"
	screen_loc = ui_zonesel
	mouse_over_pointer = MOUSE_HAND_POINTER
	var/overlay_icon = 'icons/hud/screen_gen.dmi'
	/// Standard hover overlays, shared by all dolls: body zone -> overlay object
	var/static/list/hover_overlays_cache = list()
	/// Body zone currently hovered with the standard (single-zone) highlight
	var/hovering

/atom/movable/screen/zone_sel/Initialize(mapload, datum/hud/hud_owner)
	. = ..()
	update_appearance()


/atom/movable/screen/zone_sel/proc/get_rw_hud()
	RETURN_TYPE(/datum/component/rw_gun_hud)
	if(isliving(hud.mymob))
		var/mob/living/L = hud.mymob
		return L.rw_gun_hud
	return null

/atom/movable/screen/zone_sel/proc/get_zone_from_params(params)
	var/list/modifiers = params2list(params)
	var/icon_x = text2num(LAZYACCESS(modifiers, ICON_X)) // px
	var/icon_y = text2num(LAZYACCESS(modifiers, ICON_Y)) // px
	return get_zone_at(icon_x, icon_y)

/atom/movable/screen/zone_sel/Click(location, control, params)
	if(isobserver(usr))
		return

	var/choice = get_zone_from_params(params)
	if(!choice)
		return TRUE

	if(get_rw_hud()?.on_zone_click(choice, src))
		return TRUE

	return set_selected_zone(choice, usr)

/atom/movable/screen/zone_sel/MouseEntered(location, control, params)
	. = ..()
	MouseMove(location, control, params)

/atom/movable/screen/zone_sel/MouseMove(location, control, params)
	if(isobserver(usr))
		return

	var/choice = get_zone_from_params(params)

	if(get_rw_hud()?.on_zone_hover(src, choice))
		return

	if(hovering == choice)
		return
	clear_standard_hover()
	hovering = choice
	if(!choice)
		return

	var/obj/effect/overlay/zone_sel/overlay_object = hover_overlays_cache[choice]
	if(!overlay_object)
		overlay_object = new
		overlay_object.icon_state = "[choice]"
		hover_overlays_cache[choice] = overlay_object
	vis_contents += overlay_object

/atom/movable/screen/zone_sel/MouseExited(location, control, params)
	if(isobserver(usr))
		return
	get_rw_hud()?.clear_zone_hover(src)
	clear_standard_hover()

/atom/movable/screen/zone_sel/proc/clear_standard_hover()
	if(!hovering)
		return
	vis_contents -= hover_overlays_cache[hovering]
	hovering = null

/obj/effect/overlay/zone_sel
	icon = 'icons/hud/screen_gen.dmi'
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	alpha = 128
	anchored = TRUE
	plane = ABOVE_HUD_PLANE

/atom/movable/screen/zone_sel/proc/get_zone_at(icon_x, icon_y)
	switch(icon_y)
		if(1 to 9) // Legs
			switch(icon_x)
				if(10 to 15)
					return BODY_ZONE_R_LEG
				if(17 to 22)
					return BODY_ZONE_L_LEG
		if(10 to 13) // Hands and groin
			switch(icon_x)
				if(8 to 11)
					return BODY_ZONE_R_ARM
				if(12 to 20)
					return BODY_ZONE_PRECISE_GROIN
				if(21 to 24)
					return BODY_ZONE_L_ARM
		if(14 to 22) // Chest and arms to shoulders
			switch(icon_x)
				if(8 to 11)
					return BODY_ZONE_R_ARM
				if(12 to 20)
					return BODY_ZONE_CHEST
				if(21 to 24)
					return BODY_ZONE_L_ARM
		if(23 to 30) // Head, but we need to check for eye or mouth
			if(icon_x in 12 to 20)
				switch(icon_y)
					if(23 to 24)
						if(icon_x in 15 to 17)
							return BODY_ZONE_PRECISE_MOUTH
					if(26) // Eyeline, eyes are on 15 and 17
						if(icon_x in 14 to 18)
							return BODY_ZONE_PRECISE_EYES
					if(25 to 27)
						if(icon_x in 15 to 17)
							return BODY_ZONE_PRECISE_EYES
				return BODY_ZONE_HEAD

/atom/movable/screen/zone_sel/proc/set_selected_zone(choice, mob/user, should_log = TRUE)
	if(user != hud?.mymob)
		return

	if(choice != hud.mymob.zone_selected)
		if(should_log)
			hud.mymob.log_manual_zone_selected_update("screen_hud", new_target = choice)
		hud.mymob.zone_selected = choice
		update_appearance()
		SEND_SIGNAL(user, COMSIG_MOB_SELECTED_ZONE_SET, choice)

	return TRUE

/atom/movable/screen/zone_sel/update_overlays()
	. = ..()
	if(!hud?.mymob)
		return

	var/list/rw_zones = get_rw_hud()?.get_highlighted_zones()
	if(rw_zones)
		for(var/zone in rw_zones)
			. += mutable_appearance(overlay_icon, "[zone]")
		return

	. += mutable_appearance(overlay_icon, "[hud.mymob.zone_selected]")
