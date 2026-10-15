/// Pixel size of the little resource icons and the gap between them.
#define RW_PLAN_COST_ICON_SCALE 0.5
#define RW_PLAN_COST_STEP 17
#define RW_PLAN_COST_PER_ROW 6
/// How often the "can I afford this" tint is re-checked while hovering.
#define RW_PLAN_RESOURCE_REFRESH (1 SECONDS)

/datum/component/rw_build_plan
	dupe_mode = COMPONENT_DUPE_UNIQUE

	var/datum/building_blueprint/blueprint
	var/dir = NORTH
	var/turf/hover_turf
	var/material_path

	/// Placement is physically possible on the hovered turf.
	var/placement_valid = FALSE
	/// The user currently carries everything the blueprint needs (or is in admin instant mode).
	var/can_afford = TRUE

	/**
	 * Everything below is a client image attached directly to a turf. Nothing is spawned in the
	 * world, nothing is animated per mouse move - the projection simply hops from turf to turf,
	 * so it is always snapped to the grid and never jitters.
	 */
	var/list/image/projection_images = list()
	var/list/image/cost_images = list()
	/// One entry per cost icon: path, amount, ok, plate/icon/text images.
	var/list/list/cost_slots = list()
	var/turf/cost_anchor
	var/cost_built = FALSE
	var/image/cancel_marker
	var/next_resource_check = 0

	var/atom/movable/screen/fullscreen/cursor_catcher/catcher
	var/last_mouse_params

	/// PLACE or CANCEL
	var/mode = RW_BUILD_MODE_PLACE

	/// FALSE = single-click place, TRUE = area fill
	var/fill_mode = FALSE

	// Area selection
	var/turf/corner_a
	var/turf/corner_b
	var/list/image/region_preview = list()

/datum/component/rw_build_plan/Initialize(datum/building_blueprint/bp, material_path = null, starting_mode = RW_BUILD_MODE_PLACE)
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE

	if(starting_mode == RW_BUILD_MODE_CANCEL)
		mode = RW_BUILD_MODE_CANCEL
		blueprint = null
		src.material_path = null
	else
		if(!istype(bp))
			return COMPONENT_INCOMPATIBLE
		blueprint = bp
		mode = starting_mode

		if(bp.is_stuffed())
			if(!rw_blueprint_allows_stuff(bp, material_path))
				material_path = rw_default_stuff_for(bp)
			src.material_path = material_path
		else
			src.material_path = null

	var/mob/living/L = parent
	dir = L.dir || NORTH

	if(L.client)
		catcher = L.overlay_fullscreen("rw_build_plan", /atom/movable/screen/fullscreen/cursor_catcher, 0)
		catcher.assign_to_mob(L)

	RegisterSignal(L, COMSIG_MOB_CLICKON, PROC_REF(on_clicked), TRUE)
	RegisterSignal(L, COMSIG_LIVING_DEATH, PROC_REF(on_hard_cancel))
	RegisterSignal(L, COMSIG_QDELETING, PROC_REF(on_hard_cancel))

	START_PROCESSING(SSsuperfast_process, src)

	var/modename = (mode == RW_BUILD_MODE_CANCEL) ? "Cancel" : bp.name
	L.balloon_alert(L, "[modename] ([fill_mode ? "Fill" : "Place"])")
	to_chat(L, span_notice("<b>[modename]</b> — [fill_mode ? "Fill" : "Place"] mode.<br>\
		• LMB — place / select corners<br>\
		• <b>Alt + RMB</b> — toggle Place ↔ Fill<br>\
		• Alt + LMB — rotate<br>\
		• RMB — cancel[L.rw_instant_build_active() ? "<br>• <b>Instant build is ON</b>" : ""]"))

/datum/component/rw_build_plan/Destroy(force)
	STOP_PROCESSING(SSsuperfast_process, src)
	clear_visuals()
	clear_region_preview()

	var/mob/living/L = parent
	if(L)
		L.clear_fullscreen("rw_build_plan")
		UnregisterSignal(L, list(COMSIG_MOB_CLICKON, COMSIG_LIVING_DEATH, COMSIG_QDELETING))

	catcher = null
	blueprint = null
	hover_turf = null
	cost_anchor = null
	last_mouse_params = null
	corner_a = null
	corner_b = null
	return ..()

