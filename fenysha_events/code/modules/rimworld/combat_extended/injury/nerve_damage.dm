/datum/injury/nerve_damage
	name = "Nerve Damage"
	undiagnosed_name = "nerve damage"
	desc = "Significant damage to the peripheral nerves."
	examine_desc = "has damaged nerves"
	series = "nerve_damage"
	upgrade_path = /datum/injury/nerve_damage/critical
	severity = INJURY_SEVERITY_SEVERE

	injury_flags = INJURY_FLAG_INTERNAL | INJURY_FLAG_PAINFUL | INJURY_FLAG_SELF_HEALING

	pain_amount = 20
	interaction_penalty = 1.8
	limp_slowdown = 2
	limp_chance = 40

	// Nerves regenerate very slowly (~10 minutes), surgical repair speeds this up.
	base_healing_rate = 0.0015
	base_treat_time = 10 SECONDS

	treatable_by = list(
		/obj/item/stack/medical/medicine/medkit/crude = INJURY_TREATMENT_EFFECTIVENESS_POOR,
		/obj/item/stack/medical/medicine/medkit/indusrtial = INJURY_TREATMENT_EFFECTIVENESS_EXCELLENT,
	)

/datum/injury/nerve_damage/resolve_treatment_quality(obj/item/tool, mob/user)
	return INJURY_TREATMENT_ADEQUATE

/datum/injury/nerve_damage/occur_text()
	return "goes numb and twitches"

/datum/injury/nerve_damage/critical
	name = "Critical Nerve Damage"
	undiagnosed_name = "destroyed nerves"
	desc = "The nerves are critically damaged or severed."
	examine_desc = "has critically damaged nerves"
	upgrade_path = null
	severity = INJURY_SEVERITY_CRITICAL

	// Severed nerves do not reconnect without surgical intervention.
	injury_flags = INJURY_FLAG_INTERNAL | INJURY_FLAG_PAINFUL | INJURY_FLAG_DISABLING

	pain_amount = 30
	disabling = TRUE
	interaction_penalty = 3.0

	base_healing_rate = 0.002
	base_treat_time = 15 SECONDS


/datum/injury/nerve_damage
	processes = TRUE
	COOLDOWN_DECLARE(misfire_cd)
	COOLDOWN_DECLARE(leg_giveout_cd)

/datum/injury/nerve_damage/register_effects()
	// Legs misfire while walking; arms misfire on their own (see process_effects).
	reacts_to_movement = is_leg()
	return ..()

/datum/injury/nerve_damage/process_effects(seconds_per_tick)
	if(treatment_quality >= INJURY_TREATMENT_ADEQUATE || !COOLDOWN_FINISHED(src, misfire_cd) || !SPT_PROB(2.5, seconds_per_tick))
		return
	if(is_arm())
		if(!drop_limb_item("goes numb and the grip fails"))
			if(effect_message_ready())
				to_chat(owner, span_warning("Pins and needles crawl through your [limb.plaintext_zone]."))
	else if(effect_message_ready())
		owner.visible_message(span_warning("[owner]'s [limb.plaintext_zone] twitches uncontrollably."), span_warning("Your [limb.plaintext_zone] twitches and tingles."))
	COOLDOWN_START(src, misfire_cd, 4 SECONDS)

/datum/injury/nerve_damage/on_owner_moved(movement_dir)
	if(!owner || owner.stat == DEAD || owner.body_position == LYING_DOWN || treatment_quality >= INJURY_TREATMENT_ADEQUATE)
		return
	if(!COOLDOWN_FINISHED(src, leg_giveout_cd) || !prob(limp_chance * 0.12))
		return
	owner.visible_message(span_warning("[owner]'s [limb.plaintext_zone] gives out under [owner.p_them()]!"), span_userdanger("Your [limb.plaintext_zone] stops responding for a moment!"))
	owner.Knockdown(1.5 SECONDS)
	COOLDOWN_START(src, leg_giveout_cd, 3 SECONDS)

/datum/injury/nerve_damage/critical/get_visible_signs(mob/user)
	if(!owner || !limb || treatment_quality >= INJURY_TREATMENT_ADEQUATE)
		return null
	return span_warning("[owner.p_Their()] [limb.plaintext_zone] hangs limp and unresponsive.")
