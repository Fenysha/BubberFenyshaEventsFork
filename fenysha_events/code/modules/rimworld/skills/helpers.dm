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
