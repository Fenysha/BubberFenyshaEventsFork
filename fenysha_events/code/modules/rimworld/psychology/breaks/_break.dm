/**
 * Mental break controller.
 *
 * Owns everything that happens to a mob while they are having a nervous breakdown:
 * control loss, duration, start/end effects, and per-tick behaviour.
 *
 * Psychology only decides WHEN to start a break and which severity;
 * this datum runs the break itself until it ends.
 */
/datum/psychology_break
	abstract_type = /datum/psychology_break

	/// Parent psychology datum
	var/datum/psychology/psychology
	/// Mob under the break (shortcut)
	var/mob/living/owner

	/// PSY_BREAK_MINOR / MAJOR / EXTREME
	var/severity = PSY_BREAK_NONE
	/// Human-readable id for UI / logging
	var/id = "break"
	var/name = "Mental break"
	var/description = "Having a mental break."

	/// Mood factor applied for the duration of the break
	var/mood_penalty = -15

	/// Base duration before severity scaling
	var/duration = 30 SECONDS
	/// world.time when this break ends
	var/end_time = 0

	/// Whether control has been stripped from the player
	var/control_lost = FALSE

	/// TRUE after start() has run successfully
	var/active = FALSE

	/// Chance, per psychology tick, to take a short random walk
	var/wander_chance = 40
	/// Emote played on ticks that do not wander
	var/break_emote = "sigh"

/datum/psychology_break/New(datum/psychology/parent, mob/living/mob_owner)
	psychology = parent
	owner = mob_owner

/datum/psychology_break/Destroy(force)
	if(active)
		// Safety: restore control if destroyed mid-break
		end(forced = TRUE)
	psychology = null
	owner = null
	return ..()

// ============================================================
//  Lifecycle
// ============================================================

/**
 * Begins the break. Returns TRUE on success.
 */
/datum/psychology_break/proc/start()
	if(active || !owner || !psychology)
		return FALSE

	active = TRUE
	end_time = world.time + duration

	on_start()
	lose_control()

	psychology.add_factor(
		PSY_CATEGORY_BREAK,
		id,
		mood_penalty,
		description,
		timeout = end_time
	)

	SEND_SIGNAL(owner, COMSIG_MOB_PSYCHOLOGY_BREAK_START, severity)
	return TRUE

/**
 * Ends the break and restores the mob. Safe to call multiple times.
 */
/datum/psychology_break/proc/end(forced = FALSE)
	if(!active && !forced)
		return FALSE

	var/was_active = active
	active = FALSE

	if(was_active)
		on_end(forced)
		restore_control()
		psychology?.clear_factor(PSY_CATEGORY_BREAK)

	if(owner && was_active)
		SEND_SIGNAL(owner, COMSIG_MOB_PSYCHOLOGY_BREAK_END, severity)
		if(!forced)
			to_chat(owner, span_notice("You regain control of yourself. The storm in your mind subsides... for now."))

	return TRUE

/**
 * Called every psychology process tick while this break is active.
 * Override in subtypes for wandering, tantrums, etc.
 */
/datum/psychology_break/proc/process_break(seconds_per_tick)
	if(!active)
		return
	if(world.time >= end_time)
		end()
		return
	on_tick(seconds_per_tick)

/**
 * Seconds remaining until the break ends (0 if inactive).
 */
/datum/psychology_break/proc/seconds_remaining()
	if(!active)
		return 0
	return max(0, round((end_time - world.time) / 10))

/datum/psychology_break/proc/lose_control()
	if(!owner || control_lost)
		return
	control_lost = TRUE
	ADD_TRAIT(owner, TRAIT_PSY_NO_CONTROL, PSYCHOLOGY_TRAIT)
	// Same lock caravans use: no move, no hands, no actions. The custom trait stays as a marker.
	owner.add_traits(list(TRAIT_IMMOBILIZED, TRAIT_HANDS_BLOCKED, TRAIT_INCAPACITATED), PSYCHOLOGY_TRAIT)
	owner.Stun(0.5 SECONDS, ignore_canstun = TRUE)

