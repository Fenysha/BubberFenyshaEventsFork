#define ZONE_VIEW_REFRESH_PERIOD (4 SECONDS)
#define ZONE_VIEW_PIN_TIME (15 SECONDS)

/mob/living
	/// ZONE_VIEW_* (the old boolean TRUE still means "zones").
	var/zone_view_mode = ZONE_VIEW_OFF
	var/list/zone_view_images = null
	/// turf -> number image
	var/list/zone_view_number_images = null
	var/list/zone_view_border_images = null
	var/area/zone_view_selected = null
	var/zone_view_pinned_until = 0
	var/turf/zone_view_last_turf = null

/// Images stored as turf -> image. client.images -= assoc removes KEYS, so use the values.
/proc/rw_assoc_values(list/L)
	var/list/out = list()
	for(var/key in L)
		out += L[key]
	return out

/// t in 0..1 -> red / yellow / green.
/proc/rw_heat_color(t)
	t = clamp(t, 0, 1)
	if(t < 0.5)
		return gradient("#e04545", "#e6d24a", index = t * 2)
	return gradient("#e6d24a", "#4fe07a", index = (t - 0.5) * 2)

/// Temperature (C) -> violet / blue / teal / green / amber / red.
/proc/rw_temperature_color(temp)
	var/list/stops = list(
		list(-40, "#7b5cff"),
		list(-10, "#3f9bff"),
		list(10, "#45d0c4"),
		list(21, "#5ce07a"),
		list(32, "#f2c14e"),
		list(45, "#ef476f"),
	)
	if(temp <= stops[1][1])
		return stops[1][2]
	for(var/i in 2 to length(stops))
		var/list/a = stops[i - 1]
		var/list/b = stops[i]
		if(temp <= b[1])
			return gradient(a[2], b[2], index = (temp - a[1]) / (b[1] - a[1]))
	return stops[length(stops)][2]

/// Fill colour of an area for a mode.
/proc/rw_zone_view_color(area/A, mode)
	var/is_zone = istype(A, /area/rimworld/zone)
	switch(mode)
		if(ZONE_VIEW_ZONES)
			if(is_zone)
				var/area/rimworld/zone/Z = A
				return Z.zone_color || "#ffff00"
			return "#4a90d9"
		if(ZONE_VIEW_BEAUTY)
			if(is_zone)
				var/area/rimworld/zone/Z = A
				return rw_heat_color((Z.rw_room_beauty + 5) / 10)
			return "#808890"
		if(ZONE_VIEW_CLEAN)
			if(is_zone)
				var/area/rimworld/zone/Z = A
				return rw_heat_color((Z.rw_room_cleanliness + 3) / 4)
			return "#808890"
		if(ZONE_VIEW_TEMP)
			return rw_temperature_color(A.rw_get_temperature())
	return "#888888"

/// Text of the label shown on the map for an area.
/proc/rw_zone_view_label(area/A, mode)
	if(!istype(A, /area/rimworld/zone))
		if(mode == ZONE_VIEW_TEMP)
			return "Outdoors<br>[round(A.rw_get_temperature(), 0.1)]&deg;C"
		return "Outdoors"
	var/area/rimworld/zone/Z = A
	var/role = Z.rw_role ? Z.rw_role.name : "Room"
	switch(mode)
		if(ZONE_VIEW_BEAUTY)
			return "[role]<br>beauty [round(Z.rw_room_beauty, 0.1)] ([Z.rw_get_beauty_label()])"
		if(ZONE_VIEW_CLEAN)
			return "[role]<br>clean [round(Z.rw_room_cleanliness, 0.1)] ([Z.rw_get_clean_label()])"
		if(ZONE_VIEW_TEMP)
			return "[role]<br>[round(Z.rw_get_temperature(), 0.1)]&deg;C"
	return "[role]<br>[Z.rw_size] tiles"

/mob/living/verb/toggle_zone_view_mode()
	set name = "Cycle Zone View Mode"
	set category = "IC"
	set_zone_view_mode((zone_view_mode + 1) % (ZONE_VIEW_MODE_COUNT + 1))

