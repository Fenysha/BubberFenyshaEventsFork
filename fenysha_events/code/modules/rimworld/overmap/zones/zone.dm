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

	/// Tile count.
	var/rw_size = 0
	/// Average tile beauty. 0 = neutral, roughly -6..+10 in practice.
	var/rw_room_beauty = 0
	/// Average tile cleanliness. 0 = neutral, negative = filth.
	var/rw_room_cleanliness = 0
	/// Derived "how impressive is this room" score (RimWorld impressiveness).
	var/rw_impressiveness = 0
	/// Border tiles that are plain wall / closed doors / open doors / real gaps.
	var/rw_border_walls = 0
	var/rw_doors_closed = 0
	var/rw_doors_open = 0
	var/rw_gaps = 0
	/// 0 = sealed, 1 = very leaky. Informational (UI), the thermal model uses the raw counts.
	var/rw_openness = 0
	/// tag -> count, filled during recalc.
	var/list/rw_tag_counts
	/// Objects that push heat into / out of the room (checked for QDELETED on use).
	var/list/rw_thermal_objects
	/// Current detected role. Never null after the first recalc.
	var/datum/rw_room_role/rw_role
	/// Highest-score role last time, used to detect role changes.
	var/rw_stats_dirty = TRUE
	var/rw_last_stats_time = 0
	var/rw_next_stats_time = 0

	/// Current air temperature, Celsius.
	var/rw_temperature = 15
	var/rw_temp_initialised = FALSE

/area/rimworld/zone/New()
	. = ..()
	var/list/palette = list(
		"#e8a87c", "#85dcb8", "#c38d9e", "#41b3a3",
		"#e27d60", "#f64c72", "#5cdb95", "#f9ed69",
		"#b8f2e6", "#ffa69e", "#aed9e0", "#ffb347",
	)
	zone_color = pick(palette)
	rw_role = GLOB.rw_room_roles?[/datum/rw_room_role/none]
	if(!rw_role)
		// GLOBAL_LIST_INIT may not have finished yet during early New(); soft-fallback.
		rw_role = new /datum/rw_room_role/none
	// Contents changes are handled by the Entered()/Exited() overrides below (no signal needed).

/area/rimworld/zone/Destroy()
	parent_cell_area = null
	rw_role = null
	rw_thermal_objects = null
	return ..()

/area/rimworld/zone/Entered(atom/movable/arrived, area/old_area)
	. = ..()
	rw_on_contents_changed(arrived)

/area/rimworld/zone/Exited(atom/movable/gone, direction)
	. = ..()
	rw_on_contents_changed(gone)

/area/rimworld/zone/proc/rw_on_contents_changed(atom/movable/AM)
	if(isobj(AM))
		rw_stats_dirty = TRUE

/// The planet cell this zone belongs to (through the parent outdoor area).
/area/rimworld/zone/proc/rw_get_cell()
	return parent_cell_area?.cell

/// Marks stats as stale. Cheap, safe to call from anywhere (filth spawn, floor swap, ...).
/// Base /area is a no-op; zones and outdoor rimworld areas can override.
/area/proc/rw_mark_dirty()
	return

/area/rimworld/zone/rw_mark_dirty()
	rw_stats_dirty = TRUE

/// Beauty / cleanliness / impressiveness labels — base stubs for non-zone areas.
/area/proc/rw_get_beauty()
	return 0

/area/proc/rw_get_cleanliness()
	return 0

/area/proc/rw_get_impressiveness()
	return 0

/area/rimworld/zone/rw_get_beauty()
	if(rw_stats_dirty || !rw_last_stats_time)
		rw_recalculate_stats()
	return rw_room_beauty

/area/rimworld/zone/rw_get_cleanliness()
	if(rw_stats_dirty || !rw_last_stats_time)
		rw_recalculate_stats()
	return rw_room_cleanliness

/area/rimworld/zone/rw_get_impressiveness()
	if(rw_stats_dirty || !rw_last_stats_time)
		rw_recalculate_stats()
	return rw_impressiveness


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

