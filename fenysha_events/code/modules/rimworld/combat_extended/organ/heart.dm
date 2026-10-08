#ifndef OLD_COMBAT_SYSTEM

/obj/item/organ/heart
	/// Current heart rate in beats per minute. 0 when the heart is not beating.
	var/rate = HEART_RATE_NORMAL

	/// Target heart rate the heart is trying to reach.
	/// Adrenaline, stimulants, beta blockers, and similar effects modify this through adjust_rate_target().
	var/rate_target = HEART_RATE_NORMAL

	/// World time until which CPR provides artificial cardiac output.
	var/cpr_until = 0

	/// TRUE while the heart is in ventricular fibrillation.
	/// In VF the myocardium quivers without coordinated ejection — cardiac output is effectively zero.
	var/fibrillating = FALSE

	/// Prevents spam of "heart stopping" messages.
	var/last_stop_message = 0


/obj/item/organ/heart/proc/Stop()
	if(!beating && !fibrillating)
		return FALSE

	beating = FALSE
	fibrillating = FALSE
	rate = 0
	update_appearance()
	beat = BEAT_NONE
	owner?.stop_sound_channel(CHANNEL_HEARTBEAT)

	return TRUE


/obj/item/organ/heart/proc/Restart()
	if(organ_flags & ORGAN_FAILING)
		return FALSE
	if(beating && !fibrillating)
		return FALSE

	beating = TRUE
	fibrillating = FALSE
	rate = HEART_RATE_NORMAL * 0.8
	rate_target = HEART_RATE_NORMAL
	update_appearance()

	return TRUE


/obj/item/organ/heart/proc/get_rate()
	if(fibrillating)
		// VF is often displayed as a very high, irregular rate on monitors
		return rand(180, 320)
	return beating ? round(rate) : 0


/// Returns myocardial contractility from 0 to 1 based on organ health.
/obj/item/organ/heart/proc/get_contractility()
	if(fibrillating)
		return 0
	if(!is_beating() || (organ_flags & (ORGAN_FAILING|ORGAN_EMP)))
		return 0

	return clamp((maxHealth - damage) / maxHealth, 0, 1)


/// Preload factor from circulating blood volume (Frank-Starling approximation).
/// Severe hypovolemia collapses stroke volume even if the myocardium is healthy.
/obj/item/organ/heart/proc/get_preload_factor()
	if(!owner)
		return 1

	var/ratio = owner.get_blood_ratio()

	// Above ~70% volume: full preload
	if(ratio >= 0.70)
		return 1

	// 40-70%: progressive reduction
	if(ratio >= 0.40)
		return 0.35 + (ratio - 0.40) * (0.65 / 0.30)

	// Below 40%: critically reduced filling
	if(ratio >= 0.20)
		return 0.10 + (ratio - 0.20) * (0.25 / 0.20)

	// Near-empty vascular bed — almost no forward flow from native beats
	return clamp(ratio * 0.5, 0, 0.10)


/// Returns the efficiency of a single heartbeat.
/// At high heart rates, the chambers have less time to fill between beats.
/obj/item/organ/heart/proc/get_stroke_efficiency(at_rate = rate)
	if(fibrillating)
		return 0

	if(at_rate <= HEART_RATE_STROKE_LIMIT)
		return 1

	return clamp(
		1 - (at_rate - HEART_RATE_STROKE_LIMIT) / (HEART_RATE_MAX_SURVIVABLE - HEART_RATE_STROKE_LIMIT),
		0,
		1
	)


/// Returns relative cardiac output, where 1.0 represents normal output.
/// CPR provides additional artificial circulation while active (does not replace native output).
/obj/item/organ/heart/proc/get_cardiac_output()
	var/native_output = 0

	var/contractility = get_contractility()
	if(contractility > 0 && !fibrillating)
		var/preload = get_preload_factor()
		native_output = (rate / HEART_RATE_NORMAL) * get_stroke_efficiency() * contractility * preload

	// CPR adds a small amount of artificial circulation (does not replace native beats)
	var/cpr_output = 0
	if(cpr_until > world.time)
		cpr_output = HEART_CPR_OUTPUT

	return native_output + cpr_output


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
 * Also clears ventricular fibrillation.
 * Returns TRUE if the heart was successfully restored to a coordinated rhythm.
 */
