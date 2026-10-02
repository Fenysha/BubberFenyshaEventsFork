/datum/rw_multiblock_cell
	var/offset_x = 0
	var/offset_y = 0
	var/atom_type = /obj/machinery
	var/list/tags = list()
	var/list/spawn_args = list()


/datum/rw_multiblock_layout
	var/id
	var/name = "Unnamed Multiblock"
	var/list/datum/rw_multiblock_cell/cells = list()
	var/can_rotate = TRUE

/datum/rw_multiblock_layout/New()
	build_cells()
	validate_layout()

/datum/rw_multiblock_layout/proc/build_cells()
	return

/datum/rw_multiblock_layout/proc/add_cell(ox, oy, atom_type, list/tags, list/spawn_args)
	var/datum/rw_multiblock_cell/cell = new
	cell.offset_x = ox
	cell.offset_y = oy
	cell.atom_type = atom_type
	if(tags)
		cell.tags = tags.Copy()
	if(spawn_args)
		cell.spawn_args = spawn_args.Copy()
	cells += cell
	return cell

/datum/rw_multiblock_layout/proc/validate_layout()
	var/pivots = 0
	var/interfaces = 0
	for(var/datum/rw_multiblock_cell/cell as anything in cells)
		if(RW_MB_TAG_PIVOT in cell.tags)
			pivots++
		if(RW_MB_TAG_INTERFACE in cell.tags)
			interfaces++
	if(pivots != 1)
		stack_trace("Layout '[id]' must have exactly 1 pivot cell, has [pivots].")
	if(interfaces < 1)
		stack_trace("Layout '[id]' should have at least 1 interface cell.")

/datum/rw_multiblock_layout/proc/get_pivot_cell()
	for(var/datum/rw_multiblock_cell/cell as anything in cells)
		if(RW_MB_TAG_PIVOT in cell.tags)
			return cell
	return null

/datum/rw_multiblock_layout/proc/rotate_offset(ox, oy, dir)
	switch(dir)
		if(NORTH)
			return list(ox, oy)
		if(EAST)
			return list(oy, -ox)
		if(SOUTH)
			return list(-ox, -oy)
		if(WEST)
			return list(-oy, ox)
	return list(ox, oy)


/datum/rw_multiblock_layout/proc/get_turfs(turf/pivot_turf, dir = NORTH)
	var/list/turf/result = list()
	var/datum/rw_multiblock_cell/pivot = get_pivot_cell()
	if(!pivot || !pivot_turf)
		return result

	var/list/pivot_rot = rotate_offset(pivot.offset_x, pivot.offset_y, dir)
	var/origin_x = pivot_turf.x - pivot_rot[1]
	var/origin_y = pivot_turf.y - pivot_rot[2]
	var/origin_z = pivot_turf.z

	for(var/datum/rw_multiblock_cell/cell as anything in cells)
		var/list/rot = rotate_offset(cell.offset_x, cell.offset_y, dir)
		var/turf/T = locate(origin_x + rot[1], origin_y + rot[2], origin_z)
		if(T)
			result += T
	return result

/datum/rw_multiblock_layout/proc/can_place(turf/pivot_turf, dir = NORTH, mob/user, list/fail_reasons)
	if(!pivot_turf)
		fail_reasons += "Invalid pivot turf."
		return FALSE

	var/ok = TRUE
	for(var/turf/T as anything in get_turfs(pivot_turf, dir))
		if(!T)
			ok = FALSE
			fail_reasons += "Missing turf."
			continue
		if(T.density)
			ok = FALSE
			fail_reasons += "[T] is dense."
			continue
		for(var/atom/movable/AM in T)
			if(istype(AM, /obj/effect))
				continue
			if(AM.density || istype(AM, /obj/machinery) || istype(AM, /obj/structure))
				ok = FALSE
				fail_reasons += "[AM] blocks [T]."
				break
	return ok


/datum/rw_multiblock_instance
	var/datum/rw_multiblock_layout/layout
	var/layout_id
	var/build_dir = NORTH

	var/list/atom/members = list()

	var/atom/pivot
	var/list/atom/interfaces = list()

	var/destroyed = FALSE