/mob/living/verb/select_zone_view_mode()
	set name = "Zone View Mode..."
	set category = "IC"
	var/list/choices = list(
		"Off" = ZONE_VIEW_OFF,
		"Zones" = ZONE_VIEW_ZONES,
		"Beauty" = ZONE_VIEW_BEAUTY,
		"Cleanliness" = ZONE_VIEW_CLEAN,
		"Temperature" = ZONE_VIEW_TEMP,
	)
	var/choice = tgui_input_list(src, "What should the zone view show?", "Zone View", choices)
	if(isnull(choice))
		return
	set_zone_view_mode(choices[choice])

/// Back-compat for old callers.
/mob/living/proc/toggle_zone_view()
	set_zone_view_mode(zone_view_mode ? ZONE_VIEW_OFF : ZONE_VIEW_ZONES)

/mob/living/proc/zone_view_mode_name(mode = zone_view_mode)
	switch(mode)
		if(ZONE_VIEW_ZONES)
			return "zones"
		if(ZONE_VIEW_BEAUTY)
			return "beauty"
		if(ZONE_VIEW_CLEAN)
			return "cleanliness"
		if(ZONE_VIEW_TEMP)
			return "temperature"
	return "off"

/mob/living/proc/set_zone_view_mode(new_mode)
	var/old_mode = zone_view_mode
	zone_view_mode = clamp(round(new_mode), ZONE_VIEW_OFF, ZONE_VIEW_MODE_COUNT)
	if(zone_view_mode == old_mode)
		return

	if(zone_view_mode == ZONE_VIEW_OFF)
		to_chat(src, span_notice("Zone view <b>disabled</b>."))
		clear_zone_view_images()
		UnregisterSignal(src, list(COMSIG_MOVABLE_MOVED, COMSIG_MOB_EXAMINATE))
		return

	if(old_mode == ZONE_VIEW_OFF)
		RegisterSignal(src, COMSIG_MOVABLE_MOVED, PROC_REF(on_zone_view_moved))
		RegisterSignal(src, COMSIG_MOB_EXAMINATE, PROC_REF(on_zone_view_examinate))
	to_chat(src, span_notice("Zone view: <b>[zone_view_mode_name()]</b>. Examine a tile or object to inspect its zone."))
	zone_view_last_turf = null
	update_zone_view_images()
	update_zone_view_borders(auto = TRUE)
	update_zone_view_numbers()
	zone_view_schedule_refresh()

/mob/living/proc/zone_view_schedule_refresh()
	addtimer(CALLBACK(src, PROC_REF(zone_view_refresh_tick)), ZONE_VIEW_REFRESH_PERIOD, TIMER_UNIQUE | TIMER_OVERRIDE | TIMER_DELETE_ME)

/// Values drift (stats recalc, temperature moves), so rebuild periodically.
/mob/living/proc/zone_view_refresh_tick()
	if(!zone_view_mode || QDELETED(src))
		return
	update_zone_view_images()
	update_zone_view_numbers()
	zone_view_schedule_refresh()

/mob/living/proc/on_zone_view_moved(atom/old_loc, dir, forced)
	SIGNAL_HANDLER
	if(!zone_view_mode)
		return
	var/turf/old_turf = get_turf(old_loc)
	var/turf/new_turf = get_turf(src)
	if(!new_turf)
		return
	if(!old_turf || old_turf.z != new_turf.z)
		update_zone_view_images()
	update_zone_view_borders(auto = TRUE)
	update_zone_view_numbers()

/mob/living/proc/clear_zone_view_images()
	if(client)
		if(zone_view_images)
			client.images -= zone_view_images
		if(zone_view_number_images)
			client.images -= rw_assoc_values(zone_view_number_images)
		if(zone_view_border_images)
			client.images -= zone_view_border_images
	QDEL_LIST(zone_view_images)
	zone_view_images = null
	if(zone_view_number_images)
		QDEL_LIST_ASSOC_VAL(zone_view_number_images)
		zone_view_number_images = null
	QDEL_LIST(zone_view_border_images)
	zone_view_border_images = null
	zone_view_selected = null
	zone_view_last_turf = null

