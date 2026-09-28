#ifndef OLD_COMBAT_SYSTEM

/obj/item/organ/heart
	/// Current heart rate in beats per minute. 0 when the heart is not beating.
	var/rate = HEART_RATE_NORMAL

	/// Target heart rate the heart is trying to reach.
	/// Adrenaline, stimulants, beta blockers, and similar effects modify this through adjust_rate_target().
	var/rate_target = HEART_RATE_NORMAL

	/// World time until which CPR provides artificial cardiac output.
	var/cpr_until = 0


/obj/item/organ/heart/proc/Stop()
	if(!beating)
		return FALSE

	beating = FALSE
	rate = 0
	update_appearance()
	beat = BEAT_NONE
	owner?.stop_sound_channel(CHANNEL_HEARTBEAT)

	return TRUE


/obj/item/organ/heart/proc/Restart()
	if(beating)
		return FALSE

	beating = TRUE
	rate = HEART_RATE_NORMAL * 0.8
	rate_target = HEART_RATE_NORMAL
	update_appearance()

	return TRUE


/obj/item/organ/heart/proc/get_rate()
	return beating ? round(rate) : 0


/// Returns myocardial contractility from 0 to 1 based on organ health.
/obj/item/organ/heart/proc/get_contractility()
	if(!is_beating() || (organ_flags & (ORGAN_FAILING|ORGAN_EMP)))
		return 0

	return clamp((maxHealth - damage) / maxHealth, 0, 1)


/// Returns the efficiency of a single heartbeat.
/// At high heart rates, the chambers have less time to fill between beats.
/obj/item/organ/heart/proc/get_stroke_efficiency(at_rate = rate)
	if(at_rate <= HEART_RATE_STROKE_LIMIT)
		return 1

	return clamp(
		1 - (at_rate - HEART_RATE_STROKE_LIMIT) / (HEART_RATE_MAX_SURVIVABLE - HEART_RATE_STROKE_LIMIT),
		0,
		1
	)


/// Returns relative cardiac output, where 1.0 represents normal output.
/// CPR provides a small amount of artificial circulation while the heart is stopped.
/obj/item/organ/heart/proc/get_cardiac_output()
	var/contractility = get_contractility()

	if(contractility)
		return (rate / HEART_RATE_NORMAL) * get_stroke_efficiency() * contractility

	// A stopped heart can still provide minimal circulation through CPR.
	if(cpr_until > world.time)
		return HEART_CPR_OUTPUT

	return 0


/// Shifts the heart's target rate, for example due to drugs or chemical effects.
/obj/item/organ/heart/proc/adjust_rate_target(amount, min_rate = 30, max_rate = HEART_RATE_MAX_SURVIVABLE)
	rate_target = clamp(rate_target + amount, min_rate, max_rate)


/**
 * Applies a single effective CPR compression.
 * CPR remains active for HEART_CPR_DURATION after the compression.
 */
/obj/item/organ/heart/proc/apply_cpr()
	cpr_until = world.time + HEART_CPR_DURATION


/**
 * Restarts the heart after successful defibrillation.
 * Returns TRUE if the heart was successfully restored.
 */
/obj/item/organ/heart/proc/resuscitate(start_rate = HEART_RATE_NORMAL * 1.1)
	if(organ_flags & ORGAN_FAILING)
		return FALSE

	if(get_contractility() > 0 || Restart())
		rate = start_rate
		rate_target = HEART_RATE_NORMAL
		return TRUE

	return FALSE


/obj/item/organ/heart/proc/reset_rhythm()
	rate = HEART_RATE_NORMAL
	rate_target = HEART_RATE_NORMAL
	cpr_until = 0
	Restart()


