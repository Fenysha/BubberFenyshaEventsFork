PROCESSING_SUBSYSTEM_DEF(map_halders)
	name = "Map handling"
	ss_flags = SS_BACKGROUND|SS_POST_FIRE_TIMING|SS_NO_INIT
	wait = 1 SECONDS

	dependencies = list(/datum/controller/subsystem/mapping)

/datum/controller/subsystem/processing/map_halders/fire(resumed)
	if(SSmapping.current_map_handler)
		SSmapping.current_map_handler.map_tick(wait * 0.1)
