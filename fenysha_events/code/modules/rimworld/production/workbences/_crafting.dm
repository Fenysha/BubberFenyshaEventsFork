/**
 * One queued craft on a workbench. The first job in the bench queue is the active one.
 */
/datum/rw_craft_job
	var/datum/rw_crafting_recipe/recipe
	var/uid
	/// ingredient typepath => amount already on the bench.
	var/list/delivered = list()
	var/state = RW_JOB_COLLECTING
	var/steps_done = 0
	var/working = FALSE
	var/obj/item/rw_workpiece/workpiece

/datum/rw_craft_job/New(datum/rw_crafting_recipe/_recipe)
	var/static/next_uid = 0
	recipe = _recipe
	uid = ++next_uid
	for(var/path in recipe.requirements)
		delivered[path] = 0

/datum/rw_craft_job/Destroy(force)
	if(!QDELETED(workpiece))
		workpiece.job = null
		qdel(workpiece)
	workpiece = null
	recipe = null
	return ..()

/datum/rw_craft_job/proc/match_need(obj/item/I)
	for(var/path in recipe.requirements)
		if(delivered[path] < recipe.requirements[path] && istype(I, path))
			return path
	return null

/datum/rw_craft_job/proc/is_filled()
	for(var/path in recipe.requirements)
		if(delivered[path] < recipe.requirements[path])
			return FALSE
	return TRUE

/datum/rw_craft_job/proc/get_missing_text()
	var/list/lines = list()
	for(var/path in recipe.requirements)
		var/left = recipe.requirements[path] - delivered[path]
		if(left <= 0)
			continue
		var/atom/A = path
		lines += "[left]x [initial(A.name)]"
	return english_list(lines, "nothing")

/datum/rw_craft_job/proc/get_progress()
	if(state == RW_JOB_WORKPIECE)
		return steps_done / max(1, recipe.get_total_steps())
	return 0


/obj/machinery/rw_workbench/crafting
	name = "crafting station"
	desc = "A general-purpose crafting station."
	icon_state = "crafting_bench"
	can_do_crafting = TRUE

	/// How many recipes can wait on this bench at once. The first one is the active job.
	var/max_queue = 1
	var/list/datum/rw_craft_job/queue = list()

/obj/machinery/rw_workbench/crafting/Destroy()
	clear_queue(TRUE)
	return ..()

/obj/machinery/rw_workbench/crafting/proc/active_job()
	return length(queue) ? queue[1] : null

/obj/machinery/rw_workbench/crafting/proc/get_job(uid)
	for(var/datum/rw_craft_job/job as anything in queue)
		if(job.uid == uid)
			return job
	return null

/obj/machinery/rw_workbench/crafting/proc/is_operational()
	return !QDELETED(src) && anchored && !(machine_stat & (BROKEN|NOPOWER))

/obj/machinery/rw_workbench/crafting/proc/job_still_valid(datum/rw_craft_job/job)
	return is_operational() && !QDELETED(job) && (job in queue)

/obj/machinery/rw_workbench/crafting/proc/is_workpiece_on_bench(datum/rw_craft_job/job)
	if(!job?.workpiece || QDELETED(job.workpiece))
		return FALSE
	return get_turf(job.workpiece) == get_turf(src)

/obj/machinery/rw_workbench/crafting/proc/can_continue_workpiece(datum/rw_craft_job/job)
	return job_still_valid(job) && is_workpiece_on_bench(job)

/obj/machinery/rw_workbench/crafting/proc/refresh_all()
	update_appearance(UPDATE_OVERLAYS)
	SStgui.update_uis(src)


