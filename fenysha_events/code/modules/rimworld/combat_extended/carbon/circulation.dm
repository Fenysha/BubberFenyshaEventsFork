#ifndef OLD_COMBAT_SYSTEM
/// Fraction of normal blood volume, 0..1.2
/mob/living/carbon/proc/get_blood_ratio()
	return clamp(get_blood_volume() / BLOOD_VOLUME_NORMAL, 0, 1.2)

/// Heart rate (0 if the heart is stopped or not required).
/mob/living/carbon/proc/get_heart_rate()
	var/obj/item/organ/heart/heart = get_organ_slot(ORGAN_SLOT_HEART)
	if(!needs_heart())
		return HEART_RATE_NORMAL
	return heart ? heart.get_rate() : 0

/// Brain oxygen (0 if no brain).
/mob/living/carbon/proc/get_brain_oxygen()
	var/obj/item/organ/brain/brain = get_organ_slot(ORGAN_SLOT_BRAIN)
	return brain ? brain.oxygen : 0

/mob/living/carbon/proc/update_blood_pressure()
	var/output = 1
	if(needs_heart())
		var/obj/item/organ/heart/heart = get_organ_slot(ORGAN_SLOT_HEART)
		output = heart ? heart.get_cardiac_output() : 0
	blood_pressure = round(BP_NORMAL * output * (get_blood_ratio() ** 1.5), 0.1)

/// 0..1.2: how well the brain is being supplied with blood.
/mob/living/carbon/proc/get_brain_perfusion()
	if(blood_pressure <= BP_PERFUSION_NONE)
		return 0
	if(blood_pressure >= BP_PERFUSION_MIN)
		return clamp(blood_pressure / BP_NORMAL, PERFUSION_SYNCOPE, 1.2)
	return clamp((blood_pressure - BP_PERFUSION_NONE) / (BP_PERFUSION_MIN - BP_PERFUSION_NONE), 0, 1) * PERFUSION_SYNCOPE

/mob/living/carbon/proc/handle_lungless_oxygenation(seconds_per_tick)
	if(HAS_TRAIT(src, TRAIT_NOBREATH))
		blood_oxygenation = 100
		return
	if(get_organ_slot(ORGAN_SLOT_LUNGS))
		return
	blood_oxygenation = max(blood_oxygenation - LUNG_GAS_EXCHANGE_DOWN * seconds_per_tick, 0)

/mob/living/carbon/proc/reset_circulation()
	blood_pressure = BP_NORMAL
	blood_oxygenation = 100
	var/obj/item/organ/brain/brain = get_organ_slot(ORGAN_SLOT_BRAIN)
	brain?.oxygen = BRAIN_O2_MAX
	var/obj/item/organ/heart/heart = get_organ_slot(ORGAN_SLOT_HEART)
	heart?.reset_rhythm()
	var/obj/item/organ/lungs/lungs = get_organ_slot(ORGAN_SLOT_LUNGS)
	lungs?.fluid = 0
#endif