/datum/component/rw_build_plan/proc/on_hard_cancel(datum/source)
	SIGNAL_HANDLER
	qdel(src)


/datum/component/rw_build_plan/process()
	var/mob/living/L = parent
	if(QDELETED(L) || !L.client || !catcher)
		qdel(src)
		return

	if(catcher.mouse_params != last_mouse_params)
		last_mouse_params = catcher.mouse_params
		if(last_mouse_params)
			catcher.calculate_params()

	var/turf/under_cursor = catcher.given_turf
	if(!under_cursor)
		return

	// Only a change of turf does any work. Sub-tile mouse movement is ignored on purpose.
	if(under_cursor != hover_turf)
		set_hover_turf(under_cursor)
		return

	if(mode != RW_BUILD_MODE_CANCEL && world.time >= next_resource_check)
		refresh_affordability()


/datum/component/rw_build_plan/proc/on_clicked(atom/source, atom/clicked_on, modifiers)
	SIGNAL_HANDLER

	var/mob/living/L = parent
	if(!L || L != source)
		return

	// Click on existing construction part
	if(istype(clicked_on, /obj/structure/rw_construction_part) && !LAZYACCESS(modifiers, ALT_CLICK))
		if(LAZYACCESS(modifiers, RIGHT_CLICK))
			qdel(src)
		return

	. = COMSIG_MOB_CANCEL_CLICKON

	var/turf/T = get_turf(clicked_on) || hover_turf || catcher?.given_turf
	if(!T)
		return

	// Alt + RMB → toggle Place ↔ Fill
	if(LAZYACCESS(modifiers, RIGHT_CLICK) && LAZYACCESS(modifiers, ALT_CLICK))
		fill_mode = !fill_mode
		clear_region_preview()
		corner_a = null
		corner_b = null
		L.balloon_alert(L, fill_mode ? "Fill mode" : "Place mode")
		return

	// Normal RMB
	if(LAZYACCESS(modifiers, RIGHT_CLICK))
		if(corner_a || corner_b)
			clear_region_preview()
			corner_a = null
			corner_b = null
			L.balloon_alert(L, "selection cancelled")
			return
		L.balloon_alert(L, "planning cancelled")
		qdel(src)
		return

	// Alt + LMB → rotate
	if(LAZYACCESS(modifiers, ALT_CLICK) && LAZYACCESS(modifiers, LEFT_CLICK))
		rotate()
		return

	// LMB
	if(LAZYACCESS(modifiers, LEFT_CLICK))
		if(fill_mode)
			handle_area_click(T)
		else
			if(mode == RW_BUILD_MODE_PLACE)
				try_place(T)
			else
				cancel_at(T)


/datum/component/rw_build_plan/proc/handle_area_click(turf/T)
	var/mob/living/L = parent

	if(!corner_a)
		corner_a = T
		add_region_marker(T, "greenOverlay")
		L.balloon_alert(L, "corner A")
		return

	if(!corner_b)
		corner_b = T
		add_region_marker(T, "blueOverlay")

		var/turf/start = locate(min(corner_a.x, T.x), min(corner_a.y, T.y), corner_a.z)
		var/turf/end   = locate(max(corner_a.x, T.x), max(corner_a.y, T.y), corner_a.z)
		highlight_region(block(start, end))
		L.balloon_alert(L, "corner B — click to confirm")
		return

	var/turf/start = locate(min(corner_a.x, corner_b.x), min(corner_a.y, corner_b.y), corner_a.z)
	var/turf/end   = locate(max(corner_a.x, corner_b.x), max(corner_a.y, corner_b.y), corner_a.z)
	var/list/turf/region = block(start, end)

	if(mode == RW_BUILD_MODE_PLACE)
		fill_region(region)
	else
		cancel_region(region)

	clear_region_preview()
	corner_a = null
	corner_b = null

