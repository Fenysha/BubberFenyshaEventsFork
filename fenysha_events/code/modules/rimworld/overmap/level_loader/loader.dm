SUBSYSTEM_DEF(rimworld_sublevel_loader)
	name = "\[RW\] Sub-Level Loader"
	wait = 1
	ss_flags = SS_TICKER

	dependencies = list(
		/datum/controller/subsystem/atoms,
		/datum/controller/subsystem/mapping,
		/datum/controller/subsystem/sub_levels,
		/datum/controller/subsystem/lighting,
	)

	/// Strict FIFO queue of jobs that have not started yet.
	var/list/datum/rimworld_sublevel_load_job/load_queue = list()

	/// Round-robin queue of currently active jobs.
	var/list/datum/rimworld_sublevel_load_job/active_queue = list()

	var/list/jobs_by_cell = list()

	var/active_loads = 0


/datum/controller/subsystem/rimworld_sublevel_loader/stat_entry(msg)
	msg = "\n  Pending:[length(load_queue)] Active:[active_loads]/[RW_SUBLEVEL_MAX_PARALLEL_LOADS]"
	return ..()


/datum/controller/subsystem/rimworld_sublevel_loader/proc/queue_cell(
	datum/planet_cell/cell,
	poi_name = null,
	datum/callback/post_load_callback = null,
	datum/callback/progress_callback = null
)
	if(!cell || QDELETED(cell) || !cell.is_valid())
		return FALSE

	if(cell.is_loaded())
		if(post_load_callback)
			post_load_callback.Invoke(cell, TRUE)
		return TRUE

	if(cell.loading_job && QDELETED(cell.loading_job))
		cell.loading_job = null
		cell.is_generating = FALSE

	if(cell.loading_job)
		if(post_load_callback)
			cell.loading_job.add_callback(post_load_callback)
		return TRUE

	if(cell.id)
		var/datum/rimworld_sublevel_load_job/existing_job = jobs_by_cell[cell.id]

		if(existing_job && !QDELETED(existing_job))
			if(post_load_callback)
				existing_job.add_callback(post_load_callback)

			if(progress_callback)
				existing_job.add_progress_callback(progress_callback)

			cell.loading_job = existing_job
			cell.is_generating = TRUE

			return TRUE

		if(existing_job)
			jobs_by_cell -= cell.id

	var/datum/rimworld_sublevel_load_job/job = new /datum/rimworld_sublevel_load_job(
		cell,
		poi_name,
		post_load_callback,
		progress_callback
	)

	load_queue += job

	if(cell.id)
		jobs_by_cell[cell.id] = job

	cell.loading_job = job
	cell.is_generating = TRUE

	if(cell.loading_job)
		if(post_load_callback)
			cell.loading_job.add_callback(post_load_callback)

		if(progress_callback)
			cell.loading_job.add_progress_callback(progress_callback)

		return TRUE

	fill_active_slots()

	return TRUE


/datum/controller/subsystem/rimworld_sublevel_loader/proc/fill_active_slots()
	while(
		active_loads < RW_SUBLEVEL_MAX_PARALLEL_LOADS \
		&& length(load_queue)
	)
		// Always take the oldest pending job.
		var/datum/rimworld_sublevel_load_job/job = load_queue[1]

		load_queue.Cut(1, 2)

		if(!job || QDELETED(job))
			continue

		if(job.cancel_requested)
			qdel(job)
			continue

		job.active = TRUE

		active_queue += job
		active_loads++


/datum/controller/subsystem/rimworld_sublevel_loader/proc/cancel_cell(
	datum/planet_cell/cell
)
	if(!cell)
		return FALSE

	var/datum/rimworld_sublevel_load_job/job = cell.loading_job

	if(!job && cell.id)
		job = jobs_by_cell[cell.id]

	if(!job || QDELETED(job))
		return FALSE

	/*
	 * Never delete a job while process() is executing.
	 * SSatoms.InitializeAtoms() may yield internally.
	 */
	if(job.processing)
		job.cancel_requested = TRUE
		return TRUE

	remove_job(job)

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

	// Job may still be pending.
	load_queue -= job

	// Or it may already be active.
	active_queue -= job

	if(job.active)
		job.active = FALSE
		active_loads = max(0, active_loads - 1)

	if(job.cell && job.cell.id && jobs_by_cell[job.cell.id] == job)
		jobs_by_cell -= job.cell.id

	// Immediately promote the next oldest pending job.
	fill_active_slots()


