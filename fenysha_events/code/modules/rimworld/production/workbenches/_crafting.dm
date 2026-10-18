/**
 * Crafting jobs & workbench logic, ported from /obj/machinery/rw_workbench
 * onto the lighter /obj/building/production hierarchy.
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


// =============================================================================
// Crafting production building
// =============================================================================

/obj/building/production/crafting
	name = "crafting station"
	desc = "A general-purpose crafting station."
	icon_state = "crafting_bench"
	can_do_crafting = TRUE

	/// How many recipes can wait on this bench at once. The first one is the active job.
	var/max_queue = 1
	var/list/datum/rw_craft_job/queue = list()

/obj/building/production/crafting/Destroy()
	clear_queue(TRUE)
	return ..()

/obj/building/production/crafting/proc/active_job()
	return length(queue) ? queue[1] : null

/obj/building/production/crafting/proc/get_job(uid)
	for(var/datum/rw_craft_job/job as anything in queue)
		if(job.uid == uid)
			return job
	return null

/obj/building/production/crafting/proc/job_still_valid(datum/rw_craft_job/job)
	return is_operational() && !QDELETED(job) && (job in queue)

/obj/building/production/crafting/proc/is_workpiece_on_bench(datum/rw_craft_job/job)
	if(!job?.workpiece || QDELETED(job.workpiece))
		return FALSE
	return get_turf(job.workpiece) == get_turf(src)

/obj/building/production/crafting/proc/can_continue_workpiece(datum/rw_craft_job/job)
	return job_still_valid(job) && is_workpiece_on_bench(job)

/obj/building/production/crafting/proc/refresh_all()
	update_appearance(UPDATE_OVERLAYS)
	SStgui.update_uis(src)

/obj/building/production/crafting/proc/add_job(mob/living/user, recipe_id)
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
		if(max_queue == 1 && first.state == RW_JOB_COLLECTING && !first.working)
			remove_job(first, TRUE)
		else
			balloon_alert(user, "queue is full")
			return FALSE

	queue += new /datum/rw_craft_job(recipe)
	balloon_alert(user, "[recipe.name] selected")
	refresh_all()
	return TRUE

/obj/building/production/crafting/proc/remove_job(datum/rw_craft_job/job, refund = TRUE)
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

/obj/building/production/crafting/proc/clear_queue(refund = TRUE)
	for(var/datum/rw_craft_job/job as anything in queue.Copy())
		job.working = FALSE
		remove_job(job, refund)

/obj/building/production/crafting/proc/drop_job_items(datum/rw_craft_job/job)
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

/obj/building/production/crafting/proc/can_user_deliver(mob/living/user, silent = FALSE)
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

/obj/building/production/crafting/proc/deliver(mob/living/user, obj/item/I, silent = FALSE)
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

/obj/building/production/crafting/proc/deliver_carried(mob/living/user)
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

/obj/building/production/crafting/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/rw_workpiece))
		var/obj/item/rw_workpiece/W = I
		if(W.job && (W.job in queue) && W.job.state == RW_JOB_WORKPIECE)
			if(user.transferItemToLoc(W, get_turf(src)))
				W.pixel_x = 0
				W.pixel_y = RW_WORKPIECE_PIXEL_Y
				balloon_alert(user, "workpiece placed")
				refresh_all()
				return TRUE

	if(needs_fuel() && istype(I, fuel_type))
		return refuel(I, user)

	if(!istype(user) || user.combat_mode || !active_job())
		return ..()
	var/datum/rw_craft_job/job = active_job()
	if(!job.match_need(I))
		return ..()
	if(!can_user_deliver(user))
		return TRUE
	deliver(user, I)
	return TRUE

/obj/building/production/crafting/proc/on_job_filled(mob/living/user, datum/rw_craft_job/job)
	if(job.recipe.is_workpiece())
		absorb_into_workpiece(job)
		balloon_alert(user, "workpiece ready")
		return
	job.state = RW_JOB_READY
	INVOKE_ASYNC(src, PROC_REF(run_deliver_craft), user, job)

/obj/building/production/crafting/proc/work_job(mob/living/user)
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

/// Type A: ingredients on the bench → one timed craft.
/obj/building/production/crafting/proc/run_deliver_craft(mob/living/user, datum/rw_craft_job/job)
	if(!job_still_valid(job) || job.working || job.state != RW_JOB_READY)
		return
	var/datum/rw_crafting_recipe/recipe = job.recipe
	if(!check_skill(user, recipe.required_skill, recipe.min_skill))
		return
	if(needs_fuel() && !has_fuel(fuel_per_tick))
		balloon_alert(user, "needs fuel")
		return

	job.working = TRUE
	begin_work()
	refresh_all()

	var/time = recipe.crafting_time / get_speed_multiplier()
	var/ok = rw_do_after(
		user,
		time,
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
	end_work()
	if(QDELETED(job))
		refresh_all()
		return
	job.working = FALSE

	if(!ok || !job_still_valid(job))
		refresh_all()
		return

	if(needs_fuel())
		consume_fuel(fuel_per_tick)

	finish_job(job)
	refresh_all()

/obj/building/production/crafting/proc/absorb_into_workpiece(datum/rw_craft_job/job)
	job.state = RW_JOB_WORKPIECE
	var/obj/item/rw_workpiece/W = new(get_turf(src), job, src)
	W.name = "workpiece ([job.recipe.name])"
	W.pixel_y = RW_WORKPIECE_PIXEL_Y
	job.workpiece = W
	// ingredients are consumed into the workpiece
	for(var/path in job.delivered)
		job.delivered[path] = 0
	refresh_all()

/obj/building/production/crafting/proc/run_workpiece_steps(mob/living/user, datum/rw_craft_job/job)
	if(!can_continue_workpiece(job) || job.working)
		return
	var/datum/rw_crafting_recipe/recipe = job.recipe
	if(!check_skill(user, recipe.required_skill, recipe.min_skill))
		return
	if(needs_fuel() && !has_fuel(fuel_per_tick))
		balloon_alert(user, "needs fuel")
		return

	job.working = TRUE
	begin_work()
	refresh_all()

	var/step_time = recipe.get_step_time() / get_speed_multiplier()
	var/ok = rw_do_after(
		user,
		step_time,
		src,
		recipe.required_skill,
		recipe.ideal_skill,
		minimum_delay = 0.5 SECONDS,
		skill_points = recipe.skill_xp,
		show_progress = TRUE,
		extra_checks = CALLBACK(src, PROC_REF(can_continue_workpiece), job),
	)

	if(QDELETED(src))
		return
	end_work()
	if(QDELETED(job))
		refresh_all()
		return
	job.working = FALSE

	if(!ok || !can_continue_workpiece(job))
		refresh_all()
		return

	if(needs_fuel())
		consume_fuel(fuel_per_tick)

	job.steps_done++
	if(job.steps_done >= recipe.get_total_steps())
		finish_job(job)
	refresh_all()

/obj/building/production/crafting/proc/finish_job(datum/rw_craft_job/job)
	if(!job || !(job in queue))
		return
	var/turf/T = get_turf(src)
	var/path = job.recipe.result_path
	var/amt = job.recipe.result_amount
	if(ispath(path, /obj/item/stack))
		new path(T, amt)
	else
		for(var/i in 1 to amt)
			new path(T)
	if(job.workpiece && !QDELETED(job.workpiece))
		qdel(job.workpiece)
	queue -= job
	qdel(job)

/// Override process_building only if the machine needs continuous passive work
/// (e.g. auto-smelters). Manual craft benches stay event-driven.
/obj/building/production/crafting/process_building(seconds_per_tick)
	return
