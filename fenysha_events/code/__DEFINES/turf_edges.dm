#define TURF_EDGE_STATE_FOR_DIR(dir) (\
	(dir) == NORTH ? "edge_N" : \
	(dir) == SOUTH ? "edge_S" : \
	(dir) == EAST ? "edge_E" : \
	(dir) == WEST ? "edge_W" : \
	(dir) == NORTHEAST ? "edge_NE" : \
	(dir) == NORTHWEST ? "edge_NW" : \
	(dir) == SOUTHEAST ? "edge_SE" : \
	(dir) == SOUTHWEST ? "edge_SW" : null)

/// Edge bit layout (shared with the Rust stamp: bit n of `edge_mask`).
/// N S E W NE NW SE SW -> 1 2 4 8 16 32 64 128
#define TURF_EDGE_MASK_CARDINAL (1|2|4|8)

/// Edge icon states in bit order.
GLOBAL_LIST_INIT(turf_edge_states_in_order, list("edge_N", "edge_S", "edge_E", "edge_W", "edge_NE", "edge_NW", "edge_SE", "edge_SW"))

/// dir (1..10) -> edge icon state. Indexed directly, no ternary chain.
GLOBAL_LIST_INIT(turf_edge_state_by_dir, init_turf_edge_state_by_dir())
/// dir (1..10) -> edge bit.
GLOBAL_LIST_INIT(turf_edge_bit_by_dir, init_turf_edge_bit_by_dir())
/// icon file -> bitmask of edge states it contains. icon_exists() is slow, so it runs once per file.
GLOBAL_LIST_EMPTY(turf_edge_mask_cache)

/proc/init_turf_edge_state_by_dir()
	var/list/out = new /list(10)
	out[NORTH] = "edge_N"
	out[SOUTH] = "edge_S"
	out[EAST] = "edge_E"
	out[WEST] = "edge_W"
	out[NORTHEAST] = "edge_NE"
	out[NORTHWEST] = "edge_NW"
	out[SOUTHEAST] = "edge_SE"
	out[SOUTHWEST] = "edge_SW"
	return out

/proc/init_turf_edge_bit_by_dir()
	var/list/out = new /list(10)
	for(var/i in 1 to 10)
		out[i] = 0
	out[NORTH] = 1
	out[SOUTH] = 2
	out[EAST] = 4
	out[WEST] = 8
	out[NORTHEAST] = 16
	out[NORTHWEST] = 32
	out[SOUTHEAST] = 64
	out[SOUTHWEST] = 128
	return out

/// Which of the 8 edge states exist in this icon file (cached per file).
/proc/get_icon_edge_mask(icon_file)
	if(!icon_file)
		return 0
	var/cacheable = isfile(icon_file)
	if(cacheable)
		var/cached = GLOB.turf_edge_mask_cache[icon_file]
		if(!isnull(cached))
			return cached
	var/mask = 0
	var/bit = 1
	for(var/state in GLOB.turf_edge_states_in_order)
		if(icon_exists(icon_file, state))
			mask |= bit
		bit <<= 1
	if(cacheable)
		GLOB.turf_edge_mask_cache[icon_file] = mask
	return mask

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

