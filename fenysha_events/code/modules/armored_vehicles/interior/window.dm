/**
 * Viewport for vehicle interiors. Place it on a wall tile and set dir to the way it should look, in the interior's frame.
 * It shows the real turf just outside the hull at normal scale, rotated to match the vehicle's heading.
 * Windows placed side by side along a wall show neighbouring outside turfs, so a row of them reads as one strip.
 * Outside floors draw below walls, so the wall tile under it is hidden at runtime and redrawn around a glazed hole.
 */
/obj/structure/vehicle_window
	name = "viewport"
	desc = "A slab of armored glass looking out of the vehicle."
	icon = 'fenysha_events/icons/vehicles/armored/hardpoint_modules.dmi'
	icon_state = MAP_SWITCH("", "zoom")
	anchored = TRUE
	density = FALSE
	resistance_flags = INDESTRUCTIBLE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	dir = NORTH
	/// Wall art drawn around the glass; defaults to whatever the turf underneath looks like
	var/frame_icon
	var/frame_state
	/// Hide the turf underneath so outside floors aren't covered by it
	var/hide_turf = TRUE
	var/turf/hidden_turf
	var/obj/vehicle/sealed/armored/owner
	var/datum/interior/owner_interior
	var/atom/movable/vehicle_viewport/viewport

/obj/structure/vehicle_window/Initialize(mapload)
	. = ..()
	viewport = new
	vis_contents += viewport
	var/turf/host = loc
	if(isturf(host))
		frame_icon ||= host.icon
		frame_state ||= host.icon_state
		if(hide_turf)
			hidden_turf = host
			host.alpha = 0
	update_appearance(UPDATE_OVERLAYS)

/obj/structure/vehicle_window/Destroy()
	unlink()
	if(hidden_turf)
		hidden_turf.alpha = initial(hidden_turf.alpha)
		hidden_turf = null
	vis_contents.Cut()
	QDEL_NULL(viewport)
	return ..()

/obj/structure/vehicle_window/setDir(newdir)
	. = ..()
	if(owner)
		update_view()

/obj/structure/vehicle_window/update_overlays()
	. = ..()
	. += mutable_appearance(get_frame_icon(frame_icon, frame_state), layer = ABOVE_ALL_MOB_LAYER, offset_spokesman = src, plane = GAME_PLANE)

/// Wall art with a glazed hole in the middle, cached per icon state
/proc/get_frame_icon(frame_icon, frame_state)
	var/static/list/frame_cache = list()
	var/key = "[frame_icon]-[frame_state]"
	if(frame_cache[key])
		return frame_cache[key]
	var/icon/frame = (frame_icon && frame_state) ? icon(frame_icon, frame_state, SOUTH, 1) : icon('icons/effects/effects.dmi', "nothing")
	frame.DrawBox(rgb(40, 44, 48), 6, 7, 27, 26)
	frame.DrawBox(null, 7, 8, 26, 25)
	frame.DrawBox(rgb(150, 200, 255, 35), 7, 8, 26, 25)
	frame_cache[key] = frame
	return frame

/obj/structure/vehicle_window/link_interior(datum/interior/link)
	unlink()
	owner_interior = link
	owner = link.container
	RegisterSignals(owner, list(COMSIG_MOVABLE_MOVED, COMSIG_ATOM_DIR_CHANGE), PROC_REF(on_owner_changed))
	RegisterSignal(owner, COMSIG_QDELETING, PROC_REF(unlink))
	update_view()

/obj/structure/vehicle_window/proc/unlink()
	SIGNAL_HANDLER
	if(owner)
		UnregisterSignal(owner, list(COMSIG_MOVABLE_MOVED, COMSIG_ATOM_DIR_CHANGE, COMSIG_QDELETING))
	owner = null
	owner_interior = null
	clear_view()

/obj/structure/vehicle_window/proc/clear_view()
	viewport?.vis_contents.Cut()

/obj/structure/vehicle_window/proc/on_owner_changed(datum/source)
	SIGNAL_HANDLER
	update_view()

