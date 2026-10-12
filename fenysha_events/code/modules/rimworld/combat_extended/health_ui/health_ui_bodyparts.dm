#ifndef OLD_COMBAT_SYSTEM

// Replace this with the DMI that contains your 48x48 injury icon states.
#define HEALTH_PANEL_INJURY_ICON 'fenysha_events/icons/ui/injuries.dmi'
/datum/health_ui/proc/get_bodypart_icon_suffix(body_zone)
	switch(body_zone)
		if(BODY_ZONE_HEAD)
			return "head"
		if(BODY_ZONE_CHEST)
			return "chest"
		if(BODY_ZONE_L_ARM)
			return "arm_l"
		if(BODY_ZONE_R_ARM)
			return "arm_r"
		if(BODY_ZONE_L_LEG)
			return "leg_l"
		if(BODY_ZONE_R_LEG)
			return "leg_r"
	return body_zone

/datum/health_ui/proc/get_bodypart_icon_state(obj/item/bodypart/BP)
	if(!BP)
		return null

	var/limb_id = BP.limb_id || SPECIES_HUMAN
	var/limb_gender = BP.limb_gender || "m"
	var/suffix = get_bodypart_icon_suffix(BP.body_zone)

	return "[limb_id]_[limb_gender]_[suffix]"

/datum/health_ui/proc/get_bodypart_icon_src(obj/item/bodypart/BP)
	if(!BP)
		return null

	var/icon_state = get_bodypart_icon_state(BP)
	if(!icon_state)
		return null

	var/static/list/icon_cache = list()
	if(icon_cache[icon_state])
		return icon_cache[icon_state]

	var/icon/body_icon = icon(HEALTH_PANEL_BODY_ICON, icon_state, SOUTH, 1)
	if(!body_icon)
		return null

	var/icon_src = icon2base64(body_icon)
	icon_cache[icon_state] = icon_src

	return icon_src

/**
 * Returns a cached PNG for an injury's 48x48 UI icon.
 * Missing states return null so the UI shows its compact fallback instead of "0".
 */
/datum/health_ui/proc/get_injury_icon_src(datum/injury/injury)
	if(!injury)
		return null

	var/icon_state = injury.get_ui_icon_state()
	if(!icon_state)
		return null

	var/static/list/icon_cache = list()
	if(icon_cache[icon_state])
		return icon_cache[icon_state]

	var/static/list/known_states
	if(!islist(known_states))
		known_states = icon_states(HEALTH_PANEL_INJURY_ICON)
	if(!(icon_state in known_states))
		return null

	var/icon/injury_icon = icon(HEALTH_PANEL_INJURY_ICON, icon_state, SOUTH, 1)
	if(!injury_icon)
		return null

	var/icon_src = icon2base64(injury_icon)
	if(!istext(icon_src))
		return null

	icon_cache[icon_state] = icon_src
	return icon_src

/**
 * Cached base64 icons for treatment item typepaths.
 * Key = typepath string, value = list(iconSrc, name)
 */
/datum/health_ui/proc/get_treatment_item_ui(typepath)
	if(!ispath(typepath, /obj/item))
		return null

	var/static/list/treat_icon_cache = list()
	var/key = "[typepath]"

	if(treat_icon_cache[key])
		return treat_icon_cache[key]

	var/obj/item/sample = new typepath(null)
	if(!sample)
		return null

	var/icon/I
	if(sample.icon && sample.icon_state)
		I = icon(sample.icon, sample.icon_state, SOUTH, 1)

	var/list/entry = list(
		"type" = key,
		"name" = sample.name || key,
		"iconSrc" = I ? icon2base64(I) : null,
	)
	qdel(sample)

	treat_icon_cache[key] = entry
	return entry

/**
 * Builds the list of treatment option buttons for an injury.
 */
