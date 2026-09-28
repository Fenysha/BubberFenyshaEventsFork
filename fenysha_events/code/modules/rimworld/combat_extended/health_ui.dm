/**
 * Health UI datum. Attached to a carbon, opens a detailed health panel.
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

/datum/health_ui/ui_data(mob/user)
	var/list/data = list()
	var/can_see_full = (user == owner) || HAS_TRAIT(user, TRAIT_VIEW_FULL_HEALTH)

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
	data["bodyparts"] = get_bodyparts_data(user, can_see_full)
	data["organs"] = get_special_organs_data(user, can_see_full)
	data["can_see_full"] = can_see_full

	return data

/datum/health_ui/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("select_limb")
			return TRUE

/datum/health_ui/proc/get_heartbeat_data()
	var/obj/item/organ/heart/heart = owner.get_organ_slot(ORGAN_SLOT_HEART)
	if(!heart || owner.needs_heart() && !heart)
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
			"cpr" = FALSE,
		)

	var/rate = heart.get_rate()
	var/rhythm = heart.get_rhythm_type()
	var/contractility = heart.get_contractility()
	var/stroke_efficiency = heart.get_stroke_efficiency(rate)
	var/cardiac_output = heart.get_cardiac_output()
	var/cpr = heart.cpr_until > world.time
	var/state = "beating"

	if(!heart.is_beating())
		state = cpr ? "cpr" : "stopped"
	else if(heart.organ_flags & ORGAN_FAILING)
		state = "failing"

	return list(
		"rate" = rate,
		"rhythm" = rhythm,
		"strength" = clamp(contractility * stroke_efficiency, 0, 1),
		"contractility" = clamp(contractility, 0, 1),
		"stroke_efficiency" = clamp(stroke_efficiency, 0, 1),
		"cardiac_output" = max(0, cardiac_output),
		"target_rate" = round(heart.rate_target),
		"state" = state,
		"beating" = heart.is_beating(),
		"cpr" = cpr,
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
		if("ventricular_tachycardia")
			alert = "VENTRICULAR TACHYCARDIA"
			noise = 0.08
		if("tachycardia")
			alert = "TACHYCARDIA"
		if("bradycardia")
			alert = "BRADYCARDIA"

	if(heartbeat["state"] == "failing")
		noise = max(noise, 0.08)

	return list(
		"rhythm" = rhythm,
		"alert" = alert,
		"noise" = noise,
		"flatline" = flatline,
	)

/datum/health_ui/proc/get_lungs_data()
	var/obj/item/organ/lungs/lungs = owner.get_organ_slot(ORGAN_SLOT_LUNGS)
	if(!lungs)
		return list(
			"present" = FALSE,
			"health" = 0,
			"functional" = FALSE,
			"ventilation" = 0,
			"oxygenation" = clamp(owner.blood_oxygenation, 0, 100),
			"fluid" = LUNG_FLUID_MAX,
			"fluid_ratio" = 1,
		)

	return list(
		"present" = TRUE,
		"health" = lungs.maxHealth > 0 ? clamp((lungs.maxHealth - lungs.damage) / lungs.maxHealth * 100, 0, 100) : 0,
		"functional" = !(lungs.organ_flags & ORGAN_FAILING) && lungs.get_ventilation() > 0,
		"ventilation" = clamp(lungs.get_ventilation() * 100, 0, 100),
		"oxygenation" = clamp(owner.blood_oxygenation, 0, 100),
		"fluid" = clamp(lungs.fluid, 0, LUNG_FLUID_MAX),
		"fluid_ratio" = clamp(lungs.fluid / LUNG_FLUID_MAX, 0, 1),
	)

/datum/health_ui/proc/get_bodyparts_data(mob/user, can_see_full)
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
		var/list/part_data = list(
			"zone" = zone,
			"name" = BP ? BP.plaintext_zone : zone,
			"present" = !isnull(BP),
			"brute" = BP ? BP.brute_dam : 0,
			"burn" = BP ? BP.burn_dam : 0,
			"max_damage" = BP ? BP.max_damage : 0,
			"disabled" = BP ? BP.bodypart_disabled : TRUE,
			"bleed_rate" = BP ? BP.cached_bleed_rate : 0,
			"injuries" = list(),
		)

		if(BP)
			for(var/datum/injury/injury as anything in BP.injuries)
				if(!injury.can_be_seen_by(user))
					continue
				part_data["injuries"] += list(injury.get_ui_data())

		parts[zone] = part_data

	return parts

/datum/health_ui/proc/get_special_organs_data(mob/user, can_see_full)
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
		"status" = heart ? heart.get_status_text() : "Missing",
		"state" = heartbeat["state"],
		"rhythm" = heartbeat["rhythm"],
		"rate" = heartbeat["rate"],
		"contractility" = heartbeat["contractility"],
		"stroke_efficiency" = heartbeat["stroke_efficiency"],
		"cardiac_output" = heartbeat["cardiac_output"],
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
