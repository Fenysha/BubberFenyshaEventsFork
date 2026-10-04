#ifndef OLD_COMBAT_SYSTEM
/mob/living/carbon/proc/get_medical_multiplier(list/modifiers)
	if(!length(modifiers))
		return 1.0
	var/result = 1.0
	for(var/source in modifiers)
		var/value = modifiers[source]
		if(isnum(value))
			result *= value
	return max(result, 0)

/mob/living/carbon/proc/get_medical_limit(list/limits, default_limit)
	if(!length(limits))
		return default_limit
	var/result = default_limit
	for(var/source in limits)
		var/value = limits[source]
		if(isnum(value))
			result = min(result, value)
	return max(result, 0)


/mob/living/carbon/proc/recalculate_medical_modifiers()
	pain_mod = get_medical_multiplier(pain_modifiers)
	shock_mod = get_medical_multiplier(shock_modifiers)
	consciousness_mod = get_medical_multiplier(consciousness_modifiers)
	shock_recovery_mod = get_medical_multiplier(shock_recovery_modifiers)
	consciousness_recovery_mod = get_medical_multiplier(consciousness_recovery_modifiers)
	pain_limit = get_medical_limit(pain_limit_modifiers, PAIN_MAX)
	shock_limit = get_medical_limit(shock_limit_modifiers, SHOCK_MAX)
	recalculate_medical_state()

/mob/living/carbon/proc/set_pain_modifier(source, multiplier)
	if(isnull(source))
		return
	LAZYSET(pain_modifiers, source, max(multiplier, 0))
	recalculate_medical_modifiers()

/mob/living/carbon/proc/remove_pain_modifier(source)
	LAZYREMOVE(pain_modifiers, source)
	recalculate_medical_modifiers()

/mob/living/carbon/proc/set_shock_modifier(source, multiplier)
	if(isnull(source))
		return
	LAZYSET(shock_modifiers, source, max(multiplier, 0))
	recalculate_medical_modifiers()

/mob/living/carbon/proc/remove_shock_modifier(source)
	LAZYREMOVE(shock_modifiers, source)
	recalculate_medical_modifiers()

/mob/living/carbon/proc/set_consciousness_modifier(source, multiplier)
	if(isnull(source))
		return
	LAZYSET(consciousness_modifiers, source, max(multiplier, 0))
	recalculate_medical_modifiers()

/mob/living/carbon/proc/remove_consciousness_modifier(source)
	LAZYREMOVE(consciousness_modifiers, source)
	recalculate_medical_modifiers()

/mob/living/carbon/proc/set_shock_recovery_modifier(source, multiplier)
	if(isnull(source))
		return
	LAZYSET(shock_recovery_modifiers, source, max(multiplier, 0))
	recalculate_medical_modifiers()

/mob/living/carbon/proc/remove_shock_recovery_modifier(source)
	LAZYREMOVE(shock_recovery_modifiers, source)
	recalculate_medical_modifiers()

/mob/living/carbon/proc/set_consciousness_recovery_modifier(source, multiplier)
	if(isnull(source))
		return
	LAZYSET(consciousness_recovery_modifiers, source, max(multiplier, 0))
	recalculate_medical_modifiers()

/mob/living/carbon/proc/remove_consciousness_recovery_modifier(source)
	LAZYREMOVE(consciousness_recovery_modifiers, source)
	recalculate_medical_modifiers()

/mob/living/carbon/proc/set_pain_limit(source, limit)
	if(isnull(source))
		return
	LAZYSET(pain_limit_modifiers, source, max(limit, 0))
	recalculate_medical_modifiers()

/mob/living/carbon/proc/remove_pain_limit(source)
	LAZYREMOVE(pain_limit_modifiers, source)
	recalculate_medical_modifiers()

/mob/living/carbon/proc/set_shock_limit(source, limit)
	if(isnull(source))
		return
	LAZYSET(shock_limit_modifiers, source, max(limit, 0))
	recalculate_medical_modifiers()

/mob/living/carbon/proc/remove_shock_limit(source)
	LAZYREMOVE(shock_limit_modifiers, source)
	recalculate_medical_modifiers()

/mob/living/carbon/proc/set_pain(new_pain)
	pain_base = max(new_pain, 0)
	recalculate_medical_state()

/mob/living/carbon/proc/adjust_pain(amount)
	// pain_base is rebuilt from limbs; non-injury pain lives in its own variable.
	pain_misc = max(pain_misc + amount, 0)
	recalculate_medical_state()

