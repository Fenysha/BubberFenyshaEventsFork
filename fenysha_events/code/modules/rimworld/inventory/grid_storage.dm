/datum/storage/grid
	/// Ignore classic slot limits — geometry + weight/volume govern capacity
	max_slots = INFINITY
	max_specific_storage = WEIGHT_CLASS_GIGANTIC
	max_total_storage = INFINITY

	/// Width of the grid in cells
	var/grid_width = 10
	/// Height of the grid in cells
	var/grid_height = 10

	/// 2D occupancy map: grid_occupancy[y][x] = obj/item or null (1-indexed)
	var/list/list/grid_occupancy

	/// item -> list(x, y, rotation)
	var/list/item_positions

	/// mob -> weakref to open panel
	var/list/datum/weakref/open_panels

	/// Where the panel puts its 16×16 buttons (see GRID_TOOLBAR_* defines)
	var/toolbar_mode = GRID_TOOLBAR_RIGHT

	/// Pending specific placement: list(x, y, rot). Set before attempt_insert, cleared at start of it.
	var/list/pending_placement

/datum/storage/grid/New(atom/parent, max_slots, max_specific_storage, max_total_storage, rustle_sound, remove_rustle_sound)
	// Pass our type defaults (subtypes override via var defaults, not New args)
	. = ..(parent, src.max_slots, src.max_specific_storage, src.max_total_storage, rustle_sound, remove_rustle_sound)
	init_grid()
	register_contents_hooks()

/datum/storage/grid/Destroy()
	// Close all open panels first
	for(var/mob/M as anything in LAZYCOPY(is_using))
		hide_contents(M)

	// Clear occupancy while structures still exist (parent Destroy may call remove_all)
	if(item_positions)
		for(var/obj/item/I as anything in item_positions.Copy())
			clear_occupied(I)

	unregister_contents_hooks()

	. = ..()

	grid_occupancy = null
	item_positions = null
	open_panels = null
	pending_placement = null

/datum/storage/grid/proc/init_grid()
	grid_occupancy = new /list(grid_height)
	for(var/y in 1 to grid_height)
		grid_occupancy[y] = new /list(grid_width)
	item_positions = list()


/datum/storage/grid/proc/register_contents_hooks()
	if(!real_location)
		return
	RegisterSignal(real_location, COMSIG_ATOM_ENTERED, PROC_REF(on_atom_entered))
	RegisterSignal(real_location, COMSIG_ATOM_EXITED, PROC_REF(on_atom_exited))

/datum/storage/grid/proc/unregister_contents_hooks()
	if(!real_location)
		return
	UnregisterSignal(real_location, list(COMSIG_ATOM_ENTERED, COMSIG_ATOM_EXITED))

/datum/storage/grid/proc/on_atom_entered(datum/source, atom/movable/arrived, atom/old_loc, list/atom/old_locs)
	SIGNAL_HANDLER
	if(!isitem(arrived))
		return
	var/obj/item/I = arrived
	if(item_positions[I])
		return
	// Item appeared outside our insert path — place it or eject
	var/list/best = find_best_position(I)
	if(best)
		I.grid_rotation = best[3]
		mark_occupied(I, best[1], best[2], best[3])
		refresh_views()
	else
		// No space — eject to drop location
		I.forceMove(parent ? parent.drop_location() : get_turf(parent))

/datum/storage/grid/proc/on_atom_exited(datum/source, atom/movable/gone, direction)
	SIGNAL_HANDLER
	if(!isitem(gone))
		return
	var/obj/item/I = gone
	if(item_positions[I])
		clear_occupied(I)
		refresh_views()

/// Returns TRUE if the rectangle at (x,y) with given w/h is free (or only occupied by ignore_item)
/datum/storage/grid/proc/is_rect_free(x, y, w, h, obj/item/ignore_item = null)
	if(x < 1 || y < 1 || x + w - 1 > grid_width || y + h - 1 > grid_height)
		return FALSE
	for(var/cy in y to (y + h - 1))
		for(var/cx in x to (x + w - 1))
			var/obj/item/occupant = grid_occupancy[cy][cx]
			if(occupant && occupant != ignore_item)
				return FALSE
	return TRUE

/// Returns the first item that would be displaced, or null if free / out of bounds
/datum/storage/grid/proc/get_occupying_item(x, y, w, h, obj/item/ignore_item = null)
	if(x < 1 || y < 1 || x + w - 1 > grid_width || y + h - 1 > grid_height)
		return null
	for(var/cy in y to (y + h - 1))
		for(var/cx in x to (x + w - 1))
			var/obj/item/occupant = grid_occupancy[cy][cx]
			if(occupant && occupant != ignore_item)
				return occupant
	return null

