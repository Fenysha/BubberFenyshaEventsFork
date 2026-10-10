/client
	/// Last offset applied through set_view_offset()
	var/view_offset_x = 0
	var/view_offset_y = 0

/// Pixel size of the shadow displace map, read from the dmi itself once
/proc/get_shadow_map_size()
	var/static/list/map_size
	if(!map_size)
		var/icon/probe = icon(SHADOW_MAP_ICON, "9")
		map_size = list(probe.Width(), probe.Height())
	return map_size

/**
 * Max camera offset (px) per axis that keeps the whole screen covered by the shadow displace map.
 * The map is centred on the shadow origin, so the origin may only travel (map - view) / 2 before a
 * strip without shadows shows up at the screen edge. To allow a longer look, use a bigger map dmi.
 */
/client/proc/get_view_offset_limit()
	var/list/map_size = get_shadow_map_size()
	var/list/view_size = getviewsize(view)
	return list(
		max(0, (map_size[1] * SHADOW_MAP_EFFECTIVE - view_size[1] * ICON_SIZE_X) / 2 - SHADOW_MAP_MARGIN),
		max(0, (map_size[2] * SHADOW_MAP_EFFECTIVE - view_size[2] * ICON_SIZE_Y) / 2 - SHADOW_MAP_MARGIN),
	)


/client/proc/set_view_offset(new_x, new_y, duration = 1, easing = LINEAR_EASING, force = FALSE, instant = FALSE)
	var/list/limit = get_view_offset_limit()
	new_x = clamp(new_x, -limit[1], limit[1])
	new_y = clamp(new_y, -limit[2], limit[2])
	if(!force && !instant && new_x == view_offset_x && new_y == view_offset_y)
		return

	view_offset_x = new_x
	view_offset_y = new_y

	if(instant)
		// Stop only our own animation before applying the exact camera position.
		animate(src, tag = "shadow_camera_offset")
		pixel_x = new_x
		pixel_y = new_y
	else
		animate(src, pixel_x = new_x, pixel_y = new_y, time = duration, easing = easing, tag = "shadow_camera_offset")

	mob?.hud_used?.set_shadow_origin_offset(SHADOW_ORIGIN_SIGN * new_x, SHADOW_ORIGIN_SIGN * new_y, duration, easing, instant)

/datum/hud
	/// Cached plane masters that own a wall displacement filter.
	var/list/shadow_origin_planes
	/// Used to detect when plane masters were added dynamically.
	var/shadow_origin_plane_count = -1

/datum/hud/proc/get_shadow_origin_planes()
	var/current_plane_count = 0
	for(var/group_key in master_groups)
		var/datum/plane_master_group/group = master_groups[group_key]
		if(!group || !group.plane_masters)
			continue
		current_plane_count += length(group.plane_masters)

	var/rebuild = !length(shadow_origin_planes) || current_plane_count != shadow_origin_plane_count
	if(!rebuild)
		for(var/atom/movable/screen/plane_master/wall_fov/pm as anything in shadow_origin_planes)
			if(QDELETED(pm))
				rebuild = TRUE
				break
	if(!rebuild)
		return shadow_origin_planes

	var/list/found = list()
	for(var/group_key in master_groups)
		var/datum/plane_master_group/group = master_groups[group_key]
		if(!group || !group.plane_masters)
			continue
		for(var/plane_key in group.plane_masters)
			var/atom/movable/screen/plane_master/wall_fov/pm = group.plane_masters[plane_key]
			if(!istype(pm) || QDELETED(pm) || !pm.get_filter("wall_displace"))
				continue
			found += pm

	shadow_origin_planes = found
	shadow_origin_plane_count = current_plane_count
	return found

/datum/hud/proc/set_shadow_origin_offset(dx, dy, duration, easing, instant = FALSE)
	for(var/atom/movable/screen/plane_master/wall_fov/pm as anything in get_shadow_origin_planes())
		if(QDELETED(pm))
			continue
		pm.set_displace_offset(dx, dy, duration, easing, instant)


/// Ticks (1/10s) RMB must be held before the look starts, so normal right clicks don't make the camera twitch.
#define LOOK_AROUND_HOLD_DELAY 2
/// How far the camera moves per pixel of cursor distance from the screen centre.
#define LOOK_AROUND_STRENGTH 0.6
/// Max offset as fraction of half the view.
#define LOOK_AROUND_MAX_FRACTION 0.75
/// Cursor must leave this radius (px) from the centre before the camera moves.
#define LOOK_AROUND_DEADZONE 24
/// Seconds for the camera to cover half of the remaining distance to its goal (smaller = snappier).
#define LOOK_AROUND_HALF_LIFE 0.06