/datum/rw_multiblock_instance/Destroy()
	destroyed = TRUE
	for(var/atom/A as anything in members)
		var/datum/component/rw_multiblock/comp = A.GetComponent(/datum/component/rw_multiblock)
		if(comp)
			comp.instance = null
			qdel(comp)
	members.Cut()
	interfaces.Cut()
	pivot = null
	layout = null
	return ..()

/datum/rw_multiblock_instance/proc/register_member(atom/A, list/tags)
	if(!A || (A in members))
		return
	members[A] = tags?.Copy() || list()
	if(RW_MB_TAG_PIVOT in members[A])
		pivot = A
	if(RW_MB_TAG_INTERFACE in members[A])
		interfaces |= A

	var/datum/component/rw_multiblock/comp = A.GetComponent(/datum/component/rw_multiblock)
	if(!comp)
		comp = A.AddComponent(/datum/component/rw_multiblock, src, members[A])
	else
		comp.bind_instance(src, members[A])

/datum/rw_multiblock_instance/proc/unregister_member(atom/A)
	members -= A
	interfaces -= A
	if(pivot == A)
		pivot = null

/datum/rw_multiblock_instance/proc/get_members_by_tag(tag)
	var/list/result = list()
	for(var/atom/A as anything in members)
		if(tag in members[A])
			result += A
	return result

/datum/rw_multiblock_instance/proc/get_member_by_tag(tag)
	for(var/atom/A as anything in members)
		if(tag in members[A])
			return A
	return null

/datum/rw_multiblock_instance/proc/get_turfs()
	var/list/turf/result = list()
	for(var/atom/A as anything in members)
		var/turf/T = get_turf(A)
		if(T)
			result |= T
	return result


/datum/rw_multiblock_instance/proc/dissolve(atom/triggered_by = null, disassembled = FALSE)
	if(destroyed)
		return
	destroyed = TRUE

	SEND_SIGNAL(src, COMSIG_RW_MULTIBLOCK_BROKEN, triggered_by)

	var/list/atom/to_clear = members.Copy()
	for(var/atom/A as anything in to_clear)
		var/datum/component/rw_multiblock/comp = A.GetComponent(/datum/component/rw_multiblock)
		if(comp)
			comp.instance = null
			qdel(comp)
		if(A == triggered_by)
			continue
		if(QDELETED(A))
			continue
		if(disassembled && isobj(A))
			var/obj/O = A
			O.deconstruct(TRUE)
		else
			qdel(A)

	members.Cut()
	interfaces.Cut()
	pivot = null
	qdel(src)


/datum/rw_multiblock_instance/ui_interact(mob/user, atom/source)
	if(destroyed)
		return FALSE
	return SEND_SIGNAL(src, COMSIG_RW_MULTIBLOCK_INTERACT, user, source)



/datum/component/rw_multiblock
	dupe_mode = COMPONENT_DUPE_UNIQUE

	var/datum/rw_multiblock_instance/instance
	var/list/tags = list()
	var/is_interface = FALSE
	var/is_pivot = FALSE

/datum/component/rw_multiblock/Initialize(datum/rw_multiblock_instance/mb_instance, list/member_tags)
	if(!isatom(parent))
		return COMPONENT_INCOMPATIBLE
	bind_instance(mb_instance, member_tags)

/datum/component/rw_multiblock/proc/bind_instance(datum/rw_multiblock_instance/mb_instance, list/member_tags)
	instance = mb_instance
	tags = member_tags?.Copy() || list()
	is_interface = (RW_MB_TAG_INTERFACE in tags)
	is_pivot = (RW_MB_TAG_PIVOT in tags)

/datum/component/rw_multiblock/RegisterWithParent()
	RegisterSignal(parent, COMSIG_ATOM_DESTRUCTION, PROC_REF(on_parent_destroyed))
	RegisterSignal(parent, COMSIG_QDELETING, PROC_REF(on_parent_qdel))
	if(is_interface)
		RegisterSignal(parent, COMSIG_ATOM_ATTACK_HAND, PROC_REF(on_attack_hand))


/datum/component/rw_multiblock/UnregisterFromParent()
	UnregisterSignal(parent, list(
		COMSIG_ATOM_DESTRUCTION,
		COMSIG_QDELETING,
		COMSIG_ATOM_ATTACK_HAND,
	))

