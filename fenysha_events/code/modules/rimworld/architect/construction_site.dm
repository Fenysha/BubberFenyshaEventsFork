GLOBAL_LIST_EMPTY(rw_stuff_sheets)

/proc/rw_get_stuff_sheets()
	if(length(GLOB.rw_stuff_sheets))
		return GLOB.rw_stuff_sheets
	for(var/sheet_path in typesof(/obj/item/stack/sheet/rimworld))
		var/obj/item/stack/sheet/rimworld/S = sheet_path
		var/mat_path = initial(S.rimworld_mat_type)
		if(!mat_path || GLOB.rw_stuff_sheets[mat_path])
			continue
		GLOB.rw_stuff_sheets[mat_path] = sheet_path
	return GLOB.rw_stuff_sheets

/proc/rw_get_sheet_for_material(material_path)
	if(!material_path)
		return null
	return rw_get_stuff_sheets()[material_path]

/proc/rw_blueprint_allows_stuff(datum/building_blueprint/bp, material_path)
	if(!bp?.is_stuffed() || !ispath(material_path, /datum/material/rimworld_material))
		return FALSE
	if(!rw_get_sheet_for_material(material_path))
		return FALSE
	var/datum/material/rimworld_material/mat = GET_MATERIAL_REF(material_path)
	return !!mat && (mat.stuff_category in bp.stuff_categories)

/proc/rw_default_stuff_for(datum/building_blueprint/bp)
	if(!bp?.is_stuffed())
		return null
	if(bp.default_stuff && rw_blueprint_allows_stuff(bp, bp.default_stuff))
		return bp.default_stuff
	for(var/mat_path in rw_get_stuff_sheets())
		if(rw_blueprint_allows_stuff(bp, mat_path))
			return mat_path
	return null


/datum/rw_construction_site
	var/datum/building_blueprint/blueprint
	var/turf/origin
	var/dir = NORTH
	var/material_path

	var/state = RW_SITE_HOLOGRAM
	var/steps_done = 0
	var/working = FALSE
	var/dying = FALSE

	var/list/needs = list()
	var/list/delivered = list()

	var/list/obj/structure/rw_construction_part/parts = list()

/datum/rw_construction_site/New(datum/building_blueprint/bp, turf/_origin, _dir, _material_path)
	blueprint = bp
	origin = _origin
	dir = _dir
	material_path = _material_path
	needs = bp.get_needs(_material_path)
	for(var/path in needs)
		delivered[path] = 0

	for(var/list/entry as anything in bp.get_cell_entries(origin, dir))
		var/obj/structure/rw_construction_part/P = new(entry["turf"])
		P.setup(src, entry["icon"], entry["icon_state"])
		parts += P

/datum/rw_construction_site/Destroy()
	dying = TRUE
	for(var/obj/structure/rw_construction_part/P as anything in parts)
		P.site = null
		if(!QDELETED(P))
			qdel(P)
	parts.Cut()
	blueprint = null
	origin = null
	return ..()

/datum/rw_construction_site/proc/get_material()
	return material_path ? GET_MATERIAL_REF(material_path) : null

/datum/rw_construction_site/proc/get_color()
	var/datum/material/mat = get_material()
	return mat?.color

/datum/rw_construction_site/proc/needs_total()
	. = 0
	for(var/path in needs)
		. += needs[path]

/datum/rw_construction_site/proc/get_resource_fraction()
	var/total = needs_total()
	if(total <= 0)
		return 1
	var/have = 0
	for(var/path in needs)
		have += min(delivered[path], needs[path])
	return have / total

/datum/rw_construction_site/proc/get_progress()
	return steps_done / max(1, blueprint.build_steps)

/datum/rw_construction_site/proc/get_missing_text()
	var/list/lines = list()
	for(var/path in needs)
		var/left = needs[path] - delivered[path]
		if(left <= 0)
			continue
		var/atom/A = path
		lines += "[left]x [initial(A.name)]"
	return english_list(lines, "nothing")