/obj/machinery/rw_workbench/crafting/proc/add_job(mob/living/user, recipe_id)
	var/datum/rw_faction/player/F = get_crafting_faction(user)
	var/datum/techweb/faction/web = F?.techweb
	if(!web)
		balloon_alert(user, "no faction access")
		return FALSE
	if(!is_operational())
		balloon_alert(user, "workbench unavailable")
		return FALSE
	if(!web.unlocked_recipes[recipe_id])
		balloon_alert(user, "recipe not researched")
		return FALSE

	var/datum/rw_crafting_recipe/recipe = SSresearch.get_rw_crafting_recipe(recipe_id)
	if(!accepts_recipe(recipe) || !ispath(recipe.result_path, /obj/item))
		balloon_alert(user, "recipe unavailable here")
		return FALSE
	if(!check_skill(user, recipe.required_skill, recipe.min_skill))
		return FALSE

	if(length(queue) >= max_queue)
		var/datum/rw_craft_job/first = queue[1]
		// With a single slot, picking another recipe swaps out a job that has not really started.
		if(max_queue == 1 && first.state == RW_JOB_COLLECTING && !first.working)
			remove_job(first, TRUE)
		else
			balloon_alert(user, "queue is full")
			return FALSE

	queue += new /datum/rw_craft_job(recipe)
	balloon_alert(user, "[recipe.name] selected")
	refresh_all()
	return TRUE

/obj/machinery/rw_workbench/crafting/proc/remove_job(datum/rw_craft_job/job, refund = TRUE)
	if(!job || !(job in queue))
		return FALSE
	if(job.working)
		return FALSE
	if(refund)
		drop_job_items(job)
	queue -= job
	qdel(job)
	refresh_all()
	return TRUE

/obj/machinery/rw_workbench/crafting/proc/clear_queue(refund = TRUE)
	for(var/datum/rw_craft_job/job as anything in queue.Copy())
		job.working = FALSE
		remove_job(job, refund)

/// Returns delivered ingredients to the floor. Materials already worked into a workpiece are lost.
/obj/machinery/rw_workbench/crafting/proc/drop_job_items(datum/rw_craft_job/job)
	if(job.steps_done > 0)
		return
	var/turf/T = get_turf(src)
	if(!T)
		return
	for(var/path in job.delivered)
		var/amount = job.delivered[path]
		if(amount <= 0)
			continue
		if(ispath(path, /obj/item/stack))
			new path(T, amount)
		else
			for(var/i in 1 to amount)
				new path(T)
		job.delivered[path] = 0


/obj/machinery/rw_workbench/crafting/proc/can_user_deliver(mob/living/user, silent = FALSE)
	if(!istype(user) || QDELETED(src))
		return FALSE
	if(!get_crafting_faction(user))
		if(!silent)
			balloon_alert(user, "no faction access")
		return FALSE
	if(!is_operational())
		if(!silent)
			balloon_alert(user, "workbench unavailable")
		return FALSE
	return TRUE

/**
 * Moves (part of) an item onto the bench as an ingredient of the active job.
 * Returns TRUE if anything was delivered.
 */
/obj/machinery/rw_workbench/crafting/proc/deliver(mob/living/user, obj/item/I, silent = FALSE)
	var/datum/rw_craft_job/job = active_job()
	if(!job || job.state != RW_JOB_COLLECTING || job.working)
		return FALSE
	if(QDELETED(I))
		return FALSE
	var/need_path = job.match_need(I)
	if(!need_path)
		return FALSE

	var/left = job.recipe.requirements[need_path] - job.delivered[need_path]
	var/taken = 0
	if(istype(I, /obj/item/stack))
		var/obj/item/stack/S = I
		taken = min(S.amount, left)
		if(taken <= 0 || !S.use(taken))
			return FALSE
	else
		if(I.loc == user && !user.temporarilyRemoveItemFromInventory(I))
			return FALSE
		qdel(I)
		taken = 1

	job.delivered[need_path] += taken
	if(!silent)
		balloon_alert(user, "+[taken] added")
	refresh_all()

	if(job.is_filled())
		on_job_filled(user, job)
	return TRUE