/// Collects all unique items that intersect the rectangle
/datum/storage/grid/proc/get_displaced_items(x, y, w, h, obj/item/ignore_item = null)
	. = list()
	if(x < 1 || y < 1 || x + w - 1 > grid_width || y + h - 1 > grid_height)
		return
	for(var/cy in y to (y + h - 1))
		for(var/cx in x to (x + w - 1))
			var/obj/item/occupant = grid_occupancy[cy][cx]
			if(occupant && occupant != ignore_item)
				. |= occupant

/datum/storage/grid/proc/mark_occupied(obj/item/item, x, y, rotation)
	item.grid_rotation = rotation
	var/w = GRID_EFFECTIVE_WIDTH(item)
	var/h = GRID_EFFECTIVE_HEIGHT(item)
	for(var/cy in y to (y + h - 1))
		for(var/cx in x to (x + w - 1))
			grid_occupancy[cy][cx] = item
	item_positions[item] = list(x, y, rotation)

/datum/storage/grid/proc/clear_occupied(obj/item/item)
	var/list/pos = item_positions[item]
	if(!pos)
		return
	var/x = pos[1]
	var/y = pos[2]
	var/rot = pos[3]

	// Use the stored rotation to compute the correct footprint
	var/old_rot = item.grid_rotation
	item.grid_rotation = rot
	var/w = GRID_EFFECTIVE_WIDTH(item)
	var/h = GRID_EFFECTIVE_HEIGHT(item)
	item.grid_rotation = old_rot

	for(var/cy in y to (y + h - 1))
		for(var/cx in x to (x + w - 1))
			if(cy >= 1 && cy <= grid_height && cx >= 1 && cx <= grid_width)
				if(grid_occupancy[cy][cx] == item)
					grid_occupancy[cy][cx] = null
	item_positions -= item


/**
 * Finds the earliest top-left free position for the item at its CURRENT rotation.
 * Returns list(x, y) or null.
 */
/datum/storage/grid/proc/find_free_position(obj/item/item)
	var/w = GRID_EFFECTIVE_WIDTH(item)
	var/h = GRID_EFFECTIVE_HEIGHT(item)
	if(w > grid_width || h > grid_height)
		return null
	for(var/y in 1 to (grid_height - h + 1))
		for(var/x in 1 to (grid_width - w + 1))
			if(is_rect_free(x, y, w, h))
				return list(x, y)
	return null

/**
 * Tries all unique rotations and returns the best placement:
 * list(x, y, rotation) that is highest and then leftmost, or null.
 * Prefers the item's current rotation when scores are equal.
 */
/datum/storage/grid/proc/find_best_position(obj/item/item)
	var/best_x = null
	var/best_y = null
	var/best_rot = null
	var/best_score = null

	var/original_rot = item.grid_rotation
	var/list/rots = item.get_possible_rotations()

	for(var/rot in rots)
		item.grid_rotation = rot
		var/w = GRID_EFFECTIVE_WIDTH(item)
		var/h = GRID_EFFECTIVE_HEIGHT(item)
		if(w > grid_width || h > grid_height)
			continue

		var/found_for_this_rot = FALSE
		for(var/y in 1 to (grid_height - h + 1))
			for(var/x in 1 to (grid_width - w + 1))
				if(!is_rect_free(x, y, w, h))
					continue
				var/score = y * 10000 + x * 10
				if(rot != original_rot)
					score += 1
				if(isnull(best_score) || score < best_score)
					best_score = score
					best_x = x
					best_y = y
					best_rot = rot
				found_for_this_rot = TRUE
				break
			if(found_for_this_rot)
				break

	item.grid_rotation = original_rot
	if(isnull(best_x))
		return null
	return list(best_x, best_y, best_rot)

/**
 * Search for a free position near a preferred origin after a rotation change.
 */
/datum/storage/grid/proc/find_position_near(obj/item/item, prefer_x, prefer_y, radius = 4)
	var/w = GRID_EFFECTIVE_WIDTH(item)
	var/h = GRID_EFFECTIVE_HEIGHT(item)
	if(w > grid_width || h > grid_height)
		return null

	prefer_x = clamp(prefer_x, 1, max(1, grid_width - w + 1))
	prefer_y = clamp(prefer_y, 1, max(1, grid_height - h + 1))

	if(is_rect_free(prefer_x, prefer_y, w, h, item))
		return list(prefer_x, prefer_y)

	for(var/r in 1 to radius)
		for(var/dy in -r to r)
			for(var/dx in -r to r)
				if(abs(dx) != r && abs(dy) != r)
					continue
				var/nx = prefer_x + dx
				var/ny = prefer_y + dy
				if(nx < 1 || ny < 1 || nx + w - 1 > grid_width || ny + h - 1 > grid_height)
					continue
				if(is_rect_free(nx, ny, w, h, item))
					return list(nx, ny)
	return null


