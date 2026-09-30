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
 * Attempt to treat a specific injury with an item currently held by the user.
 * item_type is a typepath string from the UI treat button.
 */
/datum/health_ui/proc/try_treat_injury(mob/living/user, injury_id, item_type_text)
	if(!user || !injury_id || !item_type_text)
		return FALSE
	if(isobserver(user))
		return FALSE

	var/item_type = text2path(item_type_text)
	if(!ispath(item_type))
		return FALSE

	var/datum/injury/target
	for(var/datum/injury/injury as anything in owner.all_injuries)
		if(injury.unique_id == injury_id)
			target = injury
			break

	if(!target || !target.limb)
		return FALSE

	// Prefer active hand, then other hand
	var/obj/item/tool
	var/obj/item/active = user.get_active_held_item()
	var/obj/item/inactive = user.get_inactive_held_item()

	if(istype(active, item_type))
		tool = active
	else if(istype(inactive, item_type))
		tool = inactive

	if(!tool)
		to_chat(user, span_warning("You need to hold the right tool in your hand."))
		return FALSE

	if(!target.item_can_treat(tool, user))
		to_chat(user, span_warning("That will not help this injury."))
		return FALSE

	return target.try_treat(tool, user)


/datum/health_ui/proc/get_heartbeat_data()
	var/obj/item/organ/heart/heart = owner.get_organ_slot(ORGAN_SLOT_HEART)
	if(!heart)
		return list(
			"rate" = 0,
			"rhythm" = "asystole",
			"strength" = 0,
			"contractility" = 0,
			"stroke_efficiency" = 0,
			"cardiac_output" = 0,
			"target_rate" = 0,
			"state" = "missing",
			"beating" = FALSE,
			"fibrillating" = FALSE,
			"cpr" = FALSE,
			"preload" = 0,
		)

	var/rate = heart.get_rate()
	var/rhythm = heart.get_rhythm_type()
	var/contractility = heart.get_contractility()
	var/stroke_efficiency = heart.get_stroke_efficiency(rate)
	var/cardiac_output = heart.get_cardiac_output()
	var/cpr = heart.cpr_until > world.time
	var/fibrillating = heart.fibrillating
	var/preload = heart.get_preload_factor()

	var/state = "beating"
	if(fibrillating)
		state = "fibrillating"
	else if(!heart.is_beating())
		state = cpr ? "cpr" : "stopped"
	else if(heart.organ_flags & ORGAN_FAILING)
		state = "failing"

	var/strength = 0
	if(!fibrillating)
		strength = clamp(contractility * stroke_efficiency * preload, 0, 1)

	return list(
		"rate" = rate,
		"rhythm" = rhythm,
		"strength" = strength,
		"contractility" = clamp(contractility, 0, 1),
		"stroke_efficiency" = clamp(stroke_efficiency, 0, 1),
		"cardiac_output" = max(0, cardiac_output),
		"target_rate" = round(heart.rate_target),
		"state" = state,
		"beating" = heart.is_beating(),
		"fibrillating" = fibrillating,
		"cpr" = cpr,
		"preload" = clamp(preload, 0, 1),
	)

/datum/health_ui/proc/get_breathing_data()
	var/obj/item/organ/lungs/lungs = owner.get_organ_slot(ORGAN_SLOT_LUNGS)
	var/has_lungs = !isnull(lungs)
	var/ventilation = has_lungs ? lungs.get_ventilation() : 0

	return list(
		"effective" = has_lungs && !owner.failed_last_breath && ventilation > 0.05,
		"oxygenation" = clamp(owner.blood_oxygenation, 0, 100),
		"ventilation" = clamp(ventilation * 100, 0, 100),
		"fluid" = has_lungs ? lungs.fluid : LUNG_FLUID_MAX,
		"fluid_ratio" = has_lungs ? clamp(lungs.fluid / LUNG_FLUID_MAX, 0, 1) : 1,
		"functional" = has_lungs && !(lungs.organ_flags & ORGAN_FAILING),
	)

/datum/health_ui/proc/get_circulation_data()
	var/blood_ratio = owner.get_blood_ratio()
	var/perfusion = owner.get_brain_perfusion()
	var/heart_output = 0
	var/obj/item/organ/heart/heart = owner.get_organ_slot(ORGAN_SLOT_HEART)
	if(heart)
		heart_output = heart.get_cardiac_output()

	return list(
		"blood_volume" = owner.get_blood_volume(),
		"blood_ratio" = clamp(blood_ratio, 0, 1.2),
		"blood_pressure" = max(owner.blood_pressure, 0),
		"perfusion" = clamp(perfusion, 0, 1.2),
		"heart_output" = max(heart_output, 0),
	)

/datum/health_ui/proc/get_movement_data()
	return list(
		"can_stand" = owner.body_position == STANDING_UP,
		"can_walk" = owner.has_gravity() && owner.usable_legs > 0,
		"slowdown" = 0,
	)

