/datum/injury/eye_trauma
	name = "Eye Trauma"
	undiagnosed_name = "injured eye"
	desc = "Trauma to the eye or orbit. Vision is compromised."
	examine_desc = "has a badly injured eye"
	series = "eye_trauma"
	upgrade_path = null
	severity = INJURY_SEVERITY_SEVERE
	visibility = INJURY_VISIBILITY_FULL

	injury_flags = INJURY_FLAG_EXTERNAL | INJURY_FLAG_PAINFUL | INJURY_FLAG_ACCEPTS_GAUZE

	pain_amount = 22
	processes = TRUE

	base_healing_rate = 0.003
	base_treat_time = 6 SECONDS
	treatable_by = list(
		/obj/item/stack/medical/medicine/medkit/crude = INJURY_TREATMENT_EFFECTIVENESS_POOR,
		/obj/item/stack/medical/medicine/medkit/indusrtial = INJURY_TREATMENT_EFFECTIVENESS_NORMAL,
	)

/datum/injury/eye_trauma/can_apply_to(obj/item/bodypart/target_limb)
	return target_limb.body_zone == BODY_ZONE_HEAD

/datum/injury/eye_trauma/on_apply(silent = FALSE, attack_direction = null)
	. = ..()
	if(owner)
		owner.adjust_eye_blur_up_to(30 SECONDS, 60 SECONDS)

/datum/injury/eye_trauma/occur_text()
	return "is struck in the eye"

/datum/injury/eye_trauma/on_applied_effects(attack_direction)
	if(prob(50))
		owner.emote("scream")
	if(isturf(owner.loc))
		owner.ce_splatter_at(get_turf(owner), TRUE)

/// Vision stays smeared until the eye is dressed.
/datum/injury/eye_trauma/process_effects(seconds_per_tick)
	if(treatment_quality >= INJURY_TREATMENT_ADEQUATE)
		return
	owner.adjust_eye_blur_up_to(3 SECONDS, 30 SECONDS)

/datum/injury/eye_trauma/get_visible_signs(mob/user)
	if(!owner || treatment_quality >= INJURY_TREATMENT_ADEQUATE)
		return null
	return span_danger("[owner.p_Their()] eye is swollen shut and weeping blood.")
