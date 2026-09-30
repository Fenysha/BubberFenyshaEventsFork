/datum/injury/rib_fracture
	name = "Rib Fracture"
	undiagnosed_name = "broken ribs"
	desc = "One or more ribs are fractured. Breathing is painful, and every step risks a bone fragment cutting an organ."
	examine_desc = "has broken ribs"
	series = "rib_fracture"
	upgrade_path = /datum/injury/rib_fracture/flail
	severity = INJURY_SEVERITY_SEVERE
	reacts_to_movement = TRUE

	injury_flags = INJURY_FLAG_INTERNAL | INJURY_FLAG_PAINFUL | INJURY_FLAG_ACCEPTS_GAUZE | INJURY_FLAG_SELF_HEALING

	pain_amount = 20
	interaction_penalty = 1.3

	base_healing_rate = 0.0012
	base_treat_time = 6 SECONDS
	// Binding the chest or bone gel keeps the fragments still.
	treatable_by = list(
		/obj/item/stack/medical/medicine/medkit/crude = INJURY_TREATMENT_EFFECTIVENESS_POOR,
		/obj/item/stack/medical/medicine/bone_gel = INJURY_TREATMENT_EFFECTIVENESS_NORMAL,
		/obj/item/stack/medical/medicine/medkit/indusrtial = INJURY_TREATMENT_EFFECTIVENESS_EXCELLENT,
	)

	/// Chance (%) per step that a shifting rib hits an organ.
	var/organ_hit_chance = 12
	var/organ_damage_min = 2
	var/organ_damage_max = 5
	/// Acute pain when a rib shifts.
	var/movement_pain = 22
	/// Chance (%) that a hit on the lungs also punctures them (pneumothorax).
	var/lung_puncture_chance = 10
	/// Relative odds of the heart being the organ that gets hit.
	var/heart_weight = 0.5
	/// Fraction of ventilation lost to painful, restricted breathing.
	var/ventilation_penalty = 0.10

/datum/injury/rib_fracture/can_apply_to(obj/item/bodypart/target_limb)
	return target_limb.body_zone == BODY_ZONE_CHEST

/datum/injury/rib_fracture/resolve_treatment_quality(obj/item/tool, mob/user)
	if(istype(tool, /obj/item/stack/medical/bone_gel))
		return INJURY_TREATMENT_EXCELLENT
	return INJURY_TREATMENT_ADEQUATE

/datum/injury/rib_fracture/occur_text()
	return "cracks sickeningly"


/datum/injury/rib_fracture/register_effects()
	. = ..()
	update_lung_effects()

/datum/injury/rib_fracture/on_treated(quality, mob/user)
	. = ..()
	update_lung_effects()

/datum/injury/rib_fracture/proc/update_lung_effects()
	set_lung_modifier(1 - scale_by_treatment(ventilation_penalty))

/datum/injury/rib_fracture/on_applied_effects(attack_direction)
	play_effect_sound(INJURY_SOUND_BONE_CRACK, 70)
	owner.emote("gasp")

/datum/injury/rib_fracture/process_effects(seconds_per_tick)
	// Re-sync in case the lungs were replaced.
	update_lung_effects()

/// Moving with broken ribs: a fragment may shift and cut whatever is behind it.
/datum/injury/rib_fracture/on_owner_moved(movement_dir)
	if(!owner || !limb || owner.stat == DEAD || owner.body_position == LYING_DOWN)
		return
	var/chance = scale_by_treatment(organ_hit_chance)
	if(owner.move_intent == MOVE_INTENT_RUN)
		chance *= 1.6
	if(prob(chance))
		hurt_organ()

/datum/injury/rib_fracture/proc/hurt_organ()
	var/list/candidates = list()
	for(var/obj/item/organ/candidate in limb)
		if(candidate.organ_flags & ORGAN_EXTERNAL)
			continue
		if(istype(candidate, /obj/item/organ/lungs))
			candidates[candidate] = 3
		else if(istype(candidate, /obj/item/organ/heart))
			candidates[candidate] = heart_weight
		else
			candidates[candidate] = 1
	if(!length(candidates))
		return

	var/obj/item/organ/target = pick_weight(candidates)
	var/damage = rand(organ_damage_min, organ_damage_max)
	if(owner.move_intent == MOVE_INTENT_RUN)
		damage *= 1.5
	target.apply_organ_damage(damage)

	pain_spike(
		movement_pain,
		"A broken rib shifts and jabs into your [target.name]!",
		"[owner] gasps and clutches [owner.p_their()] chest!",
		"gasp",
	)

	// Punctured lung: air leaks into the pleural space.
	if(istype(target, /obj/item/organ/lungs) && prob(lung_puncture_chance) && !limb.find_injury_series("pneumothorax"))
		limb.apply_generated_injury(/datum/injury/pneumothorax, null, "broken rib")

/datum/injury/rib_fracture/get_visible_signs(mob/user)
	if(!owner || treatment_quality >= INJURY_TREATMENT_ADEQUATE)
		return null
	return span_warning("[owner.p_Their()] chest looks deformed and moves in short, guarded breaths.")

/datum/injury/rib_fracture/flail
	name = "Flail Chest"
	undiagnosed_name = "caved-in chest"
	desc = "Multiple rib fractures with paradoxical chest wall motion. Respiratory failure risk, and organs are badly exposed to bone fragments."
	examine_desc = "has a section of chest wall moving independently"
	upgrade_path = null
	severity = INJURY_SEVERITY_CRITICAL

	// Too unstable to knit on its own.
	injury_flags = INJURY_FLAG_INTERNAL | INJURY_FLAG_PAINFUL | INJURY_FLAG_ACCEPTS_GAUZE

	pain_amount = 40
	disabling = TRUE
	processes = TRUE

	base_healing_rate = 0.002
	base_treat_time = 10 SECONDS

	treatable_by = list(
		/obj/item/stack/medical/medicine/medkit/indusrtial = INJURY_TREATMENT_EFFECTIVENESS_ADEQUATE,
	)

	organ_hit_chance = 30
	organ_damage_min = 4
	organ_damage_max = 8
	movement_pain = 38
	lung_puncture_chance = 25
	heart_weight = 2
	ventilation_penalty = 0.35

/datum/injury/rib_fracture/flail/occur_text()
	return "caves in under the blow"

/datum/injury/rib_fracture/flail/on_applied_effects(attack_direction)
	play_effect_sound(INJURY_SOUND_BONE_CRACK, 80)
	owner.emote("scream")

/datum/injury/rib_fracture/flail/process_effects(seconds_per_tick)
	..()
	if(treatment_quality < INJURY_TREATMENT_ADEQUATE && SPT_PROB(8, seconds_per_tick) && effect_message_ready())
		owner.visible_message(
			span_danger("[owner]'s chest wall sucks inward with every breath!"),
			span_userdanger("Part of your chest collapses inward every time you try to breathe!"),
		)

/datum/injury/rib_fracture/flail/get_visible_signs(mob/user)
	if(!owner || treatment_quality >= INJURY_TREATMENT_ADEQUATE)
		return null
	return span_userdanger("[owner.p_Their()] chest wall is caved in and moves against every breath!")
