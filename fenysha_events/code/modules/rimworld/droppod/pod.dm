#define RIMPOD_SEARCH_MAX_RADIUS 12
#define RIMPOD_SEARCH_RING_STEP 1

/datum/pod_style/rimworld
	name = "drop pod"
	desc = "A cramped one-way transport pod, built for planetary drops."
	icon_state = "pod"
	decal_icon = "default"
	rubble_type = RUBBLE_THIN
	has_door = TRUE
	shape = POD_SHAPE_NORMAL
	glow_color = "blue"


/obj/structure/closet/supplypod/rimworld_drop
	name = "drop pod"
	desc = "A one-way supply/troop pod, dropped from orbit."
	bluespace = TRUE
	style = /datum/pod_style/rimworld
	explosionSize = list(0,0,0,0)
	damage = 15
	effectStun = TRUE
	stay_after_drop = FALSE
	create_sparks = FALSE
	fallingSound = 'sound/items/weapons/mortar_long_whistle.ogg'
	delays = list(POD_TRANSIT = 15, POD_FALLING = 6, POD_OPENING = 10, POD_LEAVING = 20)

	var/datum/planet_cell/target_cell

/obj/structure/closet/supplypod/rimworld_drop/pre_open()
	. = ..()
	if(target_cell)
		SEND_SIGNAL(target_cell, COMSIG_RIMWORLD_CELL_POD_LANDED, src)


/datum/rimworld_pod_launcher
	var/datum/rimworld_planet/planet
	var/datum/planet_cell/target_cell
	var/poi_name
	var/list/obj/structure/closet/supplypod/rimworld_drop/pending_pods = list()

/datum/rimworld_pod_launcher/New(datum/planet_cell/cell, poi_hint = null)
	. = ..()
	if(!istype(cell))
		stack_trace("rimworld_pod_launcher created without a valid planet_cell")
		qdel(src)
		return
	target_cell = cell
	planet = cell.planet
	poi_name = poi_hint

/datum/rimworld_pod_launcher/Destroy()
	pending_pods.Cut()
	target_cell = null
	planet = null
	return ..()


/datum/rimworld_pod_launcher/proc/launch(list/contents_list, podtype = /obj/structure/closet/supplypod/rimworld_drop, datum/callback/on_landed_cb)
	if(!target_cell || !target_cell.is_valid())
		stack_trace("rimworld_pod_launcher: target_cell invalid at launch time")
		return FALSE

	var/datum/callback/proceed = CALLBACK(src, PROC_REF(do_launch), contents_list, podtype, on_landed_cb)
	return target_cell.ensure_loaded(poi_name, CALLBACK(src, PROC_REF(on_cell_ready), proceed))

/datum/rimworld_pod_launcher/proc/on_cell_ready(datum/callback/proceed, datum/planet_cell/cell, success)
	SIGNAL_HANDLER
	if(!success || !cell || QDELETED(src))
		log_world("rimworld_pod_launcher: failed to load target cell [cell?.get_name()]")
		return
	proceed.Invoke()

/datum/rimworld_pod_launcher/proc/do_launch(list/contents_list, podtype, datum/callback/on_landed_cb)
	if(!target_cell.is_loaded())
		log_world("rimworld_pod_launcher: cell reports ready but is_loaded() is FALSE")
		return FALSE

	var/turf/landing_turf = find_safe_landing_turf()
	if(!landing_turf)
		log_world("rimworld_pod_launcher: no safe landing turf found on cell [target_cell.get_name()]")
		return FALSE

	var/obj/structure/closet/supplypod/rimworld_drop/pod = new podtype()
	pod.target_cell = target_cell

	for(var/atom/movable/thing as anything in contents_list)
		if(!isnull(thing) && !QDELETED(thing))
			thing.forceMove(pod)

	if(on_landed_cb)
		RegisterSignal(pod, COMSIG_QDELETING, PROC_REF(clear_ref))
		var/datum/callback/wrapped = CALLBACK(src, PROC_REF(relay_landed), on_landed_cb, pod, landing_turf)
		addtimer(wrapped, pod.delays[POD_TRANSIT] + pod.delays[POD_FALLING] + 1)

	new /obj/effect/pod_landingzone(landing_turf, pod)
	return TRUE

/datum/rimworld_pod_launcher/proc/relay_landed(datum/callback/user_cb, obj/structure/closet/supplypod/rimworld_drop/pod, turf/landing_turf)
	if(QDELETED(pod))
		return
	user_cb.Invoke(pod, landing_turf)

/datum/rimworld_pod_launcher/proc/clear_ref(atom/source)
	SIGNAL_HANDLER
	pending_pods -= source

/datum/rimworld_pod_launcher/proc/find_safe_landing_turf(turf/start_turf)
	var/datum/turf_reservation/sub_level/reservation = target_cell.reservation
	var/list/candidate_turfs

	if(istype(reservation))
		candidate_turfs = reservation.get_inner_turfs()
		if(!start_turf)
			start_turf = reservation.get_center_turf()
	else
		candidate_turfs = target_cell.get_local_turfs()

	if(!candidate_turfs || !length(candidate_turfs))
		return null

	if(!start_turf || !(start_turf in candidate_turfs))
		start_turf = pick(candidate_turfs)

	if(is_turf_safe_for_landing(start_turf))
		return start_turf

	for(var/radius = 0, radius <= RIMPOD_SEARCH_MAX_RADIUS, radius += RIMPOD_SEARCH_RING_STEP)
		var/list/ring = radius == 0 ? list(start_turf) : view(radius, start_turf) - view(radius - RIMPOD_SEARCH_RING_STEP, start_turf)
		var/list/valid_in_ring = list()
		for(var/turf/candidate_turf in ring)
			if(!(candidate_turf in candidate_turfs)) //не вылезаем за пределы клетки
				continue
			if(is_turf_safe_for_landing(candidate_turf))
				valid_in_ring += candidate_turf
		if(length(valid_in_ring))
			return pick(valid_in_ring)

	var/list/all_valid = list()
	for(var/turf/candidate_turf in candidate_turfs)
		if(is_turf_safe_for_landing(candidate_turf))
			all_valid += candidate_turf
	if(length(all_valid))
		return pick(all_valid)
	return null

/datum/rimworld_pod_launcher/proc/is_turf_safe_for_landing(turf/candidate_turf)
	if(!istype(candidate_turf))
		return FALSE
	if(isspaceturf(candidate_turf) || isclosedturf(candidate_turf))
		return FALSE
	if(candidate_turf.density)
		return FALSE
	for(var/atom/movable/blocker in candidate_turf)
		if(blocker.density && !ismob(blocker))
			return FALSE
	return TRUE


/proc/launch_rimworld_pod(datum/planet_cell/cell, list/contents_list, poi_name = null, datum/callback/on_landed_cb = null, podtype = /obj/structure/closet/supplypod/rimworld_drop)
	var/datum/rimworld_pod_launcher/launcher = new(cell, poi_name)
	. = launcher.launch(contents_list, podtype, on_landed_cb)

	QDEL_IN(launcher, (launcher.target_cell ? 1 : 0) + 10 MINUTES)

#undef RIMPOD_SEARCH_MAX_RADIUS
#undef RIMPOD_SEARCH_RING_STEP
