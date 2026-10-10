#define AREA_GRID_BOUNDARY (1<<0)

#define AREA_KIND_OTHER  "other"
#define AREA_KIND_FLOOR  "floor"
#define AREA_KIND_WALL   "wall"
#define AREA_KIND_DOOR   "door"
#define AREA_KIND_WINDOW "window"
#define AREA_KIND_GRILLE "grille"
#define AREA_KIND_ABSOLUTE "absolute"

#define RUST_SEE_TURFS (1<<0)
#define RUST_SEE_MOBS  (1<<1)
#define RUST_SEE_OBJS  (1<<2)
#define RUST_SEE_THRU  (1<<3)
#define RUST_SEE_DEFAULT (RUST_SEE_TURFS | RUST_SEE_MOBS | RUST_SEE_OBJS)

/proc/get_turf_area_state(turf/T)
	if(!T)
		return null

	// The live turf type is authoritative. An ordinary /turf/open is never
	// a room boundary, even if ChangeTurf carried custom vars from the old wall.
	var/is_absolute = istype(T, /turf/cordon/absolute)
	var/is_closed_turf = istype(T, /turf/closed)
	var/is_open_turf = istype(T, /turf/open)
	var/is_boundary = is_absolute || is_closed_turf || (!is_open_turf && !!(T.area_grid_flags & AREA_GRID_BOUNDARY))
	var/opaque = IS_OPAQUE_TURF(T)
	var/dense = T.density
	var/kind = is_absolute ? AREA_KIND_ABSOLUTE : (is_boundary ? AREA_KIND_WALL : AREA_KIND_FLOOR)
	var/type_path = "[T.type]"

	if(is_absolute)
		opaque = TRUE
		dense = TRUE

	for(var/atom/movable/AM in T)
		var/path_str = "[AM.type]"
		var/is_window = findtext(path_str, "/window")
		var/is_grille = findtext(path_str, "/grille")
		if(AM.area_grid_flags & AREA_GRID_BOUNDARY)
			is_boundary = TRUE
			if(!is_absolute && !is_closed_turf)
				if(findtext(path_str, "/door"))
					kind = AREA_KIND_DOOR
					type_path = path_str
				else if(is_window)
					if(kind != AREA_KIND_DOOR)
						kind = AREA_KIND_WINDOW
						type_path = path_str
				else if(is_grille)
					if(kind == AREA_KIND_FLOOR)
						kind = AREA_KIND_GRILLE
						type_path = path_str
				else if(kind == AREA_KIND_FLOOR)
					kind = AREA_KIND_OTHER
					type_path = path_str
		else if(is_window || is_grille)
			// These objects are explicitly passable in los_check's pass flags.
			// Preserve their kind even when they do not form a room boundary.
			if(kind == AREA_KIND_FLOOR)
				kind = is_window ? AREA_KIND_WINDOW : AREA_KIND_GRILLE
				type_path = path_str
		if(AM.density && !is_window && !is_grille)
			dense = TRUE

	if(!is_boundary && kind != AREA_KIND_WINDOW && kind != AREA_KIND_GRILLE)
		kind = AREA_KIND_FLOOR

	return list(
		"is_boundary" = is_boundary,
		"opaque" = opaque,
		"dense" = dense,
		"kind" = kind,
		"type_path" = type_path,
	)
