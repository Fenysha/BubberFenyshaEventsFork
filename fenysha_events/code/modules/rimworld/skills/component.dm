/datum/component/rw_skills
	dupe_mode = COMPONENT_DUPE_UNIQUE

	/// SKILL_ID -> singleton /datum/rw_skill.
	var/static/list/all_skills

	/// SKILL_ID -> current level.
	var/list/my_skill

	/// SKILL_ID -> total cumulative XP.
	var/list/my_skill_points


/datum/component/rw_skills/Initialize(list/starting_skills)
	if(!isatom(parent))
		return COMPONENT_INCOMPATIBLE

	ensure_singletons()

	my_skill = list()
	my_skill_points = list()

	for(var/skill_id in all_skills)
		my_skill[skill_id] = RW_SKILL_MIN
		my_skill_points[skill_id] = 0

	if(starting_skills)
		set_levels(starting_skills)


/datum/component/rw_skills/RegisterWithParent()
	RegisterSignal(parent, COMSIG_RW_SKILL_CHECK, PROC_REF(on_skill_check))


/datum/component/rw_skills/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_RW_SKILL_CHECK)


/datum/component/rw_skills/proc/ensure_singletons()
	if(length(all_skills))
		return

	if(length(GLOB.all_rw_skills))
		all_skills = GLOB.all_rw_skills
		return

	all_skills = list()

	for(var/path in subtypesof(/datum/rw_skill))
		var/datum/rw_skill/skill = new path

		if(!skill.id)
			qdel(skill)
			continue

		all_skills[skill.id] = skill

	GLOB.all_rw_skills = all_skills


/**
 * Set initial skill levels.
 *
 * This intentionally places the skill exactly at the beginning
 * of that level, rather than giving it partial XP.
 */
/datum/component/rw_skills/proc/set_levels(list/new_levels)
	if(!new_levels)
		return

	for(var/skill_id in new_levels)
		set_skill(skill_id, new_levels[skill_id])


/**
 * Force a skill to an exact level.
 *
 * Existing progress inside that level is discarded.
 */
/datum/component/rw_skills/proc/set_skill(skill_id, level)
	if(!(skill_id in all_skills))
		return

	var/old_level = my_skill[skill_id] || RW_SKILL_MIN
	var/old_points = my_skill_points[skill_id] || 0

	var/new_level = clamp(
		round(text2num(level) || 0),
		RW_SKILL_MIN,
		RW_SKILL_MAX
	)

	var/new_points = rw_skill_points_for_level(new_level)

	if(old_level == new_level && old_points == new_points)
		return

	my_skill[skill_id] = new_level
	my_skill_points[skill_id] = new_points

	var/datum/rw_skill/skill = all_skills[skill_id]

	if(old_points != new_points)
		SEND_SIGNAL(parent, COMSIG_RW_SKILL_POINTS_CHANGED, skill_id, old_points, new_points, old_level, new_level)
		skill?.on_points_changed(parent, old_points, new_points)

	if(old_level != new_level)
		SEND_SIGNAL(parent, COMSIG_RW_SKILL_LEVEL_CHANGED, skill_id, old_level, new_level)
		skill?.on_level_changed(parent, old_level, new_level)


/**
 * Set total cumulative XP directly.
 *
 * The corresponding level is calculated automatically.
 */
/datum/component/rw_skills/proc/set_skill_points(skill_id, points)
	if(!(skill_id in all_skills))
		return 0

	var/old_points = my_skill_points[skill_id] || 0
	var/old_level = my_skill[skill_id] || RW_SKILL_MIN

	var/max_points = rw_skill_points_for_level(RW_SKILL_MAX)

	var/new_points = clamp(
		round(text2num(points) || 0),
		0,
		max_points
	)

	var/new_level = rw_skill_level_from_points(new_points)

	if(old_points == new_points && old_level == new_level)
		return new_points

	my_skill_points[skill_id] = new_points
	my_skill[skill_id] = new_level

	var/datum/rw_skill/skill = all_skills[skill_id]

	if(old_points != new_points)
		SEND_SIGNAL(parent, COMSIG_RW_SKILL_POINTS_CHANGED, skill_id, old_points, new_points, old_level, new_level)
		skill?.on_points_changed(parent, old_points, new_points)

	if(old_level != new_level)
		SEND_SIGNAL(parent, COMSIG_RW_SKILL_LEVEL_CHANGED, skill_id, old_level, new_level)
		skill?.on_level_changed(parent, old_level, new_level)

	return new_points


/**
 * Add XP to the skill.
 *
 * Returns the actual number of XP added.
 * At level 20 this naturally becomes 0.
 */
/datum/component/rw_skills/proc/add_skill_points(skill_id, amount)
	if(!(skill_id in all_skills))
		return 0

	var/add_amount = round(text2num(amount) || 0)

	if(add_amount <= 0)
		return 0

	var/old_points = my_skill_points[skill_id] || 0
	var/max_points = rw_skill_points_for_level(RW_SKILL_MAX)

	if(old_points >= max_points)
		return 0

	var/new_points = min(
		old_points + add_amount,
		max_points
	)

	set_skill_points(skill_id, new_points)

	return new_points - old_points


/datum/component/rw_skills/proc/get_skill(skill_id)
	return my_skill[skill_id] || 0


/datum/component/rw_skills/proc/get_skill_points(skill_id)
	return my_skill_points[skill_id] || 0


/**
 * XP earned inside the current level.
 */
/datum/component/rw_skills/proc/get_skill_points_into_level(skill_id)
	var/level = get_skill(skill_id)
	var/points = get_skill_points(skill_id)

	var/level_start = rw_skill_points_for_level(level)

	return max(
		0,
		points - level_start
	)


/**
 * XP remaining until the next level.
 */
/datum/component/rw_skills/proc/get_skill_points_to_next_level(skill_id)
	var/level = get_skill(skill_id)

	if(level >= RW_SKILL_MAX)
		return 0

	var/points = get_skill_points(skill_id)
	var/next_threshold = rw_skill_points_for_level(level + 1)

	return max(
		0,
		next_threshold - points
	)


/**
 * Progress inside the current level.
 *
 * Returns 0.0 - 1.0.
 */
/datum/component/rw_skills/proc/get_skill_progress(skill_id)
	var/level = get_skill(skill_id)

	if(level >= RW_SKILL_MAX)
		return 1

	var/points = get_skill_points(skill_id)

	var/current_threshold = rw_skill_points_for_level(level)
	var/next_threshold = rw_skill_points_for_level(level + 1)

	var/level_cost = next_threshold - current_threshold

	if(level_cost <= 0)
		return 1

	return clamp(
		(points - current_threshold) / level_cost,
		0,
		1
	)


/datum/component/rw_skills/proc/get_skill_progress_percent(skill_id)
	return get_skill_progress(skill_id) * 100


/datum/component/rw_skills/proc/is_skill_maxed(skill_id)
	return get_skill(skill_id) >= RW_SKILL_MAX


/datum/component/rw_skills/proc/on_skill_check(datum/source, skill_id, required_level)
	SIGNAL_HANDLER

	if(get_skill(skill_id) >= required_level)
		return COMPONENT_RW_SKILL_CHECK_PASS

	return NONE