/datum/component/rw_build_plan/proc/fill_region(list/turf/region)
	var/mob/living/L = parent
	var/placed = 0
	for(var/turf/T as anything in region)
		if(try_place(T, silent = TRUE))
			placed++
	L.balloon_alert(L, "filled [placed] tiles")

/datum/component/rw_build_plan/proc/cancel_region(list/turf/region)
	var/mob/living/L = parent
	var/removed = 0
	for(var/turf/T as anything in region)
		removed += cancel_at(T, silent = TRUE)
	L.balloon_alert(L, "removed [removed] blueprints")

/datum/component/rw_build_plan/proc/cancel_at(turf/T, silent = FALSE)
	. = 0
	for(var/obj/structure/rw_construction_part/P in T)
		if(P.site)
			P.site.cancel(null)
			.++
	if(. && !silent)
		var/mob/living/L = parent
		L?.balloon_alert(L, "removed")


// =====================================================================
// VISUALS
// =====================================================================

/// Removes every image this component put on the client.
/datum/component/rw_build_plan/proc/clear_visuals()
	var/mob/living/L = parent
	if(L?.client)
		L.client.images -= projection_images
		L.client.images -= cost_images
		if(cancel_marker)
			L.client.images -= cancel_marker
	projection_images.Cut()
	cost_images.Cut()
	cost_slots.Cut()
	cost_anchor = null
	cost_built = FALSE
	cancel_marker = null

/datum/component/rw_build_plan/proc/check_placement(turf/origin)
	if(mode == RW_BUILD_MODE_CANCEL)
		return TRUE
	if(!blueprint || !origin)
		return FALSE
	if(blueprint.is_multiblock())
		return rw_multiblock_can_build(blueprint.multiblock_layout_id, origin, dir, null)
	if(origin.density)
		return FALSE
	for(var/atom/movable/AM in origin)
		if(istype(AM, /obj/effect))
			continue
		if(AM.density || istype(AM, /obj/machinery) || istype(AM, /obj/structure))
			return FALSE
	return TRUE

/datum/component/rw_build_plan/proc/set_hover_turf(turf/T)
	if(!T || T == hover_turf)
		return
	hover_turf = T

	var/mob/living/L = parent
	if(!L?.client)
		return

	if(mode == RW_BUILD_MODE_CANCEL)
		if(!cancel_marker)
			cancel_marker = image('icons/turf/overlays.dmi', T, "redOverlay")
			cancel_marker.plane = ABOVE_LIGHTING_PLANE
			L.client.images |= cancel_marker
		else
			cancel_marker.loc = T
		return

	placement_valid = check_placement(T)
	update_projection(T)
	refresh_affordability(force = TRUE)

/// Cell entries of the blueprint at `origin`, without cells that fall outside the map.
/datum/component/rw_build_plan/proc/get_entries(turf/origin)
	var/list/entries = list()
	for(var/list/entry as anything in blueprint.get_cell_entries(origin, dir))
		if(entry["turf"])
			entries += list(entry)
	return entries

/datum/component/rw_build_plan/proc/update_projection(turf/origin, force_rebuild = FALSE)
	var/mob/living/L = parent
	if(!L?.client || !blueprint || !origin)
		return

	var/list/entries = get_entries(origin)
	if(!length(entries))
		clear_visuals()
		return

	if(force_rebuild || length(projection_images) != length(entries))
		rebuild_projection(entries)
	else
		// Same shape, new place: just move the existing images onto the new turfs.
		for(var/i in 1 to length(entries))
			var/image/I = projection_images[i]
			var/list/entry = entries[i]
			I.loc = entry["turf"]

	update_cost_icons(entries)

/datum/component/rw_build_plan/proc/rebuild_projection(list/entries)
	var/mob/living/L = parent
	L.client.images -= projection_images
	projection_images.Cut()

	for(var/list/entry as anything in entries)
		var/image/I = image(entry["icon"], entry["turf"], entry["icon_state"], MOB_LAYER + 0.1)
		I.plane = MOB_PLANE
		I.dir = dir
		I.alpha = RW_HOLOGRAM_ALPHA
		I.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
		projection_images += I
		L.client.images |= I

	update_projection_color()