/datum/storage/grid/can_insert(obj/item/to_insert, mob/user, messages = TRUE, force = STORAGE_NOT_LOCKED)
	if(!..())
		return FALSE

	// Weight / volume (base storage_weight_volume skips grid to avoid double-check)
	if(max_total_weight > 0)
		if(get_total_weight_kg() + to_insert.weight_kg > max_total_weight)
			if(messages && user)
				to_chat(user, span_warning("[parent] cannot hold more weight."))
			return FALSE

	if(max_total_volume > 0)
		if(get_total_volume() + to_insert.rw_volume > max_total_volume)
			if(messages && user)
				to_chat(user, span_warning("[parent] cannot hold more volume."))
			return FALSE

	// Geometry check always runs (force is about lock state, not space)
	if(isnull(pending_placement))
		var/list/best = find_best_position(to_insert)
		if(!best)
			if(messages && user)
				to_chat(user, span_warning("No free space in [parent]."))
			return FALSE

	return TRUE

/datum/storage/grid/get_total_weight_kg()
	. = 0
	for(var/obj/item/I as anything in item_positions)
		. += I.weight_kg

/datum/storage/grid/get_total_volume()
	. = 0
	for(var/obj/item/I as anything in item_positions)
		. += I.rw_volume

/**
 * Insert at a specific grid position + rotation.
 * Transactional: validates first, displaces at most ONE overlapping item, then inserts.
 */
/datum/storage/grid/proc/attempt_insert_at(obj/item/to_insert, mob/user, x, y, rotation = null, force = STORAGE_NOT_LOCKED, messages = TRUE)
	if(isnull(rotation))
		rotation = to_insert.grid_rotation

	if(item_positions[to_insert])
		return FALSE // already inside

	var/old_rot = to_insert.grid_rotation
	to_insert.grid_rotation = rotation
	var/w = GRID_EFFECTIVE_WIDTH(to_insert)
	var/h = GRID_EFFECTIVE_HEIGHT(to_insert)

	if(x < 1 || y < 1 || x + w - 1 > grid_width || y + h - 1 > grid_height)
		to_insert.grid_rotation = old_rot
		if(messages && user)
			to_chat(user, span_warning("Doesn't fit there."))
		return FALSE

	var/list/to_displace = get_displaced_items(x, y, w, h, to_insert)

	// Only allow swap with exactly one item (two hands max; multi-displace is error-prone)
	if(length(to_displace) > 1)
		to_insert.grid_rotation = old_rot
		if(messages && user)
			to_chat(user, span_warning("Doesn't fit — too many items in the way."))
		return FALSE

	// Weight / volume after displacement
	var/added_weight = to_insert.weight_kg
	var/added_vol = to_insert.rw_volume
	for(var/obj/item/D as anything in to_displace)
		added_weight -= D.weight_kg
		added_vol -= D.rw_volume

	if(max_total_weight > 0 && (get_total_weight_kg() + added_weight) > max_total_weight)
		to_insert.grid_rotation = old_rot
		if(messages && user)
			to_chat(user, span_warning("[parent] cannot hold more weight."))
		return FALSE

	if(max_total_volume > 0 && (get_total_volume() + added_vol) > max_total_volume)
		to_insert.grid_rotation = old_rot
		if(messages && user)
			to_chat(user, span_warning("[parent] cannot hold more volume."))
		return FALSE

	// Pre-validate parent can_insert without geometry (pending set so can_insert skips find)
	pending_placement = list(x, y, rotation)
	if(!can_insert(to_insert, user, messages, force))
		pending_placement = null
		to_insert.grid_rotation = old_rot
		return FALSE

	// Displace the single overlapping item (if any)
	for(var/obj/item/D as anything in to_displace)
		var/atom/drop_loc = user ? null : parent.drop_location()
		if(!attempt_remove(D, drop_loc, silent = TRUE, visual_updates = FALSE))
			D.forceMove(user ? user.drop_location() : parent.drop_location())
		if(user)
			user.put_in_hands(D)

	// Insert via classic path; pending_placement carries coordinates
	var/success = attempt_insert(to_insert, user, override = TRUE, force = force, messages = messages)
	if(!success)
		to_insert.grid_rotation = old_rot
		return FALSE

	return TRUE