/datum/health_ui/proc/get_injury_treat_options(datum/injury/injury, mob/user, list/inventory_items)
	var/list/options = list()
	if(!injury || injury.treatment_quality >= INJURY_TREATMENT_EXCELLENT)
		return options

	// Medical supplies declared by typepath remain available as potential options.
	var/list/seen_types = list()
	if(length(injury.treatable_by))
		for(var/typepath in injury.treatable_by)
			if(!ispath(typepath, /obj/item) || seen_types[typepath])
				continue
			var/list/entry = get_treatment_item_ui(typepath)
			if(entry)
				options += list(entry)
				seen_types[typepath] = TRUE

	// Tool behaviours such as cautery/scalpel/boneset do not identify a single item type.
	// Add matching concrete items from the user's carried inventory so they have an icon button.
	if(user && length(injury.treatable_tools))
		if(!islist(inventory_items))
			inventory_items = list()
			collect_health_ui_inventory_items(user, inventory_items)
		for(var/obj/item/item as anything in inventory_items)
			if(!item || seen_types[item.type] || !injury.item_can_treat(item, user))
				continue
			var/list/entry = get_treatment_item_ui(item.type)
			if(entry)
				options += list(entry)
				seen_types[item.type] = TRUE

	return options

/** Collect all carried items, including nested storage, once per datum. */
/datum/health_ui/proc/collect_health_ui_inventory_items(atom/container, list/items, list/visited)
	if(!container || !items)
		return
	if(!visited)
		visited = list()
	if(container in visited)
		return
	visited += container

	for(var/obj/item/item in container.contents)
		items += item
		collect_health_ui_inventory_items(item, items, visited)

/datum/health_ui/proc/get_limb_injury_bleed_rate(obj/item/bodypart/BP)
	if(!BP)
		return 0
	var/total = 0
	for(var/datum/injury/injury as anything in BP.injuries)
		total += injury.get_bleed_rate()
	return total

/datum/health_ui/proc/get_bodyparts_data(mob/user, viewer_access)
	var/list/parts = list()
	var/list/whole_body_injury_data = list()
	var/list/user_inventory_items = list()
	var/can_treat = user && isliving(user) && !isobserver(user)
	if(can_treat)
		collect_health_ui_inventory_items(user, user_inventory_items)

	var/list/zones = list(
		BODY_ZONE_HEAD,
		BODY_ZONE_CHEST,
		BODY_ZONE_L_ARM,
		BODY_ZONE_R_ARM,
		BODY_ZONE_L_LEG,
		BODY_ZONE_R_LEG,
	)

	// Systemic injuries are stored once on the owner but rendered on every limb.
	for(var/datum/injury/systemic_injury as anything in owner.all_injuries)
		if(systemic_injury.get_ui_body_zone() != "all" || !systemic_injury.can_be_seen_by(user))
			continue
		var/list/injury_data = systemic_injury.get_ui_data()
		injury_data["iconSrc"] = get_injury_icon_src(systemic_injury)
		injury_data["treat_options"] = can_treat ? get_injury_treat_options(systemic_injury, user, user_inventory_items) : list()
		whole_body_injury_data += list(injury_data)

	for(var/zone in zones)
		var/obj/item/bodypart/BP = owner.get_bodypart(zone)
		var/icon_state = get_bodypart_icon_state(BP)

		var/list/part_data = list(
			"zone" = zone,
			"name" = BP ? BP.plaintext_zone : zone,
			"present" = !isnull(BP),
			"structural_damage" = BP ? BP.brute_dam : 0,
			"skin_damage" = BP ? BP.burn_dam : 0,
			"structural_integrity" = BP ? BP.get_physical_integrity() * 100 : 0,
			"skin_integrity" = BP ? BP.get_skin_integrity() * 100 : 0,
			"max_damage" = BP ? BP.max_damage : 0,
			"disabled" = BP ? BP.bodypart_disabled : TRUE,
			"bleed_rate" = BP ? get_limb_injury_bleed_rate(BP) : 0,

			"icon" = HEALTH_PANEL_BODY_ICON,
			"iconState" = icon_state,
			"iconSrc" = get_bodypart_icon_src(BP),

			"sprite_id" = BP ? BP.limb_id : SPECIES_HUMAN,
			"limb_gender" = BP ? BP.limb_gender : "m",
			"injuries" = list(),
		)

		if(BP)
			for(var/datum/injury/injury as anything in BP.injuries)
				if(!injury.can_be_seen_by(user) || injury.get_ui_body_zone() == "all")
					continue
				if(injury.get_ui_body_zone() != zone)
					continue
				var/list/injury_data = injury.get_ui_data()
				injury_data["iconSrc"] = get_injury_icon_src(injury)
				injury_data["treat_options"] = can_treat ? get_injury_treat_options(injury, user, user_inventory_items) : list()
				part_data["injuries"] += list(injury_data)

		// A whole-body injury is intentionally repeated in each limb's readout.
		for(var/list/injury_data as anything in whole_body_injury_data)
			part_data["injuries"] += list(injury_data)

		parts[zone] = part_data

	return parts

