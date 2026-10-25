/**
 * Subsystem that keeps the Rust area grid in sync with the live map.
 *
 * During bulk mapgen set zone_sync_enabled = FALSE (or use begin_batch)
 * so we never run full component zone assignment mid-stamp.
 */
SUBSYSTEM_DEF(area_rust)
	name = "Area Rust"
	ss_flags = SS_NO_FIRE | SS_NO_INIT
	init_stage = INITSTAGE_MAX
	wait = 0

	/// z → TRUE once that Z has been initialised in Rust
	var/list/initialised_z = list()

	/// z → list(width, height) of the grid currently allocated in Rust
	var/list/grid_size = list()

	/// key → list(z, min_x, min_y, max_x, max_y) of sub-levels that are being loaded right now.
	/// Hooks never push per-turf updates inside these; setup_rust_zones() sends the whole cell once.
	var/list/loading_regions = list()

	/// Pending batch of tile updates keyed by z (used only during init)
	var/list/pending_batches = list()

	/// If TRUE, individual set_tile calls are deferred into pending_batches
	var/batch_mode = FALSE

	/// When FALSE, update_turf still pushes to Rust but never runs sync_zone_for_turf.
	/// Use during cell load / mass ChangeTurf.
	var/zone_sync_enabled = TRUE

	/// z → open_tiles count, short-lived cache for hot-path enclose checks
	var/list/open_tiles_cache


/**
 * Ensure a Z grid exists in Rust. Safe to call multiple times.
 */
/datum/controller/subsystem/area_rust/proc/ensure_z(z, width, height)
	var/key = "[z]"
	var/list/size = grid_size[key]
	// Never shrink: other sub-levels on this Z still live inside the existing grid.
	if(size)
		if(width <= size[1] && height <= size[2])
			return TRUE
		width = max(width, size[1])
		height = max(height, size[2])
	// Rust preserves an existing grid and grows it when a later cell needs more space.
	if(!rustg_area_init_z(z, width, height))
		stack_trace("SSarea_rust.ensure_z failed z=[z] ([width]x[height])")
		return FALSE
	grid_size[key] = list(width, height)
	initialised_z[key] = TRUE
	return TRUE

/datum/controller/subsystem/area_rust/proc/begin_region_load(key, z, min_x, min_y, max_x, max_y)
	loading_regions[key] = list(z, min_x, min_y, max_x, max_y)

/datum/controller/subsystem/area_rust/proc/end_region_load(key)
	loading_regions -= key

/// TRUE if T lies inside a sub-level that is still loading.
/datum/controller/subsystem/area_rust/proc/turf_in_loading_region(turf/T)
	if(!length(loading_regions))
		return FALSE
	for(var/key in loading_regions)
		var/list/r = loading_regions[key]
		if(T.z == r[1] && T.x >= r[2] && T.x <= r[4] && T.y >= r[3] && T.y <= r[5])
			return TRUE
	return FALSE

/// TRUE if T lies inside the grid Rust currently has for its Z.
/datum/controller/subsystem/area_rust/proc/turf_in_grid(turf/T)
	var/list/size = grid_size["[T.z]"]
	return !!size && T.x <= size[1] && T.y <= size[2]

/**
 * Walk turfs and push one batch update (no zone assignment).
 */
/datum/controller/subsystem/area_rust/proc/build_snapshot_from_turfs(z, list/turfs)
	if(!z || !length(turfs))
		return FALSE
	var/list/tiles = list()
	for(var/turf/T as anything in turfs)
		if(!T || T.z != z)
			continue
		var/list/state = get_turf_area_state(T)
		if(!state)
			continue
		tiles += list(list(
			"x" = T.x,
			"y" = T.y,
			"is_boundary" = state["is_boundary"],
			"opaque" = state["opaque"],
			"dense" = state["dense"],
			"kind" = state["kind"],
			"type_path" = state["type_path"],
		))
	if(!length(tiles))
		return FALSE
	return rustg_area_set_tiles_batch(z, tiles)

/**
 * Public entry point used by hooks.
 */
