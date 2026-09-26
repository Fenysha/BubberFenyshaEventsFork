#define TURF_EDGE_STATE_FOR_DIR(dir) (\
	(dir) == NORTH ? "edge_N" : \
	(dir) == SOUTH ? "edge_S" : \
	(dir) == EAST ? "edge_E" : \
	(dir) == WEST ? "edge_W" : \
	(dir) == NORTHEAST ? "edge_NE" : \
	(dir) == NORTHWEST ? "edge_NW" : \
	(dir) == SOUTHEAST ? "edge_SE" : \
	(dir) == SOUTHWEST ? "edge_SW" : null)

#define TURF_CORNER_CCW 1
#define TURF_CORNER_DIAG 2
#define TURF_CORNER_CW 4


/// Returns a neighboring turf, wrapping around the planetary map if required.
/// This keeps edge blending continuous across the map border.
/proc/turf_wrap_step(turf/origin, direction)
	if(!origin || !direction)
		return null

	var/turf/step = get_step(origin, direction)

	if(step)
		return step
	/*
	if(!SSmapping.expedition_planet_tiles?["[origin.z]"])
		return null
	*/
	var/nx = origin.x
	var/ny = origin.y

	if(direction & EAST)
		nx += 1

	if(direction & WEST)
		nx -= 1

	if(direction & NORTH)
		ny += 1

	if(direction & SOUTH)
		ny -= 1

	if(nx < 1)
		nx = world.maxx
	else if(nx > world.maxx)
		nx = 1

	if(ny < 1)
		ny = world.maxy
	else if(ny > world.maxy)
		ny = 1

	return locate(nx, ny, origin.z)


/// Calculates corner masks using a supplied turf type.
/// Returns: list(SE, NE, NW, SW)
///
/// This is compatible with the SS14 IconSmooth corner format:
/// 0-7 per corner.
/proc/turf_corner_fills(turf/origin, connect_type)
	var/n = istype(turf_wrap_step(origin, NORTH), connect_type)
	var/s = istype(turf_wrap_step(origin, SOUTH), connect_type)
	var/e = istype(turf_wrap_step(origin, EAST), connect_type)
	var/w = istype(turf_wrap_step(origin, WEST), connect_type)

	var/ne = istype(turf_wrap_step(origin, NORTHEAST), connect_type)
	var/nw = istype(turf_wrap_step(origin, NORTHWEST), connect_type)
	var/se = istype(turf_wrap_step(origin, SOUTHEAST), connect_type)
	var/sw = istype(turf_wrap_step(origin, SOUTHWEST), connect_type)

	var/corner_ne = 0
	var/corner_nw = 0
	var/corner_se = 0
	var/corner_sw = 0

	if(n)
		corner_ne |= TURF_CORNER_CCW
		corner_nw |= TURF_CORNER_CW

	if(ne)
		corner_ne |= TURF_CORNER_DIAG

	if(e)
		corner_ne |= TURF_CORNER_CW
		corner_se |= TURF_CORNER_CCW

	if(se)
		corner_se |= TURF_CORNER_DIAG

	if(s)
		corner_se |= TURF_CORNER_CW
		corner_sw |= TURF_CORNER_CCW

	if(sw)
		corner_sw |= TURF_CORNER_DIAG

	if(w)
		corner_sw |= TURF_CORNER_CW
		corner_nw |= TURF_CORNER_CCW

	if(nw)
		corner_nw |= TURF_CORNER_DIAG

	return list(
		corner_se,
		corner_ne,
		corner_nw,
		corner_sw,
	)


#define SMOOTH_GROUP_SHADOWMASK S_OBJ(199)