/datum/rw_construction_site/proc/update_parts()
	for(var/obj/structure/rw_construction_part/P as anything in parts)
		P.refresh_look()

/datum/rw_construction_site/proc/match_need(obj/item/I)
	for(var/path in needs)
		if(delivered[path] < needs[path] && istype(I, path))
			return path
	return null

/datum/rw_construction_site/proc/try_deliver(mob/living/user, obj/item/I)
	var/need_path = match_need(I)
	if(!need_path)
		return FALSE
	var/left = needs[need_path] - delivered[need_path]
	var/taken = 0
	if(istype(I, /obj/item/stack))
		var/obj/item/stack/S = I
		taken = min(S.amount, left)
		if(taken <= 0 || !S.use(taken))
			return FALSE
	else
		if(!user.temporarilyRemoveItemFromInventory(I))
			return FALSE
		qdel(I)
		taken = 1
	delivered[need_path] += taken
	user.balloon_alert(user, "+[taken] delivered")
	update_parts()
	return TRUE

/datum/rw_construction_site/proc/on_use(mob/living/user, obj/item/I)
	if(dying || working)
		return
	var/delivered_now = I ? try_deliver(user, I) : FALSE

	if(state == RW_SITE_HOLOGRAM)
		set_frame_state()
		user.balloon_alert(user, "construction started")
		to_chat(user, span_notice("You begin construction of [blueprint.name]. Still needed: [get_missing_text()]."))
		return

	if(delivered_now && I)
		return
	work(user)

/datum/rw_construction_site/proc/set_frame_state()
	state = RW_SITE_FRAME
	for(var/obj/structure/rw_construction_part/P as anything in parts)
		P.density = TRUE
	update_parts()

/datum/rw_construction_site/proc/can_continue(mob/living/user)
	if(dying || QDELETED(user))
		return FALSE
	for(var/obj/structure/rw_construction_part/P as anything in parts)
		if(get_dist(user, P) <= 1)
			return TRUE
	return FALSE

/datum/rw_construction_site/proc/work(mob/living/user)
	if(working || dying || state != RW_SITE_FRAME)
		return
	working = TRUE
	var/steps = max(1, blueprint.build_steps)
	var/datum/material/rimworld_material/mat = get_material()
	var/work_mult = 1
	if(istype(mat))
		work_mult = clamp((mat.get_rimworld_stat(RIMWORLD_STAT_WORK_TO_BUILD) || RIMWORLD_DEFAULT_WORK_TO_BUILD) / max(1, RIMWORLD_DEFAULT_WORK_TO_BUILD), 0.5, 4)
	var/step_time = (blueprint.construction_time * work_mult) / steps

	while(!dying && steps_done < steps)
		if(get_resource_fraction() + 0.0001 < (steps_done + 1) / steps)
			user.balloon_alert(user, "needs more materials")
			to_chat(user, span_warning("Construction is waiting for: [get_missing_text()]."))
			break
		var/atom/target = length(parts) ? parts[1] : user
		var/ok = rw_do_after(
			user,
			step_time,
			target,
			RW_SKILL_CONSTRUCTION,
			blueprint.ideal_skill,
			minimum_delay = 0.5 SECONDS,
			skill_points = 1,
			extra_checks = CALLBACK(src, PROC_REF(can_continue), user),
		)
		if(!ok || dying)
			break
		steps_done++
		update_parts()

	working = FALSE
	if(!dying && steps_done >= steps)
		finish(user)

/datum/rw_construction_site/proc/apply_material(atom/A, share = 1)
	var/datum/material/mat = get_material()
	if(!mat || !istype(A))
		return
	var/sheets = max(1, blueprint.stuff_cost) * share
	A.set_custom_materials(list((mat) = SHEET_MATERIAL_AMOUNT * sheets))
	if(!(A.material_flags & MATERIAL_COLOR))
		A.add_atom_colour(mat.color, FIXED_COLOUR_PRIORITY)

