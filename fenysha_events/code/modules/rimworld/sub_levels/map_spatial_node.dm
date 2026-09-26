/datum/map_spatial_node
	var/datum/sub_level/bounds
	var/datum/map_spatial_node/parent
	var/list/datum/map_spatial_node/children

	var/reserved = FALSE
	var/split = FALSE
	var/datum/turf_reservation/sub_level/reservation


/datum/map_spatial_node/New(
	turf/bottom_left,
	width,
	height,
	datum/map_spatial_node/parent_node = null
)
	bounds = new /datum/sub_level(bottom_left, width, height)
	parent = parent_node


/datum/map_spatial_node/Destroy()
	if(reservation)
		qdel(reservation)
		reservation = null

	if(children)
		QDEL_LIST(children)

	qdel(bounds)
	bounds = null
	parent = null

	return ..()


/datum/map_spatial_node/proc/subdivide()
	if(split || !bounds)
		return FALSE

	/**
	 * Root:
	 *
	 * 255x255
	 *
	 * becomes four:
	 *
	 * 127x127
	 * 127x127
	 * 127x127
	 * 127x127
	 *
	 * leaving one unused row and one unused column.
	 */
	if(
		!parent \
		&& bounds.width == RW_SUBLEVEL_ROOT_WIDTH \
		&& bounds.height == RW_SUBLEVEL_ROOT_HEIGHT
	)
		var/z_lvl = bounds.z
		var/base_x = bounds.x_min
		var/base_y = bounds.y_min

		var/turf/bl = locate(base_x, base_y, z_lvl)
		var/turf/br = locate(base_x + RW_SUBLEVEL_SLOT_WIDTH, base_y, z_lvl)
		var/turf/tl = locate(base_x, base_y + RW_SUBLEVEL_SLOT_HEIGHT, z_lvl)
		var/turf/tr = locate(
			base_x + RW_SUBLEVEL_SLOT_WIDTH,
			base_y + RW_SUBLEVEL_SLOT_HEIGHT,
			z_lvl
		)

		if(!bl || !br || !tl || !tr)
			return FALSE

		children = list(
			new /datum/map_spatial_node(
				bl,
				RW_SUBLEVEL_SLOT_WIDTH,
				RW_SUBLEVEL_SLOT_HEIGHT,
				src
			),
			new /datum/map_spatial_node(
				br,
				RW_SUBLEVEL_SLOT_WIDTH,
				RW_SUBLEVEL_SLOT_HEIGHT,
				src
			),
			new /datum/map_spatial_node(
				tl,
				RW_SUBLEVEL_SLOT_WIDTH,
				RW_SUBLEVEL_SLOT_HEIGHT,
				src
			),
			new /datum/map_spatial_node(
				tr,
				RW_SUBLEVEL_SLOT_WIDTH,
				RW_SUBLEVEL_SLOT_HEIGHT,
				src
			)
		)

		split = TRUE
		return TRUE

	if(bounds.width < 8 || bounds.height < 8)
		return FALSE

	var/half_w = round(bounds.width / 2)
	var/half_h = round(bounds.height / 2)
	var/z_lvl = bounds.z

	var/turf/bl = locate(bounds.x_min, bounds.y_min, z_lvl)
	var/turf/br = locate(bounds.x_min + half_w, bounds.y_min, z_lvl)
	var/turf/tl = locate(bounds.x_min, bounds.y_min + half_h, z_lvl)
	var/turf/tr = locate(
		bounds.x_min + half_w,
		bounds.y_min + half_h,
		z_lvl
	)

	if(!bl || !br || !tl || !tr)
		return FALSE

	children = list(
		new /datum/map_spatial_node(
			bl,
			half_w,
			half_h,
			src
		),
		new /datum/map_spatial_node(
			br,
			bounds.width - half_w,
			half_h,
			src
		),
		new /datum/map_spatial_node(
			tl,
			half_w,
			bounds.height - half_h,
			src
		),
		new /datum/map_spatial_node(
			tr,
			bounds.width - half_w,
			bounds.height - half_h,
			src
		)
	)

	split = TRUE
	return TRUE


/datum/map_spatial_node/proc/allocate_sub_level(
	req_w,
	req_h,
	res_id = 0,
	res_name = ""
)
	if(reserved || !bounds)
		return null

	/**
	 * Requested size is the PLAYABLE area.
	 *
	 * Reservation automatically gets one-tile border on every side,
	 * and takes the smallest node that fits it.
	 */
	var/slot_w = req_w + RW_SUBLEVEL_BORDER_SIZE * 2
	var/slot_h = req_h + RW_SUBLEVEL_BORDER_SIZE * 2

	if(bounds.width < slot_w || bounds.height < slot_h)
		return null

	if(split)
		for(var/datum/map_spatial_node/child in children)
			var/datum/turf_reservation/sub_level/res = child.allocate_sub_level(
				req_w,
				req_h,
				res_id,
				res_name
			)

			if(res)
				return res

		return null

	// Halves are rounded down, so the smallest child is this size
	var/smallest_child_w = round(bounds.width / 2)
	var/smallest_child_h = round(bounds.height / 2)
	if(smallest_child_w >= slot_w && smallest_child_h >= slot_h && subdivide())
		for(var/datum/map_spatial_node/child in children)
			var/datum/turf_reservation/sub_level/res = child.allocate_sub_level(
				req_w,
				req_h,
				res_id,
				res_name
			)

			if(res)
				return res

		return null

	reserved = TRUE
	reservation = new /datum/turf_reservation/sub_level(
		src,
		res_id,
		res_name,
		TRUE
	)
	return reservation


/datum/map_spatial_node/proc/check_merge()
	if(!split)
		return

	for(var/datum/map_spatial_node/child in children)
		if(child.reserved || child.split)
			return

	QDEL_LIST(children)
	children = null
	split = FALSE

	parent?.check_merge()