/// Blue = fine, red = can't place here, amber = placeable but you don't carry the resources, violet = admin instant.
/datum/component/rw_build_plan/proc/get_state_color()
	var/mob/living/L = parent
	if(!placement_valid)
		return RW_PLAN_COLOR_BAD
	if(L.rw_instant_build_active())
		return RW_PLAN_COLOR_ADMIN
	if(!can_afford)
		return RW_PLAN_COLOR_NO_RES
	return RW_PLAN_COLOR_OK

/datum/component/rw_build_plan/proc/update_projection_color()
	var/datum/material/mat = material_path ? GET_MATERIAL_REF(material_path) : null
	var/ghost_color = mat?.color ? mat.color : "#ffffff"
	ghost_color = color_interpolate(ghost_color, get_state_color(), 0.45)
	for(var/image/I as anything in projection_images)
		I.color = ghost_color


// ---- resource icons ----------------------------------------------------

/// The turf the cost row hangs above: the middle tile of the top row of the projection.
/datum/component/rw_build_plan/proc/get_cost_anchor(list/entries)
	var/max_y = 0
	var/min_x = 0
	var/max_x = 0
	for(var/list/entry as anything in entries)
		var/turf/T = entry["turf"]
		if(T.y > max_y)
			max_y = T.y
			min_x = T.x
			max_x = T.x
		else if(T.y == max_y)
			min_x = min(min_x, T.x)
			max_x = max(max_x, T.x)

	var/target_x = round((min_x + max_x) / 2)
	var/turf/best
	for(var/list/entry as anything in entries)
		var/turf/T = entry["turf"]
		if(T.y != max_y)
			continue
		if(!best || abs(T.x - target_x) < abs(best.x - target_x))
			best = T
	return best

/datum/component/rw_build_plan/proc/update_cost_icons(list/entries)
	if(!cost_built)
		build_cost_icons(entries)
		return

	var/turf/anchor = get_cost_anchor(entries)
	if(!anchor || anchor == cost_anchor)
		return
	cost_anchor = anchor
	for(var/image/I as anything in cost_images)
		I.loc = anchor

/// Builds the row of tiny resource icons (icon + availability plate + amount). No names, no walls of text.
/datum/component/rw_build_plan/proc/build_cost_icons(list/entries)
	var/mob/living/L = parent
	cost_built = TRUE

	var/list/needs = blueprint.get_needs(material_path)
	if(!length(needs))
		return
	var/turf/anchor = get_cost_anchor(entries)
	if(!anchor)
		return
	cost_anchor = anchor

	var/total = 0
	for(var/path in needs)
		if(ispath(path, /obj/item))
			total++

	var/index = 0
	for(var/path in needs)
		if(!ispath(path, /obj/item))
			continue
		var/obj/item/item_type = path

		var/row = round(index / RW_PLAN_COST_PER_ROW)
		var/col = index % RW_PLAN_COST_PER_ROW
		var/in_row = min(RW_PLAN_COST_PER_ROW, total - row * RW_PLAN_COST_PER_ROW)
		var/px = round((col - (in_row - 1) / 2) * RW_PLAN_COST_STEP)
		// 25px lifts the 16px icon just above the top edge of the tile.
		var/py = 25 + row * RW_PLAN_COST_STEP
		index++

		var/matrix/small = matrix().Scale(RW_PLAN_COST_ICON_SCALE)

		var/image/plate = image('icons/turf/overlays.dmi', anchor, "greenOverlay", MOB_LAYER + 0.2)
		plate.plane = MOB_PLANE
		plate.transform = small
		plate.pixel_x = px
		plate.pixel_y = py
		plate.alpha = 150
		plate.mouse_opacity = MOUSE_OPACITY_TRANSPARENT

		var/image/icon_img = image(initial(item_type.icon), anchor, initial(item_type.icon_state), MOB_LAYER + 0.3)
		icon_img.plane = MOB_PLANE
		icon_img.transform = small
		icon_img.pixel_x = px
		icon_img.pixel_y = py
		icon_img.mouse_opacity = MOUSE_OPACITY_TRANSPARENT

		var/image/text_img = image(null, anchor, null, MOB_LAYER + 0.4)
		text_img.plane = MOB_PLANE
		text_img.pixel_x = px
		text_img.pixel_y = py
		text_img.maptext_width = 32
		text_img.maptext_height = 10
		// Right-aligned inside the little icon's lower right corner.
		text_img.maptext_x = -8
		text_img.maptext_y = 8
		text_img.mouse_opacity = MOUSE_OPACITY_TRANSPARENT

		cost_slots += list(list(
			"path" = path,
			"amount" = needs[path],
			"ok" = null,
			"plate" = plate,
			"icon" = icon_img,
			"text" = text_img,
		))
		cost_images += plate
		cost_images += icon_img
		cost_images += text_img
		L.client.images |= plate
		L.client.images |= icon_img
		L.client.images |= text_img

