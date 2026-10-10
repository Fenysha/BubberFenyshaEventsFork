/**
 * Zone boundary visualisation.
 *
 * Uses the same trick as buildmode area_edit: set image.loc = area so BYOND
 * paints every turf in that area. Labels (maptext) sit on a representative turf.
 */

/mob/living
	var/zone_view_mode = FALSE
	/// Images currently pushed to client.images (fills + labels).
	var/list/zone_view_images = null


/mob/living/verb/toggle_zone_view_mode()
	set name = "Toggle Zone View Mode"
	set category = "IC"
	toggle_zone_view()


/mob/living/proc/toggle_zone_view()
	zone_view_mode = !zone_view_mode

	if(zone_view_mode)
		to_chat(src, span_notice("Zone view <b>enabled</b>. All zones on this Z are highlighted."))
		update_zone_view_images()
		RegisterSignal(src, COMSIG_MOVABLE_MOVED, PROC_REF(on_zone_view_moved))
	else
		to_chat(src, span_notice("Zone view <b>disabled</b>."))
		clear_zone_view_images()
		UnregisterSignal(src, COMSIG_MOVABLE_MOVED)


/mob/living/proc/on_zone_view_moved(atom/old_loc, dir, forced)
	SIGNAL_HANDLER
	if(!zone_view_mode)
		return
	// Only rebuild when the Z changes; area fills follow the area automatically.
	var/turf/old_turf = get_turf(old_loc)
	var/turf/new_turf = get_turf(src)
	if(!old_turf || !new_turf || old_turf.z != new_turf.z)
		update_zone_view_images()


/mob/living/proc/clear_zone_view_images()
	if(!client || !zone_view_images)
		return
	client.images -= zone_view_images
	QDEL_LIST(zone_view_images)
	zone_view_images = null


/**
 * Collect every /area that has turfs on the given Z and is worth showing.
 * Indoor zones always; outdoor /area/rimworld too (dimmer style).
 */
/mob/living/proc/collect_zones_on_z(z)
	var/list/found = list()
	// Prefer the registry — exact indoor zones created by Rust.
	for(var/key in GLOB.rimworld_rust_zones)
		var/area/rimworld/zone/Z = GLOB.rimworld_rust_zones[key]
		if(!Z || QDELETED(Z))
			continue
		// key is "z_id"
		if(findtext(key, "[z]_") != 1)
			continue
		found[Z] = TRUE

	// Also scan nearby turfs so outdoor cell areas appear even without registry.
	for(var/turf/T in RANGE_TURFS(12, src))
		if(T.z != z)
			continue
		var/area/A = T.loc
		if(!istype(A, /area/rimworld))
			continue
		found[A] = TRUE

	return found


/**
 * Pick a turf near the visual centre of an area for the maptext label.
 */
/mob/living/proc/zone_label_turf(area/A)
	if(!A)
		return null
	// Prefer bounds centre if this is a rust zone.
	if(istype(A, /area/rimworld/zone))
		var/area/rimworld/zone/Z = A
		if(Z.rust_area_id)
			var/turf/src_turf = get_turf(src)
			var/list/bounds = rustg_area_get_area_bounds(Z.rust_area_id, src_turf?.z || 0)
			if(bounds && bounds["size"])
				var/cx = round((bounds["min_x"] + bounds["max_x"]) * 0.5)
				var/cy = round((bounds["min_y"] + bounds["max_y"]) * 0.5)
				var/turf/centre = locate(cx, cy, src_turf?.z)
				if(centre && centre.loc == A)
					return centre
	// Fallback: first open turf in contents
	for(var/turf/T in A)
		return T
	return null


/mob/living/proc/update_zone_view_images()
	if(!client || !zone_view_mode)
		return

	clear_zone_view_images()
	zone_view_images = list()

	var/turf/origin = get_turf(src)
	if(!origin)
		return

	var/list/zones = collect_zones_on_z(origin.z)
	if(!length(zones))
		client.images += zone_view_images
		return

	for(var/area/A as anything in zones)
		if(QDELETED(A))
			continue

		var/is_indoor = istype(A, /area/rimworld/zone)
		var/fill_color = "#888888"
		var/fill_alpha = 40
		var/label_text = A.name

		if(is_indoor)
			var/area/rimworld/zone/Z = A
			fill_color = Z.zone_color || "#ffff00"
			fill_alpha = 70
			if(Z.rust_area_id)
				label_text = "[A.name]"
		else
			// Outdoor cell area — cooler muted tone
			fill_color = "#4a90d9"
			fill_alpha = 30

		var/image/fill = image('icons/area/areas_misc.dmi', A, "yellow")
		fill.plane = ABOVE_GAME_PLANE
		fill.layer = ABOVE_ALL_MOB_LAYER
		fill.color = fill_color
		fill.alpha = fill_alpha
		fill.appearance_flags = RESET_ALPHA | RESET_COLOR | KEEP_APART
		// loc is already A from image(..., A, ...); reinforce for clarity
		fill.loc = A
		zone_view_images += fill

		var/turf/label_turf = zone_label_turf(A)
		if(label_turf)
			var/image/label = image(loc = label_turf)
			label.plane = ABOVE_GAME_PLANE
			label.layer = ABOVE_ALL_MOB_LAYER + 0.1
			label.maptext = MAPTEXT({"<span style='color:[fill_color];text-align:center;font-size:8pt'>[label_text]</span>"})
			label.maptext_width = 128
			label.maptext_height = 20
			label.maptext_x = -48
			label.maptext_y = 2
			label.alpha = 255
			label.appearance_flags = RESET_ALPHA | KEEP_APART
			zone_view_images += label

	client.images += zone_view_images


/**
 * Admin / debug: force a full zone resync on the current Z and refresh view.
 */
/mob/living/verb/debug_resync_zones()
	set name = "Resync Zones (Debug)"
	set category = "Debug"
	if(!check_rights_for(client, R_DEBUG) && !check_rights_for(client, R_ADMIN))
		return
	var/turf/T = get_turf(src)
	if(!T)
		return
	var/area/rimworld/parent = null
	if(istype(T.loc, /area/rimworld) && !istype(T.loc, /area/rimworld/zone))
		parent = T.loc
	else if(istype(T.loc, /area/rimworld/zone))
		var/area/rimworld/zone/Z = T.loc
		parent = Z.parent_cell_area
	resync_rimworld_zones_on_z(T.z, parent)
	if(zone_view_mode)
		update_zone_view_images()
	to_chat(src, span_notice("Zones resynced on z=[T.z]."))
