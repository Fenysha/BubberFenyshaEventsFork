/area/rimworld/zone
	name = "Enclosed Room"
	icon_state = "yellow"
	outdoors = FALSE
	daylight = FALSE
	area_flags = VALID_TERRITORY | BLOBS_ALLOWED | CULT_PERMITTED
	area_flags_mapping = NONE
	default_gravity = TRUE

	var/rust_area_id = 0
	var/area/rimworld/parent_cell_area
	var/zone_color = "#ffff00"

/area/rimworld/zone/New()
	. = ..()
	var/list/palette = list(
		"#e8a87c", "#85dcb8", "#c38d9e", "#41b3a3",
		"#e27d60", "#f64c72", "#5cdb95", "#f9ed69",
		"#b8f2e6", "#ffa69e", "#aed9e0", "#ffb347",
	)
	zone_color = pick(palette)

/area/rimworld/zone/Destroy()
	parent_cell_area = null
	return ..()

/area/rimworld/zone/room
	name = "Room"

/area/rimworld/zone/hall
	name = "Hall"

/area/rimworld/zone/closet
	name = "Closet"

GLOBAL_LIST_EMPTY(rimworld_rust_zones)

/proc/rimworld_zone_key(z, rust_area_id)
	return "[z]_[rust_area_id]"

/proc/get_rimworld_zone(z, rust_area_id)
	return GLOB.rimworld_rust_zones[rimworld_zone_key(z, rust_area_id)]

/proc/ensure_rimworld_zone(z, rust_area_id, size = 0, area/rimworld/parent = null)
	var/key = rimworld_zone_key(z, rust_area_id)
	var/area/rimworld/zone/existing = GLOB.rimworld_rust_zones[key]
	if(existing && !QDELETED(existing))
		return existing

	var/zone_type = /area/rimworld/zone/room
	if(size <= 4)
		zone_type = /area/rimworld/zone/closet
	else if(size >= 40)
		zone_type = /area/rimworld/zone/hall

	var/area/rimworld/zone/A = new zone_type()
	A.rust_area_id = rust_area_id
	A.parent_cell_area = parent
	A.name = "[initial(A.name)] ([rust_area_id])"
	GLOB.rimworld_rust_zones[key] = A
	return A

/proc/release_rimworld_zone(z, rust_area_id)
	var/key = rimworld_zone_key(z, rust_area_id)
	var/area/rimworld/zone/A = GLOB.rimworld_rust_zones[key]
	if(!A)
		return
	GLOB.rimworld_rust_zones -= key
	if(!QDELETED(A))
		qdel(A)

/proc/apply_rust_zone_to_turf(turf/T, rust_area_id, is_enclosed, area/rimworld/parent_cell_area = null)
	if(!T || !rust_area_id)
		return

	if(!is_enclosed)
		if(parent_cell_area && T.loc != parent_cell_area)
			T.change_area(T.loc, parent_cell_area)
		return

	var/list/b = rustg_area_get_area_bounds(rust_area_id, T.z)
	var/size = b?["size"] || 0
	var/area/rimworld/zone/Z = ensure_rimworld_zone(T.z, rust_area_id, size, parent_cell_area)
	if(T.loc != Z)
		T.change_area(T.loc, Z)

/**
 * A component is "enclosed" (indoor zone) when it is small relative to
 * the open surface of the Z, OR it is a tiny pocket (<= 6 tiles).
 *
 * Pure outdoor space on a 128² cell is thousands of tiles — rooms are not.
 */
/proc/is_rust_area_enclosed(z, rust_area_id, open_tiles_on_z = null)
	var/list/bounds = rustg_area_get_area_bounds(rust_area_id, z)
	if(!bounds || !bounds["size"])
		return FALSE
	var/size = bounds["size"]
	// Always treat small pockets as rooms (3x3 interior = 1, 5x5 interior = 9, etc.)
	if(size <= 64)
		return TRUE
	if(isnull(open_tiles_on_z))
		var/list/stats = rustg_area_get_stats(z)
		open_tiles_on_z = stats?["open_tiles"] || 1
	// Large warehouse still indoor if under half the open map
	return size < (open_tiles_on_z * 0.5)

/proc/resolve_parent_cell_area(turf/T)
	if(!T)
		return null
	var/area/current = T.loc
	if(istype(current, /area/rimworld) && !istype(current, /area/rimworld/zone))
		return current
	if(istype(current, /area/rimworld/zone))
		var/area/rimworld/zone/Z = current
		return Z.parent_cell_area
	// Walk nearby for an outdoor rimworld area
	for(var/turf/N in RANGE_TURFS(3, T))
		if(istype(N.loc, /area/rimworld) && !istype(N.loc, /area/rimworld/zone))
			return N.loc
	return null

/proc/sync_open_tile_zone(turf/T, area/rimworld/parent = null)
	if(!T)
		return
	var/list/info = rustg_area_tile_info(T.x, T.y, T.z)
	if(!info || info["is_boundary"])
		return
	var/aid = info["area_id"]
	if(!aid)
		return
	if(!parent)
		parent = resolve_parent_cell_area(T)
	var/enclosed = is_rust_area_enclosed(T.z, aid)
	apply_rust_zone_to_turf(T, aid, enclosed, parent)