///
/// A processing loop pushes short, matching camera/shadow animations. The exponential smoothing
/// happens here; do not use instant positioning for every tick, or the movement will visibly step.
///
/datum/component/look_around
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/client/hooked
	var/looking = FALSE
	var/processing = FALSE
	var/hold_timer
	var/right_button_down = FALSE
	var/cursor_x = 0
	var/cursor_y = 0
	var/current_x = 0
	var/current_y = 0

/datum/component/look_around/Initialize()
	if(!ismob(parent))
		return COMPONENT_INCOMPATIBLE

/datum/component/look_around/RegisterWithParent()
	RegisterSignal(parent, COMSIG_MOB_CLIENT_LOGIN, PROC_REF(on_login))
	RegisterSignal(parent, COMSIG_MOB_LOGOUT, PROC_REF(on_logout))
	var/mob/M = parent
	if(M.client)
		hook_client(M.client)

/datum/component/look_around/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_MOB_CLIENT_LOGIN, COMSIG_MOB_LOGOUT))
	unhook_client()

/datum/component/look_around/Destroy(force)
	unhook_client()
	return ..()

/datum/component/look_around/proc/on_login(datum/source, client/new_client)
	SIGNAL_HANDLER
	var/mob/M = parent
	hook_client(new_client || M.client)

/datum/component/look_around/proc/on_logout(datum/source, client/old_client)
	SIGNAL_HANDLER
	unhook_client()

/datum/component/look_around/proc/hook_client(client/C)
	if(!C || hooked == C)
		return
	unhook_client()
	hooked = C
	RegisterSignal(C, COMSIG_CLIENT_MOUSEDOWN, PROC_REF(on_mouse_down))
	RegisterSignal(C, COMSIG_CLIENT_MOUSEUP, PROC_REF(on_mouse_up))
	RegisterSignal(C, COMSIG_CLIENT_MOUSEDRAG, PROC_REF(on_mouse_drag))

/datum/component/look_around/proc/unhook_client()
	if(!hooked)
		return
	if(hold_timer)
		deltimer(hold_timer)
		hold_timer = null
	looking = FALSE
	right_button_down = FALSE
	if(processing)
		STOP_PROCESSING(SSprojectiles, src)
		processing = FALSE
	if(current_x || current_y)
		current_x = 0
		current_y = 0
		if(!HAS_TRAIT(parent, TRAIT_USER_SCOPED))
			hooked.set_view_offset(0, 0, 2, force = TRUE)
	UnregisterSignal(hooked, list(COMSIG_CLIENT_MOUSEDOWN, COMSIG_CLIENT_MOUSEUP, COMSIG_CLIENT_MOUSEDRAG))
	hooked = null

/// In BYOND 514+, `button` identifies the button that changed. Older versions only provide left/right/middle.
/datum/component/look_around/proc/is_right_button_event(list/mods)
	var/button = LAZYACCESS(mods, "button")
	if(!isnull(button))
		return lowertext("[button]") == "right"
	return LAZYACCESS(mods, RIGHT_CLICK)

/datum/component/look_around/proc/can_look()
	var/mob/M = parent
	if(!hooked || QDELETED(M))
		return FALSE
	// The scope owns the camera while it is active.
	if(HAS_TRAIT(M, TRAIT_USER_SCOPED))
		return FALSE
	// Don't fight an item that zooms on right click.
	var/obj/item/held = M.get_active_held_item()
	if(held)
		var/datum/component/scope/scope = held.GetComponent(/datum/component/scope)
		if(scope && scope.zoom_method == ZOOM_METHOD_RIGHT_CLICK)
			return FALSE
	return TRUE

/datum/component/look_around/proc/on_mouse_down(client/source, atom/object, location, control, params)
	SIGNAL_HANDLER
	var/list/mods = params2list(params)
	// Do not mistake a left click for RMB just because RMB is already held.
	if(!is_right_button_event(mods))
		return
	if(!can_look())
		return

	right_button_down = TRUE
	store_cursor(mods)
	if(hold_timer)
		deltimer(hold_timer)
	hold_timer = addtimer(CALLBACK(src, PROC_REF(start_look)), LOOK_AROUND_HOLD_DELAY, TIMER_STOPPABLE)