/mob/living/carbon/proc/update_pain_from_limb(obj/item/bodypart/source_limb)
	var/total = 0
	for(var/obj/item/bodypart/BP as anything in bodyparts)
		total += BP.current_pain
	set_pain(total)

/mob/living/carbon/proc/apply_acute_pain(amount)
	if(amount <= 0)
		return
	acute_pain = clamp(acute_pain + amount, 0, PAIN_MAX * 2)
	recalculate_medical_state()

/mob/living/carbon/proc/apply_shock_impulse(amount, source = null)
	if(amount <= 0)
		return
	shock_base = clamp(shock_base + amount, 0, SHOCK_MAX * 2)
	recalculate_medical_state()

/// Knocks consciousness down immediately (it then recovers at CONSCIOUSNESS_RISE_RATE).
/mob/living/carbon/proc/apply_consciousness_impulse(amount, source = null)
	if(amount <= 0 || stat == DEAD)
		return
	consciousness = max(consciousness - amount * consciousness_mod, 0)
	update_blackout_state()

/mob/living/carbon/proc/apply_combat_impact_response(damage, body_zone, damage_type = BRUTE, source = null)
	if(damage <= 0 || stat == DEAD)
		return

	var/impact = max(damage - IMPACT_PAIN_THRESHOLD, 0)
	if(impact <= 0)
		return

	var/zone_shock_mult = IMPACT_LIMB_MULT
	var/zone_pain_mult = IMPACT_LIMB_MULT
	var/zone_consciousness_mult = IMPACT_LIMB_MULT

	switch(body_zone)
		if(BODY_ZONE_HEAD)
			zone_shock_mult = IMPACT_HEAD_MULT
			zone_pain_mult = IMPACT_HEAD_MULT
			zone_consciousness_mult = IMPACT_HEAD_MULT
		if(BODY_ZONE_CHEST)
			zone_shock_mult = IMPACT_CHEST_MULT
			zone_pain_mult = IMPACT_CHEST_MULT
			zone_consciousness_mult = IMPACT_CHEST_MULT

	if(damage_type == BURN)
		zone_consciousness_mult *= 0.35
		zone_shock_mult *= 0.60

	// High single-instance trauma produces disproportionately more shock
	// (super-linear above ~25 damage) to model kinetic energy transfer.
	var/shock_scale = IMPACT_SHOCK_MULT
	if(impact >= 25)
		shock_scale *= 1.0 + (impact - 25) * 0.018
	if(impact >= 45)
		shock_scale *= 1.25

	apply_acute_pain(impact * IMPACT_PAIN_MULT * zone_pain_mult)
	apply_shock_impulse((impact ** 0.95) * shock_scale * zone_shock_mult, source)

	var/consciousness_impulse = (max(damage - IMPACT_CONSCIOUSNESS_THRESHOLD, 0) ** 1.20) \
		* IMPACT_CONSCIOUSNESS_MULT * zone_consciousness_mult
	if(impact >= 40)
		consciousness_impulse *= 1.35
	if(consciousness_impulse > 0)
		apply_consciousness_impulse(consciousness_impulse, source)

/mob/living/carbon/proc/apply_injury_response(datum/injury/injury)
	if(!injury || stat == DEAD)
		return
	var/shock_impulse = injury.get_initial_shock()
	var/consciousness_impulse = injury.get_initial_consciousness_impact()
	if(shock_impulse > 0)
		apply_shock_impulse(shock_impulse, injury)
	if(consciousness_impulse > 0)
		apply_consciousness_impulse(consciousness_impulse, injury)


/**
 * Health still aggregates limb brute/burn + oxy/tox for HUD and death threshold.
 * Soft/hard crit from health % are disabled — incapacity comes from consciousness.
 */
/mob/living/carbon/updatehealth()
	if(HAS_TRAIT(src, TRAIT_GODMODE))
		return

	var/total_burn = 0
	var/total_brute = 0
	for(var/obj/item/bodypart/BP as anything in get_bodyparts())
		total_brute += (BP.brute_dam * BP.body_damage_coeff)
		total_burn += (BP.burn_dam * BP.body_damage_coeff)

	set_health(round(maxHealth - get_tox_loss() - total_burn - total_brute, DAMAGE_PRECISION))
	update_stat()
	update_stamina()

	var/husk_threshold = get_bodypart(BODY_ZONE_CHEST)?.max_damage * -1
	if(husk_threshold && ((maxHealth - total_burn) < husk_threshold) && stat == DEAD)
		become_husk(BURN)

	med_hud_set_health()
	// Softcrit movespeed removed — pain/shock modifiers handle mobility
	remove_movespeed_modifier(/datum/movespeed_modifier/carbon_softcrit)
	SEND_SIGNAL(src, COMSIG_LIVING_HEALTH_UPDATE)