/datum/controller/subsystem/rimworld_sublevel_loader/proc/rotate_active_job(
	datum/rimworld_sublevel_load_job/job
)
	if(!job || QDELETED(job))
		return

	if(!(job in active_queue))
		return

	active_queue -= job
	active_queue += job


/datum/controller/subsystem/rimworld_sublevel_loader/fire(resumed)
	if(!length(active_queue) && !length(load_queue))
		return

	// Fill empty parallel slots from the FRONT of the FIFO queue.
	fill_active_slots()

	if(!length(active_queue))
		return

	var/processed_jobs = 0

	while(length(active_queue))
		if(TICK_CHECK)
			return

		/*
		 * active_queue itself is round-robin.
		 * The first element gets the next slice of CPU.
		 */
		var/datum/rimworld_sublevel_load_job/job = active_queue[1]

		if(!job || QDELETED(job))
			active_queue.Cut(1, 2)
			active_loads = max(0, active_loads - 1)

			fill_active_slots()
			continue

		// A paused job stays active, but doesn't consume work.
		if(job.paused)
			rotate_active_job(job)
			processed_jobs++

			if(processed_jobs >= 64)
				return

			continue

		job.processing = TRUE
		var/result = job.process()
		job.processing = FALSE
		job.notify_progress()

		if(QDELETED(job))
			active_queue -= job
			active_loads = max(0, active_loads - 1)

			fill_active_slots()
			continue

		if(job.cancel_requested)
			result = RW_CELL_LOAD_FAILED

		switch(result)
			if(RW_CELL_LOAD_COMPLETE)
				/*
				 * remove_job() also promotes the oldest waiting job.
				 */
				job.notify_progress(TRUE)
				remove_job(job)

				job.notify_callbacks(TRUE)
				qdel(job)

			if(RW_CELL_LOAD_FAILED)
				job.notify_progress(TRUE)
				remove_job(job)

				job.notify_callbacks(FALSE)
				qdel(job)

			if(RW_CELL_LOAD_CONTINUE)
				/*
				 * The job is still active, but gives the next active
				 * job its turn.
				 */
				rotate_active_job(job)

			if(RW_CELL_LOAD_PAUSED)
				/*
				 * Keep the slot reserved, but don't let this job
				 * monopolize the scheduler.
				 */
				rotate_active_job(job)

		processed_jobs++

		/*
		 * Prevent a large amount of tiny jobs from causing the loader
		 * to monopolize one fire().
		 */
		if(processed_jobs >= 64)
			return


/datum/rimworld_sublevel_load_job
	var/datum/planet_cell/cell
	var/poi_name

	var/datum/turf_reservation/sub_level/reservation
	var/datum/map_generator/sub_level/generator

	var/active = FALSE
	var/paused = FALSE
	var/processing = FALSE
	var/cancel_requested = FALSE

	var/list/datum/callback/progress_callbacks = list()
	var/last_progress_update = 0

	/// When TRUE, TICK_CHECK inside this job is ignored.
	var/ignore_lag = TRUE

	var/phase = RW_CELL_JOB_PREPARE

	var/local_x = 1
	var/local_y = 1

	var/initialization_index = 1
	var/populate_index = 1
	var/lighting_index = 1
	var/daylight_index = 1
	var/smooth_index = 1

	/// Progress index for RW_CELL_JOB_DECODE. Walks heights[] first,
	/// then gets reset to 1 to walk cave_mask[].
	var/decode_index = 1

	/// Set once decode_index has finished heights[] and moved on to
	/// walking cave_mask[] within the same DECODE phase.
	var/decode_stage_cave_mask = FALSE

	/// Mapload source held for the whole initialize phase, not per batch.
	var/mapload_source
	var/list/mapload_arg

	var/list/datum/callback/completion_callbacks = list()


/datum/rimworld_sublevel_load_job/New(
	datum/planet_cell/new_cell,
	new_poi_name = null,
	datum/callback/post_load_callback = null,
	datum/callback/progress_callback = null
)
	. = ..()

	cell = new_cell
	poi_name = new_poi_name

	if(post_load_callback)
		completion_callbacks += post_load_callback

	if(progress_callback)
		progress_callbacks += progress_callback


/datum/rimworld_sublevel_load_job/proc/add_callback(
	datum/callback/post_load_callback
)
	if(post_load_callback)
		completion_callbacks += post_load_callback