/**
 * Every /area that has turfs on the given Z and is worth showing.
 * Indoor zones from the registry; outdoor cell areas seen nearby.
 */
/mob/living/proc/collect_zones_on_z(z)
	var/list/found = list()
	for(var/key in GLOB.rimworld_rust_zones)
		var/area/rimworld/zone/Z = GLOB.rimworld_rust_zones[key]
		if(!Z || QDELETED(Z))
			continue
		if(findtext(key, "[z]_") != 1)
			continue
		found[Z] = TRUE
	for(var/turf/T in RANGE_TURFS(12, src))
		if(T.z != z)
			continue
		var/area/A = T.loc
		if(istype(A, /area/rimworld))
			found[A] = TRUE
	return found

/// Pick a turf near the visual centre of an area for the label.
/mob/living/proc/zone_label_turf(area/A)
	if(!A)
		return null
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
	for(var/turf/T in A)
		return T
	return null

/mob/living/proc/update_zone_view_images()
	if(!client || !zone_view_mode)
		return

	if(zone_view_images)
		client.images -= zone_view_images
		QDEL_LIST(zone_view_images)
	zone_view_images = list()

	var/turf/origin = get_turf(src)
	if(!origin)
		return

	var/list/zones = collect_zones_on_z(origin.z)
	for(var/area/A as anything in zones)
		if(QDELETED(A))
			continue
		var/is_indoor = istype(A, /area/rimworld/zone)
		var/fill_color = rw_zone_view_color(A, zone_view_mode)
		// Indoor rooms are more opaque than the huge outdoor area.
		var/fill_alpha = is_indoor ? 80 : 28

		var/image/fill = image('icons/area/areas_misc.dmi', A, "yellow")
		fill.plane = ABOVE_GAME_PLANE
		fill.layer = ABOVE_ALL_MOB_LAYER
		fill.color = fill_color
		fill.alpha = fill_alpha
		fill.appearance_flags = RESET_ALPHA | RESET_COLOR | KEEP_APART
		fill.loc = A
		zone_view_images += fill

		// Outdoor area is one gigantic blob: label it only when we stand in it.
		if(!is_indoor && get_area(src) != A)
			continue
		var/turf/label_turf = zone_label_turf(A)
		if(!label_turf)
			continue
		var/image/label = image(loc = label_turf)
		label.plane = ABOVE_GAME_PLANE
		label.layer = ABOVE_ALL_MOB_LAYER + 0.1
		label.maptext = MAPTEXT("<span style='color:[fill_color];text-align:center;font-size:7pt'>[rw_zone_view_label(A, zone_view_mode)]</span>")
		label.maptext_width = 160
		label.maptext_height = 36
		label.maptext_x = -64
		label.maptext_y = 2
		label.appearance_flags = RESET_ALPHA | KEEP_APART
		zone_view_images += label

	client.images += zone_view_images

// ---------------------------------------------------------------------
// Borders
// ---------------------------------------------------------------------

/// dir -> 2px white edge strip, built once. Tinted per zone with image.color.
GLOBAL_LIST_EMPTY(rw_zone_edge_icons)

/proc/rw_get_zone_edge_icon(dir)
	if(!length(GLOB.rw_zone_edge_icons))
		for(var/d in GLOB.cardinals)
			// Start from a solid tile, wipe it, then draw only the requested strip.
			var/icon/I = icon('icons/area/areas_misc.dmi', "yellow")
			I.DrawBox(null, 1, 1, 32, 32)
			switch(d)
				if(NORTH)
					I.DrawBox("#ffffff", 1, 31, 32, 32)
				if(SOUTH)
					I.DrawBox("#ffffff", 1, 1, 32, 2)
				if(EAST)
					I.DrawBox("#ffffff", 31, 1, 32, 32)
				if(WEST)
					I.DrawBox("#ffffff", 1, 1, 2, 32)
			GLOB.rw_zone_edge_icons[d] = I
	return GLOB.rw_zone_edge_icons[dir]

