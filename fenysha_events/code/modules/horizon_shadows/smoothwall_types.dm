// MARK: Shadow-atom
/atom/movable/atom_shadow
	name = "shadow"
	icon = 'fenysha_events/icons/shadows/solid_wall_mask.dmi'
	icon_state = "wall-0"
	anchored = TRUE
	plane = ATOMS_FOV_SHADOWS_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	tiles_with = list(
		/atom/movable/atom_shadow,
		/obj/machinery/door,
		/obj/structure/grille,
		/obj/structure/window/fulltile,
		/obj/structure/window/reinforced/fulltile,
		/obj/structure/window/reinforced/plasma/fulltile,
		/obj/structure/window/reinforced/tinted/fulltile,
		)

/atom/movable/atom_shadow/Initialize(mapload)
	. = ..()
	relativewall()
	relativewall_neighbours()

/atom/movable/atom_shadow/handle_icon_junction(junction)
	icon_state = "wall-[junction]"

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

/turf/closed/indestructible
	var/atom/movable/atom_shadow/shadow

/turf/closed/indestructible/Initialize(mapload)
	. = ..()
	shadow = new /atom/movable/atom_shadow(src, src)

/turf/closed/indestructible/Destroy()
	shadow?.Destroy()
	return ..()

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
