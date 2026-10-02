/datum/controller/subsystem/research/Initialize()
	. = ..()
	layout_rw_techweb_nodes()

/datum/controller/subsystem/research/proc/layout_rw_techweb_nodes()
	var/list/datum/techweb_node/rw/rw_nodes = list()

	for(var/node_id in techweb_nodes)
		var/datum/techweb_node/rw/node = techweb_nodes[node_id]
		if(!istype(node) || istype(node, /datum/techweb_node/rw/error))
			continue
		if(node.rw_flags & RW_RESEARCH_DISABLED)
			continue
		rw_nodes[node.id] = node

	if(!length(rw_nodes))
		return

	var/list/depth_of = list()
	var/list/pending = rw_nodes.Copy()
	var/guard = 0
	var/max_guard = length(pending) + 5

	while(length(pending) && guard < max_guard)
		guard++
		var/progressed = FALSE
		for(var/node_id in pending.Copy())
			var/datum/techweb_node/rw/node = pending[node_id]
			var/max_prereq_depth = -1
			var/ready = TRUE

			for(var/prereq_id in node.prereq_ids)
				if(!rw_nodes[prereq_id])
					continue
				if(isnull(depth_of[prereq_id]))
					ready = FALSE
					break
				max_prereq_depth = max(max_prereq_depth, depth_of[prereq_id])

			if(!ready)
				continue

			depth_of[node_id] = max_prereq_depth + 1
			pending -= node_id
			progressed = TRUE

		if(!progressed)
			for(var/node_id in pending)
				depth_of[node_id] = 0
			break


	for(var/node_id in depth_of)
		var/datum/techweb_node/rw/node = rw_nodes[node_id]
		if(node)
			node.ui_depth = depth_of[node_id]
	var/list/era_rank = list()
	var/era_i = 0
	for(var/era in RW_TECH_ERA_ORDER)
		era_rank[era] = era_i++

	var/list/list/by_era = list()
	for(var/era in RW_TECH_ERA_ORDER)
		by_era[era] = list()

	for(var/node_id in rw_nodes)
		var/datum/techweb_node/rw/node = rw_nodes[node_id]
		var/era = node.tech_era
		if(!by_era[era])
			by_era[era] = list()
		by_era[era] += node

	var/const/GROUP_GAP = 1

	for(var/era in RW_TECH_ERA_ORDER)
		var/list/column = by_era[era]
		if(!length(column))
			continue

		sortTim(column, GLOBAL_PROC_REF(cmp_rw_node_layout_within_era))

		var/x = era_rank[era]
		var/y = 0
		var/last_group = null
		var/last_depth = null

		for(var/datum/techweb_node/rw/node as anything in column)
			var/d = depth_of[node.id] || 0
			if(!isnull(last_depth) && d != last_depth)
				y += 1
				last_group = null
			else if(!isnull(last_group) && node.group_id != last_group)
				y += GROUP_GAP

			node.ui_x = x
			node.ui_y = y
			y++
			last_group = node.group_id
			last_depth = d


/proc/cmp_rw_node_layout_within_era(datum/techweb_node/rw/a, datum/techweb_node/rw/b)
	if(a.ui_depth != b.ui_depth)
		return a.ui_depth - b.ui_depth

	var/group_cmp = sorttext(a.group_id || "general", b.group_id || "general")
	if(group_cmp != 0)
		return group_cmp

	return sorttext(a.display_name, b.display_name)

/datum/techweb/faction
	id = "FACTION"
	organization = "Independent Colony"
	should_generate_points = FALSE

	var/datum/rw_faction/player/owner_faction

	var/current_research_id = null
	var/list/research_queue = list()

	var/list/research_progress = list()

	var/list/unlocked_blueprints = list()
	var/list/unlocked_recipes = list()

	var/list/obj/machinery/rw_workbench/benches = list()

/datum/techweb/faction/New()
	. = ..()
	grant_starting_nodes()

/datum/techweb/faction/Destroy()
	for(var/obj/machinery/rw_workbench/bench as anything in benches)
		bench.owner_faction = null
	benches.Cut()
	owner_faction = null
	return ..()

/datum/techweb/faction/proc/get_rw_node(node_id)
	var/datum/techweb_node/rw/node = SSresearch.techweb_node_by_id(node_id)
	return istype(node) ? node : null

/datum/techweb/faction/proc/grant_starting_nodes()
	for(var/node_id in SSresearch.techweb_nodes)
		var/datum/techweb_node/rw/node = SSresearch.techweb_nodes[node_id]
		if(!istype(node) || !(node.rw_flags & RW_RESEARCH_STARTING) || researched_nodes[node_id])
			continue
		apply_node(node)

/datum/techweb/faction/proc/apply_node(datum/techweb_node/rw/node)
	researched_nodes[node.id] = TRUE
	for(var/blueprint_id in node.blueprint_ids)
		unlock_blueprint(blueprint_id)
	for(var/recipe_id in node.recipe_ids)
		unlock_recipe(recipe_id)

