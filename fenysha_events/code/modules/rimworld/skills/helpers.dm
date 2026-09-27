/**
 * Returns the XP required to ENTER `level`.
 *
 * Level 1 requires 100 XP.
 * Level 20 requires 40000 XP since the previous level.
 */
/proc/rw_skill_points_for_level_step(level)
	level = clamp(round(text2num(level) || 0), 1, RW_SKILL_MAX)
	return RW_SKILL_XP_BASE * level * level


/**
 * Returns cumulative XP required to reach `level`.
 *
 * Level 0 = 0 XP.
 * Level 1 = 100 XP.
 * Level 2 = 500 XP.
 * Level 20 = 287000 XP.
 */
/proc/rw_skill_points_for_level(level)
	level = clamp(round(text2num(level) || 0), RW_SKILL_MIN, RW_SKILL_MAX)

	var/static/list/thresholds
	if(!thresholds)
		thresholds = list(0)
		var/total = 0
		for(var/i = 1, i <= RW_SKILL_MAX, i++)
			total += rw_skill_points_for_level_step(i)
			thresholds += total

	return thresholds[level + 1]


/**
 * Converts cumulative XP into a skill level.
 */
/proc/rw_skill_level_from_points(points)
	points = max(0, round(text2num(points) || 0))

	var/level = RW_SKILL_MIN
	for(var/i = 1, i <= RW_SKILL_MAX, i++)
		if(points < rw_skill_points_for_level(i))
			break
		level = i

	return level


/**
 * Returns the human-readable rank/title for a level.
 */
/proc/rw_get_skill_title(level)
	level = clamp(round(text2num(level) || 0), RW_SKILL_MIN, RW_SKILL_MAX)
	return GLOB.rw_skill_titles[level + 1] || GLOB.rw_skill_titles[1]


/**
 * Cost used by character creation when buying a skill level.
 *
 * Existing RW_SKILL_LEVEL_COST remains the cost of level 1.
 * Every next level becomes more expensive:
 *
 *   0 -> 1 = 1x base
 *   1 -> 2 = 2x base
 *   2 -> 3 = 3x base
 *   ...
 *
 * The returned value is the TOTAL amount spent at that level.
 */
/proc/rw_skill_character_cost(level)
	level = clamp(round(text2num(level) || 0), RW_SKILL_MIN, RW_SKILL_MANUAL_MAX)

	if(level <= 0)
		return 0

	return round(RW_SKILL_LEVEL_COST * level * (level + 1) / 2)


/**
 * Cost of one individual upgrade from the current level.
 */
/proc/rw_skill_character_upgrade_cost(level)
	level = clamp(round(text2num(level) || 0), RW_SKILL_MIN, RW_SKILL_MANUAL_MAX)

	if(level >= RW_SKILL_MANUAL_MAX)
		return 0

	return rw_skill_character_cost(level + 1) - rw_skill_character_cost(level)



/proc/get_skills(atom/target)
	if(!target)
		return

	return target.GetComponent(/datum/component/rw_skills)


/proc/get_or_add_skills(atom/target)
	if(!target)
		return

	var/datum/component/rw_skills/skills = target.GetComponent(/datum/component/rw_skills)
	if(skills)
		return skills

	return target.AddComponent(/datum/component/rw_skills)


/proc/rw_get_skill(atom/target, skill_id)
	var/datum/component/rw_skills/skills = get_skills(target)
	if(!skills)
		return 0
	return skills.get_skill(skill_id)


/proc/rw_get_skill_points(atom/target, skill_id)
	var/datum/component/rw_skills/skills = get_skills(target)
	if(!skills)
		return 0
	return skills.get_skill_points(skill_id)


/proc/rw_get_target_skill_title(atom/target, skill_id)
	return rw_get_skill_title(rw_get_skill(target, skill_id))


/proc/rw_get_skill_points_into_level(atom/target, skill_id)
	var/datum/component/rw_skills/skills = get_skills(target)
	if(!skills)
		return 0
	return skills.get_skill_points_into_level(skill_id)


/proc/rw_get_skill_points_to_next_level(atom/target, skill_id)
	var/datum/component/rw_skills/skills = get_skills(target)
	if(!skills)
		return 0
	return skills.get_skill_points_to_next_level(skill_id)


/proc/rw_get_skill_progress(atom/target, skill_id)
	var/datum/component/rw_skills/skills = get_skills(target)
	if(!skills)
		return 0
	return skills.get_skill_progress(skill_id)


/proc/rw_get_skill_progress_percent(atom/target, skill_id)
	var/datum/component/rw_skills/skills = get_skills(target)
	if(!skills)
		return 0
	return skills.get_skill_progress_percent(skill_id)


/proc/rw_has_skill(atom/target, skill_id, level)
	if(!target)
		return FALSE

	if(SEND_SIGNAL(target, COMSIG_RW_SKILL_CHECK, skill_id, level) \
		& COMPONENT_RW_SKILL_CHECK_PASS)

		return TRUE

	return rw_get_skill(target, skill_id) >= level


/proc/rw_can_train_skill(atom/target, skill_id)
	var/datum/component/rw_skills/skills = get_skills(target)
	if(!skills)
		return FALSE
	return !skills.is_skill_maxed(skill_id)


/proc/rw_add_skill_points(atom/target, skill_id, amount)
	var/datum/component/rw_skills/skills = get_skills(target)
	if(!skills)
		return 0
	return skills.add_skill_points(skill_id, amount)


/proc/rw_train_skill(atom/target, skill_id, amount)
	return rw_add_skill_points(target, skill_id, amount)


/proc/rw_set_skill_points(atom/target, skill_id, points)
	var/datum/component/rw_skills/skills = get_skills(target)
	if(!skills)
		return FALSE
	return skills.set_skill_points(skill_id, points)


/proc/rw_set_skill(atom/target, skill_id, level)
	var/datum/component/rw_skills/skills = get_skills(target)
	if(!skills)
		return FALSE
	return skills.set_skill(skill_id, level)


/proc/rw_get_skill_data(atom/target, skill_id)
	var/datum/component/rw_skills/skills = get_skills(target)
	if(!skills)
		return

	var/datum/rw_skill/skill = skills.all_skills[skill_id]
	if(!skill)
		return

	var/level = skills.get_skill(skill_id)
	var/points = skills.get_skill_points(skill_id)
	var/current_threshold = rw_skill_points_for_level(level)
	var/next_threshold = rw_skill_points_for_level(level + 1)

	return list(
		"id" = skill.id,
		"name" = skill.name,
		"desc" = skill.desc,
		"sortOrder" = skill.sort_order,
		"editable" = skill.editable,

		"level" = level,
		"title" = rw_get_skill_title(level),
		"points" = points,
		"pointsIntoLevel" = skills.get_skill_points_into_level(skill_id),
		"pointsToNextLevel" = skills.get_skill_points_to_next_level(skill_id),
		"currentLevelRequired" = current_threshold,
		"nextLevelRequired" = next_threshold,
		"progress" = skills.get_skill_progress(skill_id),
		"progressPercent" = skills.get_skill_progress_percent(skill_id),
		"maxLevel" = RW_SKILL_MAX,
		"maxed" = skills.is_skill_maxed(skill_id)
	)