/datum/rimworld_sublevel_load_job/proc/add_progress_callback(
	datum/callback/progress_callback
)
	if(progress_callback)
		progress_callbacks += progress_callback

/datum/rimworld_sublevel_load_job/process()
	if(!cell || QDELETED(cell) || !cell.is_valid())
		return RW_CELL_LOAD_FAILED

	if(cancel_requested)
		return RW_CELL_LOAD_FAILED

	if(paused)
		return RW_CELL_LOAD_PAUSED

	switch(phase)
		if(RW_CELL_JOB_PREPARE)
			if(!prepare())
				return RW_CELL_LOAD_FAILED

			if(!generator.has_stamp)
				log_world("RimWorld loader: cell [cell.x],[cell.y] has no stamp.")
				return RW_CELL_LOAD_FAILED

			phase = RW_CELL_JOB_RESERVE

			return RW_CELL_LOAD_CONTINUE

		if(RW_CELL_JOB_DECODE)
			return process_decode()

		if(RW_CELL_JOB_RESERVE)
			if(!reservation || QDELETED(reservation))
				return RW_CELL_LOAD_FAILED

			if(reservation.materialize_step(RW_SUBLEVEL_RESERVE_BUDGET))
				phase = RW_CELL_JOB_PLACE

			return RW_CELL_LOAD_CONTINUE

		if(RW_CELL_JOB_PLACE)
			return process_placement()

		if(RW_CELL_JOB_POPULATE, RW_CELL_JOB_INITIALIZE)
			log_world("RimWorld loader: cell [cell.x],[cell.y] entered a retired pass [phase].")
			return RW_CELL_LOAD_FAILED

		if(RW_CELL_JOB_SMOOTH)
			return process_smoothing()

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
		RW_SUBLEVEL_INNER_WIDTH,
		RW_SUBLEVEL_INNER_HEIGHT,
		0,
		poi_name || "Cell ([cell.x],[cell.y])"
	)

	if(!reservation)
		log_world(
			"RimWorld loader: failed to allocate sub-level for cell [cell.x],[cell.y]."
		)
		return FALSE

	var/turf/BL = reservation.get_inner_bottom_left_turf()
	var/turf/TR = reservation.get_inner_top_right_turf()

	if(!BL || !TR)
		log_world(
			"RimWorld loader: reservation for cell [cell.x],[cell.y] contains invalid bounds."
		)
		return FALSE

	generator = new /datum/map_generator/sub_level()

	if(!generator)
		log_world(
			"RimWorld loader: failed to create generator for cell [cell.x],[cell.y]."
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
			"RimWorld loader: terrain preparation failed for cell [cell.x],[cell.y]."
		)
		return FALSE

	local_x = 1
	local_y = 1

	initialization_index = 1
	populate_index = 1
	lighting_index = 1
	daylight_index = 1
	smooth_index = 1
	decode_index = 1
	decode_stage_cave_mask = FALSE

	return TRUE


/datum/rimworld_sublevel_load_job/proc/process_decode()
	if(!generator || QDELETED(generator))
		return RW_CELL_LOAD_FAILED

	if(!decode_stage_cave_mask)
		var/heights_count = length(generator.heights)

		while(decode_index <= heights_count)
			if(cancel_requested)
				return RW_CELL_LOAD_FAILED

			var/next_index = generator.decode_heights_step(
				decode_index,
				RW_SUBLEVEL_DECODE_BUDGET
			)

			if(next_index == -1)
				return RW_CELL_LOAD_FAILED

			decode_index = next_index

			if(TICK_CHECK)
				return RW_CELL_LOAD_CONTINUE

			// Budget exhausted for this call (decode_heights_step
			// itself enforces the RW_SUBLEVEL_DECODE_BUDGET cap).
			if(decode_index <= heights_count)
				return RW_CELL_LOAD_CONTINUE

		// heights[] fully decoded. Transition checks need every neighbor numeric.
		generator.build_transition_mask()

		decode_stage_cave_mask = TRUE
		decode_index = 1

		return RW_CELL_LOAD_CONTINUE

	var/cave_count = length(generator.cave_mask)

	if(!cave_count)
		// Nothing to decode (caves disabled / empty mask).
		phase = RW_CELL_JOB_RESERVE
		return RW_CELL_LOAD_CONTINUE

	while(decode_index <= cave_count)
		if(cancel_requested)
			return RW_CELL_LOAD_FAILED

		var/next_index = generator.decode_cave_mask_step(
			decode_index,
			RW_SUBLEVEL_DECODE_BUDGET
		)

		decode_index = next_index

		if(TICK_CHECK)
			return RW_CELL_LOAD_CONTINUE

		if(decode_index <= cave_count)
			return RW_CELL_LOAD_CONTINUE

	phase = RW_CELL_JOB_RESERVE

	return RW_CELL_LOAD_CONTINUE


