/datum/injury/burn
	name = "Burn"
	undiagnosed_name = "burn"
	desc = "Thermal damage to the skin and underlying tissue."
	examine_desc = "is burned"
	series = "burn"
	upgrade_path = /datum/injury/burn/severe
	severity = INJURY_SEVERITY_MODERATE

	injury_flags = INJURY_FLAG_EXTERNAL | INJURY_FLAG_PAINFUL | INJURY_FLAG_ACCEPTS_GAUZE | INJURY_FLAG_SELF_HEALING

	pain_amount = 15
	damage_multiplier = 1.15

	base_healing_rate = 0.006
	base_treat_time = 4 SECONDS
	treatable_by = list(
		/obj/item/stack/medical/medicine/medkit/crude = INJURY_TREATMENT_EFFECTIVENESS_POOR,
		/obj/item/stack/medical/medicine/gauze = INJURY_TREATMENT_EFFECTIVENESS_NORMAL,
		/obj/item/stack/medical/medicine/medkit/indusrtial = INJURY_TREATMENT_EFFECTIVENESS_EXCELLENT,
	)

/datum/injury/burn/resolve_treatment_quality(obj/item/tool, mob/user)
	if(istype(tool, /obj/item/stack/medical/mesh))
		return INJURY_TREATMENT_EXCELLENT
	if(istype(tool, /obj/item/stack/medical/ointment))
		return INJURY_TREATMENT_ADEQUATE
	return INJURY_TREATMENT_POOR

/datum/injury/burn/occur_text()
	return "is scorched"

/datum/injury/burn/severe
	name = "Severe Burn"
	undiagnosed_name = "severe burn"
	desc = "Deep thermal damage. Skin is charred and blistered."
	examine_desc = "has severe burns"
	upgrade_path = /datum/injury/burn/critical
	severity = INJURY_SEVERITY_SEVERE

	// Deep burns need dressing before they start to recover.
	injury_flags = INJURY_FLAG_EXTERNAL | INJURY_FLAG_PAINFUL | INJURY_FLAG_ACCEPTS_GAUZE

	pain_amount = 28
	damage_multiplier = 1.3

	base_healing_rate = 0.004
	base_treat_time = 6 SECONDS

/datum/injury/burn/severe/occur_text()
	return "is badly burned"

/datum/injury/burn/critical
	name = "Critical Burn"
	undiagnosed_name = "charred flesh"
	desc = "Full-thickness burn. Tissue is destroyed down to muscle and bone."
	examine_desc = "is charred black"
	upgrade_path = null
	severity = INJURY_SEVERITY_CRITICAL

	pain_amount = 40
	damage_multiplier = 1.5
	disabling = TRUE

	base_healing_rate = 0.002
	base_treat_time = 9 SECONDS


/datum/injury/burn/critical/occur_text()
	return "is charred to the bone"

/datum/injury/burn/on_applied_effects(attack_direction)
	if(severity < INJURY_SEVERITY_SEVERE)
		return
	play_effect_sound(INJURY_SOUND_SIZZLE, 55)
	if(prob(severity >= INJURY_SEVERITY_CRITICAL ? 90 : 60))
		owner.emote("scream")

/datum/injury/burn/get_visible_signs(mob/user)
	if(severity < INJURY_SEVERITY_SEVERE)
		return null
	return get_untreated_sign()
