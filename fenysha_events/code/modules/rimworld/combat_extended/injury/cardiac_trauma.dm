/datum/injury/cardiac_trauma
	name = "Cardiac Trauma"
	undiagnosed_name = "chest trauma"
	desc = "Blunt or penetrating trauma to the heart region. Arrhythmia and arrest risk."
	examine_desc = "has catastrophic trauma over the heart"
	series = "cardiac_trauma"
	upgrade_path = null
	severity = INJURY_SEVERITY_CRITICAL
	visibility = INJURY_VISIBILITY_MEDICAL

	injury_flags = INJURY_FLAG_INTERNAL | INJURY_FLAG_PAINFUL | INJURY_FLAG_PROGRESSING

	pain_amount = 40
	disabling = TRUE
	processes = TRUE

	base_healing_rate = 0.002
	base_treat_time = 20 SECONDS
	treatable_by = list(
		/obj/item/stack/medical/medicine/medkit/indusrtial = INJURY_TREATMENT_EFFECTIVENESS_NORMAL,
	)

	var/fibrillation_chance = 1.5

	COOLDOWN_DECLARE(palpitation_cd)

/datum/injury/cardiac_trauma/can_apply_to(obj/item/bodypart/target_limb)
	return target_limb.body_zone == BODY_ZONE_CHEST

/datum/injury/cardiac_trauma/resolve_treatment_quality(obj/item/tool, mob/user)
	return INJURY_TREATMENT_ADEQUATE

/datum/injury/cardiac_trauma/occur_text()
	return "takes a crushing blow directly over the heart"


/datum/injury/cardiac_trauma/on_applied_effects(attack_direction)
	owner.emote("gasp")

/datum/injury/cardiac_trauma/process_effects(seconds_per_tick)
	if(treatment_quality >= INJURY_TREATMENT_ADEQUATE)
		return
	var/obj/item/organ/heart/heart = owner.get_organ_slot(ORGAN_SLOT_HEART)
	if(!heart)
		return

	// Palpitations: a painful stutter and a wave of faintness.
	if(COOLDOWN_FINISHED(src, palpitation_cd) && SPT_PROB(7, seconds_per_tick))
		pain_spike(28, "Your heart stutters painfully in your chest!", "[owner] clutches [owner.p_their()] chest, wincing.", "gasp")
		owner.apply_consciousness_impulse(45, src)
		COOLDOWN_START(src, palpitation_cd, 5 SECONDS)

	// The bruised myocardium can fall into ventricular fibrillation.
	if(heart.is_beating() && !heart.fibrillating && SPT_PROB(fibrillation_chance * scale_by_treatment(1), seconds_per_tick))
		heart.enter_fibrillation()

/datum/injury/cardiac_trauma/get_visible_signs(mob/user)
	if(!owner || treatment_quality >= INJURY_TREATMENT_ADEQUATE)
		return null
	return span_warning("[owner.p_Their()] chest is mottled with dark bruising over the heart.")
