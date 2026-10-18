/**
 * Lightweight tick subsystem for production buildings.
 * Only registered buildings are processed — no global machinery list scan.
 */
SUBSYSTEM_DEF(production)
	name = "Production"
	wait = 1 SECONDS
	ss_flags = SS_KEEP_TIMING | SS_BACKGROUND | SS_NO_INIT
	runlevels = RUNLEVEL_GAME

	var/list/obj/building/processing = list()
	var/list/obj/building/currentrun = list()

/datum/controller/subsystem/production/stat_entry(msg)
	return ..("buildings:[length(processing)]")

/datum/controller/subsystem/production/fire(resumed)
	if(!resumed)
		currentrun = processing.Copy()

	var/seconds = wait * 0.1
	while(length(currentrun))
		var/obj/building/B = currentrun[length(currentrun)]
		currentrun.len--
		if(QDELETED(B) || !B.processing)
			processing -= B
			continue
		B.process_building(seconds)
		if(MC_TICK_CHECK)
			return

/datum/controller/subsystem/production/proc/register_building(obj/building/B)
	if(!B || (B in processing))
		return
	processing += B

/datum/controller/subsystem/production/proc/unregister_building(obj/building/B)
	processing -= B
	currentrun -= B
