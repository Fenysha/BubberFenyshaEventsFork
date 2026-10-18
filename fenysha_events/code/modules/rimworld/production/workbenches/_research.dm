// MARK: Research production buildings

/obj/building/production/research
	name = "research bench"
	desc = "A bench dedicated to studying and experimenting."
	icon_state = "research_bench"
	can_do_crafting = FALSE

	var/research_power = 1

/obj/building/production/research/proc/is_valid_for_node(datum/techweb_node/rw/node)
	if(research_power <= 0)
		return FALSE
	if(length(node.workbench_types) && !is_type_in_list(src, node.workbench_types))
		return FALSE
	return TRUE

/obj/building/production/research/proc/get_missing_attachments(datum/techweb_node/rw/node)
	var/list/missing = list()
	var/list/nearby = get_nearby_attachments()
	for(var/required_path in node.required_attachments)
		var/found = FALSE
		for(var/obj/building/attachment/attachment as anything in nearby)
			if(istype(attachment, required_path))
				found = TRUE
				break
		if(!found)
			var/atom/required_atom = required_path
			missing += initial(required_atom.name)
	return missing

/obj/building/production/research/proc/can_research(datum/techweb_node/rw/node)
	if(QDELETED(src) || !anchored || !is_operational())
		return FALSE
	if(!is_valid_for_node(node))
		return FALSE
	return !length(get_missing_attachments(node))

/obj/building/production/research/proc/get_research_multiplier(datum/techweb_node/rw/node)
	if(!can_research(node))
		return 0
	var/mult = research_power
	for(var/obj/building/attachment/attachment as anything in get_nearby_attachments())
		mult += attachment.research_bonus
	return mult * get_speed_multiplier()

/obj/building/production/research/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(.)
		return
	try_research(user)

/obj/building/production/research/proc/try_research(mob/living/user)
	if(!owner_faction)
		balloon_alert(user, "no faction assigned!")
		return
	if(!owner_faction.is_member(user))
		balloon_alert(user, "not your faction!")
		return
	if(!owner_faction.can_manage_research(user))
		balloon_alert(user, "you can't research!")
		return

	var/datum/techweb/faction/web = owner_faction.techweb
	if(!web?.current_research_id)
		balloon_alert(user, "nothing to research!")
		return

	var/datum/techweb_node/rw/node = web.get_rw_node(web.current_research_id)
	if(!node)
		balloon_alert(user, "invalid research!")
		return

	if(!can_research(node))
		var/list/missing = get_missing_attachments(node)
		if(length(missing))
			balloon_alert(user, "missing: [english_list(missing)]")
		else
			balloon_alert(user, "wrong workbench!")
		return

	if(!check_skill(user, node.required_skill, node.min_skill_level))
		return

	do_research_cycle(user, web, node)

/obj/building/production/research/proc/do_research_cycle(mob/living/user, datum/techweb/faction/web, datum/techweb_node/rw/node)
	var/mult = get_research_multiplier(node)
	if(mult <= 0)
		return

	begin_work()
	var/progress_gain = RW_RESEARCH_BASE_PROGRESS * mult

	var/success = rw_do_after(
		user,
		RW_RESEARCH_CYCLE_TIME / get_speed_multiplier(),
		src,
		node.required_skill,
		node.ideal_skill,
		minimum_delay = 1.5 SECONDS,
		skill_points = node.research_skill_xp,
		timed_action_flags = IGNORE_USER_LOC_CHANGE,
		show_progress = TRUE
	)

	end_work()

	if(!success)
		return

	if(QDELETED(src) || QDELETED(web) || web.current_research_id != node.id)
		return

	web.add_research_progress(progress_gain)
	balloon_alert(user, "+[progress_gain] research")
	to_chat(user, span_notice("You make progress on [node.display_name]."))


/obj/building/production/research/simple
	name = "Simple research bench"
	desc = "A bench dedicated to studying and experimenting."
	icon_state = "research_bench"
	research_power = 0.5
	idle_power_draw = 0
	active_power_draw = 0