/// Puts every matching ingredient the user carries onto the bench.
/obj/machinery/rw_workbench/crafting/proc/deliver_carried(mob/living/user)
	var/datum/rw_craft_job/job = active_job()
	if(!job || job.state != RW_JOB_COLLECTING)
		return FALSE
	var/delivered_any = FALSE
	for(var/obj/item/I as anything in user.get_all_contents())
		if(job.state != RW_JOB_COLLECTING)
			break
		if(!rw_item_is_available(user, I) || !job.match_need(I))
			continue
		if(deliver(user, I, silent = TRUE))
			delivered_any = TRUE
	if(!delivered_any && job.state == RW_JOB_COLLECTING)
		balloon_alert(user, "nothing to add")
	return delivered_any

/obj/machinery/rw_workbench/crafting/attackby(obj/item/I, mob/living/user, params)
	// Allow placing a workpiece back onto the bench
	if(istype(I, /obj/item/rw_workpiece))
		var/obj/item/rw_workpiece/W = I
		if(W.job && (W.job in queue) && W.job.state == RW_JOB_WORKPIECE)
			if(user.transferItemToLoc(W, get_turf(src)))
				W.pixel_x = 0
				W.pixel_y = RW_WORKPIECE_PIXEL_Y
				balloon_alert(user, "workpiece placed")
				refresh_all()
				return TRUE

	if(!istype(user) || user.combat_mode || !active_job())
		return ..()
	var/datum/rw_craft_job/job = active_job()
	if(!job.match_need(I))
		return ..()
	if(!can_user_deliver(user))
		return TRUE
	deliver(user, I)
	return TRUE

/obj/machinery/rw_workbench/crafting/mouse_drop_dragged(atom/over, mob/user, src_location, over_location, params)
	if(!isliving(user) || !isitem(over) || !.)
		return
	var/mob/living/L = user
	var/obj/item/I = over
	var/datum/rw_craft_job/job = active_job()
	if(!job || !job.match_need(I))
		return ..()
	if(get_dist(L, src) > 1 || (I.loc != L && get_dist(L, I) > 1))
		return
	if(!can_user_deliver(L))
		return
	deliver(L, I)


/obj/machinery/rw_workbench/crafting/proc/on_job_filled(mob/living/user, datum/rw_craft_job/job)
	if(job.recipe.is_workpiece())
		absorb_into_workpiece(job)
		balloon_alert(user, "workpiece ready")
		return
	job.state = RW_JOB_READY
	INVOKE_ASYNC(src, PROC_REF(run_deliver_craft), user, job)

/// Click the bench / press "Work" to move the active job forward.
/obj/machinery/rw_workbench/crafting/proc/work_job(mob/living/user)
	var/datum/rw_craft_job/job = active_job()
	if(!job)
		balloon_alert(user, "no recipe selected")
		return FALSE
	if(job.working)
		return FALSE
	if(!can_user_deliver(user))
		return FALSE
	if(get_dist(user, src) > 1)
		return FALSE
	switch(job.state)
		if(RW_JOB_COLLECTING)
			balloon_alert(user, "needs: [job.get_missing_text()]")
			return FALSE
		if(RW_JOB_READY)
			INVOKE_ASYNC(src, PROC_REF(run_deliver_craft), user, job)
			return TRUE
		if(RW_JOB_WORKPIECE)
			if(!is_workpiece_on_bench(job))
				balloon_alert(user, "place the workpiece on the bench")
				return FALSE
			INVOKE_ASYNC(src, PROC_REF(run_workpiece_steps), user, job)
			return TRUE
	return FALSE

