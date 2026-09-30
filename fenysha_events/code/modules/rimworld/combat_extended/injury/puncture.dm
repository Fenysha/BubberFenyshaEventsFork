/datum/injury/puncture
	name = "Puncture Wound"
	undiagnosed_name = "puncture"
	desc = "A deep puncture wound."
	examine_desc = "has a puncture wound"
	series = "puncture"
	upgrade_path = null
	severity = INJURY_SEVERITY_MODERATE

	injury_flags = INJURY_FLAG_EXTERNAL | INJURY_FLAG_BLEEDING | INJURY_FLAG_PAINFUL | INJURY_FLAG_ACCEPTS_GAUZE | INJURY_FLAG_ACCEPTS_SUTURE | INJURY_FLAG_SELF_HEALING

	bleed_rate = 0.8
	pain_amount = 14

	base_healing_rate = 0.007
	base_treat_time = 4 SECONDS
	treatable_by = list(
		/obj/item/stack/medical/medicine/medkit/crude = INJURY_TREATMENT_EFFECTIVENESS_POOR,
		/obj/item/stack/medical/medicine/gauze = INJURY_TREATMENT_EFFECTIVENESS_NORMAL,
		/obj/item/stack/medical/medicine/suture = INJURY_TREATMENT_EFFECTIVENESS_ADEQUATE,
		/obj/item/stack/medical/medicine/medkit/indusrtial = INJURY_TREATMENT_EFFECTIVENESS_EXCELLENT,
	)

/datum/injury/puncture/occur_text()
	return "is punctured"

/datum/injury/puncture/on_applied_effects(attack_direction)
	hit_spray(attack_direction, 1, 2, TRUE)
	play_effect_sound(INJURY_SOUND_PIERCE, 50)

/datum/injury/puncture/get_visible_signs(mob/user)
	return get_untreated_sign()
