/datum/injury/laceration
	name = "Laceration"
	undiagnosed_name = "deep cut"
	desc = "A deep cut through skin and muscle."
	examine_desc = "has a deep laceration"
	series = "laceration"
	upgrade_path = /datum/injury/laceration/severe
	severity = INJURY_SEVERITY_MODERATE

	injury_flags = INJURY_FLAG_EXTERNAL | INJURY_FLAG_ACCEPTS_GAUZE | INJURY_FLAG_BLEEDING | INJURY_FLAG_PAINFUL | INJURY_FLAG_SELF_HEALING

	bleed_rate = 0.27
	pain_amount = 12
	damage_multiplier = 1.1

	base_healing_rate = 0.008
	base_treat_time = 4 SECONDS
	treatable_by = list(
		/obj/item/stack/medical/medicine/medkit/crude = INJURY_TREATMENT_EFFECTIVENESS_POOR,
		/obj/item/stack/medical/medicine/gauze = INJURY_TREATMENT_EFFECTIVENESS_NORMAL,
		/obj/item/stack/medical/medicine/suture = INJURY_TREATMENT_EFFECTIVENESS_ADEQUATE,
		/obj/item/stack/medical/medicine/medkit/indusrtial = INJURY_TREATMENT_EFFECTIVENESS_EXCELLENT,
	)
	treatable_tools = list(TOOL_CAUTERY)

/datum/injury/laceration/severe
	name = "Severe Laceration"
	undiagnosed_name = "gaping wound"
	desc = "A severe laceration with significant tissue damage."
	examine_desc = "has a gaping laceration"
	upgrade_path = /datum/injury/laceration/critical
	severity = INJURY_SEVERITY_SEVERE

	injury_flags = INJURY_FLAG_EXTERNAL | INJURY_FLAG_ACCEPTS_GAUZE | INJURY_FLAG_BLEEDING | INJURY_FLAG_PAINFUL

	bleed_rate = 0.63
	pain_amount = 22
	damage_multiplier = 1.25
	base_healing_rate = 0.005
	base_treat_time = 6 SECONDS

/datum/injury/laceration/critical
	name = "Critical Laceration"
	undiagnosed_name = "horrific gash"
	desc = "A critical laceration exposing deeper structures."
	examine_desc = "is torn open"
	upgrade_path = null
	severity = INJURY_SEVERITY_CRITICAL

	injury_flags = INJURY_FLAG_EXTERNAL | INJURY_FLAG_ACCEPTS_GAUZE | INJURY_FLAG_BLEEDING | INJURY_FLAG_PAINFUL

	bleed_rate = 1.26
	pain_amount = 35
	damage_multiplier = 1.4
	dismemberment_weight = 3.0
	disabling = TRUE
	base_healing_rate = 0.003
	base_treat_time = 8 SECONDS

/datum/injury/laceration/on_applied_effects(attack_direction)
	if(severity < INJURY_SEVERITY_SEVERE)
		return
	hit_spray(attack_direction, severity - 2, severity - 1)
	play_effect_sound(INJURY_SOUND_BLOOD, 45)

/datum/injury/laceration/get_visible_signs(mob/user)
	if(severity < INJURY_SEVERITY_SEVERE)
		return null
	return get_untreated_sign()
