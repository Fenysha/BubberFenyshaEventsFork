#define RW_SKILL_ACTION_TIME_PER_LEVEL 0.10
#define RW_SKILL_ACTION_MIN_MULTIPLIER 0.25
#define RW_SKILL_ACTION_MAX_MULTIPLIER 3.0
#define RW_SKILL_ACTION_HEALTH_MULTIPLIER 2.0


#define RW_SKILL_ACTION_MAX_INTERACTIONS 1


/proc/rw_get_skill_action_delay(expected_delay, skill_level, ideal_skill, minimum_delay = 0)
	expected_delay = max(0, round(expected_delay))
	minimum_delay = max(0, round(minimum_delay))

	if(expected_delay <= 0)
		return 0

	skill_level = max(RW_SKILL_MIN, round(skill_level))
	ideal_skill = clamp(
		round(ideal_skill),
		RW_SKILL_MIN,
		RW_SKILL_MAX
	)

	var/skill_delta = ideal_skill - skill_level
	var/multiplier = 1 + (skill_delta * RW_SKILL_ACTION_TIME_PER_LEVEL)

	multiplier = clamp(
		multiplier,
		RW_SKILL_ACTION_MIN_MULTIPLIER,
		RW_SKILL_ACTION_MAX_MULTIPLIER
	)

	return max(round(expected_delay * multiplier), minimum_delay)


/// Wounds and low consciousness slow work actions; arm function also gates manipulation.
/proc/rw_get_health_action_multiplier(atom/movable/user)
#ifndef OLD_COMBAT_SYSTEM
	if(iscarbon(user))
		var/mob/living/carbon/carbon_user = user
		var/capacity = min(carbon_user.get_work_capacity(), carbon_user.get_manipulation_capacity())
		return clamp(1 + (1 - capacity) * RW_SKILL_ACTION_HEALTH_MULTIPLIER, 1, RW_SKILL_ACTION_MAX_MULTIPLIER)
#endif
	return 1


/proc/rw_get_skill_action_delay_for(
		atom/target,
		expected_delay,
		skill_id,
		ideal_skill,
		minimum_delay = 0
	)
	if(!target)
		return max(0, minimum_delay)

	return rw_get_skill_action_delay(
		expected_delay,
		RW_GET_SKILL(target, skill_id),
		ideal_skill,
		minimum_delay
	)


/datum/timed_action/rw_skill
	/// Skill used to calculate action duration.
	var/skill_id

	/// Skill level at which `expected_delay` is used unchanged.
	var/ideal_skill

	/// Original action duration before skill modification.
	var/expected_delay

	/// Absolute minimum action duration.
	var/minimum_delay

	/// Skill level captured when the action starts.
	var/starting_skill

	/// XP granted after successful completion.
	var/skill_points


/datum/timed_action/rw_skill/New(
		atom/movable/user,
		list/targets,
		expected_delay,
		skill_id,
		ideal_skill,
		minimum_delay = 0,
		skill_points = 1,
		show_progress = TRUE,
		timed_action_flags = NONE,
		datum/callback/extra_checks = null,
		cog_icon = null,
		cog_iconstate = null,
		mob/bar_override = null
	)
	src.skill_id = skill_id
	src.ideal_skill = ideal_skill
	src.expected_delay = expected_delay
	src.minimum_delay = minimum_delay
	src.skill_points = max(0, round(skill_points))

	/*
	 * Skill is intentionally captured once when the action starts.
	 * Changing skill during the action does not dynamically change its duration.
	 */
	starting_skill = RW_GET_SKILL(user, skill_id)

	var/actual_delay = rw_get_skill_action_delay(
		expected_delay,
		starting_skill,
		ideal_skill,
		minimum_delay
	)
	actual_delay = round(actual_delay * rw_get_health_action_multiplier(user))

	. = ..(
		user,
		targets,
		actual_delay,
		show_progress,
		timed_action_flags,
		extra_checks,
		cog_icon,
		cog_iconstate,
		bar_override
	)


/**
 * Skill-aware version of do_after().
 *
 * `expected_delay`
 *     Time required by a character with `ideal_skill`.
 *
 * `skill_id`
 *     Skill used for timing and optional XP gain.
 *
 * `ideal_skill`
 *     Skill level at which the action takes exactly `expected_delay`.
 *
 * `minimum_delay`
 *     Absolute minimum duration regardless of skill.
 *
 * `skill_points`
 *     XP granted to `skill_id` after successful completion.
 *     Defaults to 1.
 *
 * This variant ALWAYS allows only one simultaneous interaction.
 */
/proc/rw_do_after(
		atom/movable/user,
		expected_delay,
		atom/target,
		skill_id,
		ideal_skill,
		minimum_delay = 0,
		skill_points = 1,
		timed_action_flags = NONE,
		show_progress = TRUE,
		datum/callback/extra_checks,
		interaction_key,
		cog_icon = 'icons/effects/progressbar.dmi',
		cog_iconstate = "cog",
		mob/bar_override = null
	)
	if(!user)
		return FALSE

	ASSERT(isnum(expected_delay), "rw_do_after was passed a non-number expected delay: [expected_delay || "null"].")
	ASSERT(!isnum(target), "a rw_do_after created by [user] had a target set as [target] - probably intended to be the time instead.")
	ASSERT(!isatom(expected_delay), "a rw_do_after created by [user] had a timer of [expected_delay] - probably intended to be the target instead.")

	if(expected_delay <= 0)
		return TRUE

	/*
	 * Unlike regular do_after(), interaction count is deliberately hardcoded
	 * to one. The caller cannot override this.
	 */
	if(!interaction_key && ismob(user))
		if(!islist(target))
			interaction_key = target
		else
			var/list/temp = list()

			for(var/atom/atom as anything in target)
				temp += ref(atom)

			sortTim(temp, GLOBAL_PROC_REF(cmp_text_asc))
			interaction_key = jointext(temp, "-")

	if(interaction_key && ismob(user))
		var/mob/as_mob = user

		var/current_interaction_count = LAZYACCESS(as_mob.do_afters, interaction_key)

		if(current_interaction_count >= RW_SKILL_ACTION_MAX_INTERACTIONS)
			return FALSE

		LAZYSET(as_mob.do_afters, interaction_key, current_interaction_count + 1)

	SEND_SIGNAL(user, COMSIG_DO_AFTER_BEGAN)

	var/datum/timed_action/rw_skill/action = new(
		user,
		target,
		expected_delay,
		skill_id,
		ideal_skill,
		minimum_delay,
		skill_points,
		show_progress,
		timed_action_flags,
		extra_checks,
		cog_icon,
		cog_iconstate,
		bar_override
	)

	var/succeeded = action.await()

	/*
	 * XP is awarded only after the action fully succeeds.
	 *
	 * Canceled actions:
	 * - give no XP
	 * - release their interaction lock normally.
	 */
	if(succeeded && skill_points > 0)
		rw_train_skill(
			user,
			skill_id,
			skill_points
		)

	if(interaction_key && ismob(user))
		var/mob/as_mob = user

		var/reduced_interaction_count = LAZYACCESS(as_mob.do_afters, interaction_key)

		if(reduced_interaction_count > 1)
			LAZYSET(as_mob.do_afters, interaction_key, reduced_interaction_count - 1)
		else
			LAZYREMOVE(as_mob.do_afters, interaction_key)

	SEND_SIGNAL(user, COMSIG_DO_AFTER_ENDED)

	return succeeded
