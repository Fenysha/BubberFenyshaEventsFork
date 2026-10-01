/datum/injury/jaw_fracture
	name = "Jaw Fracture"
	undiagnosed_name = "broken jaw"
	desc = "The mandible is fractured. Speech and eating are severely impaired."
	examine_desc = "has a broken jaw"
	series = "jaw_fracture"
	upgrade_path = null
	severity = INJURY_SEVERITY_SEVERE

	injury_flags = INJURY_FLAG_INTERNAL | INJURY_FLAG_PAINFUL | INJURY_FLAG_ACCEPTS_SPLINT | INJURY_FLAG_SELF_HEALING

	pain_amount = 20
	interaction_penalty = 2.0
	processes = TRUE

	base_healing_rate = 0.0015
	base_treat_time = 6 SECONDS
	treatable_by = list(
		/obj/item/stack/medical/medicine/medkit/crude = INJURY_TREATMENT_EFFECTIVENESS_POOR,
		/obj/item/stack/medical/medicine/bone_gel = INJURY_TREATMENT_ADEQUATE,
		/obj/item/stack/medical/medicine/medkit/indusrtial = INJURY_TREATMENT_ADEQUATE,
	)
	treatable_tools = list(TOOL_BONESET)

	COOLDOWN_DECLARE(drool_cd)

/datum/injury/jaw_fracture/can_apply_to(obj/item/bodypart/target_limb)
	return target_limb.body_zone == BODY_ZONE_HEAD

/datum/injury/jaw_fracture/resolve_treatment_quality(obj/item/tool, mob/user)
	if(tool.tool_behaviour == TOOL_BONESET || istype(tool, /obj/item/stack/medical/bone_gel))
		return INJURY_TREATMENT_EXCELLENT
	return INJURY_TREATMENT_ADEQUATE

/datum/injury/jaw_fracture/occur_text()
	return "cracks and hangs crooked"

/datum/injury/jaw_fracture/on_applied_effects(attack_direction)
	play_effect_sound(INJURY_SOUND_BONE_CRACK, 65)
	hit_spray(attack_direction, 1, 1, TRUE)

/// Speech is slurred until the jaw is set.
/datum/injury/jaw_fracture/process_effects(seconds_per_tick)
	if(treatment_quality >= INJURY_TREATMENT_ADEQUATE)
		return
	owner.set_slurring_if_lower(5 SECONDS)
	if(COOLDOWN_FINISHED(src, drool_cd) && SPT_PROB(2, seconds_per_tick) && isturf(owner.loc))
		owner.ce_splatter_at(get_turf(owner), TRUE)
		COOLDOWN_START(src, drool_cd, 7 SECONDS)

/datum/injury/jaw_fracture/get_visible_signs(mob/user)
	if(!owner || treatment_quality >= INJURY_TREATMENT_ADEQUATE)
		return null
	return span_danger("[owner.p_Their()] jaw hangs at the wrong angle, and blood drools from [owner.p_their()] mouth.")
