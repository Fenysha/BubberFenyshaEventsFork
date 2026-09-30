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



/obj/item/stack/medical/medicine/medkit
	name = "medical kit"
	singular_name = "medical kit"
	desc = "A compact medical kit containing supplies for treating common injuries."
	icon_state = "brutepack"


	amount = 1
	max_amount = 1
	treatment_effectiveness = INJURY_TREATMENT_EFFECTIVENESS_NORMAL
	treatment_self_delay = 8 SECONDS
	treatment_other_delay = 5 SECONDS
	medical_skill_xp = RW_SKILL_POINTS_SMALL
	merge_type = /obj/item/stack/medical/medicine/medkit

/obj/item/stack/medical/medicine/medkit/crude
	name = "crude medical kit"
	singular_name = "crude medical kit"
	icon_state = "brutepack"


	desc = "A crude collection of improvised medical supplies."
	treatment_effectiveness = INJURY_TREATMENT_EFFECTIVENESS_POOR
	treatment_self_delay = 10 SECONDS
	treatment_other_delay = 6 SECONDS
	medical_skill_xp = RW_SKILL_POINTS_TINY
	merge_type = /obj/item/stack/medical/medicine/medkit/crude

/obj/item/stack/medical/medicine/medkit/indusrtial
	name = "industrial medical kit"
	singular_name = "industrial medical kit"
	desc = "A rugged medical kit intended for treating injuries in industrial environments."
	icon_state = "brutepack"

	treatment_effectiveness = 1.15
	treatment_self_delay = 7 SECONDS
	treatment_other_delay = 4 SECONDS
	medical_skill_xp = RW_SKILL_POINTS_SMALL
	merge_type = /obj/item/stack/medical/medicine/medkit/indusrtial

/obj/item/stack/medical/medicine/medkit/indusrtial/glitertech
	name = "glittertech medical kit"
	singular_name = "glittertech medical kit"
	desc = "An advanced medical kit using highly refined medical technology."
	icon_state = "brutepack"

	treatment_effectiveness = 1.35
	treatment_self_delay = 5 SECONDS
	treatment_other_delay = 3 SECONDS
	medical_skill_xp = RW_SKILL_POINTS_NORMAL
	merge_type = /obj/item/stack/medical/medicine/medkit/indusrtial/glitertech

/obj/item/stack/medical/medicine/gauze
	name = "medical gauze"
	singular_name = "medical gauze"
	desc = "Sterile gauze used to dress and stabilize wounds."
	icon_state = "brutepack"

	amount = 6
	max_amount = 12
	treatment_effectiveness = INJURY_TREATMENT_EFFECTIVENESS_ADEQUATE
	treatment_self_delay = 5 SECONDS
	treatment_other_delay = 3 SECONDS
	medical_skill_xp = RW_SKILL_POINTS_TINY
	merge_type = /obj/item/stack/medical/medicine/gauze
	apply_verb = "bandaging"

/obj/item/stack/medical/medicine/suture
	name = "suture"
	singular_name = "suture"
	desc = "Sterile sutures used to close and stabilize wounds."
	icon_state = "brutepack"

	gender = PLURAL
	amount = 10
	max_amount = 10
	treatment_effectiveness = INJURY_TREATMENT_EFFECTIVENESS_NORMAL
	treatment_self_delay = 4 SECONDS
	treatment_other_delay = 2 SECONDS
	medical_skill_xp = RW_SKILL_POINTS_SMALL
	merge_type = /obj/item/stack/medical/medicine/suture
	apply_verb = "suturing"

/obj/item/stack/medical/medicine/bruise_pack
	name = "bruise pack"
	singular_name = "bruise pack"
	desc = "A therapeutic pack designed to treat blunt-force injuries."
	icon_state = "brutepack"

	amount = 6
	max_amount = 6
	treatment_effectiveness = INJURY_TREATMENT_EFFECTIVENESS_NORMAL
	treatment_self_delay = 5 SECONDS
	treatment_other_delay = 3 SECONDS
	medical_skill_xp = RW_SKILL_POINTS_SMALL
	merge_type = /obj/item/stack/medical/medicine/bruise_pack

/obj/item/stack/medical/medicine/bone_gel
	name = "bone gel"
	singular_name = "bone gel"
	desc = "A medical gel designed to assist the repair of damaged bone."
	icon_state = "brutepack"

	amount = 5
	max_amount = 5
	treatment_effectiveness = INJURY_TREATMENT_EFFECTIVENESS_EXCELLENT
	treatment_self_delay = 8 SECONDS
	treatment_other_delay = 5 SECONDS
	medical_skill_xp = RW_SKILL_POINTS_NORMAL
	merge_type = /obj/item/stack/medical/medicine/bone_gel

/obj/item/decompression_needle
	name = "decompression needle"
	desc = "A large-bore needle used to rapidly decompress the chest."

/obj/item/chest_drain
	name = "chest drain"
	desc = "A drainage tube used to evacuate air or fluid from the chest."
