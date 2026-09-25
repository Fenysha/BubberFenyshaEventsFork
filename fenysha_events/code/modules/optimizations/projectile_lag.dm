/datum/controller/subsystem/processing/projectiles
	/// Percent of a tick projectiles may always spend, even when the MC is already over its limit
	var/guaranteed_tick_usage = 25
	var/fire_start_usage = 0
	var/real_time = 0
	var/real_time_stamp = -1
	/// Longest real deciseconds one tick of movement is animated over, so a lag spike can't leave sprites trailing
	var/max_animation_window = 1.5

/// Real deciseconds, sampled once per tick; projectiles move by this so time dilation doesn't slow them
/datum/controller/subsystem/processing/projectiles/proc/real_now()
	if (real_time_stamp != world.time)
		real_time_stamp = world.time
		real_time = rustg_time_milliseconds("projectiles") / 100
	return real_time

/datum/controller/subsystem/processing/projectiles/proc/over_budget()
	return TICK_USAGE > Master.current_ticklimit && TICK_USAGE - fire_start_usage > guaranteed_tick_usage

/datum/controller/subsystem/processing/projectiles/fire(resumed = FALSE)
	fire_start_usage = TICK_USAGE
	flush_logs()
	if (!resumed)
		currentrun = processing.Copy()
	var/list/current_run = currentrun

	while(current_run.len)
		var/datum/thing = current_run[current_run.len]
		current_run.len--
		if(QDELETED(thing))
			processing -= thing
		else if(thing.process(wait * 0.1) == PROCESS_KILL)
			STOP_PROCESSING(src, thing)
		if (state != SS_RUNNING || over_budget())
			pause()
			return
