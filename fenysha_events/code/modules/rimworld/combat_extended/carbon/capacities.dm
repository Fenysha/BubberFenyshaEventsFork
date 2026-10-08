#ifndef OLD_COMBAT_SYSTEM
// ---------------------------------------------------------------------------
// RimWorld-style capacity getters
// All return 0.0 .. 1.0 (or slightly above for healthy overdrive).
// Used by work speed, movement, AI, medical UI, etc.
// ---------------------------------------------------------------------------

/// Overall consciousness factor (0 = blacked out, 1 = fully awake).
/mob/living/carbon/proc/get_consciousness_capacity()
	if(stat == DEAD || consciousness_blackout)
		return 0
	return clamp(consciousness / CONSCIOUSNESS_MAX, 0, 1)

/// Pain level as a capacity penalty (1 = no pain, 0 = max pain).
/mob/living/carbon/proc/get_pain_capacity()
	return clamp(1 - (pain / PAIN_MAX), 0, 1)

/// Shock level as a capacity penalty.
/mob/living/carbon/proc/get_shock_capacity()
	return clamp(1 - (shock / SHOCK_MAX), 0, 1)

/// Blood pumping / circulatory efficiency (heart + blood volume + pressure).
/mob/living/carbon/proc/get_blood_pumping()
	if(!CAN_HAVE_BLOOD(src))
		return 1
	var/obj/item/organ/heart/heart = get_organ_slot(ORGAN_SLOT_HEART)
	var/heart_factor = 1
	if(needs_heart())
		if(!heart || !heart.is_beating())
			return 0
		// Rough damage scaling; healthy heart = 1
		heart_factor = clamp(1 - (heart.damage / max(heart.maxHealth, 1)) * 0.85, 0.15, 1.1)
	var/volume_factor = clamp(get_blood_ratio(), 0, 1.15)
	var/pressure_factor = clamp(blood_pressure / BP_NORMAL, 0, 1.2)
	return clamp(heart_factor * volume_factor * pressure_factor, 0, 1.2)

/// Breathing / gas exchange capacity.
/mob/living/carbon/proc/get_breathing_capacity()
	if(HAS_TRAIT(src, TRAIT_NOBREATH))
		return 1
	var/obj/item/organ/lungs/lungs = get_organ_slot(ORGAN_SLOT_LUNGS)
	if(!lungs)
		return 0
	var/damage_factor = clamp(1 - (lungs.damage / max(lungs.maxHealth, 1)), 0.1, 1)
	var/fluid_factor = 1 - clamp(lungs.fluid / LUNG_FLUID_MAX, 0, 1) * 0.9
	var/ox_factor = clamp(blood_oxygenation / 100, 0, 1)
	return clamp(damage_factor * fluid_factor * ox_factor, 0, 1)

/// Manipulation / arm work capacity. Depends on consciousness + both arms.
/mob/living/carbon/proc/get_manipulation_capacity()
	var/consc = get_consciousness_capacity()
	if(consc <= 0)
		return 0

	var/arm_score = 0
	var/arm_count = 0
	for(var/zone in list(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM))
		var/obj/item/bodypart/arm = get_bodypart(zone)
		arm_count++
		if(!arm)
			continue
		// Missing = 0 contribution
		var/integrity = arm.get_physical_integrity()
		// Disabling injuries kill the arm
		var/disabled = arm.bodypart_disabled || HAS_TRAIT_FROM(arm, TRAIT_PARALYSIS, null)
		if(disabled)
			integrity *= 0.05
		// Pain on the arm further reduces usability
		var/arm_pain_pen = clamp(arm.current_pain / 40, 0, 0.7)
		integrity *= (1 - arm_pain_pen)
		arm_score += clamp(integrity, 0, 1)

	// Two healthy arms = 1.0; one arm max ~0.55; no arms = 0
	var/arms_factor = (arm_count > 0) ? (arm_score / arm_count) * (0.55 + 0.45 * (arm_score / max(arm_count, 1))) : 0
	// Global pain & shock also hinder fine motor control
	var/global_pen = min(get_pain_capacity(), get_shock_capacity())
	return clamp(consc * arms_factor * (0.4 + 0.6 * global_pen) * get_rw_manipulation_mult(), 0, 1.25)

/// Moving / locomotion capacity. Legs + consciousness + pain.
/mob/living/carbon/proc/get_moving_capacity()
	var/consc = get_consciousness_capacity()
	if(consc <= 0)
		return 0

	var/leg_score = 0
	var/leg_count = 0
	for(var/zone in list(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG))
		var/obj/item/bodypart/leg = get_bodypart(zone)
		leg_count++
		if(!leg)
			continue
		var/integrity = leg.get_physical_integrity()
		var/disabled = leg.bodypart_disabled || HAS_TRAIT_FROM(leg, TRAIT_PARALYSIS, null)
		if(disabled)
			integrity *= 0.05
		// Limp / injury slowdowns are already applied via movespeed modifiers;
		// here we only care about raw capability.
		leg_score += clamp(integrity, 0, 1)

	var/legs_factor = (leg_count > 0) ? (leg_score / leg_count) : 0
	// One leg still allows crawling / hopping at reduced speed
	if(leg_score > 0 && leg_score < 1.5)
		legs_factor = max(legs_factor, 0.25)

	var/pain_pen = get_pain_capacity()
	var/shock_pen = get_shock_capacity()
	return clamp(consc * legs_factor * (0.35 + 0.65 * min(pain_pen, shock_pen)), 0, 1)

/// Overall work / labor capacity (RimWorld "Work Speed" analogue).
/// Combines consciousness, manipulation, and general pain/shock.
/mob/living/carbon/proc/get_work_capacity()
	var/consc = get_consciousness_capacity()
	if(consc <= 0.05)
		return 0
	var/manip = get_manipulation_capacity()
	var/pain_pen = get_pain_capacity()
	var/shock_pen = get_shock_capacity()
	// Breathing & circulation soft-cap long-term work
	var/phys = min(get_breathing_capacity(), get_blood_pumping())
	return clamp(consc * manip * (0.5 + 0.5 * min(pain_pen, shock_pen)) * (0.6 + 0.4 * phys), 0, 1)

/// Sight capacity (eyes + consciousness). Simple version.
/mob/living/carbon/proc/get_sight_capacity()
	var/consc = get_consciousness_capacity()
	if(consc <= 0)
		return 0
	// Placeholder: full implementation would inspect eye organs / injuries
	return clamp(consc * get_pain_capacity(), 0, 1)

/// Talking / social capacity.
/mob/living/carbon/proc/get_talking_capacity()
	var/consc = get_consciousness_capacity()
	if(consc <= 0.15)
		return 0
	// Jaw / facial trauma would reduce this further
	return clamp(consc * get_shock_capacity(), 0, 1)
#endif