/proc/apply_rust_zone_to_turf(turf/T, rust_area_id, is_enclosed, area/rimworld/parent_cell_area = null, known_size = null)
	if(!T || !rust_area_id)
		return

	if(!is_enclosed)
		if(parent_cell_area && T.loc != parent_cell_area)
			T.change_area(T.loc, parent_cell_area)
		return

	// Reuse the size when the caller already has it (full resyncs touch thousands of tiles per zone).
	var/size = known_size
	if(isnull(size))
		var/list/b = rustg_area_get_area_bounds(rust_area_id, T.z)
		size = b?["size"] || 0
	var/area/rimworld/zone/Z = ensure_rimworld_zone(T.z, rust_area_id, size, parent_cell_area)
	if(T.loc != Z)
		T.change_area(T.loc, Z)

/// Largest component (in tiles) that can be an indoor zone. Absolute on purpose: the outdoor area of ONE
/// 127x127 cell is ~16k tiles, and a limit relative to the Z's open tiles (the old `size < open * 0.5`)
/// classified streets as rooms as soon as 3+ cells shared a Z.
#define RW_ZONE_MAX_ENCLOSED_SIZE 2500

/proc/rw_size_is_enclosed(size, open_tiles_on_z = null)
	if(!size)
		return FALSE
	return size <= RW_ZONE_MAX_ENCLOSED_SIZE

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
	if(size <= 64)
		return TRUE
	if(size > RW_ZONE_MAX_ENCLOSED_SIZE)
		return FALSE
	if(isnull(open_tiles_on_z))
		var/list/stats = rustg_area_get_stats(z)
		open_tiles_on_z = stats?["open_tiles"] || 1
	return rw_size_is_enclosed(size, open_tiles_on_z)

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
	// A sub-level that is still loading is synced once by setup_rust_zones().
	if(turf_in_loading_region(T))
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
		if(!enclosed && size <= RW_ZONE_MAX_ENCLOSED_SIZE)
			var/open_tiles = open_tiles_cache?["[z]"]
			if(isnull(open_tiles))
				var/list/stats = rustg_area_get_stats(z)
				open_tiles = stats?["open_tiles"] || 1
				if(!open_tiles_cache)
					open_tiles_cache = list()
				open_tiles_cache["[z]"] = open_tiles
			enclosed = rw_size_is_enclosed(size, open_tiles)

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
		// Only look at zones of the cell that is being synced; other cells are not affected.
		if(parent_cell_area && A.parent_cell_area && A.parent_cell_area != parent_cell_area)
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

/// Turfs of every loaded sub-level reservation on this Z (never the empty space between them).
/proc/get_loaded_sublevel_turfs_on_z(z)
	var/list/out = list()
	for(var/id_key in SSsub_levels.active_reservations)
		var/datum/turf_reservation/sub_level/res = SSsub_levels.active_reservations[id_key]
		if(!res || !length(res.bottom_left_turfs) || !length(res.top_right_turfs))
			continue
		var/turf/BL = res.bottom_left_turfs[1]
		var/turf/TR = res.top_right_turfs[1]
		if(!BL || !TR || BL.z != z)
			continue
		for(var/x in BL.x to TR.x)
			for(var/y in BL.y to TR.y)
				var/turf/T = locate(x, y, z)
				if(T)
					out += T
			CHECK_TICK
	return out

/**
 * Re-applies Rust zones to turfs.
 * limit_turfs: only those turfs; parent_cell_area is then the area they belong to.
 * No limit_turfs: every loaded sub-level on the Z. Each turf resolves ITS OWN parent area -
 * the area of the cell that just loaded must never be pushed onto other cells' turfs.
 */
