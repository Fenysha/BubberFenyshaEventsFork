/// Checks if two rectangles overlap
/proc/rects_overlap(x1, y1, w1, h1, x2, y2, w2, h2)
	return !(x1 + w1 <= x2 || x2 + w2 <= x1 || y1 + h1 <= y2 || y2 + h2 <= y1)

/// Checks if a rect collides with any rect in an assoc key -> list(x, y, w, h), ignoring one key
/proc/collides_with_any(x, y, w, h, list/element_rects, exclude_key)
	for(var/key in element_rects)
		if(key == exclude_key)
			continue
		var/list/other = element_rects[key]
		if(rects_overlap(x, y, w, h, other[1], other[2], other[3], other[4]))
			return TRUE
	return FALSE

/// Applies a tile delta to one screen_loc component such as "CENTER-3" or "EAST+1"
/proc/apply_tile_delta(component, delta)
	var/numeric_part = cut_relative_direction(component)
	var/direction = length(numeric_part) ? replacetext(component, numeric_part, "") : component
	var/numeric = text2num(numeric_part)
	if(isnull(numeric))
		numeric = 0
	numeric += delta
	if(!numeric)
		return length(direction) ? direction : "0"
	if(!length(direction))
		return "[numeric]"
	return numeric > 0 ? "[direction]+[numeric]" : "[direction][numeric]"

/// Applies a viewport pixel delta to a screen_loc, keeping its relative keywords intact.
/// dx and dy are positive right/up.
/proc/apply_screen_loc_delta(screen_loc, dx, dy)
	var/list/parts = splittext(screen_loc, ",")
	if(length(parts) < 2)
		return screen_loc

	var/first_part = trim(parts[1])
	var/second_part = trim(parts[2])
	var/swapped = (findtext(first_part, "NORTH") || findtext(first_part, "SOUTH") || findtext(first_part, "TOP") || findtext(first_part, "BOTTOM")) && !findtext(first_part, "EAST") && !findtext(first_part, "WEST")

	var/x_part = swapped ? second_part : first_part
	var/y_part = swapped ? first_part : second_part

	var/list/x_pack = splittext(x_part, ":")
	var/list/y_pack = splittext(y_part, ":")

	var/x_pixel = (length(x_pack) > 1 ? text2num(x_pack[2]) : 0) + dx
	var/x_tile_delta = round(x_pixel / ICON_SIZE_X)
	x_pixel -= x_tile_delta * ICON_SIZE_X

	var/y_pixel = (length(y_pack) > 1 ? text2num(y_pack[2]) : 0) + dy
	var/y_tile_delta = round(y_pixel / ICON_SIZE_Y)
	y_pixel -= y_tile_delta * ICON_SIZE_Y

	var/x_base = x_tile_delta ? apply_tile_delta(x_pack[1], x_tile_delta) : x_pack[1]
	var/y_base = y_tile_delta ? apply_tile_delta(y_pack[1], y_tile_delta) : y_pack[1]

	var/new_x = x_pixel ? "[x_base]:[x_pixel]" : "[x_base]"
	var/new_y = y_pixel ? "[y_base]:[y_pixel]" : "[y_base]"

	return swapped ? "[new_y],[new_x]" : "[new_x],[new_y]"

/// Widens a "WxH" viewport string by the space the docked chat pane would have taken
/proc/widen_viewport_for_onmap(size_string)
	var/list/parts = splittext(size_string, "x")
	if(length(parts) < 2)
		return size_string
	var/width = text2num(parts[1])
	var/height = text2num(parts[2])
	if(!width || !height)
		return size_string
	var/widened = width + ONMAP_VIEWPORT_EXTRA_WIDTH
	// An even width has no centre tile, which shoves the player off to one side
	if(!(widened % 2))
		widened += 1
	return "[widened]x[height]"
