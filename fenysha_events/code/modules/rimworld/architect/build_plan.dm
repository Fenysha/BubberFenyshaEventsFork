/datum/component/rw_build_plan
	dupe_mode = COMPONENT_DUPE_UNIQUE

	var/datum/building_blueprint/blueprint
	var/dir = NORTH
	var/turf/hover_turf
	var/placement_valid = FALSE
	var/list/image/ghost_images = list()
	var/material_override

/datum/component/rw_build_plan/Initialize(datum/building_blueprint/bp, material_override_path = null)
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE
	if(!istype(bp))
		return COMPONENT_INCOMPATIBLE

	blueprint = bp
	material_override = material_override_path

	var/mob/living/L = parent
	dir = L.dir || NORTH

	RegisterSignal(L, COMSIG_MOB_CLICKON, PROC_REF(on_clicked), TRUE)
	RegisterSignal(L, COMSIG_LIVING_DEATH, PROC_REF(on_hard_cancel))
	RegisterSignal(L, COMSIG_QDELETING, PROC_REF(on_hard_cancel))

	START_PROCESSING(SSfastprocess, src)

	L.balloon_alert(L, "planning: [bp.name]")
	to_chat(L, span_notice("Planning <b>[bp.name]</b>. LMB — place, RMB — cancel, ALT+LMB — rotate."))

/datum/component/rw_build_plan/Destroy(force)
	STOP_PROCESSING(SSfastprocess, src)
	clear_ghosts()

	var/mob/living/L = parent
	if(L)
		UnregisterSignal(L, list(COMSIG_MOB_CLICKON, COMSIG_LIVING_DEATH, COMSIG_QDELETING))

	blueprint = null
	hover_turf = null
	return ..()

/datum/component/rw_build_plan/proc/on_hard_cancel(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/component/rw_build_plan/process()
	var/mob/living/L = parent
	if(QDELETED(L) || !L.client)
		qdel(src)
		return
	if(hover_turf)
		var/was = placement_valid
		placement_valid = check_placement(hover_turf)
		if(was != placement_valid)
			rebuild_ghosts(hover_turf)

/datum/component/rw_build_plan/proc/on_clicked(atom/source, atom/clicked_on, modifiers)
	SIGNAL_HANDLER

	var/mob/living/L = parent
	if(!L || L != source)
		return

	. = COMSIG_MOB_CANCEL_CLICKON

	var/turf/T = get_turf(clicked_on)
	if(!T)
		return

	if(LAZYACCESS(modifiers, RIGHT_CLICK))
		L.balloon_alert(L, "planning cancelled")
		qdel(src)
		return

	if(LAZYACCESS(modifiers, ALT_CLICK))
		rotate()
		set_hover_turf(T)
		return

	set_hover_turf(T)
	try_place(T)

/datum/component/rw_build_plan/proc/clear_ghosts()
	var/mob/living/L = parent
	if(!L?.client)
		ghost_images.Cut()
		return
	for(var/image/I as anything in ghost_images)
		L.client.images -= I
	ghost_images.Cut()

/datum/component/rw_build_plan/proc/get_target_turfs(turf/origin)
	if(!blueprint || !origin)
		return list()
	if(blueprint.is_multiblock())
		var/datum/rw_multiblock_layout/layout = rw_get_multiblock_layout(blueprint.multiblock_layout_id)
		if(!layout)
			return list()
		return layout.get_turfs(origin, dir)
	return list(origin)

/datum/component/rw_build_plan/proc/check_placement(turf/origin)
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
	if(!T)
		return
	hover_turf = T
	placement_valid = check_placement(T)
	rebuild_ghosts(T)

/datum/component/rw_build_plan/proc/rebuild_ghosts(turf/origin)
	clear_ghosts()
	var/mob/living/L = parent
	if(!L?.client || !origin || !blueprint)
		return

	var/list/turf/targets = get_target_turfs(origin)
	var/list/appearance_data = blueprint.get_ghost_appearance()
	var/ghost_icon = appearance_data["icon"]
	var/ghost_state = appearance_data["icon_state"]
	var/color_mod = placement_valid ? "#66ff66" : "#ff5555"

	for(var/turf/T as anything in targets)
		var/image/I = image(ghost_icon, T, ghost_state, FLY_LAYER)
		I.alpha = 140
		I.color = color_mod
		I.appearance_flags = RESET_ALPHA | RESET_COLOR
		ghost_images += I
		L.client.images += I

/datum/component/rw_build_plan/proc/rotate()
	if(!blueprint?.can_rotate)
		return
	dir = turn(dir, -90)
	var/mob/living/L = parent
	L?.balloon_alert(L, dir2text(dir))
	if(hover_turf)
		placement_valid = check_placement(hover_turf)
		rebuild_ghosts(hover_turf)

/datum/component/rw_build_plan/proc/try_place(turf/target)
	if(!target)
		target = hover_turf
	if(!target || !blueprint)
		return FALSE

	var/mob/living/L = parent
	if(!check_placement(target))
		L?.balloon_alert(L, "can't place here!")
		return FALSE

	if(blueprint.is_multiblock())
		var/datum/rw_multiblock_instance/inst = rw_multiblock_try_build(
			blueprint.multiblock_layout_id,
			target,
			dir,
			L
		)
		return !!inst

	if(!blueprint.build_path)
		L?.balloon_alert(L, "invalid blueprint!")
		return FALSE

	var/atom/A = new blueprint.build_path(target)
	if(isobj(A))
		var/obj/O = A
		O.dir = dir
	L?.balloon_alert(L, "placed")
	return TRUE


/mob/living/proc/rw_get_build_plan()
	RETURN_TYPE(/datum/component/rw_build_plan)
	return GetComponent(/datum/component/rw_build_plan)

/mob/living/proc/rw_start_build_plan(blueprint_id, material_override = null)
	var/datum/building_blueprint/bp = SSresearch.get_building_blueprint(blueprint_id)
	if(!bp)
		return FALSE
	if(!rw_knows_blueprint(blueprint_id))
		return FALSE
	var/datum/component/rw_build_plan/existing = rw_get_build_plan()
	if(existing)
		qdel(existing)
	AddComponent(/datum/component/rw_build_plan, bp, material_override)
	return TRUE

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
