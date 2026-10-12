#ifndef OLD_COMBAT_SYSTEM

/datum/movespeed_modifier/rw_thermal
	variable = TRUE
	id = "rw_thermal"

/datum/injury/thermal
	name = "Thermal stress"
	// Temperature conditions affect the whole body, not only the limb they are attached to.
	ui_body_zone = "all"
	series = "thermal"
	severity = INJURY_SEVERITY_MINOR
	injury_flags = INJURY_FLAG_INTERNAL
	processes = TRUE
	// Core temperature injuries do not heal by themselves.
	base_healing_rate = 0
	/// Added to the owner's movement delay.
	var/slowdown = 0
	/// Multiplier on consciousness (1 = none).
	var/consciousness_mult = 1
	/// Oxygen-equivalent organ damage per second (only critical stages).
	var/organ_failure_rate = 0
	var/modifier_key = "rw_thermal"

/datum/injury/thermal/register_effects()
	. = ..()
	apply_thermal_effects()

/datum/injury/thermal/unregister_effects(replaced = FALSE)
	clear_thermal_effects()
	return ..()

/datum/injury/thermal/proc/apply_thermal_effects()
	if(!owner)
		return
	if(slowdown)
		owner.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/rw_thermal, multiplicative_slowdown = slowdown)
	if(consciousness_mult < 1)
		owner.set_consciousness_modifier(modifier_key, consciousness_mult)

/datum/injury/thermal/proc/clear_thermal_effects()
	var/mob/living/carbon/target = effects_owner || owner
	if(!target)
		return
	target.remove_movespeed_modifier(/datum/movespeed_modifier/rw_thermal)
	target.remove_consciousness_modifier(modifier_key)

/datum/injury/thermal/process_effects(seconds_per_tick)
	if(organ_failure_rate > 0 && owner && owner.stat != DEAD)
		owner.apply_damage(organ_failure_rate * seconds_per_tick, OXY)


/datum/injury/hypothermia
	parent_type = /datum/injury/thermal
	name = "Mild Hypothermia"
	undiagnosed_name = "shivering"
	desc = "Core temperature is slightly low. Shivering, numb fingers."
	examine_desc = "is shivering"
	series = RW_SERIES_HYPOTHERMIA
	upgrade_path = /datum/injury/hypothermia/moderate
	severity = INJURY_SEVERITY_MINOR
	pain_amount = 2
	slowdown = 0.1
	consciousness_mult = 0.95
	modifier_key = "rw_hypothermia"

/datum/injury/hypothermia/occur_text()
	return "starts to shiver"

/datum/injury/hypothermia/process_effects(seconds_per_tick)
	. = ..()
	if(!owner || owner.stat == DEAD || !effect_message_ready(25 SECONDS))
		return
	to_chat(owner, span_warning("You shiver and your hands feel stiff."))

/datum/injury/hypothermia/moderate
	name = "Moderate Hypothermia"
	undiagnosed_name = "violent shivering"
	desc = "Core temperature is low. Clumsy, slow, confused."
	examine_desc = "is shivering violently"
	upgrade_path = /datum/injury/hypothermia/severe
	severity = INJURY_SEVERITY_MODERATE
	pain_amount = 6
	slowdown = 0.3
	consciousness_mult = 0.8
	injury_flags = INJURY_FLAG_INTERNAL | INJURY_FLAG_PAINFUL

/datum/injury/hypothermia/moderate/occur_text()
	return "goes numb with cold"

/datum/injury/hypothermia/moderate/get_visible_signs(mob/user)
	if(!owner)
		return null
	return span_warning("[owner.p_They()] [owner.p_are()] shaking from the cold.")

/datum/injury/hypothermia/severe
	name = "Severe Hypothermia"
	undiagnosed_name = "blue lips"
	desc = "Dangerously low core temperature. Shivering stops, thinking slows."
	examine_desc = "has blue lips and a blank stare"
	upgrade_path = /datum/injury/hypothermia/critical
	severity = INJURY_SEVERITY_SEVERE
	pain_amount = 10
	slowdown = 0.6
	consciousness_mult = 0.55
	injury_flags = INJURY_FLAG_INTERNAL | INJURY_FLAG_PAINFUL

/datum/injury/hypothermia/severe/occur_text()
	return "is dangerously cold"

/datum/injury/hypothermia/severe/get_visible_signs(mob/user)
	if(!owner)
		return null
	return span_danger("[owner.p_Their()] lips are blue and [owner.p_their()] movements are sluggish.")

/datum/injury/hypothermia/critical
	name = "Critical Hypothermia"
	undiagnosed_name = "frozen stillness"
	desc = "Core temperature is lethal. Heart and breathing are failing."
	examine_desc = "is barely moving, skin icy to the touch"
	upgrade_path = null
	severity = INJURY_SEVERITY_CRITICAL
	pain_amount = 4 // too cold to feel it
	slowdown = 1.2
	consciousness_mult = 0.25
	organ_failure_rate = 0.6
	injury_flags = INJURY_FLAG_INTERNAL

/datum/injury/hypothermia/critical/occur_text()
	return "has gone limp from the cold"

/datum/injury/hypothermia/critical/get_visible_signs(mob/user)
	if(!owner)
		return null
	return span_userdanger("[owner.p_They()] [owner.p_are()] almost motionless and ice cold.")


/datum/injury/heatstroke
	parent_type = /datum/injury/thermal
	name = "Heat Exhaustion"
	undiagnosed_name = "flushed skin"
	desc = "Core temperature is high. Sweating, headache."
	examine_desc = "is flushed and sweating"
	series = RW_SERIES_HEATSTROKE
	upgrade_path = /datum/injury/heatstroke/moderate
	severity = INJURY_SEVERITY_MINOR
	pain_amount = 3
	slowdown = 0.1
	consciousness_mult = 0.95
	modifier_key = "rw_heatstroke"

