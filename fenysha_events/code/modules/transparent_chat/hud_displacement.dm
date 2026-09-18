/// How many times we re-run the pass that pushes groups off each other after the chat pass
#define CHAT_DISPLACEMENT_CASCADE_PASSES 5

/**
 * Returns a list of displacement groups for this HUD type.
 * Each group is a list of hud keys that move together when the chat is in the way.
 * Keys in no group are displaced on their own.
 */
/datum/hud/proc/get_displacement_groups()
	return list()

/**
 * Caches the chat browser rect and moves overlapping screen objects clear of it.
 * Pass null to put everything back.
 */
/datum/hud/proc/displace_hud_for_chat(list/new_rect)
	for(var/key in displaced_elements)
		var/atom/movable/screen/displaced = screen_objects[key]
		if(displaced)
			displaced.screen_loc = displaced_elements[key]
	displaced_elements.Cut()
	chat_rect = new_rect
	chat_rect_viewport = null

	if(!length(chat_rect) || !cached_map_view_size)
		recheck_action_groups()
		return

	var/our_view = mymob?.canon_client?.view
	if(!our_view)
		return

	var/list/view_size = view_to_pixels(our_view)
	var/map_w = cached_map_view_size[1]
	var/map_h = cached_map_view_size[2]
	if(!map_w || !map_h)
		return

	// The rect arrives in map-element pixels, screen_locs are viewport pixels, and BYOND counts
	// Y from the bottom while the browser counts it from the top.
	var/scale_x = view_size[1] / map_w
	var/scale_y = view_size[2] / map_h
	var/chat_left = chat_rect[1] * scale_x
	var/scaled_w = chat_rect[3] * scale_x
	var/scaled_h = chat_rect[4] * scale_y
	var/chat_bottom = view_size[2] - (chat_rect[2] * scale_y + scaled_h)
	chat_rect_viewport = list(chat_left, chat_bottom, scaled_w, scaled_h)

	var/list/element_rects = build_element_rects(our_view)
	var/list/groups = build_displacement_groups(element_rects)

	for(var/list/group in groups)
		clear_group_of_chat(group, element_rects, view_size)

	for(var/pass in 1 to CHAT_DISPLACEMENT_CASCADE_PASSES)
		var/moved_any = FALSE
		for(var/list/group in groups)
			if(clear_group_of_elements(group, element_rects, view_size))
				moved_any = TRUE
		if(!moved_any)
			break

	recheck_action_groups()

/// Action groups size themselves against the view, so they have to be told the chat moved
/datum/hud/proc/recheck_action_groups()
	listed_actions?.check_against_view()
	palette_actions?.check_against_view()

/// Builds an assoc hud_key -> list(x, y, w, h) of every screen object we can position
/datum/hud/proc/build_element_rects(our_view)
	var/list/element_rects = list()
	for(var/key in screen_objects)
		if(key == HUD_MOB_SCREENTIP)
			continue
		var/atom/movable/screen/candidate = screen_objects[key]
		if(!candidate.screen_loc)
			continue
		// Spanning locs and render targets aren't a single tile, leave them be
		if(findtext(candidate.screen_loc, " to ") || findtext(candidate.screen_loc, "*"))
			continue
		var/list/offsets = screen_loc_to_offset(candidate.screen_loc, our_view)
		if(!offsets)
			continue
		element_rects[key] = list(offsets[1], offsets[2], ICON_SIZE_X, ICON_SIZE_Y)
	return element_rects

/// Turns get_displacement_groups() into groups of keys we actually hold, plus a group per loose key
/datum/hud/proc/build_displacement_groups(list/element_rects)
	var/list/groups = list()
	var/list/grouped = list()
	for(var/list/defined_group in get_displacement_groups())
		var/list/valid_group = list()
		for(var/key in defined_group)
			if(element_rects[key])
				valid_group += key
				grouped[key] = TRUE
		if(length(valid_group))
			groups += list(valid_group)
	for(var/key in element_rects)
		if(!grouped[key])
			groups += list(list(key))
	return groups

/// Orders the four cardinal shifts, nearest chat edge first
/datum/hud/proc/shift_directions_for(el_x, el_y)
	var/chat_left = chat_rect_viewport[1]
	var/chat_bottom = chat_rect_viewport[2]
	var/chat_w = chat_rect_viewport[3]
	var/chat_h = chat_rect_viewport[4]
	var/shift_x = (el_x > chat_left + chat_w / 2) ? 1 : -1
	var/shift_y = (el_y > chat_bottom + chat_h / 2) ? 1 : -1
	var/dist_to_h_edge = min(abs(el_x - chat_left), abs(el_x - (chat_left + chat_w)))
	var/dist_to_v_edge = min(abs(el_y - chat_bottom), abs(el_y - (chat_bottom + chat_h)))
	if(dist_to_h_edge < dist_to_v_edge)
		return list(list(shift_x, 0), list(0, shift_y), list(-shift_x, 0), list(0, -shift_y))
	return list(list(0, shift_y), list(shift_x, 0), list(0, -shift_y), list(-shift_x, 0))