/**
 * Classic insert — auto-finds best position unless pending_placement is set.
 */
/datum/storage/grid/attempt_insert(obj/item/to_insert, mob/user, override = FALSE, force = STORAGE_NOT_LOCKED, messages = TRUE)
	if(item_positions[to_insert])
		return FALSE

	var/list/pending = pending_placement
	pending_placement = null // always clear immediately — safe against runtime in ..()

	var/list/best
	if(!pending)
		best = find_best_position(to_insert)
		if(!best)
			if(messages && user)
				to_chat(user, span_warning("No free space in [parent]."))
			return FALSE

	// Parent does the actual move into real_location + signals
	. = ..()
	if(!.)
		return

	if(pending)
		to_insert.grid_rotation = pending[3]
		mark_occupied(to_insert, pending[1], pending[2], pending[3])
	else if(best)
		to_insert.grid_rotation = best[3]
		mark_occupied(to_insert, best[1], best[2], best[3])
	refresh_views()

/datum/storage/grid/attempt_remove(obj/item/thing, atom/remove_to_loc, silent = FALSE, visual_updates = TRUE)
	. = ..()
	if(.)
		clear_occupied(thing)
	if(visual_updates)
		refresh_views()

/datum/storage/grid/remove_all(atom/drop_loc = parent.drop_location(), update_storage = TRUE)
	// Snapshot keys before parent empties real_location
	var/list/items = item_positions ? item_positions.Copy() : list()
	for(var/obj/item/I as anything in items)
		clear_occupied(I)
	. = ..()
	if(update_storage)
		refresh_views()

// ---------------------------------------------------------------------------
// Rotation & auto-sort
// ---------------------------------------------------------------------------

/**
 * Rotate an item already inside the grid.
 * Tries to keep it near its old center; falls back to full search.
 */
/datum/storage/grid/proc/try_rotate_item(obj/item/item, mob/user, degrees = 90)
	if(!item_positions[item])
		return FALSE

	var/list/pos = item_positions[item]
	var/old_x = pos[1]
	var/old_y = pos[2]
	var/old_rot = pos[3]

	var/old_w = ((old_rot % 180) == 0) ? item.grid_width : item.grid_height
	var/old_h = ((old_rot % 180) == 0) ? item.grid_height : item.grid_width
	var/center_x = old_x + (old_w - 1) / 2
	var/center_y = old_y + (old_h - 1) / 2

	clear_occupied(item)

	var/new_rot = (old_rot + degrees) % 360
	if(new_rot < 0)
		new_rot += 360
	item.grid_rotation = new_rot

	var/new_w = GRID_EFFECTIVE_WIDTH(item)
	var/new_h = GRID_EFFECTIVE_HEIGHT(item)

	var/prefer_x = round(center_x - (new_w - 1) / 2)
	var/prefer_y = round(center_y - (new_h - 1) / 2)

	var/list/new_pos = find_position_near(item, prefer_x, prefer_y, radius = max(new_w, new_h) + 2)
	if(new_pos)
		mark_occupied(item, new_pos[1], new_pos[2], new_rot)
		refresh_views()
		return TRUE

	var/list/any_pos = find_free_position(item)
	if(any_pos)
		mark_occupied(item, any_pos[1], any_pos[2], new_rot)
		refresh_views()
		if(user)
			to_chat(user, span_notice("Rotated and moved [item]."))
		return TRUE

	// Fail — restore
	item.grid_rotation = old_rot
	mark_occupied(item, old_x, old_y, old_rot)
	if(user)
		to_chat(user, span_warning("Cannot rotate [item] — not enough space."))
	return FALSE

/**
 * Auto-sort: larger first, each item placed with best available rotation.
 * Snapshots state and rolls back entirely if any item cannot be placed.
 */
