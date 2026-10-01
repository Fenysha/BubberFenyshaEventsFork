#ifndef OLD_COMBAT_SYSTEM

/mob/living/carbon
	/// All active /datum/injury instances affecting this mob's bodyparts.
	var/list/all_injuries

	/// Current total pain level, from 0 to PAIN_MAX.
	var/pain = 0
	/// Current pain-induced shock level, from 0 to SHOCK_MAX.
	var/shock = 0
	/// Current consciousness level, from 0 to CONSCIOUSNESS_MAX.
	var/consciousness = CONSCIOUSNESS_MAX

	/// Persistent pain caused by existing injuries and other sustained sources.
	var/pain_base = 0
	/// Temporary pain impulse from recent damage or other acute events.
	var/acute_pain = 0
	/// Persistent shock level accumulated from injuries, blood loss, and other sources.
	var/shock_base = 0
	/// DEPRECATED: impulses now reduce consciousness directly. Always ~0, kept for compatibility.
	var/consciousness_stun = 0
	/// Pain from non-injury sources (adjust_pain). Not overwritten by limb pain updates.
	var/pain_misc = 0
	/// TRUE while blacked out. Set at CONSCIOUSNESS_BLACKOUT, cleared at CONSCIOUSNESS_WAKE.
	var/consciousness_blackout = FALSE

	/// Multipliers applied when calculating the final medical state.
	var/pain_mod = 1.0
	var/shock_mod = 1.0
	var/consciousness_mod = 1.0

	/// Maximum allowed values after medical modifiers are applied.
	var/pain_limit = PAIN_MAX
	var/shock_limit = SHOCK_MAX

	/// Recovery-rate multipliers for shock and temporary consciousness loss.
	var/shock_recovery_mod = 1.0
	var/consciousness_recovery_mod = 1.0

	/// Active sources modifying pain, shock, consciousness, or their recovery.
	var/list/pain_modifiers
	var/list/shock_modifiers
	var/list/consciousness_modifiers
	var/list/shock_recovery_modifiers
	var/list/consciousness_recovery_modifiers

	/// Active sources modifying the maximum pain and shock limits.
	var/list/pain_limit_modifiers
	var/list/shock_limit_modifiers

	/// Current systemic blood pressure.
	var/blood_pressure = BP_NORMAL
	/// Current blood oxygenation level, represented as a percentage.
	var/blood_oxygenation = 100

	var/blood_pallor_visual = -1
	var/blood_colorgrade_visual = -1

	/// Cached total blood loss rate from all active injuries.
	var/total_bleed_rate = 0

	var/datum/health_ui/health_ui


/mob/living/carbon/Initialize(mapload)
	. = ..()
	health_ui = new(src)


/mob/living/carbon/Destroy()
	QDEL_NULL(health_ui)
	return ..()

/mob/living/carbon/examine(mob/user)
	. = ..()
	append_blood_loss_examine(user, .)
	append_injury_signs_examine(user, .)

/// Visible signs of injuries (spraying blood, deformed limbs, blue lips...) for anyone who looks.
/mob/living/carbon/proc/append_injury_signs_examine(mob/user, list/examine_list)
	for(var/datum/injury/injury as anything in all_injuries)
		var/signs = injury.get_visible_signs(user)
		if(signs)
			examine_list += signs

/**
 * Opens the detailed health panel for the user.
 */
/mob/living/carbon/proc/open_health_ui(mob/user)
	if(!health_ui)
		health_ui = new(src)
	health_ui.ui_interact(user)

#endif