/// Calculates the physiological demand currently placed on the heart.
/obj/item/organ/heart/proc/get_rate_drive()
	var/drive = HEART_RATE_NORMAL

	drive += owner.pain * 0.25
	drive += owner.shock * 0.3

	// Blood loss causes compensatory tachycardia.
	drive += max(0, 1 - owner.get_blood_ratio()) * 120

	// Cerebral hypoxia increases heart rate until terminal hypoxia causes bradycardia.
	drive += max(0, BRAIN_O2_HYPOXIA - owner.get_brain_oxygen()) * 0.5

	// Severe terminal hypoxia eventually causes bradycardia.
	if(owner.get_brain_oxygen() < BRAIN_O2_SEVERE * 0.5)
		drive = HEART_RATE_MIN_SURVIVABLE + owner.get_brain_oxygen()

	return drive


/obj/item/organ/heart/proc/process_rhythm(seconds_per_tick)
	if(!beating)
		rate = 0
		return

	var/target = max(rate_target, get_rate_drive())

	rate += clamp(
		target - rate,
		-HEART_RATE_SLEW * seconds_per_tick,
		HEART_RATE_SLEW * seconds_per_tick
	)

	// Extremely high or low heart rates cause cardiac arrest.
	if(rate >= HEART_RATE_MAX_SURVIVABLE || rate <= HEART_RATE_MIN_SURVIVABLE)
		if(owner.can_heartattack() && Stop())
			owner.visible_message(
				span_danger("[owner] clutches at [owner.p_their()] chest as if [owner.p_their()] heart is stopping!")
			)
			to_chat(
				owner,
				span_userdanger("You feel a terrible pain in your chest, as if your heart has stopped!")
			)
		return

	// Sustained tachycardia damages the myocardium.
	// A damaged heart may fail at a lower rate than a healthy one.
	if(rate > HEART_RATE_DAMAGE_START)
		apply_organ_damage(
			0.05 * (rate - HEART_RATE_DAMAGE_START) * seconds_per_tick
		)

		if(rate > 180 && damage > low_threshold && owner.can_heartattack() && SPT_PROB(3, seconds_per_tick))
			Stop()
			to_chat(owner, span_userdanger("Your heart flutters wildly and then stops!"))


/**
 * Processes heart rhythm and updates heartbeat feedback for the owner.
 * This replaces the default heart on_life() processing.
 */
/obj/item/organ/heart/on_life(seconds_per_tick)
	. = ..()

	if(!owner.needs_heart())
		return

	process_rhythm(seconds_per_tick)

	// A failed or stopped heart cannot maintain circulation.
	if(!beating || (organ_flags & ORGAN_FAILING))
		if(organ_flags & ORGAN_FAILING)
			Stop()

		if(!IS_UNCONSCIOUS_OR_CRIT(owner))
			owner.visible_message(
				span_danger("[owner] clutches at [owner.p_their()] chest as if [owner.p_their()] heart is stopping!")
			)

		to_chat(
			owner,
			span_userdanger("You feel a terrible pain in your chest, as if your heart has stopped!")
		)

		return

	if(isnull(owner.client))
		return

	if(rate < 50)
		if(beat != BEAT_SLOW)
			beat = BEAT_SLOW
			to_chat(owner, span_notice("You feel your heart slow down..."))
			SEND_SOUND(owner, sound('sound/effects/health/slowbeat.ogg', repeat = TRUE, channel = CHANNEL_HEARTBEAT, volume = 40))

	else if(rate > 130)
		if(beat != BEAT_FAST)
			SEND_SOUND(owner, sound('sound/effects/health/fastbeat.ogg', repeat = TRUE, channel = CHANNEL_HEARTBEAT, volume = 40))
			beat = BEAT_FAST

	else if(beat != BEAT_NONE)
		owner.stop_sound_channel(CHANNEL_HEARTBEAT)
		beat = BEAT_NONE


/**
 * Returns the clinically useful rhythm category represented by the current heart state.
 * The value is derived directly from the simulated heart state rather than stored separately.
 */
/obj/item/organ/heart/proc/get_rhythm_type()
	if(!is_beating())
		return "asystole"

	var/current_rate = get_rate()

	if(current_rate >= 180)
		return "ventricular_tachycardia"

	if(current_rate > 130)
		return "tachycardia"

	if(current_rate < 50)
		return "bradycardia"

	return "normal"

#endif