/// Type A: ingredients are on the bench, run the one timed craft.
/obj/machinery/rw_workbench/crafting/proc/run_deliver_craft(mob/living/user, datum/rw_craft_job/job)
	if(!job_still_valid(job) || job.working || job.state != RW_JOB_READY)
		return
	var/datum/rw_crafting_recipe/recipe = job.recipe
	if(!check_skill(user, recipe.required_skill, recipe.min_skill))
		return

	job.working = TRUE
	update_use_power(ACTIVE_POWER_USE)
	refresh_all()

	var/ok = rw_do_after(
		user,
		recipe.crafting_time,
		src,
		recipe.required_skill,
		recipe.ideal_skill,
		minimum_delay = 0.5 SECONDS,
		skill_points = recipe.skill_xp,
		show_progress = TRUE,
		extra_checks = CALLBACK(src, PROC_REF(job_still_valid), job),
	)

	if(QDELETED(src))
		return
	update_use_power(IDLE_POWER_USE)
	if(QDELETED(job))
		refresh_all()
		return
	job.working = FALSE

	if(!ok || !job_still_valid(job))
		refresh_all()
		return
	finish_job(user, job)

/// Moves the ingredients into a workpiece: overlays fly into it, then the workpiece fades in.
/obj/machinery/rw_workbench/crafting/proc/absorb_into_workpiece(datum/rw_craft_job/job)
	var/turf/T = get_turf(src)
	if(!T)
		return

	for(var/list/entry as anything in get_job_overlay_entries(job))
		new /obj/effect/temp_visual/rw_craft_absorb(T, entry["icon"], entry["icon_state"], entry["x"], entry["y"], 0, RW_WORKPIECE_PIXEL_Y)

	job.state = RW_JOB_WORKPIECE
	var/obj/item/rw_workpiece/W = new(T, job, src)
	job.workpiece = W
	addtimer(CALLBACK(W, TYPE_PROC_REF(/obj/item/rw_workpiece, reveal)), 0.4 SECONDS)
	refresh_all()

/// Type B: work on the workpiece, step after step, until finished or interrupted.
/obj/machinery/rw_workbench/crafting/proc/run_workpiece_steps(mob/living/user, datum/rw_craft_job/job)
	if(!job_still_valid(job) || job.working || job.state != RW_JOB_WORKPIECE)
		return
	if(!is_workpiece_on_bench(job))
		balloon_alert(user, "place the workpiece on the bench")
		return

	var/datum/rw_crafting_recipe/recipe = job.recipe
	if(!check_skill(user, recipe.required_skill, recipe.min_skill))
		return

	var/total = recipe.get_total_steps()
	job.working = TRUE
	update_use_power(ACTIVE_POWER_USE)
	refresh_all()

	while(can_continue_workpiece(job) && job.steps_done < total)
		var/atom/target = job.workpiece || src
		var/ok = rw_do_after(
			user,
			recipe.get_step_time(),
			target,
			recipe.required_skill,
			recipe.ideal_skill,
			minimum_delay = 0.5 SECONDS,
			skill_points = recipe.skill_xp,
			show_progress = TRUE,
			extra_checks = CALLBACK(src, PROC_REF(can_continue_workpiece), job),
		)
		if(!ok || !can_continue_workpiece(job))
			break
		job.steps_done++
		job.workpiece?.refresh_look()
		SStgui.update_uis(src)

	if(QDELETED(src))
		return
	update_use_power(IDLE_POWER_USE)
	if(QDELETED(job))
		refresh_all()
		return
	job.working = FALSE
	refresh_all()

	if(job_still_valid(job) && job.steps_done >= total)
		finish_job(user, job)

/obj/machinery/rw_workbench/crafting/proc/finish_job(mob/living/user, datum/rw_craft_job/job)
	var/datum/rw_crafting_recipe/recipe = job.recipe
	var/turf/drop_turf = get_turf(src)
	if(!drop_turf)
		return FALSE

	queue -= job
	qdel(job) // also removes the workpiece

	var/amount = max(1, recipe.result_amount)
	var/list/made = list()
	if(ispath(recipe.result_path, /obj/item/stack))
		made += new recipe.result_path(drop_turf, amount)
	else
		for(var/i in 1 to amount)
			made += new recipe.result_path(drop_turf)

	if(istype(user) && !QDELETED(user) && get_dist(user, src) <= 1)
		for(var/obj/item/result as anything in made)
			if(!QDELETED(result))
				user.put_in_hands(result)
		user.balloon_alert(user, "crafted [recipe.name]")
	refresh_all()
	return TRUE


