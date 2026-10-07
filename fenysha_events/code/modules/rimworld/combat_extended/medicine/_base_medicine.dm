/obj/item/stack/medical/medicine
	name = "medical supplies"
	singular_name = "medical supply"
	desc = "Medical supplies used to directly treat injuries."
	merge_type = /obj/item/stack/medical/medicine
	apply_verb = "treating"

	icon = 'icons/obj/medical/stack_medical.dmi'
	/// Base treatment effectiveness before the user's Medical skill is applied.
	/// 1.0 is a normal treatment, below 1.0 is poor, above 1.0 is better.
	var/treatment_effectiveness = 1.0

	/// Medical skill used to scale treatment effectiveness.
	var/medical_skill = RW_SKILL_MEDICAL

	/// Minimum Medical skill required to use this item's skill scaling.
	/// A value of 0 means anyone can use it.
	var/min_medical_skill = 0

	/// Additional treatment effectiveness gained per skill level.
	/// At 0.025, level 20 gives +50% effectiveness.
	var/skill_effectiveness_per_level = 0.025

	/// Upper cap for the skill multiplier. 1.5 = maximum +50% from skill.
	var/max_skill_effectiveness_multiplier = 1.5

	/// Skill level at which treatment takes its expected duration.
	var/ideal_medical_skill = RW_SKILL_MANUAL_MAX

	/// Absolute minimum treatment duration.
	var/minimum_treatment_delay = 0

	/// Time expected at the ideal Medical skill when treating yourself.
	var/treatment_self_delay = 5 SECONDS

	/// Time expected at the ideal Medical skill when treating someone else.
	var/treatment_other_delay = 2 SECONDS

	/// XP awarded after a successful treatment action.
	var/medical_skill_xp = RW_SKILL_POINTS_SMALL

	// The inherited medical loop performs the interaction and consumption.
	// Its own delays are disabled because the skill-aware delay is handled below.
	self_delay = 0
	other_delay = 0


	/// This item treats injuries directly, so raw medical-item healing values
	/// are deliberately disabled on this branch.
	heal_brute = 0
	heal_burn = 0
	stop_bleeding = 0
	sanitization = 0
	flesh_regeneration = 0

/obj/item/stack/medical/medicine/proc/get_medical_skill(mob/living/user)
	if(!user)
		return 0
	return RW_GET_SKILL(user, medical_skill)

/obj/item/stack/medical/medicine/proc/get_treatment_effectiveness(mob/living/user)
	var/skill_level = get_medical_skill(user)
	if(skill_level < min_medical_skill)
		return 0

	var/skill_multiplier = 1 + (skill_level * skill_effectiveness_per_level)
	skill_multiplier = clamp(skill_multiplier, 1, max_skill_effectiveness_multiplier)
	return max(treatment_effectiveness, 0) * skill_multiplier

/obj/item/stack/medical/medicine/proc/get_treatable_injury(mob/living/carbon/patient, healed_zone, mob/living/user)
	if(!patient)
		return

	var/obj/item/bodypart/limb = patient.get_bodypart(healed_zone)
	if(!limb)
		return

	var/effectiveness = get_treatment_effectiveness(user)
	if(effectiveness <= 0)
		return

	var/datum/injury/best_injury
	for(var/datum/injury/injury as anything in limb.injuries)
		if(!injury || QDELETED(injury))
			continue
		if(!injury.can_be_treated_by_medicine(effectiveness))
			continue

		if(!best_injury)
			best_injury = injury
			continue

		// Prefer untreated injuries first, then the more severe one.
		if(injury.treatment_effectiveness < best_injury.treatment_effectiveness)
			best_injury = injury
		else if(injury.treatment_effectiveness == best_injury.treatment_effectiveness && injury.severity > best_injury.severity)
			best_injury = injury

	return best_injury

/obj/item/stack/medical/medicine/try_heal_checks(mob/living/patient, mob/living/user, healed_zone, silent = FALSE)
	if(!(healed_zone in patient.get_all_limbs()))
		healed_zone = BODY_ZONE_CHEST

	if(!can_heal(patient, user, healed_zone, silent))
		return FALSE

	if(!works_on_dead && patient.stat == DEAD)
		if(!silent)
			patient.balloon_alert(user, "[patient.p_theyre()] dead!")
		return FALSE

	if(!iscarbon(patient))
		if(!silent)
			patient.balloon_alert(user, "injury treatment requires a carbon patient!")
		return FALSE

	var/mob/living/carbon/carbon_patient = patient
	var/obj/item/bodypart/affecting = carbon_patient.get_bodypart(healed_zone)
	if(!affecting)
		if(!silent)
			carbon_patient.balloon_alert(user, "no [parse_zone(healed_zone)]!")
		return FALSE

	if(!IS_ORGANIC_LIMB(affecting))
		if(!silent)
			carbon_patient.balloon_alert(user, "[affecting.plaintext_zone] is not organic!")
		return FALSE

	var/datum/injury/injury = get_treatable_injury(carbon_patient, healed_zone, user)
	if(!injury)
		if(!silent)
			carbon_patient.balloon_alert(user, "no treatable injuries on [affecting.plaintext_zone]!")
		return FALSE

	return TRUE

/obj/item/stack/medical/medicine/proc/can_treat_injury(
		mob/living/carbon/patient,
		mob/living/user,
		healed_zone,
		datum/injury/injury
	)
	if(!patient || !user || !injury || QDELETED(injury))
		return FALSE

	if(injury.owner != patient)
		return FALSE

	var/obj/item/bodypart/limb = patient.get_bodypart(healed_zone)
	if(!limb || injury.limb != limb)
		return FALSE

	return injury.can_be_treated_by_medicine(get_treatment_effectiveness(user))

/obj/item/stack/medical/medicine/proc/heal_injury(mob/living/carbon/patient, mob/living/user, healed_zone)
	var/datum/injury/injury = get_treatable_injury(patient, healed_zone, user)
	if(!injury)
		return FALSE

	var/effectiveness = get_treatment_effectiveness(user)
	if(effectiveness <= 0)
		return FALSE

	var/expected_delay = (patient == user ? treatment_self_delay : treatment_other_delay)
	var/interaction_key = "medical_treatment-[REF(injury)]"

	if(!rw_do_after(
		user,
		expected_delay,
		patient,
		medical_skill,
		ideal_medical_skill,
		minimum_treatment_delay,
		medical_skill_xp,
		extra_checks = CALLBACK(src, PROC_REF(can_treat_injury), patient, user, healed_zone, injury),
		interaction_key = interaction_key,
	))
		return FALSE

	var/obj/item/bodypart/limb = patient.get_bodypart(healed_zone)
	if(!injury.treat_with_medicine(user, effectiveness))
		return FALSE

	patient.visible_message(
		span_green("[user] treats [patient]'s [limb?.plaintext_zone] with [src]."),
		span_green("You treat [patient]'s [limb?.plaintext_zone] with [src]."),
		visible_message_flags = ALWAYS_SHOW_SELF_MESSAGE,
	)

	return TRUE

/obj/item/stack/medical/medicine/heal_carbon(mob/living/carbon/patient, mob/living/user, healed_zone)
	return heal_injury(patient, user, healed_zone)

/obj/item/stack/medical/medicine/heal_simplemob(mob/living/patient, mob/living/user)
	return FALSE

/obj/item/stack/medical/medicine/suicide_act(mob/living/user)
	return BRUTELOSS
