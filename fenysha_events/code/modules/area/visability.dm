/mob/proc/rust_sight_flags()
	return rust_effective_sight_flags(src, RUST_SEE_DEFAULT)

/// Apply viewer-specific visibility rules shared by single and bulk queries.
/// Ghosts do not use the normal wall-shadow chain; absolute cordons are still
/// enforced separately by the Rust LOS check and can never be seen through.
/proc/rust_effective_sight_flags(atom/source, flags)
	if(ismob(source))
		var/mob/viewer = source
		if(isobserver(viewer) || HAS_TRAIT(viewer, TRAIT_MESON_VISION) || HAS_TRAIT(viewer, TRAIT_XRAY_VISION))
			flags |= RUST_SEE_THRU
	return flags

/proc/rust_target_allowed(atom/target, flags)
	if(isturf(target))
		return flags & RUST_SEE_TURFS
	if(isliving(target))
		return flags & RUST_SEE_MOBS
	return flags & RUST_SEE_OBJS

/**
 * Same Rust room. null if grid missing.
 */
/proc/rust_same_room(turf/A, turf/B)
	if(!A || !B || A.z != B.z)
		return FALSE
	if(!SSarea_rust?.initialised_z["[A.z]"])
		return null
	return rustg_area_same_room(A.x, A.y, A.z, B.x, B.y, B.z)

/**
 * Structural can-see. Heavy work is in Rust (one FFI call).
 */
/proc/rust_dm_can_see(atom/source, atom/target, flags = RUST_SEE_DEFAULT)
	var/turf/user_turf = get_turf(source)
	var/turf/target_turf = get_turf(target)
	if(!user_turf || !target_turf || user_turf.z != target_turf.z)
		return FALSE
	if(user_turf == target_turf)
		return TRUE

	var/list/line = get_line(user_turf, target_turf)
	// Absolute cordons are a hard barrier for every viewer, including ghosts
	// and callers that set RUST_SEE_THRU.
	for(var/turf/T as anything in line)
		if(T == user_turf)
			continue
		if(istype(T, /turf/cordon/absolute))
			return FALSE
	if(flags & RUST_SEE_THRU)
		return TRUE

	// Mirrors the Rust check: sight is blocked by solid turfs and by opaque things only.
	// Dense-but-transparent objects (trees, bushes, crates, furniture) must NOT block vision,
	// so CanPass() is deliberately not used here.
	for(var/turf/next_step as anything in line)
		if(next_step == user_turf || next_step == target_turf)
			continue
		var/list/state = get_turf_area_state(next_step)
		if(state && (state["opaque"] || (state["dense"] && state["is_boundary"])))
			return FALSE
	return TRUE

/proc/rust_can_see(atom/source, atom/target, flags = RUST_SEE_DEFAULT, max_dist = 0)
	if(!source || !target)
		return FALSE
	flags = rust_effective_sight_flags(source, flags)
	if(!rust_target_allowed(target, flags))
		return FALSE

	var/turf/start = get_turf(source)
	var/turf/end = get_turf(target)
	if(!start || !end)
		return FALSE
	if(start == end)
		return TRUE
	if(start.z != end.z)
		return FALSE
	if(max_dist > 0 && get_dist(source, target) > max_dist)
		return FALSE

	if(!SSarea_rust?.initialised_z["[start.z]"])
		return rust_dm_can_see(source, target, flags)

	var/see_thru = !!(flags & RUST_SEE_THRU)
	var/result = rustg_area_can_see(start.x, start.y, start.z, end.x, end.y, end.z, see_thru, max_dist)
	if(isnull(result))
		return FALSE
	return result

/mob/proc/can_see_zone(atom/target, max_dist = 0)
	if(!max_dist)
		if(client)
			var/list/vs = getviewsize(client.view)
			max_dist = max(vs[1], vs[2])
		else
			max_dist = world.view
	return rust_can_see(src, target, rust_sight_flags(), max_dist)

/**
 * Bulk check from origin turf against a list of atoms/turfs.
 * Returns list of TRUE/FALSE aligned with targets.
 */
/proc/rust_can_see_many(atom/origin, list/targets, flags = RUST_SEE_DEFAULT, max_dist = 0)
	flags = rust_effective_sight_flags(origin, flags)
	var/turf/start = get_turf(origin)
	if(!start || !length(targets))
		return list()
	if(!SSarea_rust?.initialised_z["[start.z]"])
		var/list/fallback = list()
		for(var/atom/A in targets)
			fallback += rust_can_see(origin, A, flags, max_dist)
		return fallback

	var/see_thru = !!(flags & RUST_SEE_THRU)
	var/list/coords = list()
	var/list/allowed = list()
	for(var/atom/A in targets)
		if(!rust_target_allowed(A, flags))
			coords += list(list(start.x, start.y)) // dummy; will mark disallowed below
			allowed += FALSE
			continue
		var/turf/T = get_turf(A)
		if(!T || T.z != start.z)
			coords += list(list(start.x, start.y))
			allowed += FALSE
			continue
		coords += list(list(T.x, T.y))
		allowed += TRUE

	var/list/raw = rustg_area_can_see_many(start.x, start.y, start.z, coords, see_thru, max_dist)
	var/list/out = list()
	var/i = 0
	for(var/ok in allowed)
		i++
		if(!ok)
			out += FALSE
			continue
		var/bit = raw ? raw[i] : 0
		out += !!bit
	return out

/**
 * All turfs in the same Rust room (one JSON pull — already bulk on Rust side).
 */
/proc/rust_room_turfs(turf/origin)
	if(!origin || !SSarea_rust?.initialised_z["[origin.z]"])
		return list()
	var/aid = rustg_area_get_area_id(origin.x, origin.y, origin.z)
	if(!aid)
		return list()
	var/list/coords = rustg_area_get_area_tiles(aid, origin.z)
	if(!coords)
		return list()
	var/list/out = list()
	var/z = origin.z
	for(var/entry in coords)
		var/tx
		var/ty
		if(islist(entry))
			var/list/xy = entry
			tx = xy[1]
			ty = length(xy) >= 2 ? xy[2] : null
			if(isnull(tx))
				tx = xy["x"]
				ty = xy["y"]
		if(isnull(tx) || isnull(ty))
			continue
		var/turf/T = locate(tx, ty, z)
		if(T)
			out += T
	return out

