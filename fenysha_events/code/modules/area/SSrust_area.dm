/**
 * Subsystem that keeps the Rust area grid in sync with the live map.
 *
 * During bulk mapgen set zone_sync_enabled = FALSE (or use begin_batch)
 * so we never run full component zone assignment mid-stamp.
 */
SUBSYSTEM_DEF(area_rust)
	name = "Area Rust"
	ss_flags = SS_NO_FIRE || SS_NO_INIT
	init_stage = INITSTAGE_MAX
	wait = 0

	/// z → TRUE once that Z has been initialised in Rust
	var/list/initialised_z = list()

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
	// Rust preserves an existing grid and grows it when a later cell needs more space.
	if(initialised_z["[z]"])
		if(!rustg_area_init_z(z, width, height))
			stack_trace("SSarea_rust.ensure_z failed to resize z=[z] ([width]x[height])")
			return FALSE
		return TRUE
	if(!rustg_area_init_z(z, width, height))
		stack_trace("SSarea_rust.ensure_z failed z=[z] ([width]x[height])")
		return FALSE
	initialised_z["[z]"] = TRUE
	return TRUE

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
	if(SSarea_rust?.initialised_z["[new_turf.z]"] && !SSarea_rust.batch_mode)
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
	var/turf/T = loc
	. = ..()
	if(isturf(T) && SSarea_rust?.initialised_z["[T.z]"])
		SSarea_rust.update_turf(T)