/datum/rw_construction_site/proc/finish(mob/living/user)
	var/datum/building_blueprint/bp = blueprint
	var/turf/pivot = origin
	var/final_dir = dir
	dying = TRUE
	var/list/obj/structure/rw_construction_part/old_parts = parts.Copy()
	parts.Cut()
	for(var/obj/structure/rw_construction_part/P as anything in old_parts)
		P.site = null
		qdel(P)

	var/success = FALSE
	if(bp.is_multiblock())
		var/datum/rw_multiblock_instance/inst = rw_spawn_multiblock(bp.multiblock_layout_id, pivot, final_dir, user)
		if(inst)
			success = TRUE
			var/count = max(1, length(inst.members))
			for(var/atom/A as anything in inst.members)
				apply_material(A, 1 / count)
	else if(bp.build_path)
		var/atom/A = new bp.build_path(pivot)
		if(isobj(A))
			var/obj/O = A
			O.dir = final_dir
		apply_material(A)
		success = TRUE

	if(success)
		if(user)
			user.balloon_alert(user, "construction complete")
			to_chat(user, span_notice("You finish building [bp.name]."))
	else
		drop_delivered(pivot)
		if(user)
			to_chat(user, span_warning("The construction collapses - the place became invalid. Materials returned."))
	qdel(src)

/datum/rw_construction_site/proc/drop_delivered(turf/where)
	if(!where)
		return
	for(var/path in delivered)
		var/amount = delivered[path]
		if(amount <= 0)
			continue
		if(ispath(path, /obj/item/stack))
			new path(where, amount)
		else
			for(var/i in 1 to amount)
				new path(where)
		delivered[path] = 0


/datum/rw_construction_site/proc/cancel(mob/living/user)
	if(dying)
		return
	dying = TRUE
	drop_delivered(origin)
	if(user)
		user.balloon_alert(user, "blueprint removed")
	qdel(src)

/datum/rw_construction_site/proc/part_destroyed(obj/structure/rw_construction_part/P)
	if(dying)
		return
	parts -= P
	cancel(null)



/obj/structure/rw_construction_part
	name = "blueprint"
	desc = "A holographic blueprint."
	anchored = TRUE
	density = FALSE
	layer = ABOVE_OBJ_LAYER
	resistance_flags = INDESTRUCTIBLE
	var/datum/rw_construction_site/site
	var/part_icon
	var/part_icon_state

/obj/structure/rw_construction_part/proc/setup(datum/rw_construction_site/_site, _icon, _icon_state)
	site = _site
	part_icon = _icon
	part_icon_state = _icon_state
	dir = _site.dir
	refresh_look()

/obj/structure/rw_construction_part/Destroy()
	var/datum/rw_construction_site/S = site
	site = null
	S?.part_destroyed(src)
	return ..()

/obj/structure/rw_construction_part/proc/refresh_look()
	if(!site)
		return
	icon = part_icon
	icon_state = part_icon_state
	color = site.get_color()
	if(site.state == RW_SITE_HOLOGRAM)
		alpha = RW_HOLOGRAM_ALPHA
		name = "blueprint: [site.blueprint.name]"
		desc = "A holographic blueprint. Click it to start construction. Right-click to cancel."
	else
		alpha = round(110 + 145 * site.get_progress())
		name = "under construction: [site.blueprint.name]"
		desc = "Progress: [site.steps_done]/[site.blueprint.build_steps]. Needed: [site.get_missing_text()]. Right-click to cancel."

/obj/structure/rw_construction_part/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(. || !site)
		return
	site.on_use(user, null)
	return TRUE

/obj/structure/rw_construction_part/attackby(obj/item/I, mob/living/user, params)
	if(!site || user.combat_mode)
		return ..()
	site.on_use(user, I)
	return TRUE

/obj/structure/rw_construction_part/attack_hand_secondary(mob/user, list/modifiers)
	if(site && isliving(user))
		site.cancel(user)
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/structure/rw_construction_part/attackby_secondary(obj/item/weapon, mob/user, params)
	if(site && isliving(user))
		site.cancel(user)
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