/mob/living/proc/clear_zone_view_borders()
	if(zone_view_border_images)
		if(client)
			client.images -= zone_view_border_images
		QDEL_LIST(zone_view_border_images)
	zone_view_border_images = null
	zone_view_selected = null

/**
 * Outlines a zone. Only enclosed zones get an outline (the outdoor area is the whole map).
 */
/mob/living/proc/draw_zone_view_border(area/rimworld/zone/Z)
	clear_zone_view_borders()
	if(!client || !istype(Z) || QDELETED(Z))
		return
	zone_view_selected = Z
	zone_view_border_images = list()

	var/color = rw_zone_view_color(Z, zone_view_mode == ZONE_VIEW_OFF ? ZONE_VIEW_ZONES : zone_view_mode)
	// Always draw the outline in a bright tone of the zone colour so it reads over the fill.
	var/outline = gradient(color, "#ffffff", index = 0.55)

	for(var/turf/T as anything in Z)
		for(var/dir in GLOB.cardinals)
			var/turf/N = get_step(T, dir)
			if(N && N.loc == Z)
				continue
			var/image/edge = image(rw_get_zone_edge_icon(dir), T)
			edge.plane = ABOVE_GAME_PLANE
			edge.layer = ABOVE_ALL_MOB_LAYER + 0.05
			edge.color = outline
			edge.alpha = 235
			edge.appearance_flags = RESET_ALPHA | RESET_COLOR | KEEP_APART
			zone_view_border_images += edge
	client.images += zone_view_border_images

/// auto = TRUE: follow the zone we stand in unless an examine pinned another one.
/mob/living/proc/update_zone_view_borders(auto = FALSE)
	if(!zone_view_mode)
		return
	if(auto && world.time < zone_view_pinned_until)
		return
	var/area/A = get_area(src)
	if(A == zone_view_selected)
		return
	if(istype(A, /area/rimworld/zone))
		draw_zone_view_border(A)
	else
		clear_zone_view_borders()

/// Examine pins the outline on the examined zone for a while.
/mob/living/proc/pin_zone_view_zone(area/A)
	if(!istype(A, /area/rimworld/zone))
		return
	zone_view_pinned_until = world.time + ZONE_VIEW_PIN_TIME
	if(A != zone_view_selected)
		draw_zone_view_border(A)
	addtimer(CALLBACK(src, PROC_REF(zone_view_unpin)), ZONE_VIEW_PIN_TIME + 1, TIMER_UNIQUE | TIMER_OVERRIDE | TIMER_DELETE_ME)

/mob/living/proc/zone_view_unpin()
	if(world.time >= zone_view_pinned_until)
		update_zone_view_borders(auto = TRUE)


/// Text + colour to print on a turf in the current mode, or null to print nothing.
/mob/living/proc/zone_view_turf_text(turf/T)
	switch(zone_view_mode)
		if(ZONE_VIEW_BEAUTY)
			var/b = T.rw_tile_beauty()
			return list(round(b, 0.1), rw_heat_color((b + 5) / 10))
		if(ZONE_VIEW_CLEAN)
			var/c = T.rw_tile_cleanliness()
			return list(round(c, 0.1), rw_heat_color((c + 3) / 4))
		if(ZONE_VIEW_TEMP)
			// Air temperature is uniform per zone, so sprinkle it instead of covering every tile.
			if((T.x + T.y) % 4)
				return null
			var/temp = 20
			if(istype(T.loc, /area/rimworld))
				var/area/rimworld/rw_area = T.loc
				temp = rw_area.rw_get_temperature()
			return list("[round(temp)]&deg;", rw_temperature_color(temp))
	return null

