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
	return GLOB.conscious_state // or a custom state later

/datum/health_ui/ui_data(mob/user)
	var/list/data = list()
	var/can_see_full = (user == owner) || HAS_TRAIT(user, TRAIT_VIEW_FULL_HEALTH)

	data["parameters"] = list(
		"consciousness" = owner.consciousness,
		"pain" = owner.pain,
		"shock" = owner.shock,
		"heartbeat" = get_heartbeat_data(),
		"breathing" = get_breathing_data(),
		"movement" = get_movement_data(),
		"bleed_rate" = owner.total_bleed_rate,
	)

	// Cardiogram + lungs
	data["cardiogram"] = get_cardiogram_data()
	data["lungs"] = get_lungs_data()

	data["bodyparts"] = get_bodyparts_data(user, can_see_full)
	data["organs"] = get_special_organs_data(user, can_see_full)

	// Selection is handled on the JS side; we just provide all data
	data["can_see_full"] = can_see_full

	return data

/datum/health_ui/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("select_limb")
			// Optional: store selected zone if we need server-side logic later
			return TRUE


/datum/health_ui/proc/get_heartbeat_data()
	// Placeholder. Later: real heart rate, rhythm type
	return list(
		"rate" = 80,
		"rhythm" = "normal", // normal, arrhythmia, fibrillation, asystole
		"strength" = 1.0,
	)

/datum/health_ui/proc/get_breathing_data()
	return list(
		"rate" = 16,
		"effective" = TRUE,
		"oxygenation" = 100, // placeholder
	)

/datum/health_ui/proc/get_movement_data()
	var/list/data = list(
		"can_stand" = owner.body_position == STANDING_UP,
		"can_walk" = owner.has_gravity() && owner.usable_legs > 0,
		"slowdown" = 0, // can pull from movespeed modifiers later
	)
	return data

/datum/health_ui/proc/get_cardiogram_data()
	// Structure prepared for future arrhythmia / fibrillation support
	return list(
		"rhythm" = "normal",		// normal, bradycardia, tachycardia, arrhythmia, fibrillation, asystole
		"pattern" = list(),			// optional: array of wave points for rendering
		"alert" = null,				// "fibrillation", "asystole", etc.
	)

/datum/health_ui/proc/get_lungs_data()
	// Prepared for pneumothorax / fluid / blood in lungs
	return list(
		"left" = list(
			"fill_blood" = 0,
			"fill_fluid" = 0,
			"collapsed" = FALSE,	// pneumothorax
			"functional" = TRUE,
		),
		"right" = list(
			"fill_blood" = 0,
			"fill_fluid" = 0,
			"collapsed" = FALSE,
			"functional" = TRUE,
		),
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
	organs_data["brain"] = list(
		"present" = !isnull(brain),
		"health" = brain ? (brain.maxHealth - brain.damage) / brain.maxHealth * 100 : 0,
		"failing" = brain ? (brain.organ_flags & ORGAN_FAILING) : TRUE,
		"status" = brain ? brain.get_status_text() : "Missing",
	)

	var/obj/item/organ/heart/heart = owner.get_organ_slot(ORGAN_SLOT_HEART)
	organs_data["heart"] = list(
		"present" = !isnull(heart),
		"health" = heart ? (heart.maxHealth - heart.damage) / heart.maxHealth * 100 : 0,
		"failing" = heart ? (heart.organ_flags & ORGAN_FAILING) : TRUE,
		"beating" = heart ? heart.is_beating() : FALSE,
		"status" = heart ? heart.get_status_text() : "Missing",
	)

	var/obj/item/organ/lungs/lungs = owner.get_organ_slot(ORGAN_SLOT_LUNGS)
	organs_data["lungs"] = list(
		"present" = !isnull(lungs),
		"health" = lungs ? (lungs.maxHealth - lungs.damage) / lungs.maxHealth * 100 : 0,
		"failing" = lungs ? (lungs.organ_flags & ORGAN_FAILING) : TRUE,
		"status" = lungs ? lungs.get_status_text() : "Missing",
	)

	return organs_data
