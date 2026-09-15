/datum/sub_level
	var/width = 0
	var/height = 0
	var/z = 0

	var/x_min = 0
	var/y_min = 0
	var/x_max = 0
	var/y_max = 0

/datum/sub_level/New(turf/bottom_left, req_width, req_height)
	if(!bottom_left)
		return

	width = req_width
	height = req_height
	z = bottom_left.z

	x_min = bottom_left.x
	y_min = bottom_left.y
	x_max = x_min + width - 1
	y_max = y_min + height - 1

/datum/sub_level/proc/contains_turf(turf/T)
	if(!T || T.z != z)
		return FALSE
	return (T.x >= x_min && T.x <= x_max && T.y >= y_min && T.y <= y_max)


/datum/turf_reservation/sub_level
	turf_type = /turf/cordon
	var/id = 0
	var/name = "Sub-Level"
	var/created_at = 0
	var/datum/map_spatial_node/node = null

/datum/turf_reservation/sub_level/New(datum/map_spatial_node/target_node, new_id = 0, new_name = "")
	..()
	if(!target_node || !target_node.bounds)
		return

	node = target_node
	id = new_id
	name = new_name ? new_name : "Sub-Level #[id]"
	created_at = world.time

	var/datum/sub_level/B = target_node.bounds
	width = B.width
	height = B.height
	z_size = 1

	var/turf/BL = locate(B.x_min, B.y_min, B.z)
	var/turf/TR = locate(B.x_max, B.y_max, B.z)

	if(!BL || !TR)
		return

	bottom_left_turfs += BL
	top_right_turfs += TR

	var/z_key = "[BL.z]"
	if(!SSmapping.unused_turfs[z_key])
		SSmapping.unused_turfs[z_key] = list()

	var/list/turf/block_turfs = block(BL, TR)
	for(var/turf/T in block_turfs)
		reserved_turfs |= T
		SSmapping.unused_turfs[z_key] -= T
		SSmapping.used_turfs[T] = src
		T.turf_flags = (T.turf_flags | RESERVATION_TURF) & ~UNUSED_RESERVATION_TURF
		T.empty(turf_type, turf_type_is_baseturf ? turf_type : null)

	if(calculate_cordon_turfs(BL, TR))
		generate_cordon()

/datum/map_spatial_node/proc/allocate_sub_level(req_w, req_h, res_id = 0, res_name = "")
	if(reserved)
		return null

	if(bounds.width < req_w * 2 || bounds.height < req_h * 2)
		if(bounds.width >= req_w && bounds.height >= req_h && !split)
			reserved = TRUE
			reservation = new /datum/turf_reservation/sub_level(src, res_id, res_name)
			return reservation
		return null

	if(!split)
		if(!subdivide())
			return null

	for(var/datum/map_spatial_node/child in children)
		var/datum/turf_reservation/sub_level/res = child.allocate_sub_level(req_w, req_h, res_id, res_name)
		if(res)
			return res

	return null

/datum/turf_reservation/sub_level/Destroy()
	SSsub_levels.unregister_reservation(src)
	if(node)
		node.reserved = FALSE
		node.reservation = null
		var/datum/map_spatial_node/parent_node = node.parent
		node = null
		parent_node?.check_merge()
	return ..()

/turf/cordon/absolute
	space_lit = FALSE

/turf/cordon/absolute/CanPass(atom/movable/mover, border_dir)
	SHOULD_CALL_PARENT(FALSE)
	return FALSE

/turf/cordon/absolute/attack_ghost(mob/dead/observer/user)
	return FALSE


/datum/turf_reservation/sub_level


/datum/turf_reservation/sub_level/proc/get_bottom_left_turf()
	return length(bottom_left_turfs) ? bottom_left_turfs[1] : null


/datum/turf_reservation/sub_level/proc/get_top_right_turf()
	return length(top_right_turfs) ? top_right_turfs[1] : null


/datum/turf_reservation/sub_level/proc/get_bottom_right_turf()
	var/turf/BL = get_bottom_left_turf()
	var/turf/TR = get_top_right_turf()
	if(!BL || !TR)
		return null
	return locate(TR.x, BL.y, BL.z)

/datum/turf_reservation/sub_level/proc/get_top_left_turf()
	var/turf/BL = get_bottom_left_turf()
	var/turf/TR = get_top_right_turf()
	if(!BL || !TR)
		return null
	return locate(BL.x, TR.y, BL.z)

/datum/turf_reservation/sub_level/proc/get_corner_turfs()
	var/turf/BL = get_bottom_left_turf()
	var/turf/TR = get_top_right_turf()
	if(!BL || !TR)
		return list()
	return list(
		BL,
		locate(TR.x, BL.y, BL.z),
		TR,
		locate(BL.x, TR.y, BL.z)
	)

/datum/turf_reservation/sub_level/proc/get_center_turf()
	var/turf/BL = get_bottom_left_turf()
	var/turf/TR = get_top_right_turf()
	if(!BL || !TR)
		return null
	return locate(round((BL.x + TR.x) / 2), round((BL.y + TR.y) / 2), BL.z)

/datum/turf_reservation/sub_level/proc/get_all_turfs()
	return reserved_turfs ? reserved_turfs.Copy() : list()

/datum/turf_reservation/sub_level/proc/get_inner_turfs()
	var/turf/BL = get_bottom_left_turf()
	var/turf/TR = get_top_right_turf()
	if(!BL || !TR || width <= 2 || height <= 2)
		return list()

	var/turf/inner_BL = locate(BL.x + 1, BL.y + 1, BL.z)
	var/turf/inner_TR = locate(TR.x - 1, TR.y - 1, BL.z)
	return block(inner_BL, inner_TR)

/datum/turf_reservation/sub_level/proc/get_cordon_turfs()
	return cordon_turfs ? cordon_turfs.Copy() : list()


/datum/turf_reservation/sub_level/proc/get_random_turf(include_cordon = FALSE)
	if(include_cordon)
		return length(reserved_turfs) ? pick(reserved_turfs) : null
	var/list/turf/inners = get_inner_turfs()
	return length(inners) ? pick(inners) : null

/datum/turf_reservation/sub_level/proc/contains_turf(turf/T)
	if(!T)
		return FALSE

	var/turf/BL = get_bottom_left_turf()
	var/turf/TR = get_top_right_turf()
	if(!BL || !TR || T.z != BL.z)
		return FALSE

	return (T.x >= BL.x && T.x <= TR.x && T.y >= BL.y && T.y <= TR.y)