/**
 * Death still from lethal health / traits.
 * No SOFT_CRIT / HARD_CRIT from health thresholds.
 * Unconscious is applied by update_blackout_state() (hysteresis, see carbon_life.dm).
 */
/mob/living/carbon/update_stat()
	if(HAS_TRAIT(src, TRAIT_GODMODE))
		return

	if(stat == DEAD)
		update_damage_hud()
		update_health_hud()
		update_stamina_hud()
		med_hud_set_status()
		return

	if(consciousness_blackout)
		if(stat < SOFT_CRIT)
			set_stat(SOFT_CRIT)
	else if(stat == SOFT_CRIT || stat == HARD_CRIT)
		if(!IsUnconscious() && !HAS_TRAIT(src, TRAIT_KNOCKEDOUT))
			set_stat(STABLE)

	update_damage_hud()
	update_health_hud()
	update_stamina_hud()
	med_hud_set_status()


/mob/living/carbon/update_blood_effects()
	. = ..()

	update_blood_pallor()
	update_blood_colorgrade()


/mob/living/carbon/proc/update_blood_pallor()
	if(!CAN_HAVE_BLOOD(src))
		set_blood_pallor(0)
		return

	var/blood_ratio = get_blood_ratio()

	var/pallor = 0
	if(blood_ratio < BLOOD_PALLOR_START)
		pallor = clamp(
			(BLOOD_PALLOR_START - blood_ratio) / (BLOOD_PALLOR_START - BLOOD_PALLOR_FULL),
			0,
			1
		)

	// Don't rebuild all bodypart overlays for microscopic changes.
	pallor = round(pallor, 0.025)

	if(abs(pallor - blood_pallor_visual) < 0.025)
		return

	blood_pallor_visual = pallor
	set_blood_pallor(pallor)

/mob/living/carbon/proc/set_blood_pallor(pallor)
	for(var/obj/item/bodypart/bodypart as anything in get_bodyparts())
		bodypart.remove_color_override(BLOOD_PALLOR_COLOR_PRIORITY)

		// Static-colored bodyparts don't have a greyscale draw color
		// that can safely be recolored through this mechanism.
		if(!bodypart.should_draw_greyscale)
			bodypart.update_limb()
			continue

		// Restore the original highest-priority color first.
		bodypart.update_draw_color()

		if(pallor <= 0)
			bodypart.update_limb()
			continue

		var/base_color = bodypart.draw_color

		if(!base_color)
			base_color = COLOR_WHITE

		var/pale_color = blend_color(
			base_color,
			rgb(255, 255, 255, round(pallor * 255))
		)

		bodypart.add_color_override(
			pale_color,
			BLOOD_PALLOR_COLOR_PRIORITY
		)

		bodypart.update_limb()


/mob/living/carbon/proc/update_blood_colorgrade()
	if(!hud_used)
		return

	if(!CAN_HAVE_BLOOD(src))
		apply_blood_colorgrade(0)
		return

	var/blood_ratio = get_blood_ratio()

	var/strength = 0
	if(blood_ratio < BLOOD_COLORGRADE_START)
		strength = clamp(
			(BLOOD_COLORGRADE_START - blood_ratio) / (BLOOD_COLORGRADE_START - BLOOD_COLORGRADE_FULL),
			0,
			1
		)

	strength = round(strength, 0.025)

	if(abs(strength - blood_colorgrade_visual) < 0.025)
		return

	blood_colorgrade_visual = strength
	apply_blood_colorgrade(strength)


/mob/living/carbon/proc/apply_blood_colorgrade(strength)
	if(!hud_used)
		return

	var/list/masters = hud_used.get_true_plane_masters(RENDER_PLANE_MASTER)

	for(var/atom/movable/screen/plane_master/rendering_plate/master as anything in masters)
		if(strength <= 0)
			master.remove_filter("blood_loss_colorgrade")
			continue

		/*
		 * HSL color grading:
		 *
		 * - Hue is untouched.
		 * - Saturation decreases as blood is lost.
		 * - Lightness increases slightly.
		 *
		 * This pushes the screen toward white/grey without turning
		 * red objects into neutral grey.
		 */
		var/saturation = 1 - (0.65 * strength)
		var/lightness = 1 + (0.10 * strength)

		var/matrix/matrix = list(
			1, 0, 0,
			0, saturation, 0,
			0, 0, lightness,
			0, 0, 0
		)

		master.add_filter("blood_loss_colorgrade", 10, color_matrix_filter(matrix, FILTER_COLOR_HSL))


