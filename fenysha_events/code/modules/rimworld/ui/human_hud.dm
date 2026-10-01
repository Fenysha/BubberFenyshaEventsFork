/datum/hud/human
	default_inventory_slots = /datum/inventory_slot/human

/datum/hud/human/initialize_screen_objects()
	var/atom/movable/screen/using
	// Static elements
	add_screen_object(/atom/movable/screen/language_menu, HUD_MOB_LANGUAGE_MENU, HUD_GROUP_STATIC, ui_style, ui_human_language)
	add_screen_object(/atom/movable/screen/navigate, HUD_MOB_NAVIGATE_MENU, HUD_GROUP_STATIC, ui_style, ui_human_navigate)
	add_screen_object(/atom/movable/screen/area_creator, HUD_MOB_AREA_CREATOR, HUD_GROUP_STATIC, ui_style, ui_human_area)
	add_screen_object(/atom/movable/screen/combattoggle/flashy, HUD_MOB_INTENTS, HUD_GROUP_INFO, ui_style)
	add_screen_object(/atom/movable/screen/floor_changer/vertical, HUD_MOB_FLOOR_CHANGER, HUD_GROUP_STATIC, ui_style, ui_human_floor_changer)
	add_screen_object(/atom/movable/screen/mov_intent, HUD_MOB_MOVE_INTENT, HUD_GROUP_STATIC, ui_style)
	add_screen_object(/atom/movable/screen/drop, HUD_MOB_DROP, HUD_GROUP_STATIC, ui_style, ui_swaphand_position(mymob, 1))
	add_screen_object(/atom/movable/screen/human/toggle, HUD_HUMAN_TOGGLE_INVENTORY, HUD_GROUP_STATIC, ui_style)
	add_screen_object(/atom/movable/screen/rest, HUD_MOB_REST, HUD_GROUP_HOTKEYS, ui_style)
	add_screen_object(/atom/movable/screen/sleep, HUD_MOB_SLEEP, HUD_GROUP_HOTKEYS, ui_style, ui_above_throw)
	add_screen_object(/atom/movable/screen/pull, HUD_MOB_PULL, HUD_GROUP_STATIC, ui_style, ui_above_movement_top)
	add_screen_object(/atom/movable/screen/zone_sel, HUD_MOB_ZONE_SELECTOR, HUD_GROUP_STATIC, ui_style)
	add_screen_object(/atom/movable/screen/memories, HUD_MOB_MEMORIES, HUD_GROUP_STATIC, ui_style, ui_human_memories_menu)
	build_hand_slots()

	using = add_screen_object(/atom/movable/screen/swap_hand, HUD_MOB_SWAPHAND_2, HUD_GROUP_STATIC, ui_style, ui_swaphand_position(mymob, 2))
	using.icon_state = "act_swap"

	// Hotkey buttons
	add_screen_object(/atom/movable/screen/resist, HUD_MOB_RESIST, HUD_GROUP_HOTKEYS, ui_style)
	add_screen_object(/atom/movable/screen/throw_catch, HUD_MOB_THROW, HUD_GROUP_HOTKEYS, ui_style)

	// Info
	add_screen_object(/atom/movable/screen/spacesuit, HUD_MOB_SPACESUIT, HUD_GROUP_INFO)
	add_screen_object(/atom/movable/screen/healthdoll/human, HUD_MOB_HEALTHDOLL, HUD_GROUP_INFO)
	add_screen_object(/atom/movable/screen/stamina, HUD_MOB_STAMINA, HUD_GROUP_INFO)
	add_screen_object(/atom/movable/screen/healths, HUD_MOB_HEALTH, HUD_GROUP_INFO)
	add_screen_object(/atom/movable/screen/hunger, HUD_MOB_HUNGER, HUD_GROUP_INFO)
	add_screen_object(/atom/movable/screen/ammo_counter, HUD_MOB_AMMO_COUNTER, HUD_GROUP_INFO)

	var/list/architector_buttons = valid_subtypesof(/atom/movable/screen/human/architector_button)
	for(var/i in 1 to length(architector_buttons))
		add_screen_object(architector_buttons[i], HUD_KEY_ARCHITECTOR_BUTTON(i), ui_loc = position_architector_button(i - 1))

/datum/hud/human/proc/position_architector_button(index)
	return "EAST,SOUTH:[index * 16]"

/atom/movable/screen/human/architector_button
	name = "architector"
	icon = 'fenysha_events/icons/ui/hud/screen_midnight_addictions.dmi'
	icon_state = "template"
	mouse_over_pointer = MOUSE_HAND_POINTER
	hud_group_key = HUD_GROUP_TOGGLEABLE_INVENTORY


/atom/movable/screen/human/architector_button/architect
	name = "Open architect window"
	icon_state = "architect"

/atom/movable/screen/human/architector_button/research
	name = "Open reseach window"
	icon_state = "research"

/atom/movable/screen/human/architector_button/faction
	name = "Open faction window"
	icon_state = "faction"

/atom/movable/screen/human/architector_button/roof
	name = "Roof mode"
	desc = "Toggle roof building mode"

/atom/movable/screen/human/architector_button/roof/Click(location, control, params)
	if(isobserver(usr))
		return

	var/mob/living/carbon/human/H = usr
	H.toggle_roof_building_mode()
	if(H.roof_building_mode)
		icon_state = "rood_mode_on"
	else
		icon_state = "rood_mode"
