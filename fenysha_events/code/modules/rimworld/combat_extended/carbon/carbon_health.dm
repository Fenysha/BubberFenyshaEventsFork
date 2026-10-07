#ifndef OLD_COMBAT_SYSTEM
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
#endif
