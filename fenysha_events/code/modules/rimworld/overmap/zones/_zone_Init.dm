/**
 * Call after turfs are stamped and bind_areas_to_cell() has run.
 * One batch to Rust + one zone resync. No per-turf zone work during the push.
 */
/datum/planet_cell/proc/setup_rust_zones()
	if(!is_loaded())
		return FALSE

	var/list/turfs = get_local_turfs()
	if(!length(turfs))
		return FALSE

	var/min_x = INFINITY
	var/min_y = INFINITY
	var/max_x = 0
	var/max_y = 0
	var/z = 0
	for(var/turf/T as anything in turfs)
		if(T.x < min_x)
			min_x = T.x
		if(T.y < min_y)
			min_y = T.y
		if(T.x > max_x)
			max_x = T.x
		if(T.y > max_y)
			max_y = T.y
		z = T.z

	if(!z)
		return FALSE

	// World coords are 1-based: grid width/height must cover the highest x/y.
	var/width = max_x
	var/height = max_y

	// Batch uploads rebuild area components, so any existing zone map on this Z
	// must be resynced after the batch, even if the dimensions stay unchanged.
	var/list/old_stats = SSarea_rust.initialised_z["[z]"] ? rustg_area_get_stats(z) : null
	var/full_zone_resync = !!old_stats

	// Freeze zone assignment for the whole load path (hooks may still fire).
	var/was_sync = SSarea_rust.zone_sync_enabled
	SSarea_rust.zone_sync_enabled = FALSE

	if(!SSarea_rust.ensure_z(z, width, height))
		SSarea_rust.zone_sync_enabled = was_sync
		return FALSE

	// Single batch snapshot — no sync_zone_for_turf
	SSarea_rust.begin_batch()
	for(var/turf/T as anything in turfs)
		SSarea_rust.update_turf(T)
	SSarea_rust.flush_batches()

	var/area/rimworld/parent = null
	for(var/turf/T as anything in turfs)
		if(istype(T.loc, /area/rimworld) && !istype(T.loc, /area/rimworld/zone))
			parent = T.loc
			break

	// A batch rebuild can change component IDs outside this cell, so resync the
	// whole Z-level whenever it already had a Rust grid before this load.
	if(full_zone_resync)
		if(SSarea_rust.open_tiles_cache)
			SSarea_rust.open_tiles_cache -= "[z]"
		resync_rimworld_zones_on_z(z, parent)
	else
		resync_rimworld_zones_on_z(z, parent, turfs)

	SSarea_rust.zone_sync_enabled = was_sync
	return TRUE

/**
 * When the cell unloads, drop zone areas that belonged only to this Z.
 */
/datum/planet_cell/proc/teardown_rust_zones()
	if(!reservation)
		return
	var/turf/sample = get_bottom_left_turf()
	if(!sample)
		return
	var/z = sample.z
	for(var/key in GLOB.rimworld_rust_zones)
		if(findtext(key, "[z]_") != 1)
			continue
		var/id_str = copytext(key, length("[z]_") + 1)
		release_rimworld_zone(z, text2num(id_str))
