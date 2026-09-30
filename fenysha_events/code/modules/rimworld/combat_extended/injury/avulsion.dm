/datum/injury/avulsion
	name = "Avulsion"
	undiagnosed_name = "torn flesh"
	desc = "A large section of soft tissue has been torn away."
	examine_desc = "has a large section of flesh torn away"
	series = "avulsion"
	upgrade_path = null
	severity = INJURY_SEVERITY_CRITICAL

	injury_flags = INJURY_FLAG_EXTERNAL | INJURY_FLAG_BLEEDING | INJURY_FLAG_PAINFUL | INJURY_FLAG_ACCEPTS_GAUZE | INJURY_FLAG_ACCEPTS_SUTURE

	bleed_rate = 2.2
	pain_amount = 38
	damage_multiplier = 1.45
	dismemberment_weight = 4.0
	disabling = TRUE
	processes = TRUE

	base_healing_rate = 0.0025
	base_treat_time = 10 SECONDS
	treatable_by = list(
		/obj/item/stack/medical/medicine/medkit/crude = INJURY_TREATMENT_EFFECTIVENESS_POOR,
		/obj/item/stack/medical/medicine/gauze = INJURY_TREATMENT_EFFECTIVENESS_NORMAL,
		/obj/item/stack/medical/medicine/suture = INJURY_TREATMENT_EFFECTIVENESS_ADEQUATE,
		/obj/item/stack/medical/medicine/medkit/indusrtial = INJURY_TREATMENT_EFFECTIVENESS_EXCELLENT,
	)
	treatable_tools = list(TOOL_CAUTERY)

/datum/injury/avulsion/resolve_treatment_quality(obj/item/tool, mob/user)
	// Tissue is missing, so nothing field-grade can do better than "adequate".
	if(tool.tool_behaviour == TOOL_CAUTERY || istype(tool, /obj/item/stack/medical/suture))
		return INJURY_TREATMENT_ADEQUATE
	return INJURY_TREATMENT_POOR

/datum/injury/avulsion/occur_text()
	return "is torn open, flesh ripped away"


/datum/injury/avulsion/on_applied_effects(attack_direction)
	hit_spray(attack_direction, 3, 3)
	owner.ce_gib_splatter()
	play_effect_sound(INJURY_SOUND_BLOOD, 65)
	if(prob(80))
		owner.emote("scream")

/// The wound keeps pumping blood out while it stays open.
/datum/injury/avulsion/process_effects(seconds_per_tick)
	if(treatment_quality >= INJURY_TREATMENT_ADEQUATE || !isturf(owner.loc))
		return
	if(get_bleed_rate() > 1 && SPT_PROB(35, seconds_per_tick))
		owner.ce_spray_blood(pick(GLOB.alldirs), rand(1, 2), TRUE)

/datum/injury/avulsion/get_visible_signs(mob/user)
	if(!owner || !limb || treatment_quality >= INJURY_TREATMENT_ADEQUATE)
		return null
	return span_userdanger("A large piece of [owner.p_their()] [limb.plaintext_zone] has been torn away, leaving a gushing wound!")