/datum/controller/subsystem/area_rust/proc/update_turf(turf/T)
	if(!T || !initialised_z["[T.z]"])
		return

	if(!batch_mode)
		if(turf_in_loading_region(T))
			return
		var/area/rimworld/loading_area = T.loc
		if(istype(loading_area) && loading_area.cell_loading)
			return
		if(!turf_in_grid(T))
			return

	var/list/state = get_turf_area_state(T)
	if(!state)
		return

	if(batch_mode)
		var/list/batch = pending_batches["[T.z]"]
		if(!batch)
			batch = list()
			pending_batches["[T.z]"] = batch
		batch += list(list(
			"x" = T.x,
			"y" = T.y,
			"is_boundary" = state["is_boundary"],
			"opaque" = state["opaque"],
			"dense" = state["dense"],
			"kind" = state["kind"],
			"type_path" = state["type_path"],
		))
		return

	var/old_boundary = null
	if(open_tiles_cache)
		var/list/old_state = rustg_area_tile_info(T.x, T.y, T.z)
		if(old_state)
			old_boundary = !!old_state["is_boundary"]

	var/updated_area_id = rustg_area_set_tile(
		T.x, T.y, T.z,
		state["is_boundary"],
		state["opaque"],
		state["dense"],
		state["kind"],
		state["type_path"],
	)
	if(isnull(updated_area_id))
		return

	if(!isnull(old_boundary) && old_boundary != !!state["is_boundary"] && open_tiles_cache)
		open_tiles_cache -= "[T.z]"

	if(zone_sync_enabled && hascall(src, "sync_zone_for_turf"))
		sync_zone_for_turf(T)

/datum/controller/subsystem/area_rust/proc/update_turfs(list/turfs)
	for(var/turf/T in turfs)
		if(initialised_z["[T.z]"])
			update_turf(T)

/datum/controller/subsystem/area_rust/proc/flush_batches()
	for(var/z_str in pending_batches)
		var/z = text2num(z_str)
		var/list/tiles = pending_batches[z_str]
		if(length(tiles))
			rustg_area_set_tiles_batch(z, tiles)
			if(open_tiles_cache)
				open_tiles_cache -= z_str
	pending_batches.Cut()
	batch_mode = FALSE

/datum/controller/subsystem/area_rust/proc/begin_batch()
	batch_mode = TRUE

/datum/controller/subsystem/area_rust/proc/get_area_id(turf/T)
	if(!T || !initialised_z["[T.z]"])
		return null
	return rustg_area_get_area_id(T.x, T.y, T.z)

/datum/controller/subsystem/area_rust/proc/get_area_tiles(area_id, z)
	return rustg_area_get_area_tiles(area_id, z)

/datum/controller/subsystem/area_rust/proc/get_area_bounds(area_id, z)
	return rustg_area_get_area_bounds(area_id, z)

/datum/controller/subsystem/area_rust/proc/area_exists(area_id, z)
	return rustg_area_area_exists(area_id, z)

/datum/controller/subsystem/area_rust/proc/get_neighbors(area_id, z)
	return rustg_area_get_neighbors(area_id, z)

/datum/controller/subsystem/area_rust/proc/tile_info(turf/T)
	if(!T || !initialised_z["[T.z]"])
		return null
	return rustg_area_tile_info(T.x, T.y, T.z)

/datum/controller/subsystem/area_rust/proc/resync_turf_after_change(turf/T)
	if(!T || !initialised_z["[T.z]"])
		return
	if(turf_in_loading_region(T))
		return
	update_turf(T)
	var/list/dm_state = get_turf_area_state(T)
	var/list/rust_state = rustg_area_tile_info(T.x, T.y, T.z)
	if(!dm_state || !rust_state)
		return
	if(istype(T, /turf/open) && dm_state["is_boundary"])
		var/list/boundary_contents = list()
		for(var/atom/movable/AM in T)
			if(AM.area_grid_flags & AREA_GRID_BOUNDARY)
				boundary_contents += "[AM.type]"
		stack_trace("SSarea_rust open turf still has a DM boundary at ([T.x],[T.y],[T.z]): turf=[T.type] flags=[T.area_grid_flags] marked_contents=[jointext(boundary_contents, ", ")]. This boundary comes from current contents/type, not the turf flag alone.")
	if(!!dm_state["is_boundary"] != !!rust_state["is_boundary"] || !!dm_state["opaque"] != !!rust_state["opaque"] || !!dm_state["dense"] != !!rust_state["dense"])
		stack_trace("SSarea_rust state mismatch at ([T.x],[T.y],[T.z]): DM boundary=[dm_state["is_boundary"]] opaque=[dm_state["opaque"]] dense=[dm_state["dense"]]; Rust boundary=[rust_state["is_boundary"]] opaque=[rust_state["opaque"]] dense=[rust_state["dense"]]; turf=[T.type] flags=[T.area_grid_flags] kind=[dm_state["kind"]]. Check the loaded RUST_UTILS library and whether this coordinate is being overwritten by a stale batch.")

//MARK: Hooks
/**
 * Hooks that keep the Rust area grid up to date.
 */

/atom
	var/area_grid_flags = NONE

// Explicit flags for room-edge objects. Closed turfs are also detected by type.
/obj/machinery/door
	area_grid_flags = AREA_GRID_BOUNDARY

/obj/structure/window
	area_grid_flags = AREA_GRID_BOUNDARY