/proc/resync_rimworld_zones_on_z(z, area/rimworld/parent_cell_area = null, list/limit_turfs = null)
	var/list/stats = rustg_area_get_stats(z)
	if(!stats)
		return

	var/open_tiles = stats["open_tiles"] || 1
	var/list/live_zone_ids = list()
	var/list/to_scan
	var/full_scan = !length(limit_turfs)

	if(!full_scan)
		to_scan = limit_turfs
	else
		parent_cell_area = null
		to_scan = get_loaded_sublevel_turfs_on_z(z)
		if(!length(to_scan))
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

	// One FFI bounds lookup per component instead of one per tile.
	var/list/size_cache = list()
	var/list/enclosed_cache = list()

	for(var/turf/T as anything in to_scan)
		if(!T || T.z != z)
			continue
		var/list/info = rustg_area_tile_info(T.x, T.y, z)
		if(!info || info["is_boundary"])
			continue
		var/aid = info["area_id"]
		if(!aid)
			continue
		var/aid_key = "[aid]"
		if(isnull(enclosed_cache[aid_key]))
			var/list/bounds = rustg_area_get_area_bounds(aid, z)
			var/size = bounds?["size"] || 0
			size_cache[aid_key] = size
			enclosed_cache[aid_key] = rw_size_is_enclosed(size, open_tiles) ? 1 : 0
		var/enclosed = !!enclosed_cache[aid_key]
		if(enclosed)
			live_zone_ids[aid_key] = TRUE
		var/area/rimworld/parent = full_scan ? resolve_parent_cell_area(T) : (parent_cell_area || resolve_parent_cell_area(T))
		apply_rust_zone_to_turf(T, aid, enclosed, parent, size_cache[aid_key])
		CHECK_TICK

	var/list/scanned = null
	if(!full_scan)
		scanned = list()
		for(var/turf/S as anything in to_scan)
			scanned[S] = TRUE

	for(var/key in GLOB.rimworld_rust_zones)
		if(findtext(key, "[z]_") != 1)
			continue
		var/id_str = copytext(key, length("[z]_") + 1)
		if(live_zone_ids[id_str])
			continue
		if(scanned)
			// Limited resync: only drop zones that live inside the scanned turfs.
			var/area/rimworld/zone/Z = GLOB.rimworld_rust_zones[key]
			var/turf/sample = Z && !QDELETED(Z) ? locate(/turf) in Z : null
			if(sample && !scanned[sample])
				continue
		release_rimworld_zone(z, text2num(id_str))

/**
 * After a batch rebuild Rust may renumber components. Instead of rescanning every tile of the Z,
 * ask Rust ONE question per existing zone (the id at one of its turfs) and re-key the zone.
 * Cost: O(zones), not O(tiles). Zones whose tile became a boundary/void are released.
 */
/proc/rekey_rimworld_zones_on_z(z)
	var/prefix = "[z]_"
	var/list/moves = list() // zone area -> new aid (0 = dead)
	for(var/key in GLOB.rimworld_rust_zones)
		if(findtext(key, prefix) != 1)
			continue
		var/area/rimworld/zone/Z = GLOB.rimworld_rust_zones[key]
		if(!Z || QDELETED(Z))
			continue
		var/turf/sample = locate(/turf) in Z
		var/new_aid = 0
		if(sample && sample.z == z)
			var/list/info = rustg_area_tile_info(sample.x, sample.y, z)
			if(info && !info["is_boundary"])
				new_aid = info["area_id"] || 0
		if(new_aid != Z.rust_area_id)
			moves[Z] = new_aid
	if(!length(moves))
		return
	// Two phases so zones that swap ids do not overwrite each other.
	for(var/area/rimworld/zone/Z as anything in moves)
		GLOB.rimworld_rust_zones -= rimworld_zone_key(z, Z.rust_area_id)
	for(var/area/rimworld/zone/Z as anything in moves)
		var/new_aid = moves[Z]
		if(!new_aid || GLOB.rimworld_rust_zones[rimworld_zone_key(z, new_aid)])
			qdel(Z)
			continue
		Z.rust_area_id = new_aid
		GLOB.rimworld_rust_zones[rimworld_zone_key(z, new_aid)] = Z