/mob/living/carbon/proc/append_blood_loss_examine(mob/user, list/examine_list)
	if(!user || !CAN_HAVE_BLOOD(src))
		return

	var/blood_ratio = get_blood_ratio()

	switch(blood_ratio)
		if(BLOOD_PALLOR_START to INFINITY)
			return

		if(0.65 to BLOOD_PALLOR_START)
			examine_list += span_warning("[p_They()] look pale.")
		if(0.50 to 0.65)
			examine_list += span_warning("[p_They()] look pale and clammy.")
		if(0.35 to 0.50)
			examine_list += span_danger("[p_They()] are extremely pale and visibly weakened.")
		if(-INFINITY to 0.35)
			examine_list += span_userdanger("[p_They()] are deathly pale, with almost no color left in [p_their()] skin.")


/**
 * Damage HUD: pain/oxy focused; no softcrit vision ladder from health.
 */
/mob/living/carbon/update_damage_hud()
	if(!client)
		return

	clear_fullscreen("crit")
	clear_fullscreen("critvision")

	var/total_consciousness = get_consciousness()
	// Oxygen overlay — keep
	if(total_consciousness < 100)
		var/severity = 0
		switch(total_consciousness)
			if(0 to 20)
				severity = 7
			if(20 to 30)
				severity = 6
			if(30 to 40)
				severity = 5
			if(40 to 50)
				severity = 4
			if(50 to 65)
				severity = 3
			if(65 to 80)
				severity = 2
			if(80 to INFINITY)
				severity = 1
		overlay_fullscreen("consciousness", /atom/movable/screen/fullscreen/oxy, severity)
	else
		clear_fullscreen("consciousness")

	// Brute/burn + pain bleed into the same overlay channel
	var/total_pain = get_pain()
	if(total_pain)
		var/severity = 0
		switch(total_pain)
			if(10 to 40)
				severity = 1
			if(40 to 70)
				severity = 2
			if(70 to 90)
				severity = 3
			if(90 to 110)
				severity = 4
			if(110 to 140)
				severity = 5
			if(140 to INFINITY)
				severity = 6
		overlay_fullscreen("pain", /atom/movable/screen/fullscreen/brute, severity)
	else
		clear_fullscreen("pain")

/**
 * Heal wounds flag also clears injuries.
 * Resets medical base values so the next recalculate does not restore old state.
 */
/mob/living/carbon/fully_heal(heal_flags = HEAL_ALL)
	. = ..()

	if(heal_flags & HEAL_WOUNDS)
		for(var/datum/injury/injury as anything in all_injuries.Copy())
			injury.remove_from_limb()
			qdel(injury)

	if(heal_flags & HEAL_DAMAGE)
		pain_base = 0
		pain_misc = 0
		acute_pain = 0
		shock_base = 0
		consciousness_stun = 0
		pain = 0
		shock = 0
		consciousness = CONSCIOUSNESS_MAX
		consciousness_blackout = FALSE
		total_bleed_rate = 0
		remove_movespeed_modifier(/datum/movespeed_modifier/pain)
		reset_circulation()
		update_stat()


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

/mob/living/carbon/proc/get_cause_of_death()
	var/obj/item/organ/heart/heart = get_organ_slot(ORGAN_SLOT_HEART)
	var/obj/item/organ/lungs/lungs = get_organ_slot(ORGAN_SLOT_LUNGS)
	if(!get_organ_slot(ORGAN_SLOT_BRAIN))
		return "destruction of the brain"
	if(needs_heart() && (!heart || !heart.is_beating()))
		return "cardiac arrest leading to cerebral hypoxia"
	if(get_blood_ratio() < 0.6)
		return "exsanguination (hypovolemic shock)"
	if(lungs && lungs.fluid >= LUNG_FLUID_SEVERE)
		return "pulmonary edema / drowning"
	if(blood_oxygenation < 40)
		return "asphyxiation"
	return "cerebral hypoxia"

/mob/living/carbon/proc/reset_circulation()
	blood_pressure = BP_NORMAL
	blood_oxygenation = 100
	var/obj/item/organ/brain/brain = get_organ_slot(ORGAN_SLOT_BRAIN)
	brain?.oxygen = BRAIN_O2_MAX
	var/obj/item/organ/heart/heart = get_organ_slot(ORGAN_SLOT_HEART)
	heart?.reset_rhythm()
	var/obj/item/organ/lungs/lungs = get_organ_slot(ORGAN_SLOT_LUNGS)
	lungs?.fluid = 0


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
	return clamp(consc * arms_factor * (0.4 + 0.6 * global_pen), 0, 1)

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
