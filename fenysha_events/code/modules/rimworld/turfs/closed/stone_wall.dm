/turf/closed/rw_wall/stone
	name = "wall"
	desc = "A sturdy stone wall."

	icon = 'fenysha_events/icons/turf/closed/stone_wall_grayscale.dmi'
	icon_state = "iron_wall-0"
	base_icon_state = "iron_wall"

	explosive_resistance = 2
	hardness = 80
	min_weapon_damage = 20
	max_weapon_damage = 50

	brute_damage_multiplier = 0.50
	burn_damage_multiplier = 0.20

	explosion_damage_multiplier = 0.5

	use_material = TRUE

/turf/closed/rw_wall/stone/apply_material(datum/material/rimworld_material/path_of_istance)
	. = ..()

	if(!.)
		return FALSE

	var/datum/material/rimworld_material/my_mat = .
	if(my_mat.sheet_type)
		repair_resources = list(my_mat.sheet_type = 1)

	return .

/turf/closed/rw_wall/stone/granite
	material_type = /datum/material/rimworld_material/granite

/turf/closed/rw_wall/stone/marble
	material_type = /datum/material/rimworld_material/marble

/turf/closed/rw_wall/stone/limestone
	material_type = /datum/material/rimworld_material/limestone

/turf/closed/rw_wall/stone/sandstone
	material_type = /datum/material/rimworld_material/sandstone

/turf/closed/rw_wall/stone/slate
	material_type = /datum/material/rimworld_material/slate

/turf/closed/rw_wall/stone/jade
	material_type = /datum/material/rimworld_material/jade

/turf/closed/rw_wall/stone/obsidian
	material_type = /datum/material/rimworld_material/obsidian
