/obj/machinery/rw_workbench
	name = "workbench"
	desc = "A sturdy workbench."
	///icon = 'icons/obj/machines/rw_workbench.dmi'
	icon_state = "workbench"
	anchored = TRUE
	density = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 50
	active_power_usage = 200

	var/datum/rw_faction/player/owner_faction

	var/can_do_crafting = FALSE
	var/attachment_range = 1

/obj/machinery/rw_workbench/Initialize(mapload)
	. = ..()
	if(owner_faction)
		set_owner_faction(owner_faction)

/obj/machinery/rw_workbench/Destroy()
	set_owner_faction(null)
	return ..()

/obj/machinery/rw_workbench/proc/set_owner_faction(datum/rw_faction/player/new_faction)
	if(owner_faction?.techweb)
		owner_faction.techweb.benches -= src
	owner_faction = new_faction
	if(owner_faction?.techweb)
		owner_faction.techweb.benches |= src

/obj/machinery/rw_workbench/proc/get_nearby_attachments()
	var/list/found = list()
	for(var/obj/structure/rw_bench_attachment/attachment in range(attachment_range, src))
		if(attachment.is_functional())
			found += attachment
	return found




/obj/machinery/rw_workbench/research
	name = "research bench"
	desc = "A bench dedicated to studying and experimenting."
	icon_state = "research_bench"

	var/research_power = 1

/obj/machinery/rw_workbench/research/proc/is_valid_for_node(datum/techweb_node/rw/node)
	if(research_power <= 0)
		return FALSE
	if(length(node.workbench_types) && !is_type_in_list(src, node.workbench_types))
		return FALSE
	return TRUE

/obj/machinery/rw_workbench/research/proc/get_missing_attachments(datum/techweb_node/rw/node)
	var/list/missing = list()
	var/list/nearby = get_nearby_attachments()
	for(var/required_path in node.required_attachments)
		var/found = FALSE
		for(var/obj/structure/rw_bench_attachment/attachment as anything in nearby)
			if(istype(attachment, required_path))
				found = TRUE
				break
		if(!found)
			var/atom/required_atom = required_path
			missing += initial(required_atom.name)
	return missing

/obj/machinery/rw_workbench/research/proc/can_research(datum/techweb_node/rw/node)
	if(QDELETED(src) || !anchored || (machine_stat & (BROKEN|NOPOWER)))
		return FALSE
	if(!is_valid_for_node(node))
		return FALSE
	return !length(get_missing_attachments(node))

/obj/machinery/rw_workbench/research/proc/get_research_multiplier(datum/techweb_node/rw/node)
	if(!can_research(node))
		return 0
	var/mult = research_power
	for(var/obj/structure/rw_bench_attachment/attachment as anything in get_nearby_attachments())
		mult += attachment.research_bonus
	return mult

/obj/machinery/rw_workbench/research/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(.)
		return
	try_research(user)

/obj/machinery/rw_workbench/research/proc/try_research(mob/living/user)
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

	do_research_cycle(user, web, node)

/obj/machinery/rw_workbench/research/proc/do_research_cycle(mob/living/user, datum/techweb/faction/web, datum/techweb_node/rw/node)
	var/mult = get_research_multiplier(node)
	if(mult <= 0)
		return

	var/progress_gain = RW_RESEARCH_BASE_PROGRESS * mult

	var/success = rw_do_after(
		user,
		RW_RESEARCH_CYCLE_TIME,
		src,
		RW_SKILL_INTELLECTUAL,
		RW_RESEARCH_IDEAL_SKILL,
		minimum_delay = 1.5 SECONDS,
		skill_points = 2,
		timed_action_flags = IGNORE_USER_LOC_CHANGE,
		show_progress = TRUE
	)

	if(!success)
		return

	if(QDELETED(src) || QDELETED(web) || web.current_research_id != node.id)
		return

	web.add_research_progress(progress_gain)
	balloon_alert(user, "+[progress_gain] research")
	to_chat(user, span_notice("You make progress on [node.display_name]."))



/obj/machinery/rw_workbench/crafting
	name = "crafting station"
	desc = "A general-purpose crafting station."
	icon_state = "crafting_bench"
	can_do_crafting = TRUE

/obj/structure/rw_bench_attachment
	name = "bench attachment"
	desc = "Equipment that works together with a nearby workbench."
	anchored = TRUE
	density = TRUE
	var/research_bonus = 0

/obj/structure/rw_bench_attachment/proc/is_functional()
	return !QDELETED(src) && anchored

/obj/structure/rw_bench_attachment/analyzer
	name = "multi-analyzer"
	desc = "A set of instruments that speeds up research."
	research_bonus = 0.5