/datum/component/look_around/proc/on_mouse_up(client/source, atom/object, location, control, params)
	SIGNAL_HANDLER
	var/list/mods = params2list(params)
	// Only the release of RMB ends look-around. Releasing LMB while RMB is held must not stop it.
	if(!is_right_button_event(mods))
		return
	right_button_down = FALSE
	stop_look()

/datum/component/look_around/proc/on_mouse_drag(client/source, atom/src_object, atom/over_object, turf/src_location, turf/over_location, src_control, over_control, params)
	SIGNAL_HANDLER
	// MouseDrag params may only describe the button involved in this drag.
	// Do not infer that RMB was released from the absence of RIGHT_CLICK here.
	if(!right_button_down)
		return
	if(hold_timer || looking)
		store_cursor(params2list(params))

/datum/component/look_around/proc/store_cursor(list/mods)
	var/list/pos = parse_screen_loc_pixels(LAZYACCESS(mods, SCREEN_LOC))
	if(!pos)
		return
	cursor_x = pos[1]
	cursor_y = pos[2]

/datum/component/look_around/proc/start_look()
	hold_timer = null
	if(!can_look())
		right_button_down = FALSE
		return
	looking = TRUE
	if(!processing)
		processing = TRUE
		START_PROCESSING(SSprojectiles, src)

/datum/component/look_around/proc/stop_look()
	if(hold_timer)
		deltimer(hold_timer)
		hold_timer = null
	right_button_down = FALSE
	// process() keeps running until the camera has glided back to the body.
	looking = FALSE

/datum/component/look_around/process(seconds_per_tick)
	if(!hooked)
		processing = FALSE
		right_button_down = FALSE
		return PROCESS_KILL
	if(looking && !can_look())
		looking = FALSE
	// Scope took over the camera: let go without touching the client.
	if(HAS_TRAIT(parent, TRAIT_USER_SCOPED))
		current_x = 0
		current_y = 0
		processing = FALSE
		right_button_down = FALSE
		return PROCESS_KILL

	var/goal_x = 0
	var/goal_y = 0
	if(looking)
		var/list/view_size = getviewsize(hooked.view)
		var/half_x = view_size[1] * ICON_SIZE_X / 2
		var/half_y = view_size[2] * ICON_SIZE_Y / 2
		goal_x = look_axis(cursor_x - half_x, half_x)
		goal_y = look_axis(cursor_y - half_y, half_y)

	// Frame-rate independent exponential smoothing.
	var/blend = 1 - 0.5 ** (seconds_per_tick / LOOK_AROUND_HALF_LIFE)
	current_x += (goal_x - current_x) * blend
	current_y += (goal_y - current_y) * blend

	if(!looking && abs(current_x) < 1 && abs(current_y) < 1)
		current_x = 0
		current_y = 0
		hooked.set_view_offset(0, 0, world.tick_lag, force = TRUE, instant = TRUE)
		processing = FALSE
		return PROCESS_KILL

	hooked.set_view_offset(current_x, current_y, world.tick_lag)

/// Deadzone + strength + clamp for one axis.
/datum/component/look_around/proc/look_axis(distance, half)
	var/sign = distance < 0 ? -1 : 1
	var/magnitude = max(0, abs(distance) - LOOK_AROUND_DEADZONE)
	return sign * min(magnitude * LOOK_AROUND_STRENGTH, half * LOOK_AROUND_MAX_FRACTION)

/// "5:12,7:3" -> list(x_px, y_px) from the bottom-left corner of the map widget.
/proc/parse_screen_loc_pixels(text)
	if(!text)
		return null
	var/list/axes = splittext(text, ",")
	if(length(axes) != 2)
		return null
	var/list/result = list()
	for(var/i in 1 to 2)
		var/list/bits = splittext(axes[i], ":")
		var/count = length(bits)
		var/tile
		var/pixel = 0
		if(count >= 2)
			tile = text2num(bits[count - 1])
			pixel = text2num(bits[count])
		else if(count == 1)
			tile = text2num(bits[1])
		if(isnull(tile) || isnull(pixel))
			return null
		result += (tile - 1) * (i == 1 ? ICON_SIZE_X : ICON_SIZE_Y) + pixel
	return result

#undef LOOK_AROUND_HOLD_DELAY
#undef LOOK_AROUND_STRENGTH
#undef LOOK_AROUND_MAX_FRACTION
#undef LOOK_AROUND_DEADZONE
#undef LOOK_AROUND_HALF_LIFE
