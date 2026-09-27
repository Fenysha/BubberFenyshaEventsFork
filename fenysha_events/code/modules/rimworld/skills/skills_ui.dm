ADMIN_VERB_ONLY_CONTEXT_MENU(edit_skills, R_NONE, "Edit skills", /atom)
	VERB_ARG_TYPED(thing, VERB_ARG_TYPE_ATOM, VERB_ARG_SOURCE_WORLD, /atom)
	rw_open_skill_ui(user.mob, thing)

/proc/rw_is_skill_admin(mob/user)
	if(!user || !user.client || !user.client.holder)
		return FALSE

	return TRUE

/proc/rw_open_skill_ui(mob/user, atom/target)
	if(!user || !target || QDELETED(target))
		return

	if(!target.GetComponent(/datum/component/rw_skills))
		target.AddComponent(/datum/component/rw_skills)

	var/datum/rw_skill_ui/skill_ui = new(target)
	skill_ui.ui_interact(user)


/atom/proc/open_rw_skill_ui(mob/user)
	rw_open_skill_ui(user, src)


/datum/rw_skill_ui
	var/atom/target


/datum/rw_skill_ui/New(atom/target_atom)
	target = target_atom


/datum/rw_skill_ui/ui_interact(mob/user, datum/tgui/ui)
	if(!user || !target || QDELETED(target))
		qdel(src)
		return

	if(!target.GetComponent(/datum/component/rw_skills))
		target.AddComponent(/datum/component/rw_skills)

	ui = SStgui.try_update_ui(user, src, ui)

	if(!ui)
		ui = new(user, src, "SkillPanel")
		ui.open()


/datum/rw_skill_ui/ui_close()
	qdel(src)


/datum/rw_skill_ui/ui_host(mob/user)
	return target


/datum/rw_skill_ui/ui_state(mob/user)
	return GLOB.always_state


/datum/rw_skill_ui/ui_data(mob/user)
	var/list/data = list()
	var/datum/component/rw_skills/skills = target?.GetComponent(/datum/component/rw_skills)

	data["targetName"] = target?.name || "Unknown"
	data["targetType"] = target ? "[target.type]" : "/atom"
	data["isAdmin"] = rw_is_skill_admin(user)
	data["maxLevel"] = RW_SKILL_MAX
	data["skills"] = list()

	if(!skills)
		return data

	var/list/ordered_skills = list()
	for(var/skill_id in skills.all_skills)
		var/datum/rw_skill/skill = skills.all_skills[skill_id]
		if(skill)
			ordered_skills += skill

	for(var/i = 1, i <= length(ordered_skills), i++)
		var/best_index = i
		var/datum/rw_skill/best_skill = ordered_skills[i]
		for(var/j = i + 1, j <= length(ordered_skills), j++)
			var/datum/rw_skill/candidate = ordered_skills[j]
			if(candidate.sort_order < best_skill.sort_order)
				best_index = j
				best_skill = candidate
		if(best_index != i)
			var/datum/rw_skill/temp = ordered_skills[i]
			ordered_skills[i] = ordered_skills[best_index]
			ordered_skills[best_index] = temp

	for(var/datum/rw_skill/skill in ordered_skills)
		var/skill_data = rw_get_skill_data(target, skill.id)
		if(skill_data)
			data["skills"] += list(skill_data)

	return data


/datum/rw_skill_ui/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	var/mob/user = usr
	if(!target || QDELETED(target) || !user)
		return FALSE

	/*
	 * Viewing is intentionally available to everybody.
	 * Every mutation is rechecked server-side here.
	 */
	if(!rw_is_skill_admin(user))
		return FALSE

	var/datum/component/rw_skills/skills = target.GetComponent(/datum/component/rw_skills)
	if(!skills)
		return FALSE

	var/skill_id = "[params["id"]]"
	if(!(skill_id in skills.all_skills))
		return FALSE

	var/delta
	var/value

	switch(action)
		if("add_points")
			delta = clamp(
				round(text2num(params["amount"]) || 0),
				1,
				1000000
			)
			if(!delta)
				return FALSE
			skills.add_skill_points(skill_id, delta)
			. = TRUE

		if("remove_points")
			delta = clamp(
				round(text2num(params["amount"]) || 0),
				1,
				1000000
			)
			if(!delta)
				return FALSE
			skills.set_skill_points(
				skill_id,
				max(0, skills.get_skill_points(skill_id) - delta)
			)
			. = TRUE

		if("set_points")
			value = clamp(
				round(text2num(params["value"]) || 0),
				0,
				rw_skill_points_for_level(RW_SKILL_MAX)
			)
			skills.set_skill_points(skill_id, value)
			. = TRUE

		if("adjust_level")
			delta = clamp(
				round(text2num(params["delta"]) || 0),
				-1,
				1
			)
			if(!delta)
				return FALSE

			skills.set_skill(
				skill_id,
				clamp(
					skills.get_skill(skill_id) + delta,
					RW_SKILL_MIN,
					RW_SKILL_MAX
				)
			)
			. = TRUE

		if("set_level")
			value = clamp(
				round(text2num(params["value"]) || 0),
				RW_SKILL_MIN,
				RW_SKILL_MAX
			)
			skills.set_skill(skill_id, value)
			. = TRUE

		if("max_skill")
			skills.set_skill(skill_id, RW_SKILL_MAX)
			. = TRUE

		if("reset_skill")
			skills.set_skill(skill_id, RW_SKILL_MIN)
			. = TRUE

	return
