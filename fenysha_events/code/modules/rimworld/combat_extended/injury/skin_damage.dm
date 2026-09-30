/datum/injury/skin_damage
	name = "Skin Damage"
	undiagnosed_name = "damaged skin"
	desc = "The skin is badly damaged and no longer provides proper protection."
	examine_desc = "has badly damaged skin"
	series = "skin_damage"
	upgrade_path = /datum/injury/skin_damage/severe
	severity = INJURY_SEVERITY_MODERATE

	injury_flags = INJURY_FLAG_EXTERNAL | INJURY_FLAG_ACCEPTS_GAUZE | INJURY_FLAG_SELF_HEALING

	pain_amount = 6
	damage_multiplier = 1.2

	base_healing_rate = 0.006
	base_treat_time = 3 SECONDS
	treatable_by = list(
		/obj/item/stack/medical/medicine/medkit/crude = INJURY_TREATMENT_EFFECTIVENESS_POOR,
		/obj/item/stack/medical/medicine/gauze = INJURY_TREATMENT_EFFECTIVENESS_NORMAL,
		/obj/item/stack/medical/medicine/medkit/indusrtial = INJURY_TREATMENT_EFFECTIVENESS_EXCELLENT,
	)

/datum/injury/skin_damage/resolve_treatment_quality(obj/item/tool, mob/user)
	if(istype(tool, /obj/item/stack/medical/mesh))
		return INJURY_TREATMENT_EXCELLENT
	if(istype(tool, /obj/item/stack/medical/ointment))
		return INJURY_TREATMENT_ADEQUATE
	return INJURY_TREATMENT_POOR

/datum/injury/skin_damage/occur_text()
	return "is stripped of skin"

/datum/injury/skin_damage/severe
	name = "Severe Skin Damage"
	undiagnosed_name = "ruined skin"
	desc = "Large areas of skin are destroyed or hanging in flaps."
	examine_desc = "has ruined skin hanging in flaps"
	upgrade_path = null
	severity = INJURY_SEVERITY_SEVERE

	// Too extensive to close on its own
	injury_flags = INJURY_FLAG_EXTERNAL | INJURY_FLAG_ACCEPTS_GAUZE | INJURY_FLAG_PAINFUL

	pain_amount = 14
	damage_multiplier = 1.35

	base_healing_rate = 0.004
	base_treat_time = 5 SECONDS


/datum/injury/skin_damage/get_visible_signs(mob/user)
	return get_untreated_sign()
