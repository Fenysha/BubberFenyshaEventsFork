#ifndef OLD_COMBAT_SYSTEM
/datum/keybinding/mob/toggle_parry
	hotkey_keys = list("C")
	name = "toggle_parry"
	full_name = "Toggle Parry / Block"
	description = "Enter a defensive parry stance. You become immobilized, but the next melee attack against you can be parried."
	keybind_signal = COMSIG_KB_MOB_TOGGLE_PARRY_DOWN

/datum/keybinding/mob/toggle_parry/down(client/user)
	. = ..()
	if(.)
		return
	var/mob/living/user_mob = user.mob
	if(!isliving(user_mob))
		return TRUE
	user_mob.try_toggle_parry()
	return TRUE

/datum/keybinding/mob/open_health_panel
	hotkey_keys = list("H")
	name = "open_health_panel"
	full_name = "Open Health Panel"
	description = "Opens the health panel for the living mob under your cursor (if visible and within 3 tiles), or your own panel."
	keybind_signal = COMSIG_KB_MOB_OPENHEALTHPANEL_DOWN

/datum/keybinding/mob/open_health_panel/down(client/user, turf/target, mousepos_x, mousepos_y)
	. = ..()
	if(.)
		return

	var/mob/user_mob = user.mob
	if(!user_mob)
		return TRUE

	var/mob/living/examined = null

	// Prefer a living mob on the turf under the cursor.
	if(isturf(target))
		for(var/mob/living/candidate in target)
			if(candidate == user_mob)
				continue
			if(candidate.invisibility > user_mob.see_invisible)
				continue
			if(!can_see(user_mob, candidate, 3))
				continue
			examined = candidate
			break

	// If nothing useful under the cursor, open self.
	if(!examined)
		if(iscarbon(user_mob))
			var/mob/living/carbon/carbon_self = user_mob
			carbon_self.open_health_ui(user_mob)
		else
			to_chat(user, span_warning("You have no health panel."))
		return TRUE

	// Target is a living mob — open their panel if they support it.
	if(iscarbon(examined))
		var/mob/living/carbon/carbon_target = examined
		carbon_target.open_health_ui(user_mob)
	else
		examined.examine(user_mob)
	return TRUE
#endif

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
