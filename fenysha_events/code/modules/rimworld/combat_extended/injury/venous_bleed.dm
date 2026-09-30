/datum/injury/venous_bleed
	name = "Venous Bleeding"
	undiagnosed_name = "steady bleeding"
	desc = "A vein has been damaged. Blood flows steadily."
	examine_desc = "is bleeding steadily"
	series = "venous_bleed"
	upgrade_path = null
	severity = INJURY_SEVERITY_SEVERE

	injury_flags = INJURY_FLAG_EXTERNAL | INJURY_FLAG_BLEEDING | INJURY_FLAG_PAINFUL | INJURY_FLAG_ACCEPTS_GAUZE | INJURY_FLAG_ACCEPTS_SUTURE | INJURY_FLAG_SELF_HEALING

	bleed_rate = 1.2
	pain_amount = 10
	reacts_to_movement = TRUE

	// Low-pressure vessels can clot on their own, but very slowly.
	base_healing_rate = 0.004
	base_treat_time = 4 SECONDS
	treatable_by = list(
		/obj/item/stack/medical/medicine/medkit/crude = INJURY_TREATMENT_EFFECTIVENESS_POOR,
		/obj/item/stack/medical/medicine/gauze = INJURY_TREATMENT_EFFECTIVENESS_NORMAL,
		/obj/item/stack/medical/medicine/suture = INJURY_TREATMENT_EFFECTIVENESS_ADEQUATE,
		/obj/item/stack/medical/medicine/medkit/indusrtial = INJURY_TREATMENT_EFFECTIVENESS_EXCELLENT,
	)
	treatable_tools = list(TOOL_CAUTERY)

/datum/injury/venous_bleed/occur_text()
	return "starts bleeding steadily"

/datum/injury/venous_bleed/on_applied_effects(attack_direction)
	hit_spray(attack_direction, 1, 1, TRUE)
	play_effect_sound(INJURY_SOUND_BLOOD, 35)

/// A moving casualty leaves a trail of blood behind.
/datum/injury/venous_bleed/on_owner_moved(movement_dir)
	if(!owner || owner.stat == DEAD || treatment_quality >= INJURY_TREATMENT_ADEQUATE)
		return
	if(prob(30) && isturf(owner.loc))
		owner.ce_splatter_at(get_turf(owner), TRUE)

/datum/injury/venous_bleed/get_visible_signs(mob/user)
	return get_untreated_sign()
