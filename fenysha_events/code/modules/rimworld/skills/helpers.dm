/proc/rw_get_skill(atom/target, skill_id)
	if(!target)
		return 0
	var/datum/component/rw_skills/skills = target.GetComponent(/datum/component/rw_skills)
	if(!skills)
		return 0
	return skills.get_skill(skill_id)

/proc/rw_has_skill(atom/target, skill_id, level)
	if(!target)
		return FALSE
	if(SEND_SIGNAL(target, COMSIG_RW_SKILL_CHECK, skill_id, level) & COMPONENT_RW_SKILL_CHECK_PASS)
		return TRUE
	return rw_get_skill(target, skill_id) >= level

/proc/rw_skill_points_for_level(level)
	level = clamp(round(text2num(level) || 0), RW_SKILL_MIN, RW_SKILL_MAX)
	return level * 100

/proc/rw_skill_title(level)
	switch(clamp(round(text2num(level) || 0), RW_SKILL_MIN, RW_SKILL_MAX))
		if(0)
			return "Unskilled"
		if(1 to 2)
			return "Novice"
		if(3 to 5)
			return "Apprentice"
		if(6 to 8)
			return "Adept"
		if(9 to 11)
			return "Professional"
		if(12 to 14)
			return "Expert"
		if(15 to 17)
			return "Master"
		if(18 to 19)
			return "Grandmaster"
		if(20)
			return "Planetary Master"
	return "Unskilled"

/proc/rw_get_skill_data(atom/target, skill_id)
	if(!target || !skill_id)
		return null
	var/datum/component/rw_skills/skills = target.GetComponent(/datum/component/rw_skills)
	if(!skills)
		return null
	var/datum/rw_skill/skill = skills.all_skills[skill_id]
	if(!skill)
		return null
	var/level = skills.get_skill(skill_id)
	var/points = skills.get_skill_points(skill_id)
	var/maxed = level >= RW_SKILL_MAX
	var/current_required = rw_skill_points_for_level(level)
	var/next_required = maxed ? current_required : rw_skill_points_for_level(level + 1)
	var/span = max(1, next_required - current_required)
	var/into = max(0, points - current_required)
	var/progress = maxed ? 1 : into / span
	return list(
		"id" = skill.id,
		"name" = skill.name,
		"desc" = skill.desc,
		"sortOrder" = skill.sort_order,
		"editable" = skill.editable,
		"level" = level,
		"title" = rw_skill_title(level),
		"points" = points,
		"pointsIntoLevel" = into,
		"pointsToNextLevel" = maxed ? 0 : max(0, next_required - points),
		"currentLevelRequired" = current_required,
		"nextLevelRequired" = next_required,
		"progress" = progress,
		"progressPercent" = progress * 100,
		"maxLevel" = RW_SKILL_MAX,
		"maxed" = maxed,
		"passion" = skills.get_passion(skill_id),
	)
