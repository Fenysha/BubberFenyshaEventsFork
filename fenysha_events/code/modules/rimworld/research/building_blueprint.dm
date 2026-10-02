/datum/controller/subsystem/research
	var/list/building_blueprints = list()
	var/list/rw_crafting_recipes = list()
	var/rw_registries_ready = FALSE

/datum/controller/subsystem/research/proc/init_rw_registries()
	if(rw_registries_ready)
		return
	rw_registries_ready = TRUE

	for(var/blueprint_type in subtypesof(/datum/building_blueprint))
		var/datum/building_blueprint/blueprint = new blueprint_type
		if(!blueprint.id)
			qdel(blueprint)
			continue
		if(building_blueprints[blueprint.id])
			stack_trace("Duplicate building blueprint id '[blueprint.id]' ([blueprint_type])")
			qdel(blueprint)
			continue
		building_blueprints[blueprint.id] = blueprint

	for(var/recipe_type in subtypesof(/datum/rw_crafting_recipe))
		var/datum/rw_crafting_recipe/recipe = new recipe_type
		if(!recipe.id)
			qdel(recipe)
			continue
		if(rw_crafting_recipes[recipe.id])
			stack_trace("Duplicate crafting recipe id '[recipe.id]' ([recipe_type])")
			qdel(recipe)
			continue
		rw_crafting_recipes[recipe.id] = recipe

/datum/controller/subsystem/research/proc/get_building_blueprint(blueprint_id)
	init_rw_registries()
	return building_blueprints[blueprint_id]

/datum/controller/subsystem/research/proc/get_rw_crafting_recipe(recipe_id)
	init_rw_registries()
	return rw_crafting_recipes[recipe_id]


/datum/building_blueprint
	var/id
	var/name = "Unnamed Blueprint"
	var/desc = ""
	var/icon
	var/icon_state

	var/architect_tab = RW_ARCHITECT_TAB_STRUCTURE

	var/build_path
	var/multiblock_layout_id

	var/list/materials = list()
	var/construction_time = 5 SECONDS
	var/can_rotate = TRUE
	var/list/placement_flags = list()
	var/required_skill
	var/ideal_skill = 6

	var/ghost_icon
	var/ghost_icon_state

	var/default_unlocked = FALSE

/datum/building_blueprint/proc/is_multiblock()
	return !!multiblock_layout_id

/datum/building_blueprint/proc/get_ghost_appearance()
	if(ghost_icon && ghost_icon_state)
		return list("icon" = ghost_icon, "icon_state" = ghost_icon_state)
	if(build_path)
		var/atom/A = build_path
		return list("icon" = initial(A.icon), "icon_state" = initial(A.icon_state))
	return list("icon" = 'icons/effects/effects.dmi', "icon_state" = "eating_zone")
