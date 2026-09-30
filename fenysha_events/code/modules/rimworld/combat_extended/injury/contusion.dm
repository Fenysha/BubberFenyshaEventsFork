/datum/injury/contusion
	name = "Contusion"
	undiagnosed_name = "bruise"
	desc = "A deep bruise with damaged underlying tissue."
	examine_desc = "is heavily bruised"
	series = "contusion"
	upgrade_path = /datum/injury/contusion/severe
	severity = INJURY_SEVERITY_MODERATE

	injury_flags = INJURY_FLAG_EXTERNAL | INJURY_FLAG_PAINFUL | INJURY_FLAG_SELF_HEALING
	treatable_by = list(
		/obj/item/stack/medical/medicine/medkit/crude = INJURY_TREATMENT_EFFECTIVENESS_POOR,
		/obj/item/stack/medical/medicine/medkit/indusrtial = INJURY_TREATMENT_EFFECTIVENESS_NORMAL,
	)

	pain_amount = 8
	damage_multiplier = 1.05
	bleed_rate = 0

	base_healing_rate = 0.012
	base_treat_time = 3 SECONDS


/datum/injury/contusion/severe
	name = "Severe Contusion"
	undiagnosed_name = "massive bruise"
	desc = "A severe contusion with significant internal bleeding into the tissue."
	examine_desc = "is massively bruised and swollen"
	upgrade_path = null
	severity = INJURY_SEVERITY_SEVERE
	pain_amount = 18
	damage_multiplier = 1.15
	base_healing_rate = 0.007
