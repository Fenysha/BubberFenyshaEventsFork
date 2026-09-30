/datum/injury/pneumothorax
	name = "Pneumothorax"
	undiagnosed_name = "collapsed lung"
	desc = "Air in the pleural cavity collapsing the lung. Breathing is shallow and painful. Left alone it becomes a tension pneumothorax."
	examine_desc = "is struggling to breathe with a collapsed lung"
	series = "pneumothorax"
	upgrade_path = /datum/injury/pneumothorax/tension
	severity = INJURY_SEVERITY_SEVERE
	visibility = INJURY_VISIBILITY_MEDICAL

	injury_flags = INJURY_FLAG_INTERNAL | INJURY_FLAG_PAINFUL | INJURY_FLAG_PROGRESSING | INJURY_FLAG_ACCEPTS_GAUZE

	pain_amount = 18
	processes = TRUE

	base_healing_rate = 0.006
	base_treat_time = 5 SECONDS

	treatable_by = list(
		/obj/item/stack/medical/medicine/medkit/indusrtial = INJURY_TREATMENT_EFFECTIVENESS_ADEQUATE,
		/obj/item/decompression_needle = INJURY_TREATMENT_EFFECTIVENESS_EXCELLENT,
	)

	/// Fraction of ventilation lost while untreated.
	var/ventilation_penalty = 0.35
	/// Seconds an unsealed pneumothorax needs to turn into a tension pneumothorax.
	var/tension_delay = 5 MINUTES
	var/tension_progress = 0
	var/escalating = FALSE

/datum/injury/pneumothorax/can_apply_to(obj/item/bodypart/target_limb)
	return target_limb.body_zone == BODY_ZONE_CHEST

/datum/injury/pneumothorax/resolve_treatment_quality(obj/item/tool, mob/user)
	if(istype(tool, /obj/item/decompression_needle))
		return INJURY_TREATMENT_EXCELLENT
	return INJURY_TREATMENT_POOR

/datum/injury/pneumothorax/occur_text()
	return "is pierced, and air hisses into the chest"

/datum/injury/pneumothorax/register_effects()
	. = ..()
	update_lung_effects()

/datum/injury/pneumothorax/on_treated(quality, mob/user)
	. = ..()
	update_lung_effects()

/datum/injury/pneumothorax/proc/update_lung_effects()
	set_lung_modifier(1 - scale_by_treatment(ventilation_penalty))

/datum/injury/pneumothorax/on_applied_effects(attack_direction)
	play_effect_sound(INJURY_SOUND_PIERCE, 40)
	owner.emote("gasp")

/datum/injury/pneumothorax/process_effects(seconds_per_tick)
	update_lung_effects()

	// The leak grows until the lung is fully compressed.
	if(upgrade_path && !escalating && treatment_quality < INJURY_TREATMENT_ADEQUATE)
		tension_progress += seconds_per_tick
		if(tension_progress >= tension_delay)
			escalating = TRUE
			// Outside the Life() injury loop: promote() edits owner.all_injuries.
			addtimer(CALLBACK(src, PROC_REF(escalate)), 1)

	if(SPT_PROB(7, seconds_per_tick))
		owner.emote(prob(50) ? "cough" : "gasp")
	if(treatment_quality < INJURY_TREATMENT_ADEQUATE && SPT_PROB(6, seconds_per_tick) && effect_message_ready())
		owner.visible_message(
			span_warning("[owner] takes short, shallow breaths, [owner.p_their()] chest rising unevenly."),
			span_warning("Every breath is shallow, and one side of your chest barely moves."),
		)

/datum/injury/pneumothorax/proc/escalate()
	if(QDELETED(src) || !limb)
		return
	promote(FALSE, null, injury_source)

/datum/injury/pneumothorax/get_visible_signs(mob/user)
	if(!owner || treatment_quality >= INJURY_TREATMENT_ADEQUATE)
		return null
	return span_warning("[owner.p_Their()] chest rises unevenly, and [owner.p_they()] seem to be short of breath.")

/datum/injury/pneumothorax/tension
	name = "Tension Pneumothorax"
	undiagnosed_name = "crushing chest pressure"
	desc = "Tension pneumothorax. Pressure shifts the mediastinum and chokes the circulation; rapid death without decompression."
	examine_desc = "is cyanotic and gasping with a rigid chest"
	upgrade_path = null
	severity = INJURY_SEVERITY_CRITICAL

	pain_amount = 30
	disabling = TRUE

	base_healing_rate = 0.01
	base_treat_time = 4 SECONDS
	// Needle decompression is only way to survive tension pneumothorax.
	treatable_by = list(
		/obj/item/decompression_needle = INJURY_TREATMENT_EFFECTIVENESS_EXCELLENT,
	)
	treatable_tools = list(TOOL_SCALPEL)

	ventilation_penalty = 0.85

/datum/injury/pneumothorax/tension/resolve_treatment_quality(obj/item/tool, mob/user)
	if(istype(tool, /obj/item/decompression_needle))
		return INJURY_TREATMENT_EXCELLENT
	if((tool.tool_behaviour == TOOL_SCALPEL) && rw_has_skill(user, RW_SKILL_MEDICAL, 10))
		return INJURY_TREATMENT_POOR
	return INJURY_TREATMENT_NONE

/datum/injury/pneumothorax/tension/occur_text()
	return "swells tight as air is trapped in the chest"

/datum/injury/pneumothorax/tension/process_effects(seconds_per_tick)
	update_lung_effects()
	if(treatment_quality >= INJURY_TREATMENT_ADEQUATE)
		return

	// Obstructive shock: the trapped air squeezes the heart's venous return.
	owner.apply_shock_impulse(scale_by_treatment(1) * 20 * seconds_per_tick, src)

	if(SPT_PROB(30, seconds_per_tick))
		owner.emote("gasp")
	if(SPT_PROB(6, seconds_per_tick) && effect_message_ready())
		owner.visible_message(
			span_userdanger("[owner] gasps desperately, [owner.p_their()] lips turning blue!"),
			span_userdanger("You can't breathe! Your chest feels like it's about to burst!"),
		)

/datum/injury/pneumothorax/tension/get_visible_signs(mob/user)
	if(!owner || treatment_quality >= INJURY_TREATMENT_ADEQUATE)
		return null
	return span_userdanger("[owner] is gasping frantically. [owner.p_Their()] lips are blue-grey and [owner.p_their()] chest is rigid.")
