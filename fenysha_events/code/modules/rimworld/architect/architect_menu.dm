/datum/rw_architect_menu
	var/mob/living/owner

/datum/rw_architect_menu/New(mob/living/user)
	owner = user

/datum/rw_architect_menu/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "FactionArchitect", "Architect")
		ui.open()

/datum/rw_architect_menu/ui_state(mob/user)
	if(user == owner)
		return GLOB.not_incapacitated_state
	return GLOB.never_state

/datum/rw_architect_menu/ui_static_data(mob/user)
	var/list/data = list()
	data["tabs"] = RW_ARCHITECT_TABS

	SSresearch.init_rw_registries()

	var/mob/living/L = user
	var/list/known_ids = L.rw_get_known_blueprint_ids()
	var/list/default_ids = L.rw_get_default_blueprint_ids()
	var/list/blueprints = list()

	for(var/id in known_ids)
		var/datum/building_blueprint/bp = SSresearch.get_building_blueprint(id)
		if(!bp)
			continue

		var/list/app = bp.get_ghost_appearance()
		var/list/mats = list()
		for(var/mat in bp.materials)
			var/mat_name = "[mat]"
			if(ispath(mat))
				var/atom/M = mat
				mat_name = initial(M.name)
			mats += list(list(
				"path" = "[mat]",
				"name" = mat_name,
				"amount" = bp.materials[mat],
			))

		blueprints += list(list(
			"id" = bp.id,
			"name" = bp.name,
			"desc" = bp.desc || "",
			"tab" = bp.architect_tab,
			"can_rotate" = bp.can_rotate,
			"is_multiblock" = bp.is_multiblock(),
			"construction_time" = bp.construction_time,
			"icon" = "[app["icon"]]",
			"icon_state" = app["icon_state"],
			"materials" = mats,
			"from_faction" = !(id in default_ids),
		))

	data["blueprints"] = blueprints
	return data

/datum/rw_architect_menu/ui_data(mob/user)
	var/list/data = list()
	var/mob/living/L = user
	var/datum/component/rw_build_plan/plan = L.rw_get_build_plan()
	data["planning"] = !!plan
	data["planning_id"] = plan?.blueprint?.id
	data["planning_name"] = plan?.blueprint?.name
	data["planning_dir"] = plan ? dir2text(plan.dir) : null
	data["has_faction"] = !!(istype(L.rw_faction, /datum/rw_faction/player))
	return data

/datum/rw_architect_menu/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	var/mob/living/L = ui.user
	if(L != owner)
		return FALSE

	switch(action)
		if("select")
			var/id = params["id"]
			if(!istext(id))
				return FALSE
			if(!L.rw_knows_blueprint(id))
				return FALSE
			return L.rw_start_build_plan(id, params["material"])
		if("cancel")
			return L.rw_cancel_build_plan()
		if("rotate")
			return L.rw_rotate_build_plan()
	return FALSE