/datum/storage/grid/proc/auto_sort(mob/user)
	if(!length(item_positions))
		return

	// Snapshot for rollback
	var/list/snapshot = list()
	for(var/obj/item/I as anything in item_positions)
		var/list/item_position = item_positions[I]
		snapshot[I] = list(item_position[1], item_position[2], item_position[3])

	var/list/items = assoc_to_keys(item_positions)
	for(var/obj/item/I as anything in items)
		clear_occupied(I)

	items = sortTim(items, /proc/cmp_item_grid_area_desc)

	var/failed = 0
	for(var/obj/item/I as anything in items)
		var/list/best = find_best_position(I)
		if(best)
			I.grid_rotation = best[3]
			mark_occupied(I, best[1], best[2], best[3])
		else
			failed++

	if(failed)
		// Full rollback
		for(var/obj/item/I as anything in item_positions.Copy())
			clear_occupied(I)
		for(var/obj/item/I as anything in snapshot)
			var/list/pos = snapshot[I]
			I.grid_rotation = pos[3]
			mark_occupied(I, pos[1], pos[2], pos[3])
		if(user)
			to_chat(user, span_warning("Could not sort — not enough contiguous space."))
	else if(user)
		to_chat(user, span_notice("Storage sorted."))

	refresh_views()

/proc/cmp_item_grid_area_desc(obj/item/a, obj/item/b)
	var/area_a = a.grid_width * a.grid_height
	var/area_b = b.grid_width * b.grid_height
	if(area_a != area_b)
		return area_b - area_a
	return max(b.grid_width, b.grid_height) - max(a.grid_width, a.grid_height)


/datum/storage/grid/show_contents(mob/to_show)
	if(!to_show?.client)
		return FALSE
	if(!to_show.hud_used)
		return FALSE

	if(!IS_UNCONSCIOUS_OR_CRIT(to_show))
		if(to_show.active_storage != src)
			for(var/obj/item/thing in real_location)
				if(thing.on_found(to_show))
					to_show.active_storage?.hide_contents(to_show)
					return FALSE
		to_show.active_storage?.hide_contents(to_show)
		to_show.active_storage = src

	LAZYOR(is_using, to_show)
	RegisterSignal(to_show, COMSIG_QDELETING, PROC_REF(on_user_qdel), override = TRUE)

	var/atom/movable/screen/grid_storage_panel/panel = new(null, to_show.hud_used, src)
	LAZYINITLIST(open_panels)
	open_panels[to_show] = WEAKREF(panel)
	panel.show_to(to_show)
	return TRUE

/datum/storage/grid/hide_contents(mob/to_hide)
	if(!to_hide)
		return FALSE

	if(to_hide.active_storage == src)
		to_hide.active_storage = null
	LAZYREMOVE(is_using, to_hide)
	UnregisterSignal(to_hide, COMSIG_QDELETING)

	var/datum/weakref/ref = LAZYACCESS(open_panels, to_hide)
	var/atom/movable/screen/grid_storage_panel/panel = ref?.resolve()
	if(panel)
		panel.hide_from(to_hide)
		qdel(panel)
	LAZYREMOVE(open_panels, to_hide)
	return TRUE

/datum/storage/grid/proc/on_user_qdel(datum/source)
	SIGNAL_HANDLER
	hide_contents(source)

/datum/storage/grid/refresh_views()
	for(var/mob/M as anything in is_using)
		var/datum/weakref/ref = LAZYACCESS(open_panels, M)
		var/atom/movable/screen/grid_storage_panel/panel = ref?.resolve()
		panel?.refresh_items()

/// Returns the open panel for a mob, or null
/datum/storage/grid/proc/get_panel(mob/user)
	var/datum/weakref/ref = LAZYACCESS(open_panels, user)
	return ref?.resolve()

/obj/item/storage/backpack/grid_test
	name = "grid test backpack"
	desc = "A prototype backpack with a grid inventory. For testing only."
	icon = 'icons/obj/storage/backpack.dmi'
	icon_state = "backpack"
	inhand_icon_state = "backpack"
	lefthand_file = 'icons/mob/inhands/equipment/backpack_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/backpack_righthand.dmi'
	w_class = WEIGHT_CLASS_BULKY
	slot_flags = ITEM_SLOT_BACK
	resistance_flags = NONE
	max_integrity = 300

	grid_width = 2
	grid_height = 3
	weight_kg = 1.5
	rw_volume = 5

/obj/item/storage/backpack/grid_test/Initialize(mapload)
	. = ..()
	if(atom_storage)
		QDEL_NULL(atom_storage)
	create_storage(storage_type = /datum/storage/grid/backpack_test)

/datum/storage/grid/backpack_test
	grid_width = 8
	grid_height = 6
	max_total_weight = 25
	max_total_volume = 40
	max_specific_storage = WEIGHT_CLASS_BULKY
	allow_big_nesting = FALSE
	attack_hand_interact = TRUE
	rustle_sound = SFX_RUSTLE
	toolbar_mode = GRID_TOOLBAR_RIGHT
