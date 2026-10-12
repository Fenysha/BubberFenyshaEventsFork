/// Returns width after applying current rotation
/obj/item/proc/get_grid_width()
	return GRID_EFFECTIVE_WIDTH(src)

/// Returns height after applying current rotation
/obj/item/proc/get_grid_height()
	return GRID_EFFECTIVE_HEIGHT(src)

/// Rotate by degrees (usually ±90). Does not check storage space — caller must.
/obj/item/proc/rotate_grid(degrees = 90)
	grid_rotation = (grid_rotation + degrees) % 360
	if(grid_rotation < 0)
		grid_rotation += 360

/**
 * Returns list of unique rotations that produce distinct footprints.
 * Square and 1×1 items only need one entry.
 */
/obj/item/proc/get_possible_rotations()
	. = list()
	var/r = grid_rotation
	var/list/seen_shapes = list()
	for(var/i in 1 to 4)
		var/eff_w = ((r % 180) == 0) ? grid_width : grid_height
		var/eff_h = ((r % 180) == 0) ? grid_height : grid_width
		var/shape_key = "[eff_w]x[eff_h]"
		if(!(shape_key in seen_shapes))
			seen_shapes[shape_key] = TRUE
			. += r
		r = (r + 90) % 360
	if(!length(.))
		. += grid_rotation