/datum/controller/subsystem/area_rust/proc/sync_zone_for_turf(turf/T, radius = 1)
	if(!T || !zone_sync_enabled)
		return
	var/z = T.z
	if(!initialised_z["[z]"])
		return

	var/area/rimworld/parent = resolve_parent_cell_area(T)

	var/list/touched_ids = list()
	var/list/seed_turfs = list(T)
	seed_turfs += get_step(T, NORTH)
	seed_turfs += get_step(T, SOUTH)
	seed_turfs += get_step(T, EAST)
	seed_turfs += get_step(T, WEST)

	for(var/turf/N as anything in seed_turfs)
		if(!N || N.z != z)
			continue
		var/list/info = rustg_area_tile_info(N.x, N.y, z)
		if(!info || info["is_boundary"])
			continue
		var/aid = info["area_id"]
		if(aid)
			touched_ids["[aid]"] = TRUE

	// Paint / update components we know about from seeds
	for(var/id_str in touched_ids)
		var/aid = text2num(id_str)
		if(!aid)
			continue

		var/list/b = rustg_area_get_area_bounds(aid, z)
		var/size = b?["size"] || 0
		if(!size)
			continue

		var/enclosed = (size <= 64)
		if(!enclosed)
			var/open_tiles = open_tiles_cache?["[z]"]
			if(isnull(open_tiles))
				var/list/stats = rustg_area_get_stats(z)
				open_tiles = stats?["open_tiles"] || 1
				if(!open_tiles_cache)
					open_tiles_cache = list()
				open_tiles_cache["[z]"] = open_tiles
			enclosed = size < (open_tiles * 0.5)

		if(!enclosed)
			for(var/turf/N as anything in seed_turfs)
				if(!N || N.z != z)
					continue
				var/list/info = rustg_area_tile_info(N.x, N.y, z)
				if(info && !info["is_boundary"] && info["area_id"] == aid)
					apply_rust_zone_to_turf(N, aid, FALSE, parent)
			continue

		ensure_rimworld_zone(z, aid, size, parent)
		var/list/tiles = rustg_area_get_area_tiles(aid, z)
		if(!tiles)
			for(var/turf/N as anything in seed_turfs)
				if(N && N.z == z)
					sync_open_tile_zone(N, parent)
			continue

		for(var/entry in tiles)
			if(!islist(entry))
				continue
			var/list/xy = entry
			var/tx = xy[1]
			var/ty = length(xy) >= 2 ? xy[2] : null
			if(isnull(tx))
				tx = xy["x"]
				ty = xy["y"]
			if(isnull(tx) || isnull(ty))
				continue
			var/turf/OT = locate(tx, ty, z)
			if(OT)
				apply_rust_zone_to_turf(OT, aid, TRUE, parent)

	prune_stale_rimworld_zones(z, parent)


/proc/prune_stale_rimworld_zones(z, area/rimworld/parent_cell_area = null)
	if(!z)
		return
	var/list/dead_ids = list()
	for(var/key in GLOB.rimworld_rust_zones)
		if(findtext(key, "[z]_") != 1)
			continue
		var/area/rimworld/zone/A = GLOB.rimworld_rust_zones[key]
		if(!A || QDELETED(A))
			GLOB.rimworld_rust_zones -= key
			continue
		var/aid = A.rust_area_id
		var/alive = aid && rustg_area_area_exists(aid, z) && is_rust_area_enclosed(z, aid)
		if(alive)
			continue
		var/area/rimworld/parent = parent_cell_area || A.parent_cell_area
		// Copy turf list — change_area mutates area contents
		var/list/turf_snapshot = list()
		for(var/turf/T in A)
			turf_snapshot += T
		for(var/turf/T as anything in turf_snapshot)
			if(parent && T.loc != parent)
				T.change_area(T.loc, parent)
		dead_ids += aid

	for(var/aid in dead_ids)
		release_rimworld_zone(z, aid)

/proc/resync_rimworld_zones_on_z(z, area/rimworld/parent_cell_area = null, list/limit_turfs = null)
	var/list/stats = rustg_area_get_stats(z)
	if(!stats)
		return

	var/open_tiles = stats["open_tiles"] || 1
	var/list/live_zone_ids = list()
	var/list/to_scan

	if(length(limit_turfs))
		to_scan = limit_turfs
	else
		var/width = stats["width"] || 0
		var/height = stats["height"] || 0
		if(!width || !height)
			return
		to_scan = list()
		for(var/x in 1 to width)
			for(var/y in 1 to height)
				var/turf/T = locate(x, y, z)
				if(T)
					to_scan += T
			CHECK_TICK

	for(var/turf/T as anything in to_scan)
		if(!T || T.z != z)
			continue
		var/list/info = rustg_area_tile_info(T.x, T.y, z)
		if(!info || info["is_boundary"])
			continue
		var/aid = info["area_id"]
		if(!aid)
			continue
		if(!parent_cell_area)
			parent_cell_area = resolve_parent_cell_area(T)
		var/enclosed = is_rust_area_enclosed(z, aid, open_tiles)
		if(enclosed)
			live_zone_ids["[aid]"] = TRUE
		apply_rust_zone_to_turf(T, aid, enclosed, parent_cell_area)
		CHECK_TICK

	for(var/key in GLOB.rimworld_rust_zones)
		if(findtext(key, "[z]_") != 1)
			continue
		var/id_str = copytext(key, length("[z]_") + 1)
		if(!live_zone_ids[id_str])
			release_rimworld_zone(z, text2num(id_str))
