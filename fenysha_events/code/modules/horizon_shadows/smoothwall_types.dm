/atom
	var/shadow_flags = NONE
	var/shadow_base_icon_state = "shadow_mask"
	var/atom/movable/atom_shadow/shadow

/atom/Initialize(mapload, ...)
	. = ..()
	if(shadow_flags & ATOM_CAST_SHADOW)
		give_shadow()

/turf/Initialize(mapload)
	. = ..()
	if(shadow_flags & ATOM_CAST_SHADOW)
		give_shadow()

/atom/Destroy(force)
	. = ..()
	if(shadow)
		remove_shadow()

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
		var/junction = get_shadow_junction_from_icon()
		shadow.icon_state = "[shadow_base_icon_state]-[junction]"
		shadow.smoothing_flags = NONE
	else if(istype(shadow, /atom/movable/atom_shadow/door))
		shadow.icon_state = icon_state
		shadow.dir = dir

	if(shadow_flags & ATOM_SHADOW_ABSOLUTE)
		shadow.enable_ghost_override()

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
	smoothing_groups = SMOOTH_GROUP_SHADOWMASK + SMOOTH_GROUP_WALLS + SMOOTH_GROUP_CLOSED_TURFS
	canSmoothWith = SMOOTH_GROUP_SHADOWMASK + SMOOTH_GROUP_WALLS

	base_icon_state = "shadow_mask"

	tiles_with = list(
		/atom/movable/atom_shadow,
		/obj/machinery/door,
		/obj/structure/grille,
		/obj/structure/window/fulltile,
		/obj/structure/window/reinforced/fulltile,
		/obj/structure/window/reinforced/plasma/fulltile,
		/obj/structure/window/reinforced/tinted/fulltile,
		/turf/cordon,
	)

	var/atom/movable/atom_shadow/ghost_override_shadow


/atom/movable/atom_shadow/Initialize(mapload)
	. = ..()
	relativewall()
	relativewall_neighbours()
	if(ghost_override_shadow)
		sync_ghost_override()

/atom/movable/atom_shadow/Destroy()
	ghost_override_shadow?.Destroy()
	ghost_override_shadow = null
	return ..()

/atom/movable/atom_shadow/proc/enable_ghost_override()
	if(ghost_override_shadow)
		return
	ghost_override_shadow = new /atom/movable/atom_shadow/ghost_override(loc)
	sync_ghost_override()

/atom/movable/atom_shadow/proc/disable_ghost_override()
	ghost_override_shadow?.Destroy()
	ghost_override_shadow = null

/atom/movable/atom_shadow/proc/sync_ghost_override()
	if(!ghost_override_shadow)
		return
	ghost_override_shadow.icon = icon
	ghost_override_shadow.icon_state = icon_state
	ghost_override_shadow.dir = dir
	ghost_override_shadow.pixel_x = pixel_x
	ghost_override_shadow.pixel_y = pixel_y
	// Do NOT copy alpha/color from the normal shadow.
	// This shadow is outside the WALL_FOV pipeline.
	ghost_override_shadow.alpha = 255
	ghost_override_shadow.color = null

/atom/movable/atom_shadow/handle_icon_junction(junction)
	icon_state = "[base_icon_state]-[junction]"
	sync_ghost_override()

/atom/movable/atom_shadow/door
	icon = 'fenysha_events/icons/shadows/airlock_mask.dmi'

/atom/movable/atom_shadow/door/handle_icon_junction(junction)
	return

// MARK: Ghost shadow
/atom/movable/atom_shadow/ghost_override
	name = "ghost shadow"

	plane = GHOST_PLANE

	invisibility = INVISIBILITY_OBSERVER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	anchored = TRUE
	density = FALSE

	alpha = 255
	color = null

	smoothing_flags = NONE
	smoothing_groups = null
	canSmoothWith = null


// MARK: WALL
/turf/closed/wall
	shadow_flags = ATOM_CAST_SHADOW

/turf/closed/indestructible
	shadow_flags = ATOM_CAST_SHADOW

/turf/closed/mineral
	shadow_flags = ATOM_CAST_SHADOW

/turf/closed/rw_wall
	shadow_flags = ATOM_CAST_SHADOW

/turf/cordon/absolute
	shadow_flags = ATOM_CAST_SHADOW

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