/// Re-checks what the user carries and recolours the cost icons and the projection.
/datum/component/rw_build_plan/proc/refresh_affordability(force = FALSE)
	if(mode == RW_BUILD_MODE_CANCEL || !blueprint)
		return
	next_resource_check = world.time + RW_PLAN_RESOURCE_REFRESH

	var/mob/living/L = parent
	var/instant = L.rw_instant_build_active()
	var/list/contents = instant ? null : L.get_all_contents()
	var/all_ok = TRUE

	for(var/list/slot as anything in cost_slots)
		var/amount = slot["amount"]
		var/have = instant ? amount : rw_count_items_of_type(L, slot["path"], contents)
		var/ok = have >= amount
		if(!ok)
			all_ok = FALSE
		if(!force && slot["ok"] == ok)
			continue
		slot["ok"] = ok

		var/image/plate = slot["plate"]
		plate.icon_state = ok ? "greenOverlay" : "redOverlay"
		var/image/icon_img = slot["icon"]
		icon_img.alpha = ok ? 255 : 170
		var/image/text_img = slot["text"]
		// A lone item needs no number.
		var/count_color = ok ? "#a6ffa6" : "#ff8c8c"
		if(amount > 1)
			text_img.maptext = "<div align='right' style='font-family: Small Fonts; font-size: 6px; -dm-text-outline: 1px #000; color: [count_color];'>[amount]</div>"
		else
			text_img.maptext = ""

	var/old = can_afford
	can_afford = all_ok
	if(force || old != can_afford)
		update_projection_color()

/datum/component/rw_build_plan/proc/rotate()
	if(mode == RW_BUILD_MODE_CANCEL || !blueprint?.can_rotate)
		return
	dir = turn(dir, -90)
	var/mob/living/L = parent
	L?.balloon_alert(L, dir2text(dir))
	if(hover_turf)
		placement_valid = check_placement(hover_turf)
		update_projection(hover_turf, force_rebuild = TRUE)
		update_projection_color()

/datum/component/rw_build_plan/proc/try_place(turf/target, silent = FALSE)
	if(mode == RW_BUILD_MODE_CANCEL)
		return FALSE
	if(!target || !blueprint)
		return FALSE

	var/mob/living/L = parent
	if(!check_placement(target))
		if(!silent)
			L?.balloon_alert(L, "can't place here!")
		return FALSE
	if(!blueprint.build_path && !blueprint.is_multiblock())
		if(!silent)
			L?.balloon_alert(L, "invalid blueprint!")
		return FALSE

	// Already has a blueprint
	for(var/obj/structure/rw_construction_part/P in target)
		if(P.site)
			return FALSE

	var/datum/rw_construction_site/site = new /datum/rw_construction_site(blueprint, target, dir, material_path)

	// Admin instant build: re-checked here, not only in the UI.
	if(L?.rw_instant_build_active())
		site.complete_instantly(L)
		return TRUE

	if(!silent)
		L?.balloon_alert(L, "placed")
	return TRUE


/datum/component/rw_build_plan/proc/add_region_marker(turf/T, state)
	var/mob/living/L = parent
	if(!L?.client)
		return
	var/image/I = image('icons/turf/overlays.dmi', T, state)
	I.plane = ABOVE_LIGHTING_PLANE
	region_preview += I
	L.client.images |= I

