// TEMPORARY BENCHMARK - remove before committing.

/datum/unit_test/trainstation_load_profile

/datum/unit_test/trainstation_load_profile/Run()
	if(!SStrain_controller.mode_active)
		TEST_FAIL("train controller inactive")
		return

	var/list/candidates = list()
	for(var/datum/train_station/candidate as anything in SStrain_controller.known_stations)
		if(!candidate.template || !candidate.visible)
			continue
		candidates += candidate
		if(length(candidates) >= 2)
			break

	for(var/datum/train_station/target as anything in candidates)
		var/started = REALTIMEOFDAY
		SStrain_controller.load_station(target, FALSE, FALSE, FALSE)
		log_world("STATION LOAD: [target.name] [(REALTIMEOFDAY - started) / 10]s")

TEST_FOCUS(/datum/unit_test/trainstation_load_profile)