/// Pixels a rect must travel in the given unit direction to sit fully outside an obstacle
/proc/shift_to_clear(list/rect, list/obstacle, dx, dy)
	if(dx > 0)
		return (obstacle[1] + obstacle[3]) - rect[1]
	if(dx < 0)
		return rect[1] + rect[3] - obstacle[1]
	if(dy > 0)
		return (obstacle[2] + obstacle[4]) - rect[2]
	return rect[2] + rect[4] - obstacle[2]

/// Moves every member of a group by the same delta and records where they came from
/datum/hud/proc/apply_group_shift(list/group, list/element_rects, delta_x, delta_y)
	for(var/key in group)
		var/atom/movable/screen/moving = screen_objects[key]
		if(isnull(displaced_elements[key]))
			displaced_elements[key] = moving.screen_loc
		moving.screen_loc = apply_screen_loc_delta(moving.screen_loc, delta_x, delta_y)
		var/list/rect = element_rects[key]
		element_rects[key] = list(rect[1] + delta_x, rect[2] + delta_y, rect[3], rect[4])

/// First pass - shifts a group just far enough that none of it sits under the chat
/datum/hud/proc/clear_group_of_chat(list/group, list/element_rects, list/view_size)
	var/list/chat = chat_rect_viewport
	var/overlaps = FALSE
	for(var/key in group)
		var/list/rect = element_rects[key]
		if(rects_overlap(rect[1], rect[2], rect[3], rect[4], chat[1], chat[2], chat[3], chat[4]))
			overlaps = TRUE
			break
	if(!overlaps)
		return FALSE

	// Shift by what the member buried deepest in the chat needs, so the group stays together
	var/chat_cx = chat[1] + chat[3] / 2
	var/chat_cy = chat[2] + chat[4] / 2
	var/deepest_key = group[1]
	var/closest_dist = INFINITY
	for(var/key in group)
		var/list/rect = element_rects[key]
		var/dx = rect[1] + ICON_SIZE_X / 2 - chat_cx
		var/dy = rect[2] + ICON_SIZE_Y / 2 - chat_cy
		if(dx * dx + dy * dy < closest_dist)
			closest_dist = dx * dx + dy * dy
			deepest_key = key

	var/list/deepest_rect = element_rects[deepest_key]
	for(var/list/direction in shift_directions_for(deepest_rect[1], deepest_rect[2]))
		var/dx = direction[1]
		var/dy = direction[2]
		var/shift = ceil(shift_to_clear(deepest_rect, chat, dx, dy))
		if(shift <= 0)
			continue
		for(var/key in group)
			var/list/rect = element_rects[key]
			if(rects_overlap(rect[1] + dx * shift, rect[2] + dy * shift, rect[3], rect[4], chat[1], chat[2], chat[3], chat[4]))
				shift = max(shift, ceil(shift_to_clear(rect, chat, dx, dy)))
		var/new_x = deepest_rect[1] + dx * shift
		var/new_y = deepest_rect[2] + dy * shift
		if(new_x < ICON_SIZE_X || new_x > view_size[1] || new_y < ICON_SIZE_Y || new_y > view_size[2])
			continue
		apply_group_shift(group, element_rects, dx * shift, dy * shift)
		return TRUE
	return FALSE