/datum/rimworld_sublevel_load_job/proc/process_placement()
	if(!reservation || QDELETED(reservation))
		return RW_CELL_LOAD_FAILED

	if(!generator || QDELETED(generator))
		return RW_CELL_LOAD_FAILED

	var/processed = 0

	if(generator.has_stamp && !mapload_source)
		mapload_source = "rw_cell_[cell.x]_[cell.y]_[REF(src)]"
		mapload_arg = list(TRUE)
		SSatoms.set_tracked_initalized(INITIALIZATION_INNEW_MAPLOAD, mapload_source)

	while(local_y <= generator.height)
		while(local_x <= generator.width)
			var/turf/new_turf = generator.place_sub_level_turf(
				reservation,
				local_x,
				local_y
			)

			if(!new_turf)
				log_world(
					"RimWorld loader: failed to place turf at local [local_x],[local_y] for cell [cell.x],[cell.y]."
				)
				return RW_CELL_LOAD_FAILED

			if(generator.has_stamp)
				finish_stamped_turf(new_turf)

			local_x++
			processed++

			if(
				processed >= RW_SUBLEVEL_PLACE_BUDGET \
				|| TICK_CHECK \
				|| cancel_requested
			)
				if(cancel_requested)
					return RW_CELL_LOAD_FAILED

				return RW_CELL_LOAD_CONTINUE

		local_x = 1
		local_y++

		if(TICK_CHECK || cancel_requested)
			if(cancel_requested)
				return RW_CELL_LOAD_FAILED

			return RW_CELL_LOAD_CONTINUE

	if(generator.has_stamp)
		end_initialization(FALSE)
		if(generator.rimworld_area)
			SSmapping.reg_in_areas_in_z(list(generator.rimworld_area))
		generator.turfs_initialized = TRUE
		smooth_index = 1
		phase = RW_CELL_JOB_SMOOTH
	else
		log_world("RimWorld loader: cell [cell.x],[cell.y] has no stamp.")
		return RW_CELL_LOAD_FAILED

	return RW_CELL_LOAD_CONTINUE


/datum/rimworld_sublevel_load_job/proc/finish_stamped_turf(turf/new_turf)
	if(!(new_turf.flags_1 & INITIALIZED_1))
		SSatoms.InitAtom(new_turf, TRUE, mapload_arg)
	SSicon_smooth.remove_from_queues(new_turf)

	for(var/atom/movable/content as anything in new_turf)
		if(content.flags_1 & INITIALIZED_1)
			continue
		SSatoms.InitAtom(content, TRUE, mapload_arg)
		SSicon_smooth.remove_from_queues(content)


/datum/rimworld_sublevel_load_job/proc/process_population()
	if(!generator || QDELETED(generator))
		return RW_CELL_LOAD_FAILED

	var/open_count = generator.get_generated_open_turf_count()
	var/processed = 0
	var/area/rimworld/A = generator.rimworld_area

	if(populate_index == 1 && generator.target_biome)
		generator.target_biome.begin_population_pass()

	while(populate_index <= open_count)
		if(cancel_requested)
			if(generator.target_biome)
				generator.target_biome.end_population_pass()

			return RW_CELL_LOAD_FAILED

		var/turf/T = generator.get_generated_open_turf(populate_index)
		var/is_cave = generator.get_generated_open_is_cave(populate_index)

		if(T)
			if(!generator.populate_turf(
				T,
				(A.area_flags_mapping & FLORA_ALLOWED),
				(A.area_flags_mapping & FLORA_ALLOWED),
				(A.area_flags_mapping & MOB_SPAWN_ALLOWED),
				is_cave,
				populate_index
			))
				if(generator.target_biome)
					generator.target_biome.end_population_pass()

				return RW_CELL_LOAD_FAILED

		populate_index++
		processed++

		if(
			processed >= RW_SUBLEVEL_POPULATE_BUDGET \
			|| TICK_CHECK
		)
			return RW_CELL_LOAD_CONTINUE

	if(generator.target_biome)
		generator.target_biome.end_population_pass()

	phase = RW_CELL_JOB_INITIALIZE
	initialization_index = 1

	return RW_CELL_LOAD_CONTINUE