/turf
	/// Base beauty of the floor itself (set on floor types: carpet +, dirt -, ...)
	var/rw_beauty = 0
	/// Base cleanliness of the floor (dirt/sand floors are naturally a bit dirty).
	var/rw_cleanliness = 0

/obj
	/// Beauty this object adds to its tile (furniture, art > 0; trash, corpses < 0).
	var/rw_beauty = 0
	/// Filth amount this object adds (cleanable decals). Lowers cleanliness AND beauty.
	var/rw_filth = 0
	/// What this object contributes to room-role detection: list(RW_TAG_BED = 1)
	var/list/rw_room_tags
	/// Heat power in watts. > 0 heater, < 0 cooler.
	var/rw_heat_output = 0
	/// Thermostat (Celsius). Heaters stop above it, coolers stop below it. null = always on.
	var/rw_heat_target = null

/obj/effect/decal/cleanable
	rw_filth = 1
	rw_beauty = -1.5

/// Override in subtypes when the object is broken / unpowered / out of fuel.
/obj/proc/rw_heater_active()
	return TRUE

/// Beauty of anything standing on a tile.
/atom/movable/proc/rw_get_beauty()
	return 0

/obj/rw_get_beauty()
	return rw_beauty

/mob/living/rw_get_beauty()
	// Corpses make a room uglier.
	return stat == DEAD ? -4 : 0

/atom/movable/proc/rw_get_filth()
	return 0

/obj/rw_get_filth()
	return rw_filth

/turf/proc/rw_tile_beauty()
	var/value = rw_beauty
	for(var/atom/movable/AM as anything in contents)
		value += AM.rw_get_beauty()
	return value

/turf/proc/rw_tile_cleanliness()
	var/value = rw_cleanliness
	for(var/atom/movable/AM as anything in contents)
		value -= AM.rw_get_filth()
	return value

/**
 * Average beauty of the surroundings, for pawns that are outdoors (no zone).
 * Cheap enough to call from the psychology tick (radius 4 = 81 turfs).
 */
/turf/proc/rw_local_beauty(radius = 4)
	var/total = 0
	var/count = 0
	for(var/turf/T as anything in RANGE_TURFS(radius, src))
		total += T.rw_tile_beauty()
		count++
	return count ? total / count : 0


/obj/proc/rw_collect_room_tags(list/counts)
	var/list/tags = rw_room_tags
	if(!tags)
		for(var/path in GLOB.rw_room_tag_by_type)
			if(istype(src, path))
				tags = GLOB.rw_room_tag_by_type[path]
				break
	for(var/tag in tags)
		counts[tag] += tags[tag]


/area/rimworld/zone/proc/rw_recalculate_stats()
	rw_stats_dirty = FALSE
	rw_last_stats_time = world.time
	rw_next_stats_time = world.time + RW_ZONE_STATS_MIN_DELAY

	var/size = 0
	var/beauty_sum = 0
	var/clean_sum = 0
	var/list/tags = list()
	var/list/thermals = list()
	var/walls = 0
	var/doors_closed = 0
	var/doors_open = 0
	var/gaps = 0

	// IMPORTANT: area.contents holds ALL atoms. Never use `as anything` here —
	// that would treat objs/mobs as turfs and explode on missing turf vars.
	for(var/turf/T in src)
		size++
		beauty_sum += T.rw_beauty
		clean_sum += T.rw_cleanliness
		for(var/atom/movable/AM as anything in T)
			beauty_sum += AM.rw_get_beauty()
			clean_sum -= AM.rw_get_filth()
			if(isobj(AM))
				var/obj/O = AM
				O.rw_collect_room_tags(tags)
				if(O.rw_heat_output)
					thermals += O
		// Border analysis: look at every cardinal neighbour that is not ours.
		for(var/dir in GLOB.cardinals)
			var/turf/N = get_step(T, dir)
			if(!N || N.loc == src)
				continue
			var/obj/machinery/door/D = locate() in N
			if(D)
				if(D.density)
					doors_closed++
				else
					doors_open++
			else if(N.density)
				walls++
			else
				gaps++

	rw_size = size
	rw_border_walls = walls
	rw_doors_closed = doors_closed
	rw_doors_open = doors_open
	rw_gaps = gaps
	rw_tag_counts = tags
	rw_thermal_objects = thermals

	if(size)
		rw_room_beauty = beauty_sum / size
		rw_room_cleanliness = clean_sum / size
	else
		rw_room_beauty = 0
		rw_room_cleanliness = 0

	// Impressiveness: space + beauty - dirt (RimWorld uses a similar blend).
	var/space_term = clamp(size * 1.2, 0, 40)
	rw_impressiveness = max(0, 10 + space_term + rw_room_beauty * 10 + rw_room_cleanliness * 6)

	var/leak_edges = doors_closed + doors_open + gaps
	rw_openness = clamp((doors_open * 0.5 + gaps) / max(1, leak_edges + walls * 0.1), 0, 1)

	rw_detect_role()

