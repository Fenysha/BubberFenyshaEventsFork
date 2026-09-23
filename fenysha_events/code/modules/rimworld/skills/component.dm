/**
 * Per-atom skill levels. all_skills is static — one singleton registry for every component.
 */
/datum/component/rw_skills
	dupe_mode = COMPONENT_DUPE_UNIQUE
	/// SKILL_ID -> singleton /datum/rw_skill. Shared across all components.
	var/static/list/all_skills
	/// SKILL_ID -> level
	var/list/my_skill

/datum/component/rw_skills/Initialize(list/starting_skills)
	if(!isatom(parent))
		return COMPONENT_INCOMPATIBLE
	ensure_singletons()
	my_skill = list()
	for(var/skill_id in all_skills)
		my_skill[skill_id] = 0
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

/datum/component/rw_skills/proc/set_levels(list/new_levels)
	if(!new_levels)
		return
	for(var/skill_id in new_levels)
		set_skill(skill_id, new_levels[skill_id])

/datum/component/rw_skills/proc/set_skill(skill_id, level)
	if(!(skill_id in all_skills))
		return
	var/old_level = my_skill[skill_id]
	var/new_level = clamp(text2num(level) || 0, RW_SKILL_MIN, RW_SKILL_MAX)
	if(old_level == new_level)
		return
	my_skill[skill_id] = new_level
	var/datum/rw_skill/skill = all_skills[skill_id]
	skill?.on_level_changed(parent, old_level, new_level)

/datum/component/rw_skills/proc/get_skill(skill_id)
	return my_skill[skill_id] || 0

/datum/component/rw_skills/proc/on_skill_check(datum/source, skill_id, required_level)
	SIGNAL_HANDLER
	if(get_skill(skill_id) >= required_level)
		return COMPONENT_RW_SKILL_CHECK_PASS
	return NONE