/mob/living/proc/update_zone_view_numbers()
	if(!client)
		return
	var/turf/center = get_turf(src)
	if(!center || zone_view_mode < ZONE_VIEW_BEAUTY)
		if(zone_view_number_images)
			client.images -= rw_assoc_values(zone_view_number_images)
			QDEL_LIST_ASSOC_VAL(zone_view_number_images)
			zone_view_number_images = null
		return

	if(!zone_view_number_images)
		zone_view_number_images = list()

	var/list/wanted = list()
	for(var/turf/T as anything in RANGE_TURFS(ZONE_VIEW_NUMBER_RADIUS, center))
		if(T.density)
			continue
		wanted[T] = TRUE

	// Drop images that left the radius.
	for(var/turf/old as anything in zone_view_number_images)
		if(wanted[old])
			continue
		var/image/gone = zone_view_number_images[old]
		client.images -= gone
		zone_view_number_images -= old
		qdel(gone)

	for(var/turf/T as anything in wanted)
		var/list/entry = zone_view_turf_text(T)
		var/image/img = zone_view_number_images[T]
		if(!entry)
			if(img)
				client.images -= img
				zone_view_number_images -= T
				qdel(img)
			continue
		var/maptext_value = MAPTEXT("<span style='color:[entry[2]];text-align:center;font-size:6pt'>[entry[1]]</span>")
		if(img)
			// Same image object: changing maptext updates the client without re-adding.
			if(img.maptext != maptext_value)
				img.maptext = maptext_value
			continue
		img = image(loc = T)
		img.plane = ABOVE_GAME_PLANE
		img.layer = ABOVE_ALL_MOB_LAYER + 0.2
		img.maptext = maptext_value
		img.maptext_width = 32
		img.maptext_height = 12
		img.maptext_y = 10
		img.appearance_flags = RESET_ALPHA | KEEP_APART
		zone_view_number_images[T] = img
		client.images += img

// ---------------------------------------------------------------------
// Examine integration
// ---------------------------------------------------------------------

/**
 * Zone info for whatever the viewer examines (turf or object).
 * Hooked through COMSIG_MOB_EXAMINATE so no vanilla examine() has to be overridden.
 */
/mob/living/proc/on_zone_view_examinate(datum/source, atom/target)
	SIGNAL_HANDLER
	if(!zone_view_mode || QDELETED(target))
		return
	// The signal fires before the normal examine text; wait a tick so our block comes after it.
	addtimer(CALLBACK(src, PROC_REF(zone_view_show_examine), target), 1)

/mob/living/proc/zone_view_show_examine(atom/target)
	if(!zone_view_mode || QDELETED(target) || QDELETED(src))
		return
	var/list/lines = zone_view_examine_lines(target)
	if(length(lines))
		to_chat(src, jointext(lines, "<br>"))

/// Lines describing the zone (and the object's own contribution) of an examined atom.
/mob/living/proc/zone_view_examine_lines(atom/target)
	var/list/lines = list()
	var/turf/T = get_turf(target)
	if(!T)
		return lines
	var/area/A = T.loc

	// The object's own zone-relevant values.
	if(isobj(target))
		var/obj/O = target
		var/list/bits = list()
		if(O.rw_beauty)
			bits += "beauty [O.rw_beauty > 0 ? "+" : ""][O.rw_beauty]"
		if(O.rw_filth)
			bits += "filth [O.rw_filth]"
		if(O.rw_heat_output)
			bits += "heat [O.rw_heat_output]W"
		if(length(bits))
			lines += span_notice("[O.name]: [jointext(bits, ", ")].")

	if(istype(A, /area/rimworld/zone))
		var/area/rimworld/zone/Z = A
		lines += Z.rw_get_info_lines(src)
		pin_zone_view_zone(Z)
	else if(istype(A, /area/rimworld))
		var/area/rimworld/R = A
		lines += span_notice("<b>Zone:</b> Outdoors.")
		if(R.cell)
			lines += span_notice("Climate: [R.cell.get_climate_summary()].")
		lines += span_notice("Surroundings beauty: <b>[round(T.rw_local_beauty(), 0.1)]</b>.")

	// Tile-level numbers, always useful.
	lines += span_notice("This tile: beauty <b>[round(T.rw_tile_beauty(), 0.1)]</b>, cleanliness <b>[round(T.rw_tile_cleanliness(), 0.1)]</b>.")
	return lines

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
		update_zone_view_borders()
	to_chat(src, span_notice("Zones resynced on z=[T.z]."))
