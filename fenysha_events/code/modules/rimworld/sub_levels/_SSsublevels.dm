SUBSYSTEM_DEF(sub_levels)
	name = "Sub-Levels"
	ss_flags = SS_NO_FIRE
	dependencies = list(
		/datum/controller/subsystem/mapping,
	)

	var/list/datum/map_spatial_node/root_nodes = list()
	var/list/datum/turf_reservation/sub_level/active_reservations = list()
	var/next_id = 1

/datum/controller/subsystem/sub_levels/Initialize()
	allocate_new_root_z_level()
	return ..()

/datum/controller/subsystem/sub_levels/proc/allocate_new_root_z_level()
	var/datum/space_level/SL = SSmapping.add_new_zlevel("SubLevel Z-[root_nodes.len + 1]")
	var/z_lvl = SL.z_value

	var/turf/bl = locate(1, 1, z_lvl)
	var/datum/map_spatial_node/root = new(bl, SUB_LEVEL_ROOT_SIZE, SUB_LEVEL_ROOT_SIZE)
	root_nodes += root
	return root

/datum/controller/subsystem/sub_levels/proc/create_sub_level(width, height, name = "")
	width = clamp(width, SUB_LEVEL_MIN_SIZE, SUB_LEVEL_MAX_SIZE)
	height = clamp(height, SUB_LEVEL_MIN_SIZE, SUB_LEVEL_MAX_SIZE)
	if(!length(name))
		name = "Sub-Level #[next_id]"

	var/res_id = next_id++
	var/datum/turf_reservation/sub_level/res = null
	for(var/datum/map_spatial_node/root in root_nodes)
		res = root.allocate_sub_level(width, height, res_id, name)
		if(res)
			break

	if(!res)
		var/datum/map_spatial_node/new_root = allocate_new_root_z_level()
		res = new_root.allocate_sub_level(width, height, res_id, name)

	if(!res)
		CRASH("SSsub_levels: Faied to allocate sublevel of size [width]x[height]")

	active_reservations["[res.id]"] = res
	return res

/datum/controller/subsystem/sub_levels/proc/unregister_reservation(datum/turf_reservation/sub_level/res)
	if(res.id)
		active_reservations.Remove("[res.id]")

/datum/controller/subsystem/sub_levels/proc/delete_sub_level(sub_level_id)
	var/datum/turf_reservation/sub_level/res = active_reservations["[sub_level_id]"]
	if(res)
		qdel(res)
		return TRUE
	return FALSE

/datum/controller/subsystem/sub_levels/proc/clear_sub_level(sub_level_id)
	var/datum/turf_reservation/sub_level/res = active_reservations["[sub_level_id]"]
	if(!res)
		return FALSE

	for(var/turf/T in res.reserved_turfs)
		T.empty(res.turf_type, res.turf_type_is_baseturf ? res.turf_type : null)
	return TRUE

/datum/controller/subsystem/sub_levels/proc/jump_to_sub_level(mob/user, sub_level_id)
	var/datum/turf_reservation/sub_level/res = active_reservations["[sub_level_id]"]
	if(!res || !res.bottom_left_turfs.len || !res.top_right_turfs.len)
		return FALSE

	var/turf/BL = res.bottom_left_turfs[1]
	var/turf/TR = res.top_right_turfs[1]
	var/center_x = round((BL.x + TR.x) / 2)
	var/center_y = round((BL.y + TR.y) / 2)
	var/turf/target = locate(center_x, center_y, BL.z)

	if(target && user)
		user.forceMove(target)
		to_chat(user, span_notice("Jumped to sub-level '[res.name]' ([res.width]x[res.height], Z:[BL.z])."))
		return TRUE
	return FALSE

/datum/controller/subsystem/sub_levels/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SubLevelsManager")
		ui.open()

/datum/controller/subsystem/sub_levels/ui_data(mob/user)
	var/list/data = list()
	var/list/levels_list = list()
	var/list/z_list = list()

	for(var/datum/map_spatial_node/root in root_nodes)
		if(root.bounds)
			z_list["[root.bounds.z]"] = root.bounds.z

	for(var/id_key in active_reservations)
		var/datum/turf_reservation/sub_level/res = active_reservations[id_key]
		if(!res || !res.bottom_left_turfs.len || !res.top_right_turfs.len)
			continue
		var/turf/BL = res.bottom_left_turfs[1]
		var/turf/TR = res.top_right_turfs[1]
		levels_list += list(list(
			"id" = res.id,
			"name" = res.name,
			"width" = res.width,
			"height" = res.height,
			"z" = BL.z,
			"x_min" = BL.x,
			"y_min" = BL.y,
			"x_max" = TR.x,
			"y_max" = TR.y,
			"created_at" = res.created_at
		))

	data["sub_levels"] = levels_list
	data["z_levels"] = z_list
	data["total_roots"] = root_nodes.len
	data["max_size"] = SUB_LEVEL_ROOT_SIZE
	return data

/datum/controller/subsystem/sub_levels/ui_state(mob/user)
	return ADMIN_STATE(R_ADMIN)

/datum/controller/subsystem/sub_levels/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	if(!check_rights_for(usr.client, R_ADMIN))
		return FALSE

	switch(action)
		if("create")
			var/w = text2num(params["width"])
			var/h = text2num(params["height"])
			var/name = html_encode(params["name"])
			if(w && h)
				create_sub_level(w, h, name)
				return TRUE

		if("delete")
			var/id = text2num(params["id"])
			if(id)
				delete_sub_level(id)
				return TRUE

		if("clear")
			var/id = text2num(params["id"])
			if(id)
				clear_sub_level(id)
				return TRUE

		if("jump")
			var/id = text2num(params["id"])
			if(id)
				jump_to_sub_level(ui.user, id)
				return TRUE

		if("rebuild_cordon")
			var/id = text2num(params["id"])
			var/datum/turf_reservation/sub_level/res = active_reservations["[id]"]
			if(res && res.bottom_left_turfs.len && res.top_right_turfs.len)
				res.calculate_cordon_turfs(res.bottom_left_turfs[1], res.top_right_turfs[1])
				res.generate_cordon()
				return TRUE

ADMIN_VERB(open_sublevel_editor, R_ADMIN, "\[RW\] Sublevels", "Open sub level manager.", ADMIN_CATEGORY_EVENTS)
	SSsub_levels.ui_interact(usr)