/datum/rimworld_sublevel_load_job/proc/process_initialization()
	if(!generator || QDELETED(generator))
		end_initialization(FALSE)
		return RW_CELL_LOAD_FAILED

	var/list/pending = generator.pending_init

	if(!length(pending))
		end_initialization(TRUE)
		generator.turfs_initialized = TRUE
		phase = generator.has_stamp ? RW_CELL_JOB_LIGHTING : RW_CELL_JOB_SMOOTH
		smooth_index = 1
		lighting_index = 1

		return RW_CELL_LOAD_CONTINUE

	if(!mapload_source)
		mapload_source = "rw_cell_[cell.x]_[cell.y]_[REF(src)]"
		mapload_arg = list(TRUE)
		SSatoms.set_tracked_initalized(INITIALIZATION_INNEW_MAPLOAD, mapload_source)

	var/processed = 0

	while(initialization_index <= length(pending))
		if(cancel_requested)
			end_initialization(FALSE)
			return RW_CELL_LOAD_FAILED

		var/atom/A = pending[initialization_index]
		initialization_index++

		if(A && !QDELETED(A) && !(A.flags_1 & INITIALIZED_1))
			SSatoms.InitAtom(A, TRUE, mapload_arg)

		processed++
		if(processed >= RW_SUBLEVEL_INITIALIZE_BUDGET || TICK_CHECK)
			return RW_CELL_LOAD_CONTINUE

	end_initialization(TRUE)

	if(generator.rimworld_area)
		SSmapping.reg_in_areas_in_z(list(generator.rimworld_area))

	generator.turfs_initialized = TRUE

	phase = generator.has_stamp ? RW_CELL_JOB_LIGHTING : RW_CELL_JOB_SMOOTH
	smooth_index = 1
	lighting_index = 1

	return RW_CELL_LOAD_CONTINUE


/datum/rimworld_sublevel_load_job/proc/end_initialization(late_init)
	if(!mapload_source)
		return

	var/source = mapload_source
	mapload_source = null
	mapload_arg = null

	// Releasing this queue is the smoothing pass. The stamp already has corners.
	var/list/deferred = SSicon_smooth.deferred_by_source[source]
	if(deferred)
		for(var/atom/thing as anything in deferred)
			if(thing)
				thing.smoothing_flags &= ~SMOOTH_QUEUED
		SSicon_smooth.deferred_by_source -= source

	if(late_init)
		var/list/late_loaders = SSatoms.late_loaders
		for(var/atom/late as anything in late_loaders)
			if(!QDELETED(late))
				late.LateInitialize()
		late_loaders.Cut()

	SSatoms.clear_tracked_initalize(source)


/datum/rimworld_sublevel_load_job/proc/process_smoothing()
	if(!generator || QDELETED(generator))
		return RW_CELL_LOAD_FAILED

	var/turf_count = generator.get_generated_turf_count()
	var/processed = 0

	while(smooth_index <= turf_count)
		if(cancel_requested)
			return RW_CELL_LOAD_FAILED

		var/turf/T = generator.get_generated_turf(smooth_index)
		smooth_index++

		if(istype(T, /turf/open) && !istype(T, /turf/open/rimworld/grass))
			var/turf/open/open_turf = T
			open_turf.update_edges()

		processed++

		if(
			processed >= RW_SUBLEVEL_SMOOTH_BUDGET \
			|| TICK_CHECK
		)
			return RW_CELL_LOAD_CONTINUE

	phase = RW_CELL_JOB_FINISH

	return RW_CELL_LOAD_CONTINUE


/datum/rimworld_sublevel_load_job/proc/process_lighting()
	if(!generator || QDELETED(generator))
		return RW_CELL_LOAD_FAILED

	var/turf_count = generator.get_generated_turf_count()
	var/list/batch = list()

	while(
		lighting_index <= turf_count \
		&& length(batch) < RW_SUBLEVEL_LIGHTING_BUDGET
	)
		if(cancel_requested)
			return RW_CELL_LOAD_FAILED

		var/turf/T = generator.get_generated_turf(lighting_index)
		lighting_index++

		if(T)
			batch += T

	if(length(batch))
		SSlighting.setup_static_lighting_if_needed(batch)

	if(lighting_index <= turf_count)
		return RW_CELL_LOAD_CONTINUE

	phase = RW_CELL_JOB_DAYLIGHT
	daylight_index = 1

	return RW_CELL_LOAD_CONTINUE