/datum/techweb/faction/proc/unlock_blueprint(blueprint_id)
	if(!SSresearch.get_building_blueprint(blueprint_id))
		stack_trace("Research node references unknown building blueprint '[blueprint_id]'")
		return FALSE
	unlocked_blueprints[blueprint_id] = TRUE
	return TRUE

/datum/techweb/faction/proc/unlock_recipe(recipe_id)
	if(!SSresearch.get_rw_crafting_recipe(recipe_id))
		stack_trace("Research node references unknown crafting recipe '[recipe_id]'")
		return FALSE
	unlocked_recipes[recipe_id] = TRUE
	return TRUE

/datum/techweb/faction/proc/has_blueprint(blueprint_id)
	return !!unlocked_blueprints[blueprint_id]

/datum/techweb/faction/proc/has_recipe(recipe_id)
	return !!unlocked_recipes[recipe_id]

/datum/techweb/faction/proc/is_node_visible(datum/techweb_node/rw/node)
	if(node.rw_flags & RW_RESEARCH_DISABLED)
		return FALSE
	if(!(node.rw_flags & RW_RESEARCH_HIDDEN) || researched_nodes[node.id])
		return TRUE
	for(var/prereq_id in node.prereq_ids)
		if(researched_nodes[prereq_id])
			return TRUE
	return FALSE

/datum/techweb/faction/proc/can_start_research(datum/techweb_node/rw/node)
	if(!istype(node) || researched_nodes[node.id] || !is_node_visible(node))
		return FALSE
	for(var/prereq_id in node.prereq_ids)
		if(!researched_nodes[prereq_id])
			return FALSE
	return TRUE

/datum/techweb/faction/proc/can_enqueue_research(datum/techweb_node/rw/node)
	if(!istype(node) || researched_nodes[node.id] || !is_node_visible(node))
		return FALSE
	if(node.id == current_research_id || (node.id in research_queue))
		return FALSE
	for(var/prereq_id in node.prereq_ids)
		if(researched_nodes[prereq_id] || prereq_id == current_research_id || (prereq_id in research_queue))
			continue
		return FALSE
	return TRUE

/datum/techweb/faction/proc/set_current_research(node_id, mob/user)
	var/datum/techweb_node/rw/node = get_rw_node(node_id)
	if(!node || !can_start_research(node))
		return FALSE
	if(current_research_id == node_id)
		return FALSE
	if(current_research_id)
		research_queue.Insert(1, current_research_id)
	current_research_id = node_id
	research_queue -= node_id
	return TRUE

/datum/techweb/faction/proc/enqueue_research(node_id)
	var/datum/techweb_node/rw/node = get_rw_node(node_id)
	if(!can_enqueue_research(node))
		return FALSE
	research_queue += node_id
	advance_queue()
	return TRUE

/datum/techweb/faction/proc/dequeue_research(node_id)
	if(!(node_id in research_queue))
		return FALSE
	research_queue -= node_id
	prune_queue()
	return TRUE

/datum/techweb/faction/proc/clear_queue()
	if(!length(research_queue))
		return FALSE
	research_queue.Cut()
	return TRUE

/datum/techweb/faction/proc/move_in_queue(node_id, direction)
	var/index = research_queue.Find(node_id)
	if(!index)
		return FALSE
	var/new_index = index + (direction < 0 ? -1 : 1)
	if(new_index < 1 || new_index > length(research_queue))
		return FALSE
	research_queue.Swap(index, new_index)
	return TRUE

/datum/techweb/faction/proc/cancel_current_research()
	if(!current_research_id)
		return FALSE
	current_research_id = null
	prune_queue()
	advance_queue()
	return TRUE

/datum/techweb/faction/proc/advance_queue()
	if(current_research_id)
		return FALSE
	for(var/next_id in research_queue.Copy())
		var/datum/techweb_node/rw/node = get_rw_node(next_id)
		if(!node || researched_nodes[next_id] || (node.rw_flags & RW_RESEARCH_DISABLED))
			research_queue -= next_id
			continue
		if(can_start_research(node))
			research_queue -= next_id
			current_research_id = next_id
			return TRUE
	return FALSE

/datum/techweb/faction/proc/prune_queue()
	var/changed = TRUE
	while(changed)
		changed = FALSE
		for(var/queued_id in research_queue.Copy())
			var/datum/techweb_node/rw/node = get_rw_node(queued_id)
			var/keep = istype(node) && !researched_nodes[queued_id]
			if(keep)
				for(var/prereq_id in node.prereq_ids)
					if(researched_nodes[prereq_id] || prereq_id == current_research_id || (prereq_id in research_queue))
						continue
					keep = FALSE
					break
			if(!keep)
				research_queue -= queued_id
				changed = TRUE

/datum/techweb/faction/proc/add_research_progress(amount)
	if(!current_research_id)
		return

	var/datum/techweb_node/rw/node = get_rw_node(current_research_id)
	if(!node)
		current_research_id = null
		advance_queue()
		return

	research_progress[current_research_id] = (research_progress[current_research_id] || 0) + amount

	if(research_progress[current_research_id] >= max(1, node.research_cost))
		finish_research(node)

