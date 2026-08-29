/datum/map_config
	var/handler_type = /datum/map_handler/default
	/// Assoc list(/datum/job/captain = -1)
	var/list/custom_manifest

	var/override_titlescreen = FALSE

/datum/map_config/LoadConfig(filename, error_if_missing)
	. = ..()
	if(!.)
		return FALSE
	override_titlescreen = .["override_titlescreen"] || FALSE

	var/handler = .["map_handler"]
	if(handler)
		var/htype = text2path(handler)
		if(ispath(htype, /datum/map_handler))
			handler_type = htype

	var/manifest = .["custom_manifest"]
	if(islist(manifest))
		var/list/raw_manifest = manifest
		var/list/parsed_manifest = list()

		for(var/job_path_text in raw_manifest)
			var/job_type = text2path(job_path_text)

			if(!ispath(job_type, /datum/job))
				log_mapping("Warning: Invalid job path '[job_path_text]' in map config [filename]")
				continue

			var/pos_count = raw_manifest[job_path_text]
			if(istext(pos_count))
				pos_count = text2num(pos_count)

			parsed_manifest[job_type] = pos_count

		if(length(parsed_manifest))
			custom_manifest = parsed_manifest

	return .


/datum/controller/subsystem/mapping
	var/datum/map_handler/current_map_handler

/datum/controller/subsystem/mapping/proc/load_map_handler(datum/map_config/config)
	if(config && ispath(config.handler_type, /datum/map_handler))
		current_map_handler = new config.handler_type()
		current_map_handler.config = config
		current_map_handler.initialize()

/datum/map_handler
	/// Our map config
	var/datum/map_config/config
	/// Is maploading finished
	var/map_loaded = FALSE

/datum/map_handler/proc/initialize()
	RegisterSignal(SSjob, COMSIG_OCCUPATIONS_SETUP, PROC_REF(on_job_ocupation_done))
	return

/datum/map_handler/proc/before_station_load()
	return

/datum/map_handler/proc/after_station_load()
	return

/datum/map_handler/proc/on_enter_pregame()
	SHOULD_NOT_SLEEP(TRUE)

	return

/datum/map_handler/proc/on_round_start()
	SHOULD_NOT_SLEEP(TRUE)

	return

/datum/map_handler/proc/on_job_ocupation_done()
	SIGNAL_HANDLER
	UnregisterSignal(SSjob, COMSIG_OCCUPATIONS_SETUP) // Changing ocupations only for first time
	if(config.custom_manifest)
		SSjob.setup_occupations_from_list(config.custom_manifest)

