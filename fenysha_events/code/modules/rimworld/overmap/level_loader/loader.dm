#define RW_CELL_LOAD_CONTINUE 0
#define RW_CELL_LOAD_COMPLETE 1
#define RW_CELL_LOAD_FAILED 2

#define RW_CELL_JOB_PREPARE 1
#define RW_CELL_JOB_PLACE 2
#define RW_CELL_JOB_INITIALIZE 3
#define RW_CELL_JOB_POPULATE 4
#define RW_CELL_JOB_LIGHTING 5
#define RW_CELL_JOB_DAYLIGHT 6
#define RW_CELL_JOB_FINISH 7


SUBSYSTEM_DEF(rimworld_sublevel_loader)
	name = "\[rw\] Sub-Level Loader"
	wait = 1
	ss_flags = SS_TICKER

	dependencies = list(
		/datum/controller/subsystem/atoms,
		/datum/controller/subsystem/mapping,
		/datum/controller/subsystem/sub_levels,
		/datum/controller/subsystem/lighting,
	)

	var/list/datum/rimworld_sublevel_load_job/load_queue = list()
	var/list/jobs_by_cell = list()


/datum/controller/subsystem/rimworld_sublevel_loader/stat_entry(msg)
	msg = "\n  Queue:[length(load_queue)]"
	return ..()


/**
 * Adds a planet cell to the asynchronous generation queue.
 *
 * post_load_callback is invoked as:
 *
 *     callback.Invoke(cell, TRUE)
 *
 * when generation finishes successfully.
 */
/datum/controller/subsystem/rimworld_sublevel_loader/proc/queue_cell(
	datum/planet_cell/cell,
	poi_name = null,
	datum/callback/post_load_callback = null
)
	if(!cell || QDELETED(cell))
		return FALSE

	if(!cell.is_valid())
		return FALSE

	/**
	 * Already loaded.
	 */
	if(cell.is_loaded())
		if(post_load_callback)
			post_load_callback.Invoke(cell, TRUE)
		return TRUE

	/**
	 * Already generating.
	 *
	 * Attach this callback to the existing job instead of creating a duplicate
	 * generation task.
	 */
	if(cell.loading_job)
		if(post_load_callback)
			cell.loading_job.add_callback(post_load_callback)

		return TRUE

	/**
	 * Check the subsystem queue as a safety fallback.
	 */
	if(cell.id && jobs_by_cell[cell.id])
		var/datum/rimworld_sublevel_load_job/existing_job = jobs_by_cell[cell.id]

		if(post_load_callback)
			existing_job.add_callback(post_load_callback)

		cell.loading_job = existing_job
		cell.is_generating = TRUE

		return TRUE

	var/datum/rimworld_sublevel_load_job/job = \
		new /datum/rimworld_sublevel_load_job(
			cell,
			poi_name,
			post_load_callback
		)

	load_queue += job

	if(cell.id)
		jobs_by_cell[cell.id] = job

	cell.loading_job = job
	cell.is_generating = TRUE

	return TRUE


/**
 * Cancels a queued generation.
 *
 * If generation is already running, its reservation and temporary generator
 * will be cleaned by the job's Destroy().
 */
/datum/controller/subsystem/rimworld_sublevel_loader/proc/cancel_cell(
	datum/planet_cell/cell
)
	if(!cell)
		return FALSE

	var/datum/rimworld_sublevel_load_job/job = cell.loading_job

	if(!job)
		if(cell.id)
			job = jobs_by_cell[cell.id]

	if(!job)
		return FALSE

	load_queue -= job

	if(cell.id && jobs_by_cell[cell.id] == job)
		jobs_by_cell -= cell.id

	if(cell.loading_job == job)
		cell.loading_job = null

	cell.is_generating = FALSE

	qdel(job)

	return TRUE


/datum/controller/subsystem/rimworld_sublevel_loader/proc/remove_job(
	datum/rimworld_sublevel_load_job/job
)
	if(!job)
		return

	load_queue -= job

	if(job.cell && job.cell.id)
		if(jobs_by_cell[job.cell.id] == job)
			jobs_by_cell -= job.cell.id


/datum/controller/subsystem/rimworld_sublevel_loader/fire(resumed)
	if(!length(load_queue))
		return

	var/datum/rimworld_sublevel_load_job/job = load_queue[1]

	if(!job || QDELETED(job))
		load_queue.Cut(1, 2)
		return

	var/result = job.process()

	switch(result)

		if(RW_CELL_LOAD_COMPLETE)
			job.notify_callbacks(TRUE)
			remove_job(job)
			qdel(job)

		if(RW_CELL_LOAD_FAILED)
			job.notify_callbacks(FALSE)
			remove_job(job)
			qdel(job)

		if(RW_CELL_LOAD_CONTINUE)
			/**
			 * Round-robin between multiple loading cells.
			 *
			 * This prevents one large cell from starving other cells queued
			 * for generation.
			 */
			if(length(load_queue) > 1)
				load_queue.Cut(1, 2)
				load_queue += job



