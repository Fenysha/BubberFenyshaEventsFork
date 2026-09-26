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
	canSmoothWith = SMOOTH_GROUP_SHADOWMASK

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

	return .


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
	icon_state = "shadow_mask-[junction]"
	sync_ghost_override()


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


/atom/movable/atom_shadow/door
	icon = 'fenysha_events/icons/shadows/airlock_mask.dmi'

/atom/movable/atom_shadow/door/handle_icon_junction(junction)
	return

// MARK: WALL
/turf/closed/wall
	var/atom/movable/atom_shadow/shadow

/turf/closed/wall/Initialize(mapload)
	. = ..()
	shadow = new /atom/movable/atom_shadow(src, src)

/turf/closed/wall/Destroy()
	shadow?.Destroy()
	return ..()

// Indestructible
/turf/closed/indestructible
	var/atom/movable/atom_shadow/shadow

/turf/closed/indestructible/Initialize(mapload)
	. = ..()
	shadow = new /atom/movable/atom_shadow(src, src)

/turf/closed/indestructible/Destroy()
	shadow?.Destroy()
	return ..()

// Mineral
/turf/closed/mineral
	var/atom/movable/atom_shadow/shadow

/turf/closed/mineral/Initialize(mapload)
	. = ..()
	shadow = new /atom/movable/atom_shadow(src, src)

/turf/closed/mineral/Destroy()
	shadow?.Destroy()
	return ..()

// Rim Wall
/turf/closed/rw_wall
	var/atom/movable/atom_shadow/shadow

/turf/closed/rw_wall/Initialize(mapload)
	. = ..()
	shadow = new /atom/movable/atom_shadow(src, src)

/turf/closed/rw_wall/Destroy()
	shadow?.Destroy()
	return ..()

/turf/cordon/absolute
	var/atom/movable/atom_shadow/shadow

/turf/cordon/absolute/Initialize(mapload)
	. = ..()
	shadow = new /atom/movable/atom_shadow(src, src)
	shadow.enable_ghost_override()

// MARK: Door Airlock
/obj/machinery/door
	var/atom/movable/atom_shadow/door/shadow

/obj/machinery/door/Initialize(mapload)
	. = ..()
	if(!glass)
		shadow = new(loc)
		shadow.icon_state = icon_state
		shadow.dir = dir

/obj/machinery/door/setDir(newdir)
    . = ..()
    shadow?.dir = newdir

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

/obj/machinery/door/Destroy()
	shadow?.Destroy()
	return ..()

/obj/machinery/door/poddoor/update_icon(updates = ALL)
	. = ..()
	if(shadow)
		shadow.icon_state = density ? "closed" : "open"