/datum/injury/heatstroke/occur_text()
	return "starts to overheat"

/datum/injury/heatstroke/process_effects(seconds_per_tick)
	. = ..()
	if(!owner || owner.stat == DEAD || !effect_message_ready(25 SECONDS))
		return
	to_chat(owner, span_warning("You are drenched in sweat and your head throbs."))

/datum/injury/heatstroke/moderate
	name = "Moderate Heatstroke"
	undiagnosed_name = "dizziness"
	desc = "Core temperature is dangerously high."
	examine_desc = "is red-faced and swaying"
	upgrade_path = /datum/injury/heatstroke/severe
	severity = INJURY_SEVERITY_MODERATE
	pain_amount = 7
	slowdown = 0.3
	consciousness_mult = 0.8
	injury_flags = INJURY_FLAG_INTERNAL | INJURY_FLAG_PAINFUL

/datum/injury/heatstroke/severe
	name = "Severe Heatstroke"
	undiagnosed_name = "confusion"
	desc = "Organs begin to suffer from the heat."
	examine_desc = "is confused and burning up"
	upgrade_path = /datum/injury/heatstroke/critical
	severity = INJURY_SEVERITY_SEVERE
	pain_amount = 12
	slowdown = 0.6
	consciousness_mult = 0.55
	organ_failure_rate = 0.2
	injury_flags = INJURY_FLAG_INTERNAL | INJURY_FLAG_PAINFUL

/datum/injury/heatstroke/critical
	name = "Critical Heatstroke"
	undiagnosed_name = "collapse"
	desc = "Lethal core temperature. Organ failure."
	examine_desc = "is collapsing from the heat"
	upgrade_path = null
	severity = INJURY_SEVERITY_CRITICAL
	pain_amount = 6
	slowdown = 1.2
	consciousness_mult = 0.25
	organ_failure_rate = 0.7
	injury_flags = INJURY_FLAG_INTERNAL


/datum/injury/frostbite
	name = "Frostnip"
	undiagnosed_name = "pale numb skin"
	desc = "Skin and shallow tissue are starting to freeze."
	examine_desc = "has pale, waxy skin"
	series = RW_SERIES_FROSTBITE
	upgrade_path = /datum/injury/frostbite/severe
	severity = INJURY_SEVERITY_MODERATE
	injury_flags = INJURY_FLAG_EXTERNAL | INJURY_FLAG_PAINFUL | INJURY_FLAG_ACCEPTS_GAUZE | INJURY_FLAG_SELF_HEALING
	pain_amount = 8
	damage_multiplier = 1.1
	base_healing_rate = 0.004
	base_treat_time = 4 SECONDS
	treatable_by = list(
		/obj/item/stack/medical/medicine/medkit/crude = INJURY_TREATMENT_EFFECTIVENESS_POOR,
		/obj/item/stack/medical/medicine/gauze = INJURY_TREATMENT_EFFECTIVENESS_NORMAL,
		/obj/item/stack/medical/medicine/medkit/indusrtial = INJURY_TREATMENT_EFFECTIVENESS_EXCELLENT,
	)

/datum/injury/frostbite/resolve_treatment_quality(obj/item/tool, mob/user)
	if(istype(tool, /obj/item/stack/medical/mesh))
		return INJURY_TREATMENT_EXCELLENT
	if(istype(tool, /obj/item/stack/medical/ointment))
		return INJURY_TREATMENT_ADEQUATE
	return INJURY_TREATMENT_POOR

/datum/injury/frostbite/occur_text()
	return "goes numb and white with cold"

/// Frostbite does not heal while the limb is still being frozen.
/datum/injury/frostbite/process_healing(seconds_per_tick)
	var/mob/living/carbon/human/H = owner
	if(istype(H) && limb && H.rw_frost_exposure?[limb.body_zone] > 0)
		return
	return ..()

/datum/injury/frostbite/get_visible_signs(mob/user)
	return get_untreated_sign()

/datum/injury/frostbite/severe
	name = "Frostbite"
	undiagnosed_name = "blackening skin"
	desc = "Deep tissue is frozen. Blisters, dark patches."
	examine_desc = "has blistered, blackening skin"
	upgrade_path = /datum/injury/frostbite/necrotic
	severity = INJURY_SEVERITY_SEVERE
	// Too deep to close on its own: needs a dressing.
	injury_flags = INJURY_FLAG_EXTERNAL | INJURY_FLAG_PAINFUL | INJURY_FLAG_ACCEPTS_GAUZE
	pain_amount = 18
	damage_multiplier = 1.25
	interaction_penalty = 1.5
	limp_slowdown = 1
	limp_chance = 25
	base_healing_rate = 0.003
	base_treat_time = 6 SECONDS

/datum/injury/frostbite/severe/occur_text()
	return "blisters and darkens from frostbite"

/datum/injury/frostbite/necrotic
	name = "Necrotic Frostbite"
	undiagnosed_name = "dead black tissue"
	desc = "The tissue is dead. The limb is useless and may need amputation."
	examine_desc = "is black and dead"
	upgrade_path = null
	severity = INJURY_SEVERITY_CRITICAL
	injury_flags = INJURY_FLAG_EXTERNAL | INJURY_FLAG_DISABLING | INJURY_FLAG_ACCEPTS_GAUZE
	pain_amount = 10 // dead nerves
	damage_multiplier = 1.4
	disabling = TRUE
	interaction_penalty = 3.0
	dismemberment_weight = 25
	base_healing_rate = 0.001
	base_treat_time = 9 SECONDS

/datum/injury/frostbite/necrotic/occur_text()
	return "has frozen solid and died"
#endif