/datum/rimworld_sublevel_load_job
	var/datum/planet_cell/cell
	var/poi_name

	var/datum/turf_reservation/sub_level/reservation
	var/datum/map_generator/sub_level/generator

	/**
	 * Current generation phase.
	 */
	var/phase = RW_CELL_JOB_PREPARE

	/**
	 * Placement cursor.
	 *
	 * local_y is the current map layer.
	 * local_x is the current turf inside that layer.
	 */
	var/local_x = 1
	var/local_y = 1

	/**
	 * Post-processing cursors.
	 */
	var/populate_index = 1
	var/lighting_index = 1
	var/daylight_index = 1

	/**
	 * Completion callbacks.
	 */
	var/list/datum/callback/completion_callbacks = list()


/datum/rimworld_sublevel_load_job/New(
	datum/planet_cell/new_cell,
	new_poi_name = null,
	datum/callback/post_load_callback = null
)
	. = ..()

	cell = new_cell
	poi_name = new_poi_name

	if(post_load_callback)
		completion_callbacks += post_load_callback


/datum/rimworld_sublevel_load_job/proc/add_callback(
	datum/callback/post_load_callback
)
	if(!post_load_callback)
		return

	completion_callbacks += post_load_callback


/datum/rimworld_sublevel_load_job/process()
	if(!cell || QDELETED(cell))
		return RW_CELL_LOAD_FAILED

	if(!cell.is_valid())
		return RW_CELL_LOAD_FAILED

	switch(phase)

		if(RW_CELL_JOB_PREPARE)
			if(!prepare())
				return RW_CELL_LOAD_FAILED

			phase = RW_CELL_JOB_PLACE
			return RW_CELL_LOAD_CONTINUE


		if(RW_CELL_JOB_PLACE)
			return process_placement()


		if(RW_CELL_JOB_INITIALIZE)
			if(!initialize())
				return RW_CELL_LOAD_FAILED

			phase = RW_CELL_JOB_POPULATE
			populate_index = 1

			/**
			 * Initialization is intentionally one large synchronous operation.
			 * Give the MC a chance to continue before starting post-processing.
			 */
			return RW_CELL_LOAD_CONTINUE


		if(RW_CELL_JOB_POPULATE)
			return process_population()


		if(RW_CELL_JOB_LIGHTING)
			return process_lighting()


		if(RW_CELL_JOB_DAYLIGHT)
			return process_daylight()


		if(RW_CELL_JOB_FINISH)
			if(!finish())
				return RW_CELL_LOAD_FAILED

			return RW_CELL_LOAD_COMPLETE

	return RW_CELL_LOAD_FAILED



/datum/rimworld_sublevel_load_job/proc/prepare()
	if(!cell || !cell.is_valid())
		return FALSE

	reservation = SSsub_levels.create_sub_level(
		cell.local_width,
		cell.local_height,
		0,
		poi_name || "Cell ([cell.x],[cell.y])"
	)

	if(!reservation)
		log_world(
			"RimWorld loader: failed to allocate sub-level \
			for cell [cell.x],[cell.y]."
		)
		return FALSE

	var/turf/BL = reservation.get_bottom_left_turf()
	var/turf/TR = reservation.get_top_right_turf()

	if(!BL || !TR)
		log_world(
			"RimWorld loader: reservation for cell [cell.x],[cell.y] \
			contains invalid bounds."
		)
		return FALSE

	generator = new /datum/map_generator/sub_level()

	if(!generator)
		log_world(
			"RimWorld loader: failed to create generator \
			for cell [cell.x],[cell.y]."
		)
		return FALSE

	generator.setup_planet_context(
		cell.planet,
		cell.x,
		cell.y,
		cell
	)

	if(!generator.prepare_sub_level_terrain(reservation))
		log_world(
			"RimWorld loader: terrain preparation failed \
			for cell [cell.x],[cell.y]."
		)
		return FALSE

	local_x = 1
	local_y = 1

	return TRUE


