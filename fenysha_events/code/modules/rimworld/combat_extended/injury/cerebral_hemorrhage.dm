/datum/injury/cerebral_hemorrhage
	name = "Cerebral Hemorrhage"
	undiagnosed_name = "internal head bleeding"
	desc = "Bleeding inside the skull raises intracranial pressure, compressing and damaging the brain. Symptoms worsen with time."
	examine_desc = "is deteriorating from severe intracranial bleeding"
	series = "cerebral_hemorrhage"
	upgrade_path = null
	severity = INJURY_SEVERITY_CRITICAL
	visibility = INJURY_VISIBILITY_MEDICAL

	injury_flags = INJURY_FLAG_INTERNAL | INJURY_FLAG_BLEEDING | INJURY_FLAG_PAINFUL | INJURY_FLAG_PROGRESSING

	bleed_rate = 1.8
	pain_amount = 34
	processes = TRUE
	disabling = TRUE

	base_healing_rate = 0.004
	base_treat_time = 20 SECONDS

	/// Intracranial pressure, 0..100. Drives the symptom stage.
	var/pressure = 0
	/// Pressure gained per second per unit of bleed rate while untreated.
	var/pressure_gain = 0.35
	/// Pressure lost per second once the bleed is controlled.
	var/pressure_relief = 0.5
	/// Brain damage per second at 100 pressure.
	var/brain_damage_rate = 0.3

/datum/injury/cerebral_hemorrhage/can_apply_to(obj/item/bodypart/target_limb)
	return target_limb.body_zone == BODY_ZONE_HEAD

/datum/injury/cerebral_hemorrhage/resolve_treatment_quality(obj/item/tool, mob/user)
	return INJURY_TREATMENT_ADEQUATE

/datum/injury/cerebral_hemorrhage/occur_text()
	return "takes a blow that rattles the skull"

/// 0 = silent, 1 = headache, 2 = neurological signs, 3 = herniation.
/datum/injury/cerebral_hemorrhage/proc/get_stage()
	if(pressure >= 75)
		return 3
	if(pressure >= 45)
		return 2
	if(pressure >= 15)
		return 1
	return 0

/datum/injury/cerebral_hemorrhage/process_effects(seconds_per_tick)
	if(treatment_quality < INJURY_TREATMENT_ADEQUATE)
		pressure = min(pressure + get_bleed_rate() * pressure_gain * seconds_per_tick, 100)
	else
		pressure = max(pressure - pressure_relief * seconds_per_tick, 0)

	var/stage = get_stage()

	// Irregular, ineffective breathing (Cheyne-Stokes) at the end stage.
	set_lung_modifier(stage >= 3 ? 0.85 : 1)

	if(stage < 1)
		return

	// Stage 1: headache, confusion, blurred vision.
	if(SPT_PROB(8, seconds_per_tick))
		owner.adjust_confusion_up_to(4 SECONDS, 12 SECONDS)
		owner.adjust_eye_blur_up_to(4 SECONDS, 12 SECONDS)
		if(effect_message_ready())
			to_chat(owner, span_warning(pick(
				"A crushing pressure builds behind your eyes.",
				"Your head pounds so hard that you can barely think.",
				"Light stabs at your eyes and the room swims.",
			)))

	if(stage < 2)
		return

	// Stage 2: brain tissue is being compressed.
	var/obj/item/organ/brain/brain = owner.get_organ_slot(ORGAN_SLOT_BRAIN)
	brain?.apply_organ_damage(brain_damage_rate * (pressure / 100) * seconds_per_tick)
	owner.set_slurring_if_lower(6 SECONDS)

	if(SPT_PROB(6, seconds_per_tick))
		bleed_from_head()
	if(SPT_PROB(5, seconds_per_tick))
		owner.vomit(VOMIT_CATEGORY_DEFAULT, lost_nutrition = 10)
	if(SPT_PROB(4, seconds_per_tick))
		owner.apply_consciousness_impulse(60, src)

	if(stage < 3)
		return

	// Stage 3: herniation. Seizures, blackouts, gasping.
	if(SPT_PROB(6, seconds_per_tick))
		seizure()
	if(SPT_PROB(15, seconds_per_tick))
		owner.emote("gasp")

/datum/injury/cerebral_hemorrhage/proc/bleed_from_head()
	if(isturf(owner.loc))
		owner.ce_splatter_at(get_turf(owner), TRUE)
	owner.visible_message(
		span_danger("Blood trickles from [owner]'s [pick("nose", "ear")]."),
		span_userdanger("You feel warm blood run from your [pick("nose", "ear")]."),
	)

/datum/injury/cerebral_hemorrhage/proc/seizure()
	owner.visible_message(
		span_danger("[owner] convulses violently!"),
		span_userdanger("Your body seizes up, thrashing out of your control!"),
	)
	owner.set_jitter_if_lower(10 SECONDS)
	owner.Knockdown(6 SECONDS)
	owner.apply_consciousness_impulse(140, src)

/datum/injury/cerebral_hemorrhage/get_visible_signs(mob/user)
	if(!owner)
		return null
	switch(get_stage())
		if(2)
			return span_warning("[owner.p_Their()] pupils are unequal, and blood seeps from [owner.p_their()] ear.")
		if(3)
			return span_userdanger("[owner.p_They()] twitch[owner.p_es()] and stare[owner.p_s()] blankly, with uneven pupils and blood in [owner.p_their()] ears.")
	return null