/datum/health_ui/proc/get_special_organs_data(mob/user, viewer_access)
	var/list/organs_data = list()

	var/obj/item/organ/brain/brain = owner.get_organ_slot(ORGAN_SLOT_BRAIN)
	var/brain_health = brain && brain.maxHealth > 0 ? clamp((brain.maxHealth - brain.damage) / brain.maxHealth * 100, 0, 100) : 0

	organs_data["brain"] = list(
		"present" = !isnull(brain),
		"health" = brain_health,
		"failing" = brain ? !!(brain.organ_flags & ORGAN_FAILING) : TRUE,
		"status" = brain ? brain.get_status_text() : "Missing",
		"oxygen" = brain ? clamp(brain.oxygen, 0, BRAIN_O2_MAX) : 0,
		"perfusion" = clamp(owner.get_brain_perfusion(), 0, 1.2),
	)

	var/obj/item/organ/heart/heart = owner.get_organ_slot(ORGAN_SLOT_HEART)
	var/heart_health = heart && heart.maxHealth > 0 ? clamp((heart.maxHealth - heart.damage) / heart.maxHealth * 100, 0, 100) : 0
	var/heartbeat = get_heartbeat_data()

	organs_data["heart"] = list(
		"present" = !isnull(heart),
		"health" = heart_health,
		"failing" = heart ? !!(heart.organ_flags & ORGAN_FAILING) : TRUE,
		"beating" = heart ? heart.is_beating() : FALSE,
		"fibrillating" = heartbeat["fibrillating"],
		"status" = heart ? heart.get_status_text() : "Missing",
		"state" = heartbeat["state"],
		"rhythm" = heartbeat["rhythm"],
		"rate" = heartbeat["rate"],
		"contractility" = heartbeat["contractility"],
		"stroke_efficiency" = heartbeat["stroke_efficiency"],
		"cardiac_output" = heartbeat["cardiac_output"],
		"preload" = heartbeat["preload"],
		"cpr" = heartbeat["cpr"],
	)

	var/obj/item/organ/lungs/lungs = owner.get_organ_slot(ORGAN_SLOT_LUNGS)
	var/lung_health = lungs && lungs.maxHealth > 0 ? clamp((lungs.maxHealth - lungs.damage) / lungs.maxHealth * 100, 0, 100) : 0

	organs_data["lungs"] = list(
		"present" = !isnull(lungs),
		"health" = lung_health,
		"failing" = lungs ? !!(lungs.organ_flags & ORGAN_FAILING) : TRUE,
		"status" = lungs ? lungs.get_status_text() : "Missing",
		"ventilation" = lungs ? clamp(lungs.get_ventilation(), 0, 1) : 0,
		"fluid_ratio" = lungs ? clamp(lungs.fluid / LUNG_FLUID_MAX, 0, 1) : 1,
		"oxygenation" = clamp(owner.blood_oxygenation, 0, 100),
	)

	return organs_data
#endif