/// Offsets (pixel_x, pixel_y) of ingredient icons lying on the bench top.
GLOBAL_LIST_INIT(rw_bench_item_slots, list(
	list(-9, 10), list(0, 12), list(9, 10),
	list(-9, 2), list(0, 4), list(9, 2),
	list(-4, 7), list(5, 7),
))

/obj/machinery/rw_workbench/crafting/proc/get_job_overlay_entries(datum/rw_craft_job/job)
	var/list/entries = list()
	if(!job)
		return entries
	var/list/slots = GLOB.rw_bench_item_slots
	var/used = 0
	for(var/path in job.delivered)
		var/count = job.delivered[path]
		if(count <= 0 || !ispath(path, /obj/item))
			continue
		var/obj/item/item_type = path
		// Up to two copies per ingredient so a big stack still looks like a pile.
		for(var/n in 1 to min(count, 2))
			if(used >= length(slots))
				return entries
			var/list/slot = slots[++used]
			entries += list(list(
				"icon" = initial(item_type.icon),
				"icon_state" = initial(item_type.icon_state),
				"x" = slot[1],
				"y" = slot[2],
			))
	return entries

/obj/machinery/rw_workbench/crafting/update_overlays()
	. = ..()
	var/datum/rw_craft_job/job = active_job()
	if(!job || job.state == RW_JOB_WORKPIECE)
		return
	for(var/list/entry as anything in get_job_overlay_entries(job))
		var/mutable_appearance/MA = mutable_appearance(entry["icon"], entry["icon_state"], layer + 0.1)
		MA.transform = matrix().Scale(RW_CRAFT_OVERLAY_SCALE)
		MA.pixel_x = entry["x"]
		MA.pixel_y = entry["y"]
		. += MA


/obj/machinery/rw_workbench/crafting/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(.)
		return
	ui_interact(user)

/obj/machinery/rw_workbench/crafting/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RWWorkbench", name)
		ui.open()

/obj/machinery/rw_workbench/crafting/ui_state(mob/user)
	if(!isliving(user))
		return GLOB.never_state
	if(owner_faction && !owner_faction.is_member(user))
		return GLOB.never_state
	return GLOB.not_incapacitated_state

/obj/machinery/rw_workbench/crafting/ui_static_data(mob/user)
	var/list/data = list()
	SSresearch.init_rw_registries()

	var/list/icons = list()
	for(var/recipe_id in SSresearch.rw_crafting_recipes)
		var/datum/rw_crafting_recipe/recipe = SSresearch.rw_crafting_recipes[recipe_id]
		if(!accepts_recipe(recipe) || !ispath(recipe.result_path, /obj/item))
			continue
		icons["[recipe.result_path]"] = rw_get_recipe_item_icon_src(recipe.result_path)
		for(var/item_path in recipe.requirements)
			icons["[item_path]"] = rw_get_recipe_item_icon_src(item_path)
	data["icons"] = icons
	return data

