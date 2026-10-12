#ifndef OLD_COMBAT_SYSTEM
#define HEALTH_PANEL_BODY_ICON 'fenysha_events/icons/ui/health_ui.dmi'

/**
 * Health UI datum. Provides the compact physiological and anatomical
 * representation consumed by tgui/interfaces/HealthPanel.
 */
/datum/health_ui
	var/mob/living/carbon/owner
	var/datum/tgui/ui

/datum/health_ui/New(mob/living/carbon/new_owner)
	owner = new_owner

/datum/health_ui/Destroy()
	owner = null
	return ..()

/datum/health_ui/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "HealthPanel")
		ui.open()

/datum/health_ui/ui_state(mob/user)
	return GLOB.conscious_state

/**
 * Viewer access level for medical data.
 * 0 = none / public surface only
 * 1 = self (owner examining themselves)
 * 2 = medical (TRAIT_VIEW_FULL_HEALTH or scanner)
 * 3 = full (ghosts, admin, always_full_health)
 */
/datum/health_ui/proc/get_viewer_access(mob/user)
	/* we finish it later
	if(!user)
		return INJURY_VISIBILITY_NONE
	if(isobserver(user) || isAdminObserver(user))
		return INJURY_VISIBILITY_FULL
	if(HAS_TRAIT(user, TRAIT_VIEW_FULL_HEALTH))
		return INJURY_VISIBILITY_FULL
	if(user == owner)
		return INJURY_VISIBILITY_SELF
	// Adjacent living with medical HUD / skill can be treated as medical later
	*/
	return INJURY_VISIBILITY_FULL

/datum/health_ui/ui_data(mob/user)
	var/list/data = list()
	var/viewer_access = get_viewer_access(user)
	var/can_see_full = viewer_access >= INJURY_VISIBILITY_MEDICAL
	var/can_treat = !isobserver(user) && isliving(user)

	data["viewer_access"] = viewer_access
	data["can_see_full"] = can_see_full
	data["can_treat"] = can_treat
	data["is_self"] = (user == owner)
	data["is_dead"] = owner?.stat == DEAD
	data["subject_name"] = owner?.name

	data["temperature"] = get_temperature_data()
	data["parameters"] = list(
		"consciousness" = clamp(owner.consciousness, 0, CONSCIOUSNESS_MAX),
		"pain" = clamp(owner.pain, 0, PAIN_MAX),
		"shock" = clamp(owner.shock, 0, SHOCK_MAX),
		"heartbeat" = get_heartbeat_data(),
		"breathing" = get_breathing_data(),
		"circulation" = get_circulation_data(),
		"movement" = get_movement_data(),
		"bleed_rate" = owner.total_bleed_rate,
	)

	data["cardiogram"] = get_cardiogram_data()
	data["lungs"] = get_lungs_data()
	data["bodyparts"] = get_bodyparts_data(user, viewer_access)
	data["organs"] = get_special_organs_data(user, viewer_access)

	return data

/datum/health_ui/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	var/mob/user = ui.user
	if(!user || isobserver(user))
		return FALSE

	switch(action)
		if("select_limb")
			return TRUE

		if("treat_injury")
			return try_treat_injury(user, params["injury_id"], params["item_type"])

	return FALSE

/**
 * Attempt to treat a specific injury with an item in the user's carried inventory.
 * item_type is the typepath string sent by a treatment button.
 */
/datum/health_ui/proc/try_treat_injury(mob/living/user, injury_id, item_type_text)
	if(!user || !owner || !injury_id || !item_type_text || isobserver(user))
		return FALSE

	var/item_type = text2path(item_type_text)
	if(!ispath(item_type, /obj/item))
		return FALSE

	var/datum/injury/target
	for(var/datum/injury/injury as anything in owner.all_injuries)
		if(injury.unique_id == injury_id)
			target = injury
			break

	if(!target || !target.limb || target.owner != owner)
		return FALSE

	// Prefer hands for predictable behaviour; otherwise use a matching carried item.
	var/obj/item/tool
	var/obj/item/active = user.get_active_held_item()
	var/obj/item/inactive = user.get_inactive_held_item()

	if(istype(active, item_type) && target.item_can_treat(active, user))
		tool = active
	else if(istype(inactive, item_type) && target.item_can_treat(inactive, user))
		tool = inactive
	else
		tool = find_inventory_treatment_item(user, item_type, target, user)

	if(!tool)
		to_chat(user, span_warning("You need the right treatment item in your inventory."))
		return FALSE

	if(!target.item_can_treat(tool, user))
		to_chat(user, span_warning("That will not help this injury."))
		return FALSE

	return target.try_treat(tool, user)

/**
 * Search all items carried by the user, including items inside bags and storage.
 * The visited list prevents loops in malformed containment trees.
 */
/datum/health_ui/proc/find_inventory_treatment_item(atom/container, item_type, datum/injury/target, mob/living/user, list/visited)
	if(!container || !ispath(item_type, /obj/item) || !target)
		return null

	if(!visited)
		visited = list()
	if(container in visited)
		return null
	visited += container

	for(var/obj/item/item in container.contents)
		if(istype(item, item_type) && target.item_can_treat(item, user))
			return item

		var/obj/item/nested_item = find_inventory_treatment_item(item, item_type, target, user, visited)
		if(nested_item)
			return nested_item

	return null

#endif