/datum/rimworld_sublevel_load_job/proc/process_daylight()
	if(!generator || QDELETED(generator))
		return RW_CELL_LOAD_FAILED

	// Per-turf daylight wash during load repaints the whole cell while it is still being built.
	var/area/rimworld/loaded_area = generator.rimworld_area
	if(loaded_area && SSdaylight.setup_complete)
		loaded_area.update_base_lighting()
		if(loaded_area.daylight && !loaded_area.daylight_lit)
			loaded_area.apply_daylight_overlay()

	phase = RW_CELL_JOB_FINISH
	return RW_CELL_LOAD_CONTINUE


/datum/rimworld_sublevel_load_job/proc/finish()
	if(
		!cell \
		|| QDELETED(cell) \
		|| !reservation \
		|| QDELETED(reservation) \
		|| !generator \
		|| QDELETED(generator)
	)
		return FALSE

	if(cancel_requested)
		return FALSE

	cell.reservation = reservation
	cell.sub_level_id = reservation.id

	reservation = null

	if(generator.rimworld_area)
		generator.rimworld_area.cell_loading = FALSE
	cell.is_generated = TRUE
	cell.is_generating = FALSE
	cell.loading_job = null

	cell.refresh_from_planet()

	qdel(generator)
	generator = null

	return TRUE


/datum/rimworld_sublevel_load_job/proc/notify_callbacks(success)
	if(!length(completion_callbacks))
		return

	for(var/datum/callback/callback in completion_callbacks)
		if(callback)
			callback.Invoke(cell, success)

	completion_callbacks.Cut()


/datum/rimworld_sublevel_load_job/proc/notify_progress(force = FALSE)
	if(!length(progress_callbacks))
		return

	if(!force && world.time < last_progress_update + 2)
		return

	last_progress_update = world.time

	for(var/datum/callback/callback in progress_callbacks)
		if(callback)
			callback.Invoke(src)


/datum/rimworld_sublevel_load_job/proc/get_progress_data()
	var/list/data = list(
		"progress" = 0,
		"stage" = "Preparing",
		"detail" = "Preparing local world generation...",
		"current" = 0,
		"total" = 0,
		"unit" = "steps",
	)

	if(!generator || QDELETED(generator))
		return data

	switch(phase)
		if(RW_CELL_JOB_PREPARE)
			data["progress"] = 0.02
			data["stage"] = "Preparing"
			data["detail"] = "Preparing local terrain generator..."

		if(RW_CELL_JOB_DECODE)
			if(!decode_stage_cave_mask)
				var/total = length(generator.heights)
				var/current = clamp(decode_index - 1, 0, total)

				data["progress"] = total \
					? 0.03 + (current / total) * 0.10 \
					: 0.13

				data["stage"] = "Decoding Terrain"
				data["detail"] = "Decoding terrain heights..."
				data["current"] = current
				data["total"] = total
				data["unit"] = "samples"
			else
				var/total = length(generator.cave_mask)
				var/current = clamp(decode_index - 1, 0, total)

				data["progress"] = total \
					? 0.13 + (current / total) * 0.04 \
					: 0.17

				data["stage"] = "Building Caves"
				data["detail"] = "Building cave mask..."
				data["current"] = current
				data["total"] = total
				data["unit"] = "cells"

		if(RW_CELL_JOB_RESERVE)
			data["progress"] = 0.18
			data["stage"] = "Allocating Map"
			data["detail"] = "Reserving a sub-level for the settlement..."
			data["current"] = 0
			data["total"] = 1
			data["unit"] = "stage"

		if(RW_CELL_JOB_PLACE)
			var/total = max(1, generator.width * generator.height)
			var/current = clamp(
				((local_y - 1) * generator.width) + local_x - 1,
				0,
				total
			)

			data["progress"] = 0.18 + (current / total) * 0.42
			data["stage"] = "Generating Terrain"
			data["detail"] = "Placing terrain and structures..."
			data["current"] = current
			data["total"] = total
			data["unit"] = "tiles"

		if(RW_CELL_JOB_SMOOTH)
			var/total = max(1, generator.get_generated_turf_count())
			var/current = clamp(smooth_index - 1, 0, total)

			data["progress"] = 0.60 + (current / total) * 0.14
			data["stage"] = "Smoothing Terrain"
			data["detail"] = "Connecting terrain edges and smoothing tiles..."
			data["current"] = current
			data["total"] = total
			data["unit"] = "tiles"

		if(RW_CELL_JOB_LIGHTING)
			var/total = max(1, generator.get_generated_turf_count())
			var/current = clamp(lighting_index - 1, 0, total)

			data["progress"] = 0.74 + (current / total) * 0.16
			data["stage"] = "Lighting"
			data["detail"] = "Preparing static lighting..."
			data["current"] = current
			data["total"] = total
			data["unit"] = "tiles"

		if(RW_CELL_JOB_DAYLIGHT)
			data["progress"] = 0.93
			data["stage"] = "Daylight"
			data["detail"] = "Applying planetary daylight..."
			data["current"] = 1
			data["total"] = 1
			data["unit"] = "stage"

		if(RW_CELL_JOB_FINISH)
			data["progress"] = 0.98
			data["stage"] = "Finishing"
			data["detail"] = "Finalizing settlement map..."
			data["current"] = 1
			data["total"] = 1
			data["unit"] = "stage"

	return data


