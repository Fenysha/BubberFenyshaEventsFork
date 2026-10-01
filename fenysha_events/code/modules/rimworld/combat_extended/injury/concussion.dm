/datum/injury/concussion
	name = "Concussion"
	undiagnosed_name = "head trauma"
	desc = "A concussion. Disorientation, nausea, and impaired coordination."
	examine_desc = "looks dazed from a head injury"
	series = "concussion"
	upgrade_path = /datum/injury/concussion/severe
	severity = INJURY_SEVERITY_MODERATE
	visibility = INJURY_VISIBILITY_MEDICAL

	injury_flags = INJURY_FLAG_INTERNAL | INJURY_FLAG_PAINFUL | INJURY_FLAG_SELF_HEALING
	treatable_by = list(
		/obj/item/stack/medical/medicine/medkit/crude = INJURY_TREATMENT_EFFECTIVENESS_POOR,
		/obj/item/stack/medical/medicine/medkit/indusrtial = INJURY_TREATMENT_EFFECTIVENESS_NORMAL,
	)

	pain_amount = 16
	processes = TRUE

	// Rest heals a concussion.
	base_healing_rate = 0.006
	var/symptom_chance = 6

	COOLDOWN_DECLARE(symptom_cd)

/datum/injury/concussion/can_apply_to(obj/item/bodypart/target_limb)
	return target_limb.body_zone == BODY_ZONE_HEAD

/datum/injury/concussion/on_apply(silent = FALSE, attack_direction = null)
	. = ..()
	if(owner)
		owner.adjust_confusion_up_to(8 SECONDS, 20 SECONDS)
		owner.adjust_eye_blur_up_to(6 SECONDS, 15 SECONDS)

/datum/injury/concussion/process_effects(seconds_per_tick)
	if(!COOLDOWN_FINISHED(src, symptom_cd) || !SPT_PROB(symptom_chance, seconds_per_tick))
		return
	owner.adjust_confusion_up_to(4 SECONDS, 12 SECONDS)
	owner.adjust_eye_blur_up_to(3 SECONDS, 10 SECONDS)
	if(effect_message_ready())
		to_chat(owner, span_warning(pick(
			"Your head throbs and the room tilts.",
			"A wave of dizziness washes over you.",
			"Bright spots swim across your vision.",
		)))
	COOLDOWN_START(src, symptom_cd, 4 SECONDS)

/datum/injury/concussion/get_visible_signs(mob/user)
	if(!owner || owner.stat == DEAD)
		return null
	return span_warning("[owner.p_They()] look[owner.p_s()] dazed and unfocused.")

/datum/injury/concussion/severe
	name = "Severe Concussion"
	undiagnosed_name = "severe head trauma"
	desc = "Severe concussion. Vomiting, blackouts, and lasting neurological symptoms."
	examine_desc = "is clearly suffering from severe head trauma"
	upgrade_path = null
	severity = INJURY_SEVERITY_SEVERE

	pain_amount = 28
	base_healing_rate = 0.003
	symptom_chance = 10

	COOLDOWN_DECLARE(vomit_cd)
	COOLDOWN_DECLARE(collapse_cd)

/datum/injury/concussion/severe/on_apply(silent = FALSE, attack_direction = null)
	. = ..()
	if(owner)
		owner.adjust_confusion_up_to(20 SECONDS, 40 SECONDS)
		owner.adjust_eye_blur_up_to(15 SECONDS, 30 SECONDS)
		if(prob(40))
			owner.vomit(VOMIT_CATEGORY_DEFAULT, lost_nutrition = 15)

/datum/injury/concussion/severe/process_effects(seconds_per_tick)
	..()
	if(COOLDOWN_FINISHED(src, vomit_cd) && SPT_PROB(1.8, seconds_per_tick))
		owner.vomit(VOMIT_CATEGORY_DEFAULT, lost_nutrition = 10)
		COOLDOWN_START(src, vomit_cd, 12 SECONDS)
	if(COOLDOWN_FINISHED(src, collapse_cd) && SPT_PROB(2, seconds_per_tick))
		owner.visible_message(span_danger("[owner] sways and nearly collapses!"), span_userdanger("Your vision tunnels and your legs buckle!"))
		owner.apply_consciousness_impulse(110, src)
		COOLDOWN_START(src, collapse_cd, 8 SECONDS)
