/datum/component/rw_build_plan
	dupe_mode = COMPONENT_DUPE_UNIQUE

	var/datum/building_blueprint/blueprint
	var/dir = NORTH
	var/turf/hover_turf
	var/placement_valid = FALSE
	var/list/image/ghost_images = list()
	var/material_path

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
		• RMB — cancel"))

/datum/component/rw_build_plan/Destroy(force)
	STOP_PROCESSING(SSsuperfast_process, src)
	clear_ghosts()
	clear_region_preview()

	var/mob/living/L = parent
	if(L)
		L.clear_fullscreen("rw_build_plan")
		UnregisterSignal(L, list(COMSIG_MOB_CLICKON, COMSIG_LIVING_DEATH, COMSIG_QDELETING))

	catcher = null
	blueprint = null
	hover_turf = null
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

	if(catcher.mouse_params == last_mouse_params)
		return

	last_mouse_params = catcher.mouse_params
	if(last_mouse_params)
		catcher.calculate_params()

	var/turf/under_cursor = catcher.given_turf
	if(under_cursor && under_cursor != hover_turf)
		set_hover_turf(under_cursor)


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


/datum/component/rw_build_plan/proc/clear_ghosts()
	var/mob/living/L = parent
	if(L?.client)
		for(var/image/I as anything in ghost_images)
			L.client.images -= I
	ghost_images.Cut()

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

	if(mode == RW_BUILD_MODE_CANCEL)
		clear_ghosts()
		var/mob/living/L = parent
		if(L?.client)
			var/image/I = image('icons/turf/overlays.dmi', T, "redOverlay")
			I.plane = ABOVE_LIGHTING_PLANE
			ghost_images += I
			L.client.images |= I
	else
		placement_valid = check_placement(T)
		rebuild_ghosts(T)

/datum/component/rw_build_plan/proc/rebuild_ghosts(turf/origin)
	clear_ghosts()
	var/mob/living/L = parent
	if(!L?.client || !origin || !blueprint)
		return

	var/datum/material/mat = material_path ? GET_MATERIAL_REF(material_path) : null
	var/ghost_color = placement_valid ? (mat?.color || "#ffffff") : "#ff5555"

	for(var/list/entry as anything in blueprint.get_cell_entries(origin, dir))
		var/turf/T = entry["turf"]
		if(!T)
			continue
		var/image/I = image(entry["icon"], T, entry["icon_state"], MOB_LAYER + 0.1)
		I.plane = MOB_PLANE
		I.dir = dir
		I.alpha = RW_HOLOGRAM_ALPHA
		I.color = ghost_color
		I.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
		ghost_images += I
		L.client.images |= I

/datum/component/rw_build_plan/proc/rotate()
	if(mode == RW_BUILD_MODE_CANCEL || !blueprint?.can_rotate)
		return
	dir = turn(dir, -90)
	var/mob/living/L = parent
	L?.balloon_alert(L, dir2text(dir))
	if(hover_turf)
		placement_valid = check_placement(hover_turf)
		rebuild_ghosts(hover_turf)

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

	new /datum/rw_construction_site(blueprint, target, dir, material_path)
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


/mob/living/proc/rw_get_build_plan()
	RETURN_TYPE(/datum/component/rw_build_plan)
	return GetComponent(/datum/component/rw_build_plan)

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