/datum/psychology_break/proc/restore_control()
	if(!owner || !control_lost)
		return
	control_lost = FALSE
	REMOVE_TRAIT(owner, TRAIT_PSY_NO_CONTROL, PSYCHOLOGY_TRAIT)
	owner.remove_traits(list(TRAIT_IMMOBILIZED, TRAIT_HANDS_BLOCKED, TRAIT_INCAPACITATED), PSYCHOLOGY_TRAIT)

/** Called once when the break begins (after flags set, before control loss). */
/datum/psychology_break/proc/on_start()
	to_chat(owner, span_userdanger("You feel your mind slipping... You have lost control of yourself!"))

/** Called once when the break ends (before control restored). */
/datum/psychology_break/proc/on_end(forced = FALSE)
	return

/**
 * Per-tick behaviour while the break is active.
 * The player stays locked; the body still paces in a random direction.
 */
/datum/psychology_break/proc/on_tick(seconds_per_tick)
	if(!owner || QDELETED(owner) || owner.stat == DEAD)
		return
	if(prob(wander_chance))
		var/steps = rand(1, 2)
		for(var/i in 1 to steps)
			if(!wander_step())
				break
	else if(break_emote && prob(30))
		owner.emote(break_emote)

/**
 * One step in a random open direction.
 * Immobilize is lifted only for that step, then put back, so the player still cannot steer.
 */
/datum/psychology_break/proc/wander_step()
	if(!owner || QDELETED(owner) || owner.buckled || !isturf(owner.loc))
		return FALSE
	var/list/options = list()
	for(var/dir in GLOB.cardinals)
		var/turf/dest = get_step(owner, dir)
		if(!dest || dest.is_blocked_turf(exclude_mobs = TRUE))
			continue
		options += dir
	if(!length(options))
		return FALSE
	var/picked = pick(options)
	REMOVE_TRAIT(owner, TRAIT_IMMOBILIZED, PSYCHOLOGY_TRAIT)
	step(owner, picked)
	if(control_lost && owner && !QDELETED(owner))
		ADD_TRAIT(owner, TRAIT_IMMOBILIZED, PSYCHOLOGY_TRAIT)
	return TRUE



/// Mild breakdown — short, player mostly just locked out
/datum/psychology_break/minor
	severity = PSY_BREAK_MINOR
	id = "break_minor"
	name = "Minor mental break"
	description = "Having a minor mental break."
	mood_penalty = -10
	duration = PSY_BREAK_DURATION_MINOR
	wander_chance = 35
	break_emote = "sigh"

/datum/psychology_break/minor/on_start()
	to_chat(owner, span_warning("The pressure is too much. Your legs start moving on their own..."))

/// Serious breakdown — longer lockout
/datum/psychology_break/major
	severity = PSY_BREAK_MAJOR
	id = "break_major"
	name = "Major mental break"
	description = "Having a major mental break."
	mood_penalty = -15
	duration = PSY_BREAK_DURATION_MAJOR
	wander_chance = 65
	break_emote = "cry"

/datum/psychology_break/major/on_start()
	to_chat(owner, span_userdanger("Something inside you snaps. You can no longer trust your own hands..."))

/// Catastrophic breakdown — longest, heaviest effects
/datum/psychology_break/extreme
	severity = PSY_BREAK_EXTREME
	id = "break_extreme"
	name = "Extreme mental break"
	description = "Suffering an extreme mental break."
	mood_penalty = -25
	duration = PSY_BREAK_DURATION_EXTREME
	wander_chance = 85
	break_emote = "scream"

/datum/psychology_break/extreme/on_start()
	to_chat(owner, span_userdanger("Your mind collapses. The world is noise and fear — you are no longer in control."))


/**
 * Creates the appropriate break datum for a severity level.
 * Does not start it — caller must call start().
 */
/proc/create_psychology_break(datum/psychology/psy, severity)
	RETURN_TYPE(/datum/psychology_break)
	if(!psy || !psy.owner)
		return null
	var/break_path
	switch(severity)
		if(PSY_BREAK_MINOR)
			break_path = /datum/psychology_break/minor
		if(PSY_BREAK_MAJOR)
			break_path = /datum/psychology_break/major
		if(PSY_BREAK_EXTREME)
			break_path = /datum/psychology_break/extreme
		else
			return null
	return new break_path(psy, psy.owner)
