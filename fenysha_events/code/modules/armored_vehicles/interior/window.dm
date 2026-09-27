/**
 * Viewport for vehicle interiors, working like a mirage border. Place it on a wall tile and set dir to the side it looks out of.
 * The glass shows the turf just outside the hull on that side, and the turfs beyond are drawn past it,
 * the same way the map edge shows what lies across the border. It refreshes whenever the vehicle moves.
 * Outside floors draw below walls, so the wall tile is hidden at runtime and redrawn around a glazed hole.
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
	/// How many tiles past the glass the view reaches
	var/view_range = 6
	/// How many tiles either side of the glass the view spreads
	var/view_spread = 4
	var/turf/hidden_turf
	var/hidden_turf_opacity
	var/obj/vehicle/sealed/armored/owner
	var/datum/interior/owner_interior
	/// Shows the turf right outside the hull, on the glass itself
	var/atom/movable/vehicle_viewport/glass_holder
	/// Shows everything past it
	var/atom/movable/vehicle_viewport/beyond_holder

/obj/structure/vehicle_window/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/simple_rotation, ROTATION_IGNORE_ANCHORED)
	glass_holder = new
	beyond_holder = new
	vis_contents += list(glass_holder, beyond_holder)
	var/turf/host = loc
	if(isturf(host))
		frame_icon ||= host.icon
		frame_state ||= host.icon_state
		hidden_turf = host
		hidden_turf_opacity = host.opacity
		host.alpha = 0
		host.set_opacity(FALSE)
	update_appearance(UPDATE_OVERLAYS)
	// Spawned after the interior loaded, so it missed the usual linking
	if(!mapload)
		var/datum/interior/inside = get_vehicle_interior(get_turf(src))
		if(inside)
			link_interior(inside)

/obj/structure/vehicle_window/Destroy()
	unlink()
	vis_contents.Cut()
	QDEL_NULL(glass_holder)
	QDEL_NULL(beyond_holder)
	if(hidden_turf)
		hidden_turf.alpha = initial(hidden_turf.alpha)
		hidden_turf.set_opacity(hidden_turf_opacity)
		hidden_turf = null
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
	glass_holder?.vis_contents.Cut()
	beyond_holder?.vis_contents.Cut()

/obj/structure/vehicle_window/proc/on_owner_changed(datum/source)
	SIGNAL_HANDLER
	update_view()

/obj/structure/vehicle_window/proc/update_view()
	clear_view()
	var/turf/vehicle_turf = get_turf(owner)
	if(!vehicle_turf)
		return
	var/list/forward = dir2offset(dir)
	var/list/sideways = dir2offset(turn(dir, 90))

	// The glass shows the turf just outside the hull, in line with where the window sits along its wall
	var/list/interior_center = get_interior_center()
	var/lateral = round((x - interior_center[1]) * sideways[1] + (y - interior_center[2]) * sideways[2], 1)
	var/distance = get_hull_extent(dir) + 1
	var/glass_x = vehicle_turf.x + forward[1] * distance + sideways[1] * lateral
	var/glass_y = vehicle_turf.y + forward[2] * distance + sideways[2] * lateral
	var/turf/glass_turf = locate(glass_x, glass_y, vehicle_turf.z)
	if(!glass_turf)
		return
	glass_holder.vis_contents += glass_turf

	// Everything past the glass, drawn as one block like a mirage border
	var/corner_one_x = glass_x + forward[1] - sideways[1] * view_spread
	var/corner_one_y = glass_y + forward[2] - sideways[2] * view_spread
	var/corner_two_x = glass_x + forward[1] * view_range + sideways[1] * view_spread
	var/corner_two_y = glass_y + forward[2] * view_range + sideways[2] * view_spread
	var/min_x = clamp(min(corner_one_x, corner_two_x), 1, world.maxx)
	var/min_y = clamp(min(corner_one_y, corner_two_y), 1, world.maxy)
	var/max_x = clamp(max(corner_one_x, corner_two_x), 1, world.maxx)
	var/max_y = clamp(max(corner_one_y, corner_two_y), 1, world.maxy)
	if(min_x > max_x || min_y > max_y)
		return
	beyond_holder.vis_contents += block(min_x, min_y, vehicle_turf.z, max_x, max_y, vehicle_turf.z)
	// The block's bottom left turf is drawn on the holder, so shift it to where it sits relative to the glass
	beyond_holder.pixel_x = (min_x - glass_x) * ICON_SIZE_X
	beyond_holder.pixel_y = (min_y - glass_y) * ICON_SIZE_Y

/obj/structure/vehicle_window/proc/get_interior_center()
	var/list/turfs = owner_interior?.loaded_turfs
	if(!length(turfs))
		return list(x, y)
	var/turf/first = turfs[1]
	var/turf/last = turfs[length(turfs)]
	return list((first.x + last.x) / 2, (first.y + last.y) / 2)

/// How many tiles the hull reaches past the vehicle's own turf in a world direction
/obj/structure/vehicle_window/proc/get_hull_extent(world_dir)
	var/obj/hitbox/hitbox = owner.hitbox
	if(!hitbox)
		return 0
	var/along_length = (world_dir & (NORTH|SOUTH)) ? hitbox.bound_height : hitbox.bound_width
	return max(round(along_length / ICON_SIZE_ALL / 2), 1)

INITIALIZE_IMMEDIATE(/atom/movable/vehicle_viewport)
/// Like a mirage border holder: draws real turfs from elsewhere
/atom/movable/vehicle_viewport
	name = "outside"
	anchored = TRUE
	appearance_flags = PIXEL_SCALE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/atom/movable/vehicle_viewport/forceMove(atom/destination)
	return FALSE

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
