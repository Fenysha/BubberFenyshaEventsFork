/datum/injury/facial_trauma
	name = "Facial Trauma"
	undiagnosed_name = "ruined face"
	desc = "Severe soft-tissue and bone damage to the face."
	examine_desc = "has a horribly injured face"
	series = "facial_trauma"
	upgrade_path = null
	severity = INJURY_SEVERITY_SEVERE

	injury_flags = INJURY_FLAG_EXTERNAL | INJURY_FLAG_BLEEDING | INJURY_FLAG_PAINFUL | INJURY_FLAG_ACCEPTS_GAUZE | INJURY_FLAG_ACCEPTS_SUTURE

	bleed_rate = 0.6
	pain_amount = 24
	processes = TRUE

	base_healing_rate = 0.004
	base_treat_time = 7 SECONDS
	treatable_by = list(
		/obj/item/stack/medical/medicine/medkit/indusrtial/glitertech = INJURY_TREATMENT_EFFECTIVENESS_NORMAL,
	)

	COOLDOWN_DECLARE(spit_cd)

/datum/injury/facial_trauma/can_apply_to(obj/item/bodypart/target_limb)
	return target_limb.body_zone == BODY_ZONE_HEAD

/datum/injury/facial_trauma/on_apply(silent = FALSE, attack_direction = null)
	. = ..()
	if(limb)
		ADD_TRAIT(limb, TRAIT_DISFIGURED, unique_id)

/datum/injury/facial_trauma/on_remove(replaced = FALSE)
	if(limb)
		REMOVE_TRAIT(limb, TRAIT_DISFIGURED, unique_id)

/datum/injury/facial_trauma/occur_text()
	return "is smashed"

/datum/injury/facial_trauma/on_applied_effects(attack_direction)
	hit_spray(attack_direction, 1, 2, TRUE)
	play_effect_sound(INJURY_SOUND_BONE_CRACK, 55)

/datum/injury/facial_trauma/process_effects(seconds_per_tick)
	if(treatment_quality >= INJURY_TREATMENT_ADEQUATE)
		return
	if(COOLDOWN_FINISHED(src, spit_cd) && SPT_PROB(4, seconds_per_tick) && isturf(owner.loc))
		owner.ce_splatter_at(get_turf(owner), TRUE)
		if(effect_message_ready())
			owner.visible_message(span_danger("[owner] spits out a mouthful of blood."), span_warning("Your mouth fills with blood and you spit it out."))
		COOLDOWN_START(src, spit_cd, 6 SECONDS)

/datum/injury/facial_trauma/get_visible_signs(mob/user)
	if(!owner || treatment_quality >= INJURY_TREATMENT_ADEQUATE)
		return null
	return span_danger("[owner.p_Their()] face is a swollen, bloody ruin.")