/obj/item/organ/heart/proc/resuscitate(start_rate = HEART_RATE_NORMAL * 1.1)
	if(organ_flags & ORGAN_FAILING)
		return FALSE

	// Already beating normally — just nudge the rate
	if(beating && !fibrillating)
		rate = start_rate
		rate_target = HEART_RATE_NORMAL
		return TRUE

	// Need actual myocardial function to restart
	if(get_contractility() <= 0 && !(organ_flags & ORGAN_EMP))
		// Contractility is zero because of damage/failure, not EMP
		// (EMP case is already blocked by the failing check above in most setups)
		return FALSE

	fibrillating = FALSE
	beating = TRUE
	rate = start_rate
	rate_target = HEART_RATE_NORMAL
	update_appearance()
	return TRUE


/obj/item/organ/heart/proc/reset_rhythm()
	if(organ_flags & ORGAN_FAILING)
		return FALSE
	rate = HEART_RATE_NORMAL
	rate_target = HEART_RATE_NORMAL
	cpr_until = 0
	fibrillating = FALSE
	beating = TRUE
	update_appearance()


/// Calculates the physiological demand currently placed on the heart.
/obj/item/organ/heart/proc/get_rate_drive()
	if(!owner)
		return HEART_RATE_NORMAL

	var/drive = HEART_RATE_NORMAL

	drive += owner.pain * 0.25
	drive += owner.shock * 0.3

	// Blood loss causes compensatory tachycardia.
	var/blood_ratio = owner.get_blood_ratio()
	drive += max(0, 1 - blood_ratio) * 120

	// Cerebral hypoxia increases heart rate until terminal hypoxia causes bradycardia.
	var/brain_o2 = owner.get_brain_oxygen()
	drive += max(0, BRAIN_O2_HYPOXIA - brain_o2) * 0.5

	// Severe terminal hypoxia eventually causes bradycardia / pre-asystole.
	// Scale toward the minimum survivable rate instead of adding raw oxygen units.
	if(brain_o2 < BRAIN_O2_SEVERE * 0.5)
		var/severity = 1 - (brain_o2 / (BRAIN_O2_SEVERE * 0.5))
		drive = LERP(drive, HEART_RATE_MIN_SURVIVABLE, clamp(severity, 0, 1))

	return drive


/**
 * Chance (0-100) that the current conditions will precipitate ventricular fibrillation.
 * Driven by severe hypovolemia, extreme tachycardia and myocardial damage.
 */
/obj/item/organ/heart/proc/get_fibrillation_chance(seconds_per_tick)
	if(!owner || fibrillating || !beating)
		return 0
	if(organ_flags & (ORGAN_FAILING | ORGAN_EMP))
		return 0

	var/blood_ratio = owner.get_blood_ratio()
	var/chance = 0

	// Severe hypovolemia is the primary driver
	if(blood_ratio < 0.45)
		chance += (0.45 - blood_ratio) * 40   // up to ~18 at ratio 0

	// Extreme rate further destabilises the myocardium
	if(rate > 160)
		chance += (rate - 160) * 0.15

	// Only substantial myocardial damage adds arrhythmia risk; scale it instead of
	// giving a sudden fibrillation chance for barely crossing a damage threshold.
	if(damage > high_threshold)
		var/damage_range = max(maxHealth - high_threshold, 1)
		chance += clamp((damage - high_threshold) / damage_range, 0, 1) * 12

	// Very low volume + high rate is especially dangerous
	if(blood_ratio < 0.30 && rate > 140)
		chance += 12

	return chance * seconds_per_tick


/**
 * Puts the heart into ventricular fibrillation.
 * Coordinated contraction ceases; cardiac output collapses.
 */