/datum/component/rw_build_plan/proc/highlight_region(list/turf/region)
	var/mob/living/L = parent
	if(!L?.client)
		return
	clear_region_preview()
	for(var/turf/T as anything in region)
		var/image/I = image('icons/turf/overlays.dmi', T, "redOverlay")
		I.plane = ABOVE_LIGHTING_PLANE
		region_preview += I
	L.client.images |= region_preview

/datum/component/rw_build_plan/proc/clear_region_preview()
	var/mob/living/L = parent
	if(L?.client)
		L.client.images -= region_preview
	region_preview.Cut()


// =====================================================================
// MOB HELPERS
// =====================================================================

/mob/living
	/// Admin toggle: planned buildings complete immediately and cost nothing.
	var/rw_instant_build = FALSE

/mob/living/proc/rw_get_build_plan()
	RETURN_TYPE(/datum/component/rw_build_plan)
	return GetComponent(/datum/component/rw_build_plan)

/mob/living/proc/rw_can_instant_build()
	return rw_is_skill_admin(src)

/mob/living/proc/rw_instant_build_active()
	return rw_instant_build && rw_can_instant_build()

/mob/living/proc/rw_toggle_instant_build()
	if(!rw_can_instant_build())
		rw_instant_build = FALSE
		return FALSE
	rw_instant_build = !rw_instant_build
	balloon_alert(src, rw_instant_build ? "instant build: ON" : "instant build: OFF")
	log_game("[key_name(src)] turned RW instant build [rw_instant_build ? "on" : "off"].")
	var/datum/component/rw_build_plan/plan = rw_get_build_plan()
	plan?.refresh_affordability(force = TRUE)
	return TRUE

/mob/living/proc/rw_start_build_plan(blueprint_id, material_path = null, mode = RW_BUILD_MODE_PLACE)
	var/datum/building_blueprint/bp = null
	if(mode != RW_BUILD_MODE_CANCEL)
		bp = SSresearch.get_building_blueprint(blueprint_id)
		if(!bp)
			return FALSE
		if(!rw_knows_blueprint(blueprint_id))
			return FALSE
		if(bp.is_stuffed() && material_path && !rw_blueprint_allows_stuff(bp, material_path))
			return FALSE

	var/datum/component/rw_build_plan/existing = rw_get_build_plan()
	if(existing)
		qdel(existing)

	AddComponent(/datum/component/rw_build_plan, bp, material_path, mode)
	return TRUE

/mob/living/proc/rw_start_cancel_plan()
	return rw_start_build_plan(null, null, RW_BUILD_MODE_CANCEL)

/mob/living/proc/rw_cancel_build_plan()
	var/datum/component/rw_build_plan/plan = rw_get_build_plan()
	if(!plan)
		return FALSE
	balloon_alert(src, "planning cancelled")
	qdel(plan)
	return TRUE

/mob/living/proc/rw_rotate_build_plan()
	var/datum/component/rw_build_plan/plan = rw_get_build_plan()
	if(!plan)
		return FALSE
	plan.rotate()
	return TRUE

/mob/living/proc/rw_get_default_blueprint_ids()
	SSresearch.init_rw_registries()
	var/list/ids = list()
	for(var/id in SSresearch.building_blueprints)
		var/datum/building_blueprint/bp = SSresearch.building_blueprints[id]
		if(bp.default_unlocked)
			ids += id
	return ids

/mob/living/proc/rw_get_known_blueprint_ids()
	var/list/ids = rw_get_default_blueprint_ids()
	var/datum/rw_faction/player/F = istype(rw_faction, /datum/rw_faction/player) ? rw_faction : null
	if(F?.techweb)
		for(var/id in F.techweb.unlocked_blueprints)
			if(F.techweb.unlocked_blueprints[id])
				ids |= id
	return ids

/mob/living/proc/rw_knows_blueprint(blueprint_id)
	return (blueprint_id in rw_get_known_blueprint_ids())

/mob/living/proc/open_architect_menu()
	var/datum/rw_architect_menu/menu = new(src)
	menu.ui_interact(src)