/obj/machinery/rw_workbench/crafting/ui_data(mob/user)
	var/list/data = list()
	var/mob/living/L = user
	var/datum/rw_faction/player/F = get_crafting_faction(L)
	var/datum/techweb/faction/web = F?.techweb
	var/list/contents = L ? L.get_all_contents() : list()
	var/datum/rw_craft_job/active = active_job()

	data["bench_name"] = name
	data["has_faction"] = !!F
	data["can_craft"] = !!F && is_operational()
	data["busy"] = !!active?.working
	data["max_queue"] = max_queue
	data["message"] = ""
	if(!F)
		data["message"] = owner_faction ? "This workbench belongs to another faction." : "Join a faction to use researched crafting recipes."
	else if(machine_stat & BROKEN)
		data["message"] = "The workbench is broken."
	else if(machine_stat & NOPOWER)
		data["message"] = "The workbench has no power."

	// Available recipes (right side of the UI)
	var/list/recipes = list()
	if(web)
		for(var/recipe_id in web.unlocked_recipes)
			if(!web.unlocked_recipes[recipe_id])
				continue
			var/datum/rw_crafting_recipe/recipe = SSresearch.get_rw_crafting_recipe(recipe_id)
			if(!accepts_recipe(recipe) || !ispath(recipe.result_path, /obj/item))
				continue

			var/list/requirements = list()
			for(var/item_path in recipe.requirements)
				var/atom/item_type = item_path
				requirements += list(list(
					"path" = "[item_path]",
					"name" = initial(item_type.name),
					"amount" = recipe.requirements[item_path],
					"carried" = rw_count_items_of_type(L, item_path, contents),
				))

			var/obj/item/result_type = recipe.result_path
			var/user_skill = RW_GET_SKILL(L, recipe.required_skill)
			recipes += list(list(
				"id" = recipe.id,
				"name" = recipe.name,
				"desc" = recipe.desc,
				"category" = recipe.category,
				"craft_type" = recipe.craft_type,
				"crafting_time" = recipe.crafting_time / 10,
				"steps" = recipe.get_total_steps(),
				"result_name" = initial(result_type.name),
				"result_path" = "[recipe.result_path]",
				"result_amount" = recipe.result_amount,
				"requirements" = requirements,
				"skill" = list(
					"id" = recipe.required_skill,
					"name" = rw_get_skill_name(recipe.required_skill),
					"min" = recipe.min_skill,
					"ideal" = recipe.ideal_skill,
					"user" = user_skill,
					"ok" = user_skill >= recipe.min_skill,
				),
			))
	data["recipes"] = recipes

	// Queue (left side of the UI). The first entry is the active job.
	var/list/queue_data = list()
	for(var/datum/rw_craft_job/job as anything in queue)
		var/datum/rw_crafting_recipe/job_recipe = job.recipe
		var/list/reqs = list()
		for(var/item_path in job_recipe.requirements)
			var/atom/item_type = item_path
			reqs += list(list(
				"path" = "[item_path]",
				"name" = initial(item_type.name),
				"amount" = job_recipe.requirements[item_path],
				"delivered" = job.delivered[item_path],
				"carried" = rw_count_items_of_type(L, item_path, contents),
			))
		var/obj/item/job_result = job_recipe.result_path
		var/job_skill = RW_GET_SKILL(L, job_recipe.required_skill)
		queue_data += list(list(
			"uid" = job.uid,
			"recipe_id" = job_recipe.id,
			"name" = job_recipe.name,
			"desc" = job_recipe.desc,
			"craft_type" = job_recipe.craft_type,
			"state" = job.state,
			"steps" = job_recipe.get_total_steps(),
			"steps_done" = job.steps_done,
			"working" = job.working,
			"filled" = job.is_filled(),
			"result_name" = initial(job_result.name),
			"result_path" = "[job_recipe.result_path]",
			"result_amount" = job_recipe.result_amount,
			"requirements" = reqs,
			"skill" = list(
				"name" = rw_get_skill_name(job_recipe.required_skill),
				"min" = job_recipe.min_skill,
				"user" = job_skill,
				"ok" = job_skill >= job_recipe.min_skill,
			),
		))
	data["queue"] = queue_data
	return data

