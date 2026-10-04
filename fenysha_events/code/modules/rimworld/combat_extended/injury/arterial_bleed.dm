/datum/injury/arterial_bleed
	name = "Arterial Bleeding"
	undiagnosed_name = "spurting blood"
	desc = "An artery has been damaged. Blood is spurting under pressure."
	examine_desc = "is spurting arterial blood"
	series = "arterial_bleed"
	upgrade_path = null
	severity = INJURY_SEVERITY_CRITICAL

	injury_flags = INJURY_FLAG_EXTERNAL | INJURY_FLAG_BLEEDING | INJURY_FLAG_PAINFUL | INJURY_FLAG_ACCEPTS_GAUZE | INJURY_FLAG_ACCEPTS_SUTURE | INJURY_FLAG_PROGRESSING

	bleed_rate = 1.6
	pain_amount = 28
	processes = TRUE

	// Never closes by itself: healing only starts once treated.
	base_healing_rate = 0.01
	base_treat_time = 6 SECONDS
	treatable_by = list(
		/obj/item/stack/medical/medicine/medkit/crude = INJURY_TREATMENT_EFFECTIVENESS_POOR,
		/obj/item/stack/medical/medicine/gauze = INJURY_TREATMENT_EFFECTIVENESS_NORMAL,
		/obj/item/stack/medical/medicine/suture = INJURY_TREATMENT_EFFECTIVENESS_ADEQUATE,
		/obj/item/stack/medical/medicine/medkit/indusrtial = INJURY_TREATMENT_EFFECTIVENESS_EXCELLENT,
	)
	treatable_tools = list(TOOL_CAUTERY)

	/// Untreated arterial bleeding keeps worsening up to this rate.
	var/max_bleed_rate = 2.3

	COOLDOWN_DECLARE(spurt_cd)

/datum/injury/arterial_bleed/resolve_treatment_quality(obj/item/tool, mob/user)
	// Gauze only applies pressure; the vessel itself needs closing.
	if(tool.tool_behaviour == TOOL_CAUTERY)
		return INJURY_TREATMENT_EXCELLENT
	if(istype(tool, /obj/item/stack/medical/suture))
		return INJURY_TREATMENT_ADEQUATE
	return INJURY_TREATMENT_POOR

/datum/injury/arterial_bleed/occur_text()
	return "erupts in a spray of arterial blood"

/datum/injury/arterial_bleed/on_applied_effects(attack_direction)
	hit_spray(attack_direction, 3, 3)
	play_effect_sound(INJURY_SOUND_BLOOD, 60)

/datum/injury/arterial_bleed/process_effects(seconds_per_tick)
	// Treatment stops the escalation, then the normal healing takes over.
	if(treatment_quality == INJURY_TREATMENT_NONE && bleed_rate > 0.5 && bleed_rate < max_bleed_rate)
		bleed_rate = min(bleed_rate + 0.03 * seconds_per_tick, max_bleed_rate)

	// Stitches or a good pressure dressing turn spray into a seep.
	var/rate = get_bleed_rate()
	var/heart_rate = owner.get_heart_rate()
	if(rate < 0.5 || heart_rate <= 0 || treatment_quality >= INJURY_TREATMENT_ADEQUATE || !isturf(owner.loc))
		return

	if(!COOLDOWN_FINISHED(src, spurt_cd))
		return

	// Spray is pulsatile, but gated by cooldown so it doesn't spam every tick.
	var/pulses = clamp(round(heart_rate / 50), 1, 3)
	var/reach = clamp(round(rate * 0.7), 1, 3)
	var/spacing = (seconds_per_tick * 10) / pulses
	for(var/i in 0 to pulses - 1)
		addtimer(CALLBACK(src, PROC_REF(spurt), reach), round(i * spacing))

	COOLDOWN_START(src, spurt_cd, 1.8 SECONDS)

/// One jet of arterial blood. Bursts out in random directions, not just one.
/datum/injury/arterial_bleed/proc/spurt(reach)
	if(QDELETED(src) || QDELETED(owner) || !limb || owner.stat == DEAD || !isturf(owner.loc))
		return
	var/jets = clamp(round(reach / 1.5) + 1, 1, 3)
	for(var/i in 1 to jets)
		owner.ce_spray_blood(pick(GLOB.alldirs), rand(1, reach))
	for(var/mob/living/nearby in orange(1, owner))
		if(prob(35))
			nearby.add_mob_blood(owner)
	play_effect_sound(INJURY_SOUND_BLOOD, 40, 1 SECONDS)
	if(effect_message_ready(8 SECONDS))
		owner.visible_message(
			span_danger("Blood spurts from [owner]'s [limb.plaintext_zone] in [jets > 1 ? "powerful jets" : "a jet"]!"),
			span_userdanger("Blood pulses out of your [limb.plaintext_zone] with every heartbeat!"),
		)

/datum/injury/arterial_bleed/get_visible_signs(mob/user)
	if(!owner || !limb || treatment_quality >= INJURY_TREATMENT_ADEQUATE)
		return null
	return span_danger("Blood is spurting from [owner.p_their()] [limb.plaintext_zone]!")
