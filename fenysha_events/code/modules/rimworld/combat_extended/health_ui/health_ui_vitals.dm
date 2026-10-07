#ifndef OLD_COMBAT_SYSTEM
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
#endif
