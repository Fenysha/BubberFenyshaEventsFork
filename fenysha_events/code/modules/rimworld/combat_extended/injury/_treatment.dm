/**
 * Returns the bleeding multiplier produced by continuous skill-based treatment.
 * Higher treatment effectiveness means less active bleeding.
 */
/datum/injury/proc/get_bleed_treatment_multiplier()
	return clamp(1 - (treatment_effectiveness * 0.75), 0.10, 1.0)

/**
 * Returns the healing multiplier produced by continuous skill-based treatment.
 * This deliberately scales continuously instead of using only treatment tiers.
 */
/datum/injury/proc/get_healing_treatment_multiplier()
	return 1 + (treatment_effectiveness * 2.0)

/**
 * Returns the pain multiplier produced by continuous skill-based treatment.
 */
/datum/injury/proc/get_pain_treatment_multiplier()
	return clamp(1 - (treatment_effectiveness * 0.50), 0.20, 1.0)

/**
 * Returns TRUE if skill-based medicine can still improve this injury.
 */
/datum/injury/proc/can_be_treated_by_medicine(effectiveness)
	if(effectiveness <= 0)
		return FALSE
	if(treatment_effectiveness >= effectiveness)
		return FALSE
	return TRUE

/**
 * Applies continuous treatment directly to this injury.
 *
 * Unlike the legacy item treatment path, this does not collapse the result
 * into a discrete quality tier. The medicine effectiveness and the user's
 * Medical skill determine the actual treatment strength.
 */
/datum/injury/proc/treat_with_medicine(mob/living/user, effectiveness)
	if(!can_be_treated_by_medicine(effectiveness))
		return FALSE

	treatment_effectiveness = max(treatment_effectiveness, effectiveness)

	// Keep the existing treatment-quality field useful for old UI and systems.
	var/new_quality = INJURY_TREATMENT_POOR
	if(effectiveness >= INJURY_TREATMENT_EFFECTIVENESS_EXCELLENT)
		new_quality = INJURY_TREATMENT_EXCELLENT
	else if(effectiveness >= INJURY_TREATMENT_EFFECTIVENESS_ADEQUATE)
		new_quality = INJURY_TREATMENT_ADEQUATE

	if(new_quality > treatment_quality)
		treatment_quality = new_quality

	// Use the normal treatment hook so healing processing is enabled.
	on_treated(treatment_quality, user)
	processes = TRUE

	if(owner && !HAS_TRAIT(owner, TRAIT_GODMODE) && user)
		to_chat(owner, span_notice("The treatment improves the condition of your [name]."))

	limb?.update_injuries()
	return TRUE

/datum/injury/proc/try_treat(obj/item/tool, mob/living/user)
	if(!item_can_treat(tool, user))
		return FALSE
	return treat(tool, user)

/datum/injury/proc/get_item_treatment_effectiveness(obj/item/tool)
	if(!tool)
		return 0

	if(length(treatable_tools) && (tool.tool_behaviour in treatable_tools))
		return INJURY_TREATMENT_EFFECTIVENESS_NORMAL

	if(!length(treatable_by))
		return 0

	for(var/typepath in treatable_by)
		if(!istype(tool, typepath))
			continue

		var/effectiveness = treatable_by[typepath]
		if(isnull(effectiveness))
			return INJURY_TREATMENT_EFFECTIVENESS_NORMAL

		return max(0, effectiveness)

	return 0

/datum/injury/proc/item_can_treat(obj/item/tool, mob/user)
	if(treatment_quality >= INJURY_TREATMENT_EXCELLENT)
		return FALSE
	return get_item_treatment_effectiveness(tool) > 0

/**
 * Default treatment implementation.
 * Subtypes may override for special behaviour (surgery steps, etc.).
 */
/datum/injury/proc/treat(obj/item/tool, mob/user)
	if(!can_be_treated_by(tool, user))
		return FALSE

	var/quality = resolve_treatment_quality(tool, user)

	if(!do_after(user, base_treat_time, target = owner || user))
		return FALSE

	if(apply_treatment(quality, user))
		if(isstack(tool))
			var/obj/item/stack/stack_tool = tool
			stack_tool.use(1)
		return TRUE
	return FALSE

/datum/injury/proc/can_be_treated_by(obj/item/tool, mob/user)
	return item_can_treat(tool, user)

/**
 * Determines treatment quality from tool and (optionally) user skill.
 * Override or extend later for skill-based quality.
 */
/datum/injury/proc/resolve_treatment_quality(obj/item/tool, mob/user)
	var/effectiveness = get_item_treatment_effectiveness(tool)
	if(effectiveness >= INJURY_TREATMENT_EFFECTIVENESS_EXCELLENT)
		return INJURY_TREATMENT_EXCELLENT
	if(effectiveness >= INJURY_TREATMENT_EFFECTIVENESS_ADEQUATE)
		return INJURY_TREATMENT_ADEQUATE
	if(effectiveness >= INJURY_TREATMENT_EFFECTIVENESS_POOR)
		return INJURY_TREATMENT_POOR
	return INJURY_TREATMENT_NONE

/**
 * Applies treatment of the given quality. Improves multipliers and enables healing.
 * Returns TRUE if quality was actually improved.
 */
/datum/injury/proc/apply_treatment(quality = INJURY_TREATMENT_ADEQUATE, mob/user)
	if(quality <= treatment_quality)
		return FALSE

	treatment_quality = quality
	on_treated(quality, user)
	limb?.update_injuries()
	return TRUE

/**
 * Sets bleed/heal/pain multipliers according to treatment quality
 * and ensures the injury is processed for healing.
 */
/datum/injury/proc/on_treated(quality, mob/user)
	switch(quality)
		if(INJURY_TREATMENT_POOR)
			treated_bleed_mult = 0.55
			treated_heal_mult  = 1.4
			treated_pain_mult  = 0.85
		if(INJURY_TREATMENT_ADEQUATE)
			treated_bleed_mult = 0.25
			treated_heal_mult  = 2.2
			treated_pain_mult  = 0.65
		if(INJURY_TREATMENT_EXCELLENT)
			treated_bleed_mult = 0.08
			treated_heal_mult  = 3.5
			treated_pain_mult  = 0.45
		else
			treated_bleed_mult = 1.0
			treated_heal_mult  = 1.0
			treated_pain_mult  = 1.0

	// Treatment enables healing processing
	if(base_healing_rate > 0 || (injury_flags & INJURY_FLAG_SELF_HEALING))
		processes = TRUE

	if(owner && !HAS_TRAIT(owner, TRAIT_GODMODE) && user)
		to_chat(owner, span_notice("The treatment eases the pain of your [name]."))