/turf/ChangeTurf(path, list/new_baseturfs, flags)
	var/old_type = type
	. = ..()
	var/turf/new_turf = .
	if(!new_turf || old_type == new_turf.type || !ispath(old_type, /turf/closed) || !istype(new_turf, /turf/open))
		return new_turf
	if(SSarea_rust?.initialised_z["[new_turf.z]"] && !SSarea_rust.batch_mode && !SSarea_rust.turf_in_loading_region(new_turf))
		// ChangeTurf restores/recalculates parts of turf state after AfterChange.
		// Re-read the final live turf one tick later, including deferred changes.
		addtimer(CALLBACK(SSarea_rust, TYPE_PROC_REF(/datum/controller/subsystem/area_rust, resync_turf_after_change), new_turf), 1)
	return new_turf

/turf/AfterChange(flags, oldType)
	. = ..()
	// Open turf type is authoritative. Never carry a room-boundary flag from
	// a replaced wall into a normal open turf.
	if(istype(src, /turf/open) && !istype(src, /turf/cordon/absolute))
		area_grid_flags &= ~AREA_GRID_BOUNDARY
	if(SSarea_rust?.initialised_z["[z]"])
		SSarea_rust.update_turf(src)

/turf/set_density(new_value)
	var/old = density
	. = ..()
	if(old != density && SSarea_rust?.initialised_z["[z]"])
		SSarea_rust.update_turf(src)

/atom/movable/set_density(new_value)
	var/old = density
	. = ..()
	if(old == density)
		return
	var/turf/T = loc
	if(isturf(T) && SSarea_rust?.initialised_z["[T.z]"])
		SSarea_rust.update_turf(T)

/atom/set_opacity(new_opacity)
	var/old = opacity
	. = ..()
	if(old == opacity)
		return
	var/turf/T = get_turf(src)
	if(T && SSarea_rust?.initialised_z["[T.z]"])
		SSarea_rust.update_turf(T)

/atom/proc/set_area_grid_boundary(enabled)
	if(enabled)
		area_grid_flags |= AREA_GRID_BOUNDARY
	else
		area_grid_flags &= ~AREA_GRID_BOUNDARY
	var/turf/T = get_turf(src)
	if(T && SSarea_rust?.initialised_z["[T.z]"])
		SSarea_rust.update_turf(T)

/obj/machinery/door/open(forced = DEFAULT_DOOR_CHECKS)
	. = ..()
	if(.)
		var/turf/T = loc
		if(isturf(T) && SSarea_rust?.initialised_z["[T.z]"])
			SSarea_rust.update_turf(T)

/obj/machinery/door/close(forced = DEFAULT_DOOR_CHECKS)
	. = ..()
	if(.)
		var/turf/T = loc
		if(isturf(T) && SSarea_rust?.initialised_z["[T.z]"])
			SSarea_rust.update_turf(T)

/turf/Destroy(force)
	var/saved_x = x
	var/saved_y = y
	var/saved_z = z
	var/was_tracked = SSarea_rust?.initialised_z["[saved_z]"]
	. = ..()
	if(was_tracked)
		var/turf/replacement = locate(saved_x, saved_y, saved_z)
		if(replacement)
			SSarea_rust.update_turf(replacement)

/obj/machinery/door/Destroy(force)
	var/list/turfs = locs.Copy()
	. = ..()
	SSarea_rust?.update_turfs(turfs)

// light_blocking keeps opacity_sources current for every opaque movable that spawns, moves or is deleted
/turf/add_opacity_source(atom/movable/new_source)
	. = ..()
	if(SSarea_rust?.initialised_z["[z]"])
		SSarea_rust.update_turf(src)

/turf/remove_opacity_source(atom/movable/old_source)
	. = ..()
	if(SSarea_rust?.initialised_z["[z]"])
		SSarea_rust.update_turf(src)

// Mapped and cell-loaded room edges arrive with the batch snapshot; these cover the ones built later
/obj/machinery/door/Initialize(mapload)
	. = ..()
	if(!mapload)
		SSarea_rust?.update_turfs(locs)

/obj/structure/window/Initialize(mapload, direct)
	. = ..()
	if(!mapload)
		SSarea_rust?.update_turfs(locs)

/obj/structure/window/Moved(atom/old_loc, movement_dir, forced, list/old_locs, momentum_change = TRUE)
	. = ..()
	SSarea_rust?.update_turfs(old_locs || list(old_loc))
	SSarea_rust?.update_turfs(locs)

// The parent clears density while the window is still on its tile, so re-read once it has left
/obj/structure/window/Destroy()
	var/list/turfs = locs.Copy()
	. = ..()
	SSarea_rust?.update_turfs(turfs)