/// Called by the environment subsystem. Returns TRUE if it did real work.
/area/rimworld/zone/proc/rw_tick_stats()
	if(!length(contents))
		return FALSE
	var/due = rw_stats_dirty ? (world.time >= rw_next_stats_time) : (world.time >= rw_last_stats_time + RW_ZONE_STATS_PERIOD)
	if(!due)
		return FALSE
	rw_recalculate_stats()
	return TRUE


/area/proc/rw_get_beauty_label()
	return rw_label_for(rw_get_beauty(), GLOB.rw_beauty_labels)

/area/rimworld/zone/rw_get_beauty_label()
	return rw_label_for(rw_get_beauty(), GLOB.rw_beauty_labels)

/area/rimworld/zone/proc/rw_get_clean_label()
	return rw_label_for(rw_room_cleanliness, GLOB.rw_clean_labels)

/area/rimworld/zone/proc/rw_get_impressive_label()
	return rw_label_for(rw_impressiveness, GLOB.rw_impressive_labels)

/area/rimworld/zone/proc/rw_get_temp_label()
	return rw_label_for(rw_temperature, GLOB.rw_temp_labels)

/// Short role + id name shown on maps.
/area/rimworld/zone/proc/rw_refresh_name()
	var/shown = rw_role ? rw_role.name : initial(name)
	name = "[shown] ([rust_area_id])"


/area/rimworld/zone/proc/rw_get_info_lines(mob/living/viewer)
	var/list/lines = list()
	if(rw_stats_dirty || !rw_last_stats_time)
		rw_recalculate_stats()
	lines += span_notice("<b>Zone:</b> [rw_role ? rw_role.name : "Room"] - [rw_size] tiles, [rw_get_impressive_label()].")
	lines += span_notice("Beauty: <b>[round(rw_room_beauty, 0.1)]</b> ([rw_get_beauty_label()]), cleanliness: <b>[round(rw_room_cleanliness, 0.1)]</b> ([rw_get_clean_label()]).")
	var/temp_line = "Temperature: <b>[round(rw_get_temperature(), 0.1)]&deg;C</b> ([rw_get_temp_label()])"
	if(istype(viewer, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = viewer
		var/list/range = H.get_rw_comfort_range()
		if(range)
			var/t = rw_get_temperature()
			if(t < range["min"])
				temp_line += " - <b>too cold</b> for your clothing (comfy from [round(range["min"])]&deg;C)"
			else if(t > range["max"])
				temp_line += " - <b>too hot</b> for your clothing (comfy up to [round(range["max"])]&deg;C)"
			else
				temp_line += " - comfortable for you"
	lines += span_notice("[temp_line].")
	lines += span_notice("Openings: [rw_doors_closed] closed door\s, [rw_doors_open] open door\s, [rw_gaps] gap\s.")
	return lines
