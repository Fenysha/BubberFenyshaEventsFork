SUBSYSTEM_DEF(rw_environment)
	name = "\[RW\] Environment"
	wait = 2 SECONDS
	// NOTE: bitwise OR, not logical || — the old `||` collapsed the flags to TRUE (1).
	ss_flags = SS_KEEP_TIMING | SS_BACKGROUND | SS_TICKER
	runlevels = RUNLEVEL_GAME

	var/list/loaded_cells = list()
	var/list/cell_run
	var/list/zone_run
	var/last_run_time = 0

/datum/controller/subsystem/rw_environment/stat_entry(msg)
	msg = "cells:[length(loaded_cells)] zones:[length(GLOB.rimworld_rust_zones)]"
	return ..()

/datum/controller/subsystem/rw_environment/proc/register_cell(datum/planet_cell/cell)
	if(cell && !(cell in loaded_cells))
		loaded_cells += cell

/datum/controller/subsystem/rw_environment/proc/unregister_cell(datum/planet_cell/cell)
	loaded_cells -= cell

/datum/controller/subsystem/rw_environment/fire(resumed = FALSE)
	if(!resumed)
		cell_run = loaded_cells.Copy()
		zone_run = GLOB.rimworld_rust_zones.Copy()
		if(!last_run_time)
			last_run_time = world.time
	var/now = world.time
	var/delta_ds = clamp(now - last_run_time, 1, 10 SECONDS)
	var/seconds = delta_ds * 0.1

	var/list/cells = cell_run
	while(length(cells))
		var/datum/planet_cell/cell = cells[length(cells)]
		cells.len--
		if(QDELETED(cell) || !cell.is_loaded())
			if(!QDELETED(cell))
				cell.stop_cell_weather()
			loaded_cells -= cell
			continue
		cell.process_environment(delta_ds)
		if(MC_TICK_CHECK)
			return

	var/list/zones = zone_run
	while(length(zones))
		var/key = zones[length(zones)]
		zones.len--
		var/area/rimworld/zone/Z = GLOB.rimworld_rust_zones[key]
		if(!Z || QDELETED(Z))
			continue
		Z.rw_tick_stats()
		Z.rw_tick_thermal(seconds)
		if(MC_TICK_CHECK)
			return

	last_run_time = now