/datum/health_ui/proc/get_cardiogram_data()
	var/heartbeat = get_heartbeat_data()
	var/rhythm = heartbeat["rhythm"]
	var/alert
	var/noise = 0
	var/flatline = 0

	switch(rhythm)
		if("asystole")
			alert = "ASYSTOLE"
			flatline = 1
		if("ventricular_fibrillation")
			alert = "VENTRICULAR FIBRILLATION"
			noise = 0.35
			flatline = 0
		if("ventricular_tachycardia")
			alert = "VENTRICULAR TACHYCARDIA"
			noise = 0.08
		if("tachycardia")
			alert = "TACHYCARDIA"
		if("bradycardia")
			alert = "BRADYCARDIA"

	if(heartbeat["state"] == "failing")
		noise = max(noise, 0.08)

	if(heartbeat["state"] == "fibrillating")
		noise = max(noise, 0.35)

	return list(
		"rhythm" = rhythm,
		"alert" = alert,
		"noise" = noise,
		"flatline" = flatline,
	)

/datum/health_ui/proc/get_lungs_icon_src()
	var/static/cached
	if(cached)
		return cached
	var/icon/lungs_icon = icon(HEALTH_PANEL_BODY_ICON, "lungs", SOUTH, 1)
	if(!lungs_icon)
		return null
	cached = icon2base64(lungs_icon)
	return cached

/datum/health_ui/proc/get_lungs_data()
	var/obj/item/organ/lungs/lungs = owner.get_organ_slot(ORGAN_SLOT_LUNGS)
	var/icon_src = get_lungs_icon_src()

	if(!lungs)
		return list(
			"present" = FALSE,
			"health" = 0,
			"functional" = FALSE,
			"ventilation" = 0,
			"oxygenation" = clamp(owner.blood_oxygenation, 0, 100),
			"fluid" = LUNG_FLUID_MAX,
			"fluid_ratio" = 1,
			"iconSrc" = icon_src,
		)

	return list(
		"present" = TRUE,
		"health" = lungs.maxHealth > 0 ? clamp((lungs.maxHealth - lungs.damage) / lungs.maxHealth * 100, 0, 100) : 0,
		"functional" = !(lungs.organ_flags & ORGAN_FAILING) && lungs.get_ventilation() > 0,
		"ventilation" = clamp(lungs.get_ventilation() * 100, 0, 100),
		"oxygenation" = clamp(owner.blood_oxygenation, 0, 100),
		"fluid" = clamp(lungs.fluid, 0, LUNG_FLUID_MAX),
		"fluid_ratio" = clamp(lungs.fluid / LUNG_FLUID_MAX, 0, 1),
		"iconSrc" = icon_src,
	)

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
 * Cached base64 icons for treatment item typepaths.
 * Key = typepath string, value = list(iconSrc, name)
 */
/datum/health_ui/proc/get_treatment_item_ui(typepath)
	if(!ispath(typepath))
		return null

	var/static/list/treat_icon_cache = list()
	var/key = "[typepath]"

	if(treat_icon_cache[key])
		return treat_icon_cache[key]

	var/obj/item/sample = new typepath()
	if(!sample)
		return null

	var/icon/I = icon(sample.icon, sample.icon_state, SOUTH, 1)
	var/list/entry = list(
		"type" = key,
		"name" = sample.name,
		"iconSrc" = I ? icon2base64(I) : null,
	)
	qdel(sample)

	treat_icon_cache[key] = entry
	return entry

/**
 * Builds the list of treatment option buttons for an injury.
 */
/datum/health_ui/proc/get_injury_treat_options(datum/injury/injury)
	var/list/options = list()
	if(!injury)
		return options

	if(length(injury.treatable_by))
		for(var/typepath in injury.treatable_by)
			var/list/entry = get_treatment_item_ui(typepath)
			if(entry)
				options += list(entry)

	// Tool behaviours are harder to icon; skip pure tools unless they map to items
	return options

/datum/health_ui/proc/get_limb_injury_bleed_rate(obj/item/bodypart/BP)
	if(!BP)
		return 0
	var/total = 0
	for(var/datum/injury/injury as anything in BP.injuries)
		total += injury.get_bleed_rate()
	return total

/datum/health_ui/proc/get_bodyparts_data(mob/user, viewer_access)
	var/list/parts = list()
	var/list/zones = list(
		BODY_ZONE_HEAD,
		BODY_ZONE_CHEST,
		BODY_ZONE_L_ARM,
		BODY_ZONE_R_ARM,
		BODY_ZONE_L_LEG,
		BODY_ZONE_R_LEG,
	)

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
				if(!injury.can_be_seen_by(user))
					continue
				var/list/injury_data = injury.get_ui_data()
				injury_data["treat_options"] = get_injury_treat_options(injury)
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