/datum/rimworld_sublevel_load_job/Destroy()
	end_initialization(FALSE)

	if(reservation)
		qdel(reservation)
		reservation = null

	if(generator)
		if(generator.rimworld_area)
			generator.rimworld_area.cell_loading = FALSE
		qdel(generator)
		generator = null

	if(cell)
		if(cell.loading_job == src)
			cell.loading_job = null

		if(cell.is_generating)
			cell.is_generating = FALSE

	cell = null

	return ..()




GLOBAL_DATUM(rimworld_sublevel_load_test, /datum/rimworld_sublevel_load_test)
/datum/rimworld_sublevel_load_test
	var/start_time
	var/end_time

	var/requested = 0
	var/queued = 0
	var/completed = 0
	var/failed = 0

	var/active = TRUE

	/// Cell key -> start realtime
	var/list/cell_start_times = list()

	/// Cell key -> result information
	var/list/results = list()

	/// Cell key -> cell datum
	var/list/test_cells = list()


/datum/rimworld_sublevel_load_test/New(requested_count)
	. = ..()

	start_time = REALTIMEOFDAY
	requested = requested_count

	cell_start_times = list()
	results = list()
	test_cells = list()


/datum/rimworld_sublevel_load_test/proc/queue_cell(
	datum/planet_cell/cell,
	datum/controller/subsystem/rimworld_sublevel_loader/loader
)
	if(!active || !cell || QDELETED(cell))
		return FALSE

	var/key = "[cell.x]:[cell.y]"

	if(test_cells[key])
		return FALSE

	if(cell.is_loaded())
		return FALSE

	if(cell.loading_job)
		return FALSE

	test_cells[key] = cell
	cell_start_times[key] = REALTIMEOFDAY

	if(!loader.queue_cell(
		cell,
		"LoadTest ([cell.x],[cell.y])",
		CALLBACK(src, PROC_REF(on_cell_complete))
	))
		test_cells -= key
		cell_start_times -= key
		return FALSE

	queued++

	log_world(
		"RW LOAD TEST: queued cell ([cell.x],[cell.y]) \
		[queued]/[requested]"
	)

	return TRUE


/datum/rimworld_sublevel_load_test/proc/on_cell_complete(
	datum/planet_cell/cell,
	success
)
	if(!cell)
		return

	var/key = "[cell.x]:[cell.y]"
	var/start = cell_start_times[key]
	var/elapsed = isnull(start) ? 0 : (REALTIMEOFDAY - start) / 10

	if(success)
		completed++
	else
		failed++

	results[key] = list(
		"x" = cell.x,
		"y" = cell.y,
		"success" = !!success,
		"time" = elapsed,
	)

	cell_start_times -= key

	log_world(
		"RW LOAD TEST: cell ([cell.x],[cell.y]) \
		[success ? "COMPLETED" : "FAILED"] \
		in [round(elapsed, 0.01)]s \
		([completed + failed]/[queued])"
	)

	check_finished()


/datum/rimworld_sublevel_load_test/proc/check_finished()
	if(!active)
		return

	if(completed + failed < queued)
		return

	active = FALSE
	end_time = REALTIMEOFDAY

	report()


