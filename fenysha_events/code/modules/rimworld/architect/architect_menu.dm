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

	var/list/materials = list()
	var/list/categories = list()
	for(var/mat_path in rw_get_stuff_sheets())
		var/datum/material/rimworld_material/mat = GET_MATERIAL_REF(mat_path)
		if(!istype(mat))
			continue
		var/category = "[mat.stuff_category]"
		categories |= category
		materials += list(list(
			"path" = "[mat_path]",
			"name" = mat.name,
			"desc" = mat.desc,
			"color" = mat.color,
			"category" = category,
			"hp" = mat.get_hp_factor(),
			"beauty" = mat.get_beauty_factor(),
			"flammability" = mat.get_flammability_factor(),
			"armor_sharp" = mat.get_armor_sharp(),
			"armor_blunt" = mat.get_armor_blunt(),
			"armor_heat" = mat.get_armor_heat(),
			"value" = mat.get_market_value(),
		))
	data["materials"] = materials
	data["material_categories"] = categories

	var/mob/living/L = user
	var/list/known_ids = L.rw_get_known_blueprint_ids()
	var/list/default_ids = L.rw_get_default_blueprint_ids()
	var/list/blueprints = list()

	for(var/id in known_ids)
		var/datum/building_blueprint/bp = SSresearch.get_building_blueprint(id)
		if(!bp)
			continue

		var/list/app = bp.get_ghost_appearance()
		var/list/extra = list()
		for(var/mat in bp.materials)
			var/mat_name = "[mat]"
			if(ispath(mat))
				var/atom/M = mat
				mat_name = initial(M.name)
			extra += list(list(
				"path" = "[mat]",
				"name" = mat_name,
				"amount" = bp.materials[mat],
			))

		var/list/stuff_cats = list()
		for(var/cat in bp.stuff_categories)
			stuff_cats += "[cat]"

		blueprints += list(list(
			"id" = bp.id,
			"name" = bp.name,
			"desc" = bp.desc || "",
			"tab" = bp.architect_tab,
			"can_rotate" = bp.can_rotate,
			"is_multiblock" = bp.is_multiblock(),
			"construction_time" = bp.construction_time,
			"build_steps" = bp.build_steps,
			"icon" = "[app["icon"]]",
			"icon_state" = app["icon_state"],
			"extra_costs" = extra,
			"stuffed" = bp.is_stuffed(),
			"stuff_cost" = bp.stuff_cost,
			"stuff_categories" = stuff_cats,
			"default_stuff" = bp.is_stuffed() ? "[rw_default_stuff_for(bp)]" : null,
			"from_faction" = !(id in default_ids),
		))

		blueprints += list(list(
			"id" = "__cancel__",
			"name" = "Cancel Blueprints",
			"desc" = "Remove existing construction holograms and frames by selection or dragging.",
			"tab" = RW_ARCHITECT_TAB_MISC,
			"can_rotate" = FALSE,
			"is_multiblock" = FALSE,
			"construction_time" = 0,
			"build_steps" = 0,
			"icon" = "icons/hud/buildmode.dmi",
			"icon_state" = "buildmode_delete",
			"extra_costs" = list(),
			"stuffed" = FALSE,
			"stuff_cost" = 0,
			"stuff_categories" = list(),
			"default_stuff" = null,
			"from_faction" = FALSE,
			"is_cancel" = TRUE,
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
	data["planning_material"] = plan?.material_path ? "[plan.material_path]" : null
	data["has_faction"] = !!(istype(L.rw_faction, /datum/rw_faction/player))

	var/list/stock = list()
	for(var/obj/item/stack/sheet/rimworld/S in L.get_all_contents())
		if(S.rimworld_mat_type)
			stock["[S.rimworld_mat_type]"] += S.amount
	data["stock"] = stock
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
			if(params["id"] == "__cancel__" || params["is_cancel"])
				return L.rw_start_cancel_plan()
			if(!L.rw_knows_blueprint(id))
				return FALSE
			var/datum/building_blueprint/bp = SSresearch.get_building_blueprint(id)
			if(!bp)
				return FALSE
			var/material_path
			if(bp.is_stuffed())
				if(istext(params["material"]))
					material_path = text2path(params["material"])
				if(!rw_blueprint_allows_stuff(bp, material_path))
					material_path = rw_default_stuff_for(bp)
			return L.rw_start_build_plan(id, material_path)
		if("cancel")
			return L.rw_cancel_build_plan()
		if("rotate")
			return L.rw_rotate_build_plan()
		if("cancel_mode")
			return L.rw_start_cancel_plan()
	return FALSE
