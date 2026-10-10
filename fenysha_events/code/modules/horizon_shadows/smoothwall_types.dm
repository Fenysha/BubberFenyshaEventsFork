SUBSYSTEM_DEF(shadow)
	name = "Shadow"
	dependencies = list(
		/datum/controller/subsystem/icon_smooth,
	)
	wait = 1
	priority = FIRE_PRIORITY_SMOOTHING + 10
	ss_flags = SS_TICKER | SS_NO_INIT

	var/list/queue = list()
	/// assoc lookup for `queue`, makes dedupe O(1) (it used to be `A in queue`, O(n))
	var/list/queued_lookup = list()
	var/list/door_queue = list()
	var/list/door_lookup = list()

	/// Every atom that currently owns a USE_ICON_STATE shadow, used by the resync sweeps
	var/list/casters = list()
	/// Resync sweeps still to do. Walls get smoothed AFTER they are initialized, so we re-read their icon_state
	/// once smoothing has surely settled (safety net on top of the smoothing hook).
	var/resync_sweeps_left = 2
	var/next_resync = 0

/datum/controller/subsystem/shadow/fire()
	if(SSatoms.initializing_something())
		return

	// Safety net for map load: re-read every wall's icon_state after icon smoothing finished
	if(resync_sweeps_left && SSicon_smooth.initialized && world.time >= next_resync)
		resync_sweeps_left--
		next_resync = world.time + 10 SECONDS
		for(var/atom/caster as anything in casters)
			queue_shadow(caster)

	var/list/cache = queue
	while(length(cache))
		var/atom/A = cache[length(cache)]
		cache.len--
		queued_lookup -= A

		if(QDELETED(A) || !(A.shadow_flags & ATOM_SHADOW_USE_ICON_STATE) || !A.shadow)
			continue

		A.update_shadow_from_icon_state()

		if(MC_TICK_CHECK)
			return

	cache = door_queue
	while(length(cache))
		var/obj/machinery/door/D = cache[length(cache)]
		cache.len--
		door_lookup -= D

		if(QDELETED(D))
			continue

		D.update_dir()

		if(MC_TICK_CHECK)
			return

	if(!length(queue) && !length(door_queue) && !resync_sweeps_left)
		can_fire = FALSE

/datum/controller/subsystem/shadow/proc/queue_shadow(atom/A)
	if(!(A.shadow_flags & ATOM_SHADOW_USE_ICON_STATE) || queued_lookup[A])
		return
	queued_lookup[A] = TRUE
	queue += A
	can_fire = TRUE

/datum/controller/subsystem/shadow/proc/unqueue_shadow(atom/A)
	casters -= A
	if(queued_lookup[A])
		queued_lookup -= A
		queue -= A

/datum/controller/subsystem/shadow/proc/queue_door(obj/machinery/door/D)
	if(door_lookup[D])
		return
	door_lookup[D] = TRUE
	door_queue += D
	can_fire = TRUE


/atom
	var/shadow_flags = NONE
	var/shadow_base_icon_state = "shadow_mask"
	var/atom/movable/atom_shadow/shadow

// NOTE: /turf/Initialize used to call give_shadow() a second time, it is redundant (atom/Initialize already does it)
/atom/Initialize(mapload, ...)
	. = ..()
	if(shadow_flags & ATOM_CAST_SHADOW)
		give_shadow()

/atom/Destroy(force)
	. = ..()
	if(shadow_flags & ATOM_SHADOW_USE_ICON_STATE)
		SSshadow.unqueue_shadow(src)
	if(shadow)
		remove_shadow()

/turf/Initialize(mapload)
	. = ..()
	if(shadow_flags & ATOM_CAST_SHADOW)
		give_shadow()

/atom/proc/give_shadow()
	if(shadow)
		return

	var/turf/T = get_turf(src)
	if(!T)
		return

	var/shadow_path = /atom/movable/atom_shadow

	if(istype(src, /obj/machinery/door))
		var/obj/machinery/door/D = src
		if(D.glass)
			return
		shadow_path = /atom/movable/atom_shadow/door

	shadow = new shadow_path(T)
	shadow.base_icon_state = shadow_base_icon_state

	if(shadow_flags & ATOM_SHADOW_USE_ICON_STATE)
		shadow.icon_state = "[shadow_base_icon_state]-0"
		shadow.smoothing_flags = NONE
		SSshadow.casters += src
		register_shadow_smoothing()
		SSshadow.queue_shadow(src)
	else if(istype(shadow, /atom/movable/atom_shadow/door))
		shadow.icon_state = icon_state
		shadow.dir = dir

	if(shadow_flags & ATOM_SHADOW_ABSOLUTE)
		shadow.mark_absolute()