/datum/rimworld_sublevel_load_test/proc/report()
	var/elapsed = (end_time - start_time) / 10
	var/success_rate = queued ? (completed / queued) * 100 : 0
	var/average_time = 0

	if(completed + failed)
		var/total_cell_time = 0

		for(var/key in results)
			var/list/result = results[key]
			total_cell_time += result["time"]

		average_time = total_cell_time / length(results)

	log_world("============================================================")
	log_world("RW LOAD TEST COMPLETE")
	log_world("Requested cells: [requested]")
	log_world("Queued cells:    [queued]")
	log_world("Completed:       [completed]")
	log_world("Failed:          [failed]")
	log_world("Success rate:    [round(success_rate, 0.1)]%")
	log_world("Total time:      [round(elapsed, 0.01)]s")
	log_world("Average cell:    [round(average_time, 0.01)]s")

	if(elapsed > 0)
		log_world(
			"Throughput:      [round(completed / elapsed, 0.01)] cells/s"
		)

	log_world("============================================================")

	to_chat(
		GLOB.admins,
		span_notice("\[RW\] Load test finished:[completed]/[queued] cells loaded, [failed] failed, [round(elapsed, 0.1)]s total.")
	)


/// Returns a random valid, currently unloaded cell.
/// Returns null when no suitable cell can be found.
/datum/rimworld_sublevel_load_test/proc/find_random_cell(
	datum/rimworld_planet/planet
)
	if(!planet)
		return null

	// Avoid potentially looping forever if most of the planet is already loaded.
	var/max_attempts = 100

	for(var/i in 1 to max_attempts)
		var/x = rand(1, planet.map_width)
		var/y = rand(1, planet.map_height)

		if(!planet.is_valid_coordinate(x, y))
			continue

		var/key = "[x]:[y]"
		if(test_cells[key])
			continue

		var/datum/planet_cell/cell = planet.cells[key]

		// Create the cell lazily if it does not exist yet.
		if(!cell)
			cell = new /datum/planet_cell(planet, x, y)
			planet.cells[key] = cell

		if(!cell || QDELETED(cell))
			continue

		if(cell.is_loaded())
			continue

		if(cell.loading_job)
			continue

		return cell

	return null


ADMIN_VERB(rimworld_load_random_cells, R_ADMIN, "\[RW\] Load random cells", "Load a specified number of random planet cells as a stress test.", ADMIN_CATEGORY_DEBUG)
	if(!SSrimworld_planetmap.planet)
		to_chat(usr, span_warning("RimWorld planet has not been generated."))
		return

	if(GLOB.rimworld_sublevel_load_test?.active)
		to_chat(
			usr,
			span_warning("A RimWorld sub-level load test is already running.")
		)
		return

	var/count = input(
		usr,
		"How many random cells should be loaded?",
		"RimWorld Load Test",
		10
	) as num

	count = round(count)

	if(count <= 0)
		return

	// Safety limit for accidental huge stress tests.
	count = min(count, 500)

	var/datum/rimworld_planet/planet = SSrimworld_planetmap.planet
	var/datum/rimworld_sublevel_load_test/test = new(count)

	GLOB.rimworld_sublevel_load_test = test

	var/max_attempts = count * 20
	var/attempts = 0

	while(
		test.queued < count \
		&& attempts < max_attempts
	)
		attempts++

		var/datum/planet_cell/cell = test.find_random_cell(planet)

		if(!cell)
			continue

		test.queue_cell(
			cell,
			SSrimworld_sublevel_loader
		)

	if(!test.queued)
		test.active = FALSE
		qdel(test)
		GLOB.rimworld_sublevel_load_test = null

		to_chat(
			usr,
			span_warning("Could not find any unloaded cells suitable for testing.")
		)
		return

	log_world(
		"============================================================"
	)

	log_world(
		"RW LOAD TEST STARTED BY [key_name(usr)]"
	)

	log_world(
		"Requested: [count]"
	)

	log_world(
		"Queued: [test.queued]"
	)

	log_world(
		"Parallel loader limit: [RW_SUBLEVEL_MAX_PARALLEL_LOADS]"
	)

	log_world(
		"============================================================"
	)

	to_chat(
		usr,
		span_notice("\[RW\] Load test started: [test.queued] random cells queued. Maximum parallel loads: [RW_SUBLEVEL_MAX_PARALLEL_LOADS]. Results will be written to the world log.")
	)
