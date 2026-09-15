/datum/map_spatial_node
	var/datum/sub_level/bounds
	var/datum/map_spatial_node/parent
	var/list/datum/map_spatial_node/children

	var/reserved = FALSE
	var/split = FALSE
	var/datum/turf_reservation/sub_level/reservation

/datum/map_spatial_node/New(turf/bottom_left, width, height, datum/map_spatial_node/parent_node = null)
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
	if(split || bounds.width < 8 || bounds.height < 8)
		return FALSE

	var/half_w = round(bounds.width / 2)
	var/half_h = round(bounds.height / 2)
	var/z_lvl = bounds.z

	var/turf/bl = locate(bounds.x_min, bounds.y_min, z_lvl)
	var/turf/br = locate(bounds.x_min + half_w, bounds.y_min, z_lvl)
	var/turf/tl = locate(bounds.x_min, bounds.y_min + half_h, z_lvl)
	var/turf/tr = locate(bounds.x_min + half_w, bounds.y_min + half_h, z_lvl)

	children = list(
		new /datum/map_spatial_node(bl, half_w, half_h, src),
		new /datum/map_spatial_node(br, bounds.width - half_w, half_h, src),
		new /datum/map_spatial_node(tl, half_w, bounds.height - half_h, src),
		new /datum/map_spatial_node(tr, bounds.width - half_w, bounds.height - half_h, src)
	)
	split = TRUE
	return TRUE

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