/// Make the shadow follow the icon smoothing of its owner (fixes shadows not "catching" walls smoothed after init)
/atom/proc/register_shadow_smoothing()
	RegisterSignal(src, COMSIG_ATOM_SMOOTHED_ICON, PROC_REF(on_shadow_owner_smoothed), override = TRUE)

/atom/proc/on_shadow_owner_smoothed(datum/source)
	SIGNAL_HANDLER
	SSshadow.queue_shadow(src)


/atom/proc/update_shadow_from_icon_state()
	if(!(shadow_flags & ATOM_SHADOW_USE_ICON_STATE) || QDELETED(shadow))
		return

	var/new_state = "[shadow_base_icon_state]-[get_shadow_junction_from_icon()]"
	// don't touch the appearance when nothing changed - every set is a client-side appearance update
	if(shadow.icon_state == new_state)
		return
	shadow.icon_state = new_state

/atom/proc/remove_shadow()
	QDEL_NULL(shadow)

/atom/proc/get_shadow_junction_from_icon()
	var/static/list/cache = list()
	var/state = icon_state
	if(!state)
		return 0
	if(state in cache)
		return cache[state]

	var/pos = findlasttext(state, "-")
	var/num = 0
	if(pos)
		var/numtext = copytext(state, pos + 1)
		num = text2num(numtext)
		if(isnull(num))
			num = 0

	cache[state] = num
	return num

/atom/movable/Moved(atom/old_loc, movement_dir, forced, list/old_locs, momentum_change)
	. = ..()
	if(shadow)
		shadow.forceMove(loc)

/atom/movable/setDir(newdir)
	. = ..()
	shadow?.dir = newdir

// MARK: Shadow-atom
/atom/movable/atom_shadow
	name = "shadow"
	icon = 'fenysha_events/icons/shadows/shadow_mask.dmi'
	icon_state = "shadow_mask-0"
	anchored = TRUE
	plane = ATOMS_FOV_SHADOWS_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = SMOOTH_GROUP_SHADOWMASK
	canSmoothWith = SMOOTH_GROUP_SHADOWMASK + SMOOTH_GROUP_WALLS

	base_icon_state = "shadow_mask"


/// Tints the mask (invisibly) so the cordon chain (cordon_chain.dm) can pick it out.
/atom/movable/atom_shadow/proc/mark_absolute()
	color = CORDON_MARK_COLOR

// Old names, kept so nothing else breaks
/atom/movable/atom_shadow/proc/enable_ghost_override()
	return
/atom/movable/atom_shadow/proc/disable_ghost_override()
	return
/atom/movable/atom_shadow/proc/sync_ghost_override()
	return

/atom/movable/atom_shadow/proc/handle_icon_junction(junction)
	icon_state = "[base_icon_state]-[junction]"

/atom/movable/atom_shadow/door
	icon = 'fenysha_events/icons/shadows/airlock_mask.dmi'

/atom/movable/atom_shadow/door/handle_icon_junction(junction)
	return

// MARK: WALL
/turf/closed/wall
	shadow_flags = ATOM_CAST_SHADOW | ATOM_SHADOW_USE_ICON_STATE

/turf/closed/indestructible
	shadow_flags = ATOM_CAST_SHADOW | ATOM_SHADOW_USE_ICON_STATE

/turf/closed/indestructible/fakeglass
	shadow_flags = NONE

/turf/closed/mineral
	shadow_flags = ATOM_CAST_SHADOW | ATOM_SHADOW_USE_ICON_STATE

/turf/closed/rw_wall
	shadow_flags = ATOM_CAST_SHADOW | ATOM_SHADOW_USE_ICON_STATE

/turf/cordon/absolute
	shadow_flags = ATOM_CAST_SHADOW | ATOM_SHADOW_ABSOLUTE

/obj/machinery/door
	shadow_flags = ATOM_CAST_SHADOW


// MARK: Door Airlock
/obj/machinery/door/airlock/update_icon(updates = ALL)
	. = ..()
	if(shadow)
		switch(airlock_state)
			if(AIRLOCK_OPENING)
				shadow.icon_state = "opening"
			if(AIRLOCK_OPEN)
				shadow.icon_state = "open"
			if(AIRLOCK_CLOSING)
				shadow.icon_state = "closing"
			if(AIRLOCK_CLOSED)
				shadow.icon_state = "closed"

/obj/machinery/door/poddoor/update_icon(updates = ALL)
	. = ..()
	if(shadow)
		shadow.icon_state = density ? "closed" : "open"