/obj/structure/vehicle_window/proc/update_view()
	clear_view()
	var/turf/vehicle_turf = get_turf(owner)
	if(!vehicle_turf)
		return
	// Degrees the vehicle is turned clockwise relative to the interior's forward
	var/datum/interior/armored/armored_interior = owner_interior
	var/interior_forward = istype(armored_interior) ? armored_interior.forward_dir : EAST
	var/rotation = dir2angle(owner.dir) - dir2angle(interior_forward)
	var/world_dir = turn(dir, -rotation)

	// Keep the view in line with where the viewport sits along its wall
	var/list/interior_center = get_interior_center()
	var/list/offset = rotate_offset(x - interior_center[1], y - interior_center[2], rotation)
	var/list/forward = dir2offset(world_dir)
	var/list/sideways = dir2offset(turn(world_dir, 90))
	var/lateral = round(offset[1] * sideways[1] + offset[2] * sideways[2], 1)

	var/distance = get_hull_extent(world_dir) + 1
	var/turf/outside = locate(vehicle_turf.x + forward[1] * distance + sideways[1] * lateral, vehicle_turf.y + forward[2] * distance + sideways[2] * lateral, vehicle_turf.z)
	if(!outside)
		return
	viewport.vis_contents += outside
	var/matrix/view_transform = matrix()
	view_transform.Turn(-rotation)
	viewport.transform = view_transform

/obj/structure/vehicle_window/proc/get_interior_center()
	var/list/turfs = owner_interior?.loaded_turfs
	if(!length(turfs))
		return list(x, y)
	var/turf/first = turfs[1]
	var/turf/last = turfs[length(turfs)]
	return list((first.x + last.x) / 2, (first.y + last.y) / 2)

/// Rotates an x/y offset clockwise by the given degrees
/obj/structure/vehicle_window/proc/rotate_offset(offset_x, offset_y, degrees)
	var/rotated_x = offset_x * cos(degrees) + offset_y * sin(degrees)
	var/rotated_y = offset_y * cos(degrees) - offset_x * sin(degrees)
	return list(rotated_x, rotated_y)

/// How many tiles the hull reaches past the vehicle's own turf in a world direction
/obj/structure/vehicle_window/proc/get_hull_extent(world_dir)
	var/obj/hitbox/hitbox = owner.hitbox
	if(!hitbox)
		return 0
	var/along_length = (world_dir & (NORTH|SOUTH)) ? hitbox.bound_height : hitbox.bound_width
	return max(round(along_length / ICON_SIZE_ALL / 2), 1)

/atom/movable/vehicle_viewport
	name = "outside"
	anchored = TRUE
	appearance_flags = PIXEL_SCALE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/// Swaps your view to the outside of the vehicle until you move, resist or look away
/obj/structure/periscope
	name = "periscope"
	desc = "A periscope for viewing the outside of the vehicle. Move or resist to stop looking through it."
	icon = 'fenysha_events/icons/vehicles/armored/3x3/tank_interior.dmi'
	icon_state = "periscope"
	anchored = TRUE
	density = FALSE
	resistance_flags = INDESTRUCTIBLE
	var/obj/vehicle/sealed/armored/owner
	var/list/mob/viewers_looking = list()

/obj/structure/periscope/Destroy()
	for(var/mob/viewer as anything in viewers_looking)
		stop_looking(viewer)
	owner = null
	return ..()

/obj/structure/periscope/link_interior(datum/interior/link)
	owner = link.container

/obj/structure/periscope/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(.)
		return
	if(!owner || (user in viewers_looking) || user.client?.eye != user)
		return TRUE
	viewers_looking += user
	user.reset_perspective(owner)
	user.client?.view_size.add(4)
	RegisterSignals(user, list(COMSIG_MOVABLE_MOVED, COMSIG_LIVING_RESIST, COMSIG_MOB_LOGOUT, COMSIG_QDELETING), PROC_REF(stop_looking))
	return TRUE

/obj/structure/periscope/proc/stop_looking(mob/viewer)
	SIGNAL_HANDLER
	UnregisterSignal(viewer, list(COMSIG_MOVABLE_MOVED, COMSIG_LIVING_RESIST, COMSIG_MOB_LOGOUT, COMSIG_QDELETING))
	viewers_looking -= viewer
	viewer.reset_perspective()
	viewer.client?.view_size.resetToDefault()

/obj/structure/periscope/apc
	name = "APC periscope"

/obj/structure/periscope/som
	icon = 'fenysha_events/icons/vehicles/armored/3x4/som_interior_small_props.dmi'
	icon_state = "periscope"
	pixel_x = -5

/obj/structure/periscope/som/Initialize(mapload)
	. = ..()
	update_appearance(UPDATE_OVERLAYS)

/obj/structure/periscope/som/update_overlays()
	. = ..()
	. += emissive_appearance(icon, "[icon_state]_emissive", src)