/datum/rimworld_sublevel_load_job/proc/process_placement()
	if(!reservation || QDELETED(reservation))
		return RW_CELL_LOAD_FAILED

	if(!generator || QDELETED(generator))
		return RW_CELL_LOAD_FAILED

	while(local_y <= generator.height)

		while(local_x <= generator.width)
			var/turf/new_turf = generator.place_sub_level_turf(
				reservation,
				local_x,
				local_y
			)

			if(!new_turf)
				log_world(
					"RimWorld loader: failed to place turf \
					at local [local_x],[local_y] \
					for cell [cell.x],[cell.y]."
				)
				return RW_CELL_LOAD_FAILED

			local_x++

			/**
			 * Yield only after a completed turf operation.
			 */
			if(TICK_CHECK)
				return RW_CELL_LOAD_CONTINUE

		/**
		 * Finished one complete horizontal layer.
		 */
		local_x = 1
		local_y++

		if(TICK_CHECK)
			return RW_CELL_LOAD_CONTINUE


	/**
	 * Entire map is now physically placed.
	 */
	phase = RW_CELL_JOB_INITIALIZE

	return RW_CELL_LOAD_CONTINUE


/datum/rimworld_sublevel_load_job/proc/initialize()
	if(!reservation || QDELETED(reservation))
		return FALSE

	if(!generator || QDELETED(generator))
		return FALSE

	if(!generator.initialize_all_turfs())
		return FALSE

	return TRUE

/datum/rimworld_sublevel_load_job/proc/process_population()
	if(!generator || QDELETED(generator))
		return RW_CELL_LOAD_FAILED

	var/open_count = generator.get_generated_open_turf_count()

	while(populate_index <= open_count)
		var/turf/T = generator.get_generated_open_turf(
			populate_index
		)

		if(T)
			var/area/rimworld/A = generator.rimworld_area

			if(!generator.populate_turf(
				T,
				(A.area_flags_mapping & FLORA_ALLOWED),
				(A.area_flags_mapping & FLORA_ALLOWED),
				(A.area_flags_mapping & MOB_SPAWN_ALLOWED)
			))
				return RW_CELL_LOAD_FAILED

		populate_index++

		if(TICK_CHECK)
			return RW_CELL_LOAD_CONTINUE

	phase = RW_CELL_JOB_LIGHTING
	lighting_index = 1

	return RW_CELL_LOAD_CONTINUE


/datum/rimworld_sublevel_load_job/proc/process_lighting()
	if(!generator || QDELETED(generator))
		return RW_CELL_LOAD_FAILED

	var/turf_count = generator.get_generated_turf_count()

	while(lighting_index <= turf_count)
		var/turf/T = generator.get_generated_turf(
			lighting_index
		)

		if(T)
			SSlighting.setup_static_lighting_if_needed(
				list(T)
			)

		lighting_index++

		if(TICK_CHECK)
			return RW_CELL_LOAD_CONTINUE

	phase = RW_CELL_JOB_DAYLIGHT
	daylight_index = 1

	return RW_CELL_LOAD_CONTINUE


/datum/rimworld_sublevel_load_job/proc/process_daylight()
	if(!generator || QDELETED(generator))
		return RW_CELL_LOAD_FAILED

	var/turf_count = generator.get_generated_turf_count()

	while(daylight_index <= turf_count)
		var/turf/T = generator.get_generated_turf(
			daylight_index
		)

		if(T && SSdaylight.setup_complete)
			SSdaylight.handle_loaded_turfs(
				list(T)
			)

		daylight_index++

		if(TICK_CHECK)
			return RW_CELL_LOAD_CONTINUE

	phase = RW_CELL_JOB_FINISH

	return RW_CELL_LOAD_CONTINUE


/datum/rimworld_sublevel_load_job/proc/finish()
	if(!cell || QDELETED(cell))
		return FALSE

	if(!reservation || QDELETED(reservation))
		return FALSE

	if(!generator || QDELETED(generator))
		return FALSE

	cell.reservation = reservation
	cell.sub_level_id = reservation.id

	// The cell now owns the reservation.
	reservation = null

	cell.is_generated = TRUE
	cell.is_generating = FALSE
	cell.loading_job = null

	// Refresh planetary metadata.
	cell.refresh_from_planet()

	qdel(generator)
	generator = null

	return TRUE

/datum/rimworld_sublevel_load_job/proc/notify_callbacks(success)
	if(!length(completion_callbacks))
		return

	for(var/datum/callback/callback in completion_callbacks)
		if(!callback)
			continue

		callback.Invoke(
			cell,
			success
		)

	completion_callbacks.Cut()


/datum/rimworld_sublevel_load_job/Destroy()
	/**
	 * If generation failed or was cancelled before ownership was transferred,
	 * the job still owns the reservation.
	 */
	if(reservation)
		qdel(reservation)
		reservation = null

	if(generator)
		qdel(generator)
		generator = null

	if(cell)
		if(cell.loading_job == src)
			cell.loading_job = null

		if(cell.is_generating)
			cell.is_generating = FALSE

	cell = null

	return ..()
