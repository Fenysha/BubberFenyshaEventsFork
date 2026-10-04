/datum/injury/internal_bleeding
	name = "Internal Bleeding"
	undiagnosed_name = "internal injury"
	desc = "Bleeding into a body cavity. No external wound may be visible."
	examine_desc = "is pale and deteriorating from internal bleeding"
	series = "internal_bleeding"
	upgrade_path = null
	severity = INJURY_SEVERITY_SEVERE
	visibility = INJURY_VISIBILITY_MEDICAL

	injury_flags = INJURY_FLAG_INTERNAL | INJURY_FLAG_BLEEDING | INJURY_FLAG_PAINFUL | INJURY_FLAG_PROGRESSING

	bleed_rate = 0.45
	pain_amount = 14
	processes = TRUE

	base_healing_rate = 0.004
	base_treat_time = 10 SECONDS
	treatable_by = list(
		/obj/item/stack/medical/medicine/medkit/indusrtial = INJURY_TREATMENT_EFFECTIVENESS_NORMAL,
	)

	COOLDOWN_DECLARE(vomit_cd)

/datum/injury/internal_bleeding/can_apply_to(obj/item/bodypart/target_limb)
	return target_limb.body_zone == BODY_ZONE_CHEST

/datum/injury/internal_bleeding/resolve_treatment_quality(obj/item/tool, mob/user)
	return INJURY_TREATMENT_ADEQUATE

/datum/injury/internal_bleeding/occur_text()
	return "is struck hard, deep tissue tearing beneath the skin"

/datum/injury/internal_bleeding/process_effects(seconds_per_tick)
	if(treatment_quality >= INJURY_TREATMENT_ADEQUATE || get_bleed_rate() < 0.25)
		return
	if(COOLDOWN_FINISHED(src, vomit_cd) && SPT_PROB(1.5 + get_bleed_rate() * 1.5, seconds_per_tick))
		owner.vomit(VOMIT_CATEGORY_BLOOD, lost_nutrition = 10)
		COOLDOWN_START(src, vomit_cd, 8 SECONDS)

/datum/injury/internal_bleeding/get_visible_signs(mob/user)
	if(!owner || treatment_quality >= INJURY_TREATMENT_ADEQUATE || get_bleed_rate() < 0.6)
		return null
	return span_warning("[owner.p_Their()] abdomen is swollen and dark with bruising.")
