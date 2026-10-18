/**
 * Workpiece – intermediate item for RW_CRAFT_TYPE_WORKPIECE recipes.
 * Must sit on its originating bench to continue crafting steps.
 */
/obj/item/rw_workpiece
	name = "workpiece"
	desc = "An unfinished piece of work."
	resistance_flags = INDESTRUCTIBLE

	var/datum/rw_craft_job/job
	var/obj/building/production/crafting/bench
	var/revealed = FALSE

/obj/item/rw_workpiece/Initialize(mapload, datum/rw_craft_job/_job, obj/building/production/crafting/_bench)
	. = ..()
	if(_job)
		job = _job
	if(_bench)
		bench = _bench
	if(!job?.recipe)
		// Allowed to be created bare and filled later (absorb_into_workpiece path).
		return
	var/obj/item/result_type = job.recipe.result_path
	icon = initial(result_type.icon)
	icon_state = initial(result_type.icon_state)
	pixel_y = RW_WORKPIECE_PIXEL_Y
	color = "#9fc4e8"
	alpha = 0
	addtimer(CALLBACK(src, PROC_REF(reveal)), 0.4 SECONDS)

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
	if(!job?.recipe)
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
