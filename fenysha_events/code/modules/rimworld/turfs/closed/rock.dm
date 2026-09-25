/turf/closed/rw_wall/rock
	name = "rock"
	icon = MAP_SWITCH('fenysha_events/icons/turf/closed/mountain_wall.dmi', 'icons/turf/mining.dmi')
	icon_state = "mountain_wall-0"
	smoothing_groups = SMOOTH_GROUP_CLOSED_TURFS + SMOOTH_GROUP_MINERAL_WALLS
	canSmoothWith = SMOOTH_GROUP_MINERAL_WALLS
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_BORDER
	baseturfs = /turf/open/misc/asteroid/airless
	opacity = TRUE
	density = TRUE

	plane = WALL_PLANE
	layer = EDGED_TURF_LAYER
	base_icon_state = "mountain_wall"

	transform = MAP_SWITCH(TRANSLATE_MATRIX(-4, -4), matrix())
	max_integrity = 600

	/// How long it takes to complete one mine step with tools, before the tool's speed and the user's skill modifier are factored in.
	var/mine_speed = 25 SECONDS
	/// Anount of times we need to mine this turf to actually have result
	var/mine_steps = 3

	/// Shound this rock give stone chunk on mine
	var/give_stone_chunk = TRUE
	/// Type of stone chunk this rock gives
	var/stone_chunk_type

	/// Object type we want to give after mine
	var/obj/item/mine_result
	/// Default amount of mine_result wg give on mine
	var/mine_amout = 20

	var/mine_amount_affected_by_skill

	/// Material this wall relate to
	var/datum/material/rimworld_material/material
	/// Type of material, used is subtypes
	var/material_type
	var/stamp_visual = FALSE



/turf/closed/rw_wall/rock/Initialize(mapload)
	. = ..()
	if(stamp_visual)
		return
	var/wall_icon_state = "[base_icon_state]-255"
	add_large_wall_overlay(icon, wall_icon_state)

/turf/closed/rw_wall/rock/examine(mob/user)
	. = ..()
	if(material)
		. += span_notice("It seems like this rock is made of [material.name]")


// Rock that automaticaly apply it's colors and materials on spawn
/turf/closed/rw_wall/rock/auto

/turf/closed/rw_wall/rock/auto/Initialize(mapload)
	if(!stamp_visual)
		set_regional_effects()
	. = ..()

/turf/closed/rw_wall/rock/auto/proc/set_regional_effects()
	var/datum/planet_cell/my_cell = get_planet_cell(src)
	if(!my_cell)
		return FALSE
	var/datum/material/rimworld_material/my_mat = \
		SSmaterials.get_material(RW_MATERIAL_NAME_TO_TYPE[my_cell.material])
	if(!my_mat)
		return FALSE
	set_base_color(my_mat.color)
	name = "[my_mat.name] [name]"
	max_integrity = max_integrity * my_mat.get_hp_factor()
	mine_steps = round(mine_steps * my_mat.get_hp_factor())

	material = my_mat
	return TRUE