/datum/controller/subsystem/job/proc/setup_occupations_from_list(list/jobs_to_load)
	if(!LAZYLEN(jobs_to_load))
		log_job_debug("setup_occupations_from_list: Passed empty or invalid jobs list.")
		return FALSE

	name_occupations = list()
	type_occupations = list()

	var/list/new_all_occupations = list()
	var/list/new_joinable_occupations = list()
	var/list/new_joinable_departments = list()
	var/list/new_joinable_departments_by_type = list()
	var/list/new_experience_jobs_map = list()

	for(var/job_type in jobs_to_load)
		if(!ispath(job_type, /datum/job))
			log_job_debug("setup_occupations_from_list: Invalid job path '[job_type]' ignored.")
			continue

		var/datum/job/job = new job_type()
		if(!job)
			log_job_debug("setup_occupations_from_list: Failed to instantiate '[job_type]'.")
			continue

		var/custom_positions = jobs_to_load[job_type]
		if(isnum(custom_positions))
			job.total_positions = custom_positions
			job.spawn_positions = custom_positions

		if(!job.config_check())
			qdel(job)
			continue

		if(!job.map_check())
			log_job_debug("setup_occupations_from_list: Removed [job.title] due to map config.")
			qdel(job)
			continue

		new_all_occupations += job

		if(job.title)
			name_occupations[job.title] = job
		for(var/alt_title in job.alternate_titles)
			if(alt_title)
				name_occupations[alt_title] = job

		type_occupations[job_type] = job

		if(job.job_flags & JOB_NEW_PLAYER_JOINABLE)
			new_joinable_occupations += job

			if(!LAZYLEN(job.departments_list))
				var/datum/job_department/department = new_joinable_departments_by_type[/datum/job_department/undefined]
				if(!department)
					department = new /datum/job_department/undefined()
					new_joinable_departments_by_type[/datum/job_department/undefined] = department
				department.add_job(job)
				continue

			for(var/department_type in job.departments_list)
				if(!ispath(department_type, /datum/job_department))
					continue
				var/datum/job_department/department = new_joinable_departments_by_type[department_type]
				if(!department)
					department = new department_type()
					new_joinable_departments_by_type[department_type] = department
				department.add_job(job)

	if(!length(new_all_occupations))
		log_job_debug("setup_occupations_from_list: No valid jobs loaded from custom list!")
		return FALSE

	sortTim(new_all_occupations, GLOBAL_PROC_REF(cmp_job_display_with_departments_asc))
	for(var/datum/job/job as anything in new_all_occupations)
		if(!job.exp_granted_type)
			continue
		new_experience_jobs_map[job.exp_granted_type] += list(job)

	sortTim(new_joinable_departments_by_type, GLOBAL_PROC_REF(cmp_department_display_asc), associative = TRUE)
	for(var/department_type in new_joinable_departments_by_type)
		var/datum/job_department/department = new_joinable_departments_by_type[department_type]
		sortTim(department.department_jobs, GLOBAL_PROC_REF(cmp_job_display_with_departments_asc))
		new_joinable_departments += department
		if(department.department_experience_type)
			new_experience_jobs_map[department.department_experience_type] = department.department_jobs.Copy()

	all_occupations = new_all_occupations
	joinable_occupations = sortTim(new_joinable_occupations, GLOBAL_PROC_REF(cmp_job_display_with_departments_asc))
	joinable_departments = new_joinable_departments
	joinable_departments_by_type = new_joinable_departments_by_type
	experience_jobs_map = new_experience_jobs_map


	if(!type_occupations[overflow_role])
		if(length(joinable_occupations))
			var/datum/job/fallback_job = joinable_occupations[1]
			overflow_role = fallback_job.type
		else if(length(all_occupations))
			var/datum/job/fallback_job = all_occupations[1]
			overflow_role = fallback_job.type
		else
			overflow_role = null
	return TRUE


/datum/map_handler/proc/map_tick(time_lapsed)
	return

/datum/map_handler/default


/datum/map_handler/buckshot_roulette/initialize()
	. = ..()
	RegisterSignal(SSdcs, COMSIG_GLOBAL_PLAYER_SETUP_FINISHED, PROC_REF(on_player_join))

/datum/map_handler/buckshot_roulette/proc/on_player_join(datum/dcs, mob/living/joining)
	SIGNAL_HANDLER

	INVOKE_ASYNC(src, PROC_REF(teleport_to_club), joining)

/datum/map_handler/buckshot_roulette/proc/teleport_to_club(mob/living/joining)
	var/job_spawn_title = joining?.mind?.assigned_role?.title
	var/obj/effect/landmark/start/spawnpoint
	var/obj/effect/landmark/reserv_spawnpoint = null
	for(var/obj/effect/landmark/start/spawn_point as anything in GLOB.start_landmarks_list)
		if(spawn_point.name == job_spawn_title)
			spawnpoint = spawn_point
	if(!spawnpoint)
		reserv_spawnpoint = locate(/obj/effect/landmark/observer_start) in GLOB.landmarks_list
	var/turf/target_turf = spawnpoint ? get_turf(spawnpoint) : get_turf(reserv_spawnpoint)
	if(!target_turf)
		message_admins("Failed to spawn new character for [ADMIN_LOOKUPFLW(joining)]")
		return
	joining.forceMove(target_turf)

/datum/map_handler/buckshot_roulette/on_enter_pregame()
	set_station_name("Buckshot roulette club")
	addtimer(CALLBACK(src, PROC_REF(update_lobby)), 2 SECONDS)

/datum/map_handler/buckshot_roulette/proc/update_lobby()
	SStitle.change_title_screen('fenysha_events/icons/lobby/buckshot.png')
	SSticker.set_lobby_music('fenysha_events/sounds/ost/backshot_roulette/buckshot_ost_gate_modded.ogg', override = TRUE)
	for(var/client/C in GLOB.clients)
		C?.playtitlemusic(volume_multiplier = 1)