/obj/item/organ/heart/proc/enter_fibrillation()
	if(fibrillating)
		return FALSE

	fibrillating = TRUE
	beating = TRUE          // still "electrically active", but chaotic
	rate = rand(200, 280)   // monitor shows high irregular rate
	beat = BEAT_NONE
	owner?.stop_sound_channel(CHANNEL_HEARTBEAT)
	update_appearance()

	if(owner)
		owner.visible_message(
			span_danger("[owner]'s heart rhythm becomes chaotic!"),
			span_userdanger("Your heart flutters wildly and loses any effective beat!")
		)

	return TRUE


/obj/item/organ/heart/proc/process_rhythm(seconds_per_tick)
	if(!owner)
		return

	// Already in VF — no coordinated rate control
	if(fibrillating)
		// Small chance of spontaneous deterioration into full asystole
		if(SPT_PROB(1, seconds_per_tick))
			Stop()
			if(owner)
				to_chat(owner, span_userdanger("Your heart falls completely silent..."))
		return

	if(!beating)
		rate = 0
		return

	var/target = max(rate_target, get_rate_drive())

	rate += clamp(
		target - rate,
		-HEART_RATE_SLEW * seconds_per_tick,
		HEART_RATE_SLEW * seconds_per_tick
	)

	// Check for transition into ventricular fibrillation
	var/fib_chance = get_fibrillation_chance(seconds_per_tick)
	if(fib_chance > 0 && SPT_PROB(fib_chance, seconds_per_tick))
		enter_fibrillation()
		return

	// Extremely high or low heart rates cause cardiac arrest (asystole path)
	if((rate >= HEART_RATE_MAX_SURVIVABLE || rate <= HEART_RATE_MIN_SURVIVABLE) && beating)
		if(owner.can_heartattack() && Stop())
			notify_heart_stop()
		return

	// Sustained tachycardia damages the myocardium.
	// A damaged heart may fail at a lower rate than a healthy one.
	if(rate > HEART_RATE_DAMAGE_START)
		apply_organ_damage(
			0.05 * (rate - HEART_RATE_DAMAGE_START) * seconds_per_tick
		)

		if(rate > 180 && damage > low_threshold && owner.can_heartattack() && SPT_PROB(3, seconds_per_tick))
			// Prefer fibrillation over instant asystole when volume is still present
			if(owner.get_blood_ratio() > 0.25 && prob(90))
				enter_fibrillation()
			else if(beating)
				Stop()
				to_chat(owner, span_userdanger("Your heart flutters wildly and then stops!"))


/**
 * Sends the "heart stopping" feedback to the owner / nearby players.
 * Rate-limited so it does not spam every life tick.
 */
/obj/item/organ/heart/proc/notify_heart_stop()
	if(!owner)
		return
	if(world.time < last_stop_message + 5 SECONDS)
		return
	if(IS_UNCONSCIOUS_OR_CRIT(owner))
		return

	last_stop_message = world.time

	owner.visible_message(
		span_danger("[owner] clutches at [owner.p_their()] chest as if [owner.p_their()] heart is stopping!")
	)
	to_chat(
		owner,
		span_userdanger("You feel a terrible pain in your chest, as if your heart has stopped!")
	)


/**
 * Processes heart rhythm and updates heartbeat feedback for the owner.
 * This replaces default heart rhythm processing while retaining generic organ life handling.
 */
/obj/item/organ/heart/on_life(seconds_per_tick)
	. = ..()

	if(!owner || !owner.needs_heart())
		return

	// A failing heart is terminal in this state machine; stop it once and do not
	// let rhythm processing restart or re-stop it every life tick.
	if(organ_flags & ORGAN_FAILING)
		if(beating || fibrillating)
			Stop()
		notify_heart_stop()
		return

	process_rhythm(seconds_per_tick)

	// A stopped or fibrillating heart cannot maintain effective circulation.
	if(!beating || fibrillating)
		// Message only when the heart just stopped (not while already in VF)
		if(!fibrillating)
			notify_heart_stop()

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
	if(fibrillating)
		return "ventricular_fibrillation"

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