/obj/machinery/rw_workbench/crafting/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/mob/living/user = ui.user
	if(!istype(user) || get_dist(user, src) > 1 || user.z != z)
		return FALSE

	switch(action)
		if("select_recipe")
			if(!istext(params["id"]))
				return FALSE
			return add_job(user, params["id"])
		if("cancel_job")
			var/datum/rw_craft_job/job = get_job(text2num(params["uid"]))
			if(!job)
				return FALSE
			if(job.working)
				balloon_alert(user, "busy")
				return FALSE
			return remove_job(job, TRUE)
		if("deliver_carried")
			if(!can_user_deliver(user))
				return FALSE
			return deliver_carried(user)
		if("work")
			return work_job(user)
	return FALSE


/**
 * The "blank" created from a workpiece recipe. It stores the recipe (through its job) and is
 * worked on step by step until it turns into the finished item.
 * Can be picked up and moved, but must be placed back on the workbench to continue working.
 */
/obj/item/rw_workpiece
	name = "workpiece"
	desc = "An unfinished piece of work."
	resistance_flags = INDESTRUCTIBLE

	var/datum/rw_craft_job/job
	var/obj/machinery/rw_workbench/crafting/bench
	var/revealed = FALSE

/obj/item/rw_workpiece/Initialize(mapload, datum/rw_craft_job/_job, obj/machinery/rw_workbench/crafting/_bench)
	. = ..()
	job = _job
	bench = _bench
	if(!job?.recipe)
		return INITIALIZE_HINT_QDEL
	var/obj/item/result_type = job.recipe.result_path
	icon = initial(result_type.icon)
	icon_state = initial(result_type.icon_state)
	pixel_y = RW_WORKPIECE_PIXEL_Y
	color = "#9fc4e8"
	alpha = 0

/obj/item/rw_workpiece/Destroy()
	if(job?.workpiece == src)
		job.workpiece = null
	job = null
	bench = null
	return ..()

/obj/item/rw_workpiece/proc/reveal()
	if(QDELETED(src))
		return
	revealed = TRUE
	refresh_look(animated = TRUE)

/obj/item/rw_workpiece/proc/refresh_look(animated = FALSE)
	if(!revealed || !job?.recipe)
		return
	var/obj/item/result_type = job.recipe.result_path
	var/total = job.recipe.get_total_steps()
	var/target_alpha = round(110 + 145 * job.get_progress())
	name = "unfinished [initial(result_type.name)]"
	desc = "A workpiece for [job.recipe.name]. Progress: [job.steps_done]/[total]. Place it on the workbench to continue."
	if(animated)
		animate(src, alpha = target_alpha, time = 0.3 SECONDS)
	else
		alpha = target_alpha

/obj/item/rw_workpiece/attack_hand(mob/living/user, list/modifiers)
	// If the workpiece is on its bench — click continues work instead of picking it up
	if(bench && !QDELETED(bench) && get_turf(src) == get_turf(bench) && !user.combat_mode)
		bench.work_job(user)
		return TRUE
	return ..()

/obj/item/rw_workpiece/attackby(obj/item/I, mob/living/user, params)
	if(user.combat_mode || !bench || QDELETED(bench))
		return ..()
	if(get_turf(src) == get_turf(bench))
		bench.work_job(user)
		return TRUE
	return ..()


/// Ingredient icon flying from the bench top into the workpiece.
/obj/effect/temp_visual/rw_craft_absorb
	duration = 5
	randomdir = FALSE
	layer = ABOVE_OBJ_LAYER + 0.2

/obj/effect/temp_visual/rw_craft_absorb/Initialize(mapload, _icon, _icon_state, start_x = 0, start_y = 0, end_x = 0, end_y = 0)
	. = ..()
	icon = _icon
	icon_state = _icon_state
	pixel_x = start_x
	pixel_y = start_y
	transform = matrix().Scale(RW_CRAFT_OVERLAY_SCALE)
	animate(src, time = duration, pixel_x = end_x, pixel_y = end_y, alpha = 0, transform = matrix().Scale(0.4), easing = SINE_EASING)


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