/datum/techweb/faction/proc/finish_research(datum/techweb_node/rw/node)
	apply_node(node)
	research_progress -= node.id
	if(current_research_id == node.id)
		current_research_id = null

	var/had_next = advance_queue()

	if(owner_faction)
		var/datum/techweb_node/rw/next_node = had_next ? get_rw_node(current_research_id) : null
		for(var/mob/living/M in owner_faction.members)
			to_chat(M, span_boldnotice("Research completed: [node.display_name]"))
			if(next_node)
				to_chat(M, span_notice("Now researching: [next_node.display_name]"))

/datum/techweb/faction/proc/get_bench_status()
	if(!current_research_id)
		return list("ready" = FALSE, "text" = "Nothing is being researched.")
	var/datum/techweb_node/rw/node = get_rw_node(current_research_id)
	if(!node)
		return list("ready" = FALSE, "text" = "Unknown research.")
	if(!length(benches))
		return list("ready" = FALSE, "text" = "The faction has no workbenches.")

	var/list/missing
	for(var/obj/machinery/rw_workbench/bench as anything in benches)
		var/obj/machinery/rw_workbench/research/research_bench = bench
		if(!istype(research_bench))
			continue
		if(research_bench.can_research(node))
			return list("ready" = TRUE, "text" = "Workbench is operational.")
		if(!research_bench.is_valid_for_node(node))
			continue
		if(!length(missing))
			missing = research_bench.get_missing_attachments(node)

	if(length(missing))
		return list("ready" = FALSE, "text" = "Missing next to a workbench: [english_list(missing)].")
	var/list/names = node.get_workbench_names()
	if(length(names))
		return list("ready" = FALSE, "text" = "Needs workbench: [english_list(names)].")
	return list("ready" = FALSE, "text" = "No working research workbench.")


/datum/techweb/faction/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "FactionResearch", "Research")
		ui.open()

/datum/techweb/faction/ui_state(mob/user)
	if(owner_faction?.is_member(user))
		return GLOB.not_incapacitated_state
	return GLOB.never_state

/datum/techweb/faction/ui_static_data(mob/user)
	var/list/data = list()
	var/list/nodes = list()

	for(var/node_id in SSresearch.techweb_nodes)
		var/datum/techweb_node/rw/node = SSresearch.techweb_nodes[node_id]
		if(!istype(node) || istype(node, /datum/techweb_node/rw/error))
			continue

		var/list/flags = list()
		if(node.rw_flags & RW_RESEARCH_HIDDEN)
			flags += "hidden"
		if(node.rw_flags & RW_RESEARCH_STARTING)
			flags += "starting"
		if(node.rw_flags & RW_RESEARCH_DISABLED)
			flags += "disabled"

		var/list/prereq_list = list()
		for(var/prereq_id in node.prereq_ids)
			prereq_list += prereq_id

		var/list/rewards = list()
		for(var/blueprint_id in node.blueprint_ids)
			var/datum/building_blueprint/blueprint = SSresearch.get_building_blueprint(blueprint_id)
			rewards += list(list("kind" = "blueprint", "name" = blueprint ? blueprint.name : "[blueprint_id]"))
		for(var/recipe_id in node.recipe_ids)
			var/datum/rw_crafting_recipe/recipe = SSresearch.get_rw_crafting_recipe(recipe_id)
			rewards += list(list("kind" = "recipe", "name" = recipe ? recipe.name : "[recipe_id]"))

		nodes += list(list(
			"id" = node.id,
			"name" = node.display_name,
			"desc" = node.description,
			"cost" = node.research_cost,
			"prereqs" = prereq_list,
			"benches" = node.get_workbench_names(),
			"attachments" = node.get_attachment_names(),
			"flags" = flags,
			"rewards" = rewards,
			"era" = node.tech_era,
			"ui_x" = node.ui_x,
			"ui_y" = node.ui_y,
		))

	data["nodes"] = nodes
	return data
/datum/techweb/faction/ui_data(mob/user)
	var/list/data = list()

	var/list/researched = list()
	for(var/node_id in researched_nodes)
		if(researched_nodes[node_id])
			researched += node_id
	data["researched"] = researched
	data["current"] = current_research_id
	data["progress"] = research_progress.Copy()
	data["queue"] = research_queue.Copy()
	data["can_manage"] = !!owner_faction?.can_manage_research(user)

	var/list/bench_status = get_bench_status()
	data["bench_ready"] = bench_status["ready"]
	data["bench_text"] = bench_status["text"]
	return data

/datum/techweb/faction/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	var/mob/living/user = ui.user
	if(!owner_faction?.can_manage_research(user))
		user.balloon_alert(user, "researchers only!")
		return FALSE

	var/node_id = params["id"]
	if(!isnull(node_id) && !istext(node_id))
		return FALSE

	switch(action)
		if("enqueue")
			return enqueue_research(node_id)
		if("dequeue")
			return dequeue_research(node_id)
		if("start_now")
			return set_current_research(node_id, user)
		if("cancel_current")
			return cancel_current_research()
		if("queue_move")
			return move_in_queue(node_id, text2num(params["dir"]))
		if("clear_queue")
			return clear_queue()

	return FALSE
