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

	return T.x >= x_min && T.x <= x_max && T.y >= y_min && T.y <= y_max


/datum/turf_reservation/sub_level
	turf_type = /turf/cordon

	var/id = 0
	var/name = "Sub-Level"
	var/created_at = 0

	var/datum/map_spatial_node/node = null

	var/z = 0
	var/x_min = 0
	var/y_min = 0
	var/x_max = 0
	var/y_max = 0

	var/inner_width = 0
	var/inner_height = 0
	var/border_size = RW_SUBLEVEL_BORDER_SIZE

	var/materialized = FALSE
	var/materialize_x = 0
	var/materialize_y = 0


/datum/turf_reservation/sub_level/New(datum/map_spatial_node/target_node, new_id = 0, new_name = "", defer_materialization = FALSE)
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

	z = B.z
	x_min = B.x_min
	y_min = B.y_min
	x_max = B.x_max
	y_max = B.y_max

	inner_width = width - (border_size * 2)
	inner_height = height - (border_size * 2)

	materialize_x = x_min
	materialize_y = y_min

	var/turf/BL = locate(x_min, y_min, z)
	var/turf/TR = locate(x_max, y_max, z)

	if(!BL || !TR)
		return

	bottom_left_turfs += BL
	top_right_turfs += TR

	if(!defer_materialization)
		materialize_all()


/datum/turf_reservation/sub_level/proc/materialize_all()
	while(!materialized)
		if(materialize_step(RW_SUBLEVEL_RESERVE_BUDGET))
			break


/datum/turf_reservation/sub_level/proc/materialize_step(work_budget = RW_SUBLEVEL_RESERVE_BUDGET)
	if(materialized)
		return TRUE

	if(work_budget <= 0)
		work_budget = RW_SUBLEVEL_RESERVE_BUDGET

	var/z_key = "[z]"
	var/work_done = 0
	var/list/batch = list()

	if(!SSmapping.unused_turfs[z_key])
		SSmapping.unused_turfs[z_key] = list()

	while(materialize_y <= y_max)
		while(materialize_x <= x_max)
			var/turf/T = locate(materialize_x, materialize_y, z)

			if(T)
				reserved_turfs += T
				batch += T

				SSmapping.used_turfs[T] = src

				T.turf_flags = (T.turf_flags | RESERVATION_TURF) & ~UNUSED_RESERVATION_TURF

				if(
					materialize_x == x_min \
					|| materialize_x == x_max \
					|| materialize_y == y_min \
					|| materialize_y == y_max
				)
					T.empty(
						turf_type,
						turf_type_is_baseturf ? turf_type : null
					)

			materialize_x++
			work_done++

			if(length(batch) >= RW_SUBLEVEL_RESERVE_BUDGET)
				SSmapping.unused_turfs[z_key] -= batch
				batch.Cut()

			if(work_done >= work_budget || TICK_CHECK)
				if(length(batch))
					SSmapping.unused_turfs[z_key] -= batch

				return FALSE

		materialize_x = x_min
		materialize_y++

		if(work_done >= work_budget || TICK_CHECK)
			if(length(batch))
				SSmapping.unused_turfs[z_key] -= batch

			return FALSE

	if(length(batch))
		SSmapping.unused_turfs[z_key] -= batch

	var/turf/BL = get_bottom_left_turf()
	var/turf/TR = get_top_right_turf()

	if(BL && TR)
		if(calculate_cordon_turfs(BL, TR))
			generate_cordon()

	materialized = TRUE
	return TRUE


/mob/dead/observer/abstract_move(atom/new_loc)
	if(new_loc)
		var/turf/T = get_turf(new_loc)

		if(T && istype(T, /turf/cordon/absolute) && !client?.holder)
			return FALSE

	return ..()


/turf/cordon/absolute
	space_lit = FALSE


/turf/cordon/absolute/CanPass(atom/movable/mover, border_dir)
	SHOULD_CALL_PARENT(FALSE)
	return FALSE


/turf/cordon/absolute/attack_ghost(mob/dead/observer/user)
	return FALSE


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

	return locate(
		round((BL.x + TR.x) / 2),
		round((BL.y + TR.y) / 2),
		BL.z
	)


/datum/turf_reservation/sub_level/proc/get_all_turfs()
	var/turf/BL = get_bottom_left_turf()
	var/turf/TR = get_top_right_turf()

	if(!BL || !TR)
		return list()

	return block(BL, TR)


/datum/turf_reservation/sub_level/proc/get_inner_bottom_left_turf()
	var/turf/BL = get_bottom_left_turf()

	if(!BL)
		return null

	return locate(
		BL.x + border_size,
		BL.y + border_size,
		BL.z
	)


/datum/turf_reservation/sub_level/proc/get_inner_top_right_turf()
	var/turf/TR = get_top_right_turf()

	if(!TR)
		return null

	return locate(
		TR.x - border_size,
		TR.y - border_size,
		TR.z
	)


/datum/turf_reservation/sub_level/proc/get_inner_bottom_right_turf()
	var/turf/BL = get_bottom_left_turf()
	var/turf/TR = get_top_right_turf()

	if(!BL || !TR)
		return null

	return locate(
		TR.x - border_size,
		BL.y + border_size,
		BL.z
	)


/datum/turf_reservation/sub_level/proc/get_inner_top_left_turf()
	var/turf/BL = get_bottom_left_turf()
	var/turf/TR = get_top_right_turf()

	if(!BL || !TR)
		return null

	return locate(
		BL.x + border_size,
		TR.y - border_size,
		BL.z
	)


/datum/turf_reservation/sub_level/proc/get_inner_turfs()
	var/turf/BL = get_inner_bottom_left_turf()
	var/turf/TR = get_inner_top_right_turf()

	if(!BL || !TR)
		return list()

	return block(BL, TR)


/datum/turf_reservation/sub_level/proc/get_cordon_turfs()
	return cordon_turfs ? cordon_turfs.Copy() : list()


/datum/turf_reservation/sub_level/proc/get_random_turf(include_cordon = FALSE)
	if(include_cordon)
		var/list/all_turfs = get_all_turfs()
		return length(all_turfs) ? pick(all_turfs) : null

	var/list/inners = get_inner_turfs()
	return length(inners) ? pick(inners) : null


/datum/turf_reservation/sub_level/proc/contains_turf(turf/T)
	if(!T)
		return FALSE

	if(T.z != z)
		return FALSE

	return T.x >= x_min && T.x <= x_max && T.y >= y_min && T.y <= y_max


/datum/turf_reservation/sub_level/proc/contains_inner_turf(turf/T)
	if(!T)
		return FALSE

	var/turf/BL = get_inner_bottom_left_turf()
	var/turf/TR = get_inner_top_right_turf()

	if(!BL || !TR || T.z != BL.z)
		return FALSE

	return T.x >= BL.x && T.x <= TR.x && T.y >= BL.y && T.y <= TR.y


/datum/turf_reservation/sub_level/Destroy()
	SSsub_levels.unregister_reservation(src)

	if(node)
		node.reserved = FALSE
		node.reservation = null

		var/datum/map_spatial_node/parent_node = node.parent
		node = null

		parent_node?.check_merge()

	return ..()
