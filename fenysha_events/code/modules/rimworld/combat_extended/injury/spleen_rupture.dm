/datum/injury/spleen_rupture
	name = "Ruptured Spleen"
	undiagnosed_name = "abdominal bleeding"
	desc = "The spleen is ruptured. Rapid internal blood loss, and moving makes it worse."
	examine_desc = "is rigid and tender across the upper abdomen"
	series = "spleen_rupture"
	upgrade_path = null
	severity = INJURY_SEVERITY_CRITICAL
	visibility = INJURY_VISIBILITY_MEDICAL
	reacts_to_movement = TRUE

	injury_flags = INJURY_FLAG_INTERNAL | INJURY_FLAG_BLEEDING | INJURY_FLAG_PAINFUL

	bleed_rate = 2.0
	pain_amount = 26
	processes = TRUE

	base_healing_rate = 0.003
	treatable_by = list(
		/obj/item/stack/medical/medicine/medkit/indusrtial/glitertech = INJURY_TREATMENT_EFFECTIVENESS_EXCELLENT,
	)

/datum/injury/spleen_rupture/can_apply_to(obj/item/bodypart/target_limb)
	return target_limb.body_zone == BODY_ZONE_CHEST

/datum/injury/spleen_rupture/resolve_treatment_quality(obj/item/tool, mob/user)
	return INJURY_TREATMENT_ADEQUATE

/datum/injury/spleen_rupture/occur_text()
	return "is struck with a wet, tearing impact"


/datum/injury/spleen_rupture/on_applied_effects(attack_direction)
	owner.emote("groan")

/datum/injury/spleen_rupture/on_owner_moved(movement_dir)
	if(!owner || owner.stat == DEAD || owner.body_position == LYING_DOWN || treatment_quality >= INJURY_TREATMENT_ADEQUATE)
		return
	if(prob(owner.move_intent == MOVE_INTENT_RUN ? 18 : 9))
		pain_spike(30, "A stabbing pain tears through your abdomen as you move!", "[owner] doubles over, clutching [owner.p_their()] side!", "groan")

/datum/injury/spleen_rupture/process_effects(seconds_per_tick)
	if(treatment_quality >= INJURY_TREATMENT_ADEQUATE)
		return
	if(SPT_PROB(3, seconds_per_tick))
		owner.vomit(VOMIT_CATEGORY_BLOOD, lost_nutrition = 10)

/datum/injury/spleen_rupture/get_visible_signs(mob/user)
	if(!owner || treatment_quality >= INJURY_TREATMENT_ADEQUATE)
		return null
	return span_warning("[owner.p_They()] hold[owner.p_s()] [owner.p_their()] side, bent over and grimacing.")