/datum/component/rw_multiblock/proc/on_attack_hand(atom/source, mob/user)
	SIGNAL_HANDLER
	if(!instance || instance.destroyed)
		return
	if(instance.ui_interact(user, source))
		return COMPONENT_CANCEL_ATTACK_CHAIN
	return

/datum/component/rw_multiblock/proc/on_parent_destroyed(atom/source)
	SIGNAL_HANDLER
	if(instance && !instance.destroyed)
		instance.dissolve(source, disassembled = FALSE)

/datum/component/rw_multiblock/proc/on_parent_qdel(atom/source)
	SIGNAL_HANDLER
	if(instance && !instance.destroyed)
		instance.dissolve(source, disassembled = FALSE)

/datum/component/rw_multiblock/proc/get_instance()
	return instance

/datum/component/rw_multiblock/proc/has_tag(tag)
	return (tag in tags)




GLOBAL_LIST_EMPTY(rw_multiblock_layouts)

/proc/rw_init_multiblock_layouts()
	if(length(GLOB.rw_multiblock_layouts))
		return
	for(var/path in subtypesof(/datum/rw_multiblock_layout))
		var/datum/rw_multiblock_layout/L = new path
		if(!L.id)
			qdel(L)
			continue
		if(GLOB.rw_multiblock_layouts[L.id])
			stack_trace("Duplicate multiblock layout id '[L.id]'")
			qdel(L)
			continue
		GLOB.rw_multiblock_layouts[L.id] = L

/proc/rw_get_multiblock_layout(layout_id)
	rw_init_multiblock_layouts()
	return GLOB.rw_multiblock_layouts[layout_id]

/proc/rw_spawn_multiblock(layout_id, turf/pivot_turf, dir = NORTH, atom/creator = null)
	var/datum/rw_multiblock_layout/layout = rw_get_multiblock_layout(layout_id)
	if(!layout || !pivot_turf)
		return null

	var/list/reasons = list()
	if(!layout.can_place(pivot_turf, dir, null, reasons))
		return null

	var/datum/rw_multiblock_cell/pivot_cell = layout.get_pivot_cell()
	if(!pivot_cell)
		return null

	var/list/pivot_rot = layout.rotate_offset(pivot_cell.offset_x, pivot_cell.offset_y, dir)
	var/origin_x = pivot_turf.x - pivot_rot[1]
	var/origin_y = pivot_turf.y - pivot_rot[2]
	var/origin_z = pivot_turf.z

	var/datum/rw_multiblock_instance/inst = new
	inst.layout = layout
	inst.layout_id = layout.id
	inst.build_dir = dir

	for(var/datum/rw_multiblock_cell/cell as anything in layout.cells)
		var/list/rot = layout.rotate_offset(cell.offset_x, cell.offset_y, dir)
		var/turf/T = locate(origin_x + rot[1], origin_y + rot[2], origin_z)
		if(!T)
			inst.dissolve(null, FALSE)
			return null

		var/atom/A = new cell.atom_type(T)
		if(isobj(A))
			var/obj/O = A
			O.dir = dir
			if(ismachinery(O))
				continue

		inst.register_member(A, cell.tags)

	return inst

/proc/rw_multiblock_can_build(layout_id, turf/pivot_turf, dir = NORTH, mob/user)
	var/datum/rw_multiblock_layout/layout = rw_get_multiblock_layout(layout_id)
	if(!layout)
		return FALSE
	var/list/reasons = list()
	if(!layout.can_place(pivot_turf, dir, user, reasons))
		if(user && length(reasons))
			to_chat(user, span_warning(reasons[1]))
		return FALSE
	return TRUE

/proc/rw_multiblock_try_build(layout_id, turf/pivot_turf, dir = NORTH, mob/user)
	if(!rw_multiblock_can_build(layout_id, pivot_turf, dir, user))
		return null
	var/datum/rw_multiblock_instance/inst = rw_spawn_multiblock(layout_id, pivot_turf, dir, user)
	if(!inst)
		if(user)
			to_chat(user, span_warning("Failed to assemble the structure."))
		return null
	if(user)
		to_chat(user, span_notice("Structure assembled ([inst.layout.name])."))
	return inst