/// Later passes - shifts a group off any element outside it that it has landed on
/datum/hud/proc/clear_group_of_elements(list/group, list/element_rects, list/view_size)
	var/list/chat = chat_rect_viewport
	var/list/obstacles = list()
	for(var/key in element_rects)
		if(key in group)
			continue
		obstacles += list(element_rects[key])

	var/needs_move = FALSE
	for(var/key in group)
		var/list/rect = element_rects[key]
		for(var/list/obstacle in obstacles)
			if(rects_overlap(rect[1], rect[2], rect[3], rect[4], obstacle[1], obstacle[2], obstacle[3], obstacle[4]))
				needs_move = TRUE
				break
		if(needs_move)
			break
	if(!needs_move)
		return FALSE

	var/list/reference_rect = element_rects[group[1]]
	for(var/list/direction in shift_directions_for(reference_rect[1], reference_rect[2]))
		var/dx = direction[1]
		var/dy = direction[2]
		var/shift = 0
		for(var/key in group)
			var/list/rect = element_rects[key]
			if(rects_overlap(rect[1], rect[2], rect[3], rect[4], chat[1], chat[2], chat[3], chat[4]))
				shift = max(shift, shift_to_clear(rect, chat, dx, dy))
			for(var/list/obstacle in obstacles)
				if(rects_overlap(rect[1], rect[2], rect[3], rect[4], obstacle[1], obstacle[2], obstacle[3], obstacle[4]))
					shift = max(shift, shift_to_clear(rect, obstacle, dx, dy))
		if(shift <= 0)
			continue
		shift = ceil(shift)
		var/new_x = reference_rect[1] + dx * shift
		var/new_y = reference_rect[2] + dy * shift
		if(new_x < ICON_SIZE_X || new_x > view_size[1] || new_y < ICON_SIZE_Y || new_y > view_size[2])
			continue
		if(group_collides_after_shift(group, element_rects, obstacles, dx * shift, dy * shift))
			continue
		apply_group_shift(group, element_rects, dx * shift, dy * shift)
		return TRUE
	return FALSE

/// TRUE if any group member would still sit on the chat or an obstacle after the given delta
/datum/hud/proc/group_collides_after_shift(list/group, list/element_rects, list/obstacles, delta_x, delta_y)
	var/list/chat = chat_rect_viewport
	for(var/key in group)
		var/list/rect = element_rects[key]
		var/shifted_x = rect[1] + delta_x
		var/shifted_y = rect[2] + delta_y
		if(rects_overlap(shifted_x, shifted_y, rect[3], rect[4], chat[1], chat[2], chat[3], chat[4]))
			return TRUE
		for(var/list/obstacle in obstacles)
			if(rects_overlap(shifted_x, shifted_y, rect[3], rect[4], obstacle[1], obstacle[2], obstacle[3], obstacle[4]))
				return TRUE
	return FALSE

/// Nudges a single screen object clear of the chat, for elements added after the rect arrived
/datum/hud/proc/displace_single_element(hud_key, atom/movable/screen/target)
	if(!chat_rect_viewport || !target.screen_loc)
		return
	if(findtext(target.screen_loc, " to ") || findtext(target.screen_loc, "*"))
		return
	var/our_view = mymob?.canon_client?.view
	if(!our_view)
		return
	var/list/offsets = screen_loc_to_offset(target.screen_loc, our_view)
	if(!offsets)
		return

	var/chat_left = chat_rect_viewport[1]
	var/chat_bottom = chat_rect_viewport[2]
	var/chat_w = chat_rect_viewport[3]
	var/chat_h = chat_rect_viewport[4]
	if(!rects_overlap(offsets[1], offsets[2], ICON_SIZE_X, ICON_SIZE_Y, chat_left, chat_bottom, chat_w, chat_h))
		return

	var/list/view_size = view_to_pixels(our_view)
	var/list/element_rects = build_element_rects(our_view)
	var/shift_y_dir = ((chat_bottom + chat_h / 2) > view_size[2] / 2) ? -1 : 1
	var/shift_x_dir = ((chat_left + chat_w / 2) > view_size[1] / 2) ? -1 : 1

	var/new_x = offsets[1]
	var/new_y = offsets[2]
	var/displaced = FALSE
	for(var/attempt in 1 to 20)
		new_y += shift_y_dir * ICON_SIZE_Y
		if(!rects_overlap(new_x, new_y, ICON_SIZE_X, ICON_SIZE_Y, chat_left, chat_bottom, chat_w, chat_h) && !collides_with_any(new_x, new_y, ICON_SIZE_X, ICON_SIZE_Y, element_rects, hud_key))
			displaced = TRUE
			break
	if(!displaced)
		new_x = offsets[1]
		new_y = offsets[2]
		for(var/attempt in 1 to 20)
			new_x += shift_x_dir * ICON_SIZE_X
			if(!rects_overlap(new_x, new_y, ICON_SIZE_X, ICON_SIZE_Y, chat_left, chat_bottom, chat_w, chat_h) && !collides_with_any(new_x, new_y, ICON_SIZE_X, ICON_SIZE_Y, element_rects, hud_key))
				displaced = TRUE
				break
	if(!displaced)
		return

	displaced_elements[hud_key] = target.screen_loc
	target.screen_loc = apply_screen_loc_delta(target.screen_loc, new_x - offsets[1], new_y - offsets[2])

#undef CHAT_DISPLACEMENT_CASCADE_PASSES
