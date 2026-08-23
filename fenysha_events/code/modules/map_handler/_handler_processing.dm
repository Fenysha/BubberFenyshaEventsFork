PROCESSING_SUBSYSTEM_DEF(map_halders)
	name = "Map handling"
	ss_flags = SS_BACKGROUND|SS_POST_FIRE_TIMING
	wait = 1 SECONDS

	dependencies = list(/datum/controller/subsystem/mapping)

/datum/controller/subsystem/processing/map_halders/Initialize()
	RegisterSignal(SSticker, COMSIG_TICKER_ENTER_PREGAME, PROC_REF(on_enter_pregame))
	RegisterSignal(SSticker, COMSIG_TICKER_ROUND_STARTING, PROC_REF(on_round_start))
	return SS_INIT_SUCCESS

/datum/controller/subsystem/processing/map_halders/proc/on_enter_pregame()
	if(SSmapping.current_map_handler)
		SSmapping.current_map_handler.on_enter_pregame()

/datum/controller/subsystem/processing/map_halders/proc/on_round_start()
	if(SSmapping.current_map_handler)
		SSmapping.current_map_handler.on_round_start()

/datum/controller/subsystem/processing/map_halders/fire(resumed)
	if(SSmapping.current_map_handler)
		SSmapping.current_map_handler.map_tick(wait * 0.1)
