/datum/element/diggable_advanced
	element_flags = ELEMENT_BESPOKE | ELEMENT_DETACH_ON_HOST_DESTROY
	argument_hash_start_idx = 2

	/// Typepath of what we spawn on shovel
	var/atom/to_spawn
	/// Amount to spawn on shovel
	var/amount
	/// What should we tell the user they did?
	var/action_text
	/// What should we tell other people what the user did?
	var/action_text_third_person
	/// Percentage chance of receiving a bonus worm
	var/worm_chance
	/// Callback invoked after the dig is complete.
	/// Expected args: (turf/source, mob/user, obj/item/tool)
	var/datum/callback/post_dig_callback

/datum/element/diggable_advanced/Attach(
	datum/target,
	to_spawn,
	amount = 1,
	worm_chance = 30,
	action_text = "dig up",
	action_text_third_person = "digs up",
	datum/callback/post_dig_callback = null
)
	. = ..()
	if(!isturf(target))
		return ELEMENT_INCOMPATIBLE
	if(!to_spawn)
		stack_trace("[type] wasn't passed a typepath to spawn attaching to [target].")
		return ELEMENT_INCOMPATIBLE

	src.to_spawn = to_spawn
	src.amount = amount
	src.worm_chance = worm_chance
	src.action_text = action_text
	src.action_text_third_person = action_text_third_person
	src.post_dig_callback = post_dig_callback

	RegisterSignal(target, COMSIG_ATOM_TOOL_ACT(TOOL_SHOVEL), PROC_REF(on_shovel))

/datum/element/diggable_advanced/Detach(datum/source, ...)
	. = ..()
	UnregisterSignal(source, COMSIG_ATOM_TOOL_ACT(TOOL_SHOVEL))
	post_dig_callback = null


/datum/element/diggable_advanced/proc/on_shovel(turf/source, mob/user, obj/item/tool)
	SIGNAL_HANDLER

	for(var/i in 1 to amount)
		new to_spawn(source)

	if(prob(worm_chance))
		new /obj/item/food/bait/worm(source)

	user.visible_message(
		span_notice("[user] [action_text_third_person] [source]."),
		span_notice("You [action_text] [source]."),
	)

	playsound(source, 'sound/effects/shovel_dig.ogg', 50, TRUE)
	if(post_dig_callback)
		post_dig_callback.Invoke(source, user, tool)

	source.ScrapeAway(flags = CHANGETURF_INHERIT_AIR)


/turf/open/rimworld/dirt
	name = "Dirt"
	desc = "Ordinary dirt - not particularly well-suited for growing plants."

	icon = 'fenysha_events/icons/turf/floors/nature/dirt.dmi'
	icon_state = "0"


	edge_priority = 5
	baseturfs = /turf/open/rimworld/dirt
	slowdown = 0.35
	rw_turf_flags = SUPPORTS_MOBS

	footstep = FOOTSTEP_SAND
	barefootstep = FOOTSTEP_SAND
	clawfootstep = FOOTSTEP_SAND

	var/variant_amount = 15

/turf/open/rimworld/dirt/mud
	name = "mud"
	desc = "Wet earth along the water. Grass does not take here."
	baseturfs = /turf/open/rimworld/dirt/mud

/turf/open/rimworld/dirt/Initialize(mapload)
	if(!stamp_visual)
		icon_state = "[rand(0, variant_amount)]"
	. = ..()


/turf/open/rimworld/grass
	name = "Grass"
	desc = "An ordinary grass. Touch it. It's not a bad choice for growing plants."

	icon = 'fenysha_events/icons/turf/floors/nature/grayscale/grass_grayscale.dmi'
	icon_state = "0"

	color = GRASS_COLOR_FOREST
	base_color = GRASS_COLOR_FOREST

	footstep = FOOTSTEP_SAND
	barefootstep = FOOTSTEP_SAND
	clawfootstep = FOOTSTEP_SAND
	baseturfs = /turf/open/rimworld/dirt
	edge_priority = 7
	fertility = 1.0
	can_be_tilled = TRUE

	slowdown = 0.5
	seasonal_color = TRUE
	var/variant_amount = 5

/turf/open/rimworld/grass/Initialize(mapload)
	if(!stamp_visual)
		icon_state = "[rand(0, variant_amount)]"
		if(base_color)
			set_base_color(base_color)
		else if(color)
			set_base_color(color)
	. = ..()

/turf/open/rimworld/grass/proc/blend_neighbor_color()
	var/list/mine = rw_color_channels(color)
	if(!mine)
		return
	var/red = mine[1]
	var/green = mine[2]
	var/blue = mine[3]
	var/samples = 1
	for(var/direction in GLOB.cardinals)
		var/turf/open/rimworld/grass/neighbor = get_step(src, direction)
		if(!istype(neighbor))
			continue
		var/list/theirs = rw_color_channels(neighbor.color)
		if(!theirs)
			continue
		red += theirs[1]
		green += theirs[2]
		blue += theirs[3]
		samples++
	if(samples <= 1)
		return
	var/blended = rgb(round(red / samples), round(green / samples), round(blue / samples))
	color = blended
	set_base_color(blended)

/proc/rw_color_channels(value)
	if(!istext(value) || length(value) < 7 || copytext(value, 1, 2) != "#")
		return null
	return list(
		text2num(copytext(value, 2, 4), 16),
		text2num(copytext(value, 4, 6), 16),
		text2num(copytext(value, 6, 8), 16)
	)


/turf/open/rimworld/grass/light
	name = "Light grass"
	icon = 'fenysha_events/icons/turf/floors/nature/grayscale/grasslight_grayscale.dmi'
	icon_state = "0"

	color = GRASS_COLOR_FOREST_LIGHT
	base_color = GRASS_COLOR_FOREST_LIGHT

	fertility = 1.1
	edge_priority = 8

/turf/open/rimworld/grass/tall
	name = "Tall grass"

	icon = 'fenysha_events/icons/turf/floors/nature/grayscale/grasstall_grayscale.dmi'
	icon_state = "0"

	color = GRASS_COLOR_FOREST_TALL
	base_color = GRASS_COLOR_FOREST_TALL
	fertility = 1.5

	edge_priority = 9
	slowdown = 1.1



/turf/open/rimworld/grass/forest
	color = GRASS_COLOR_FOREST
	base_color = GRASS_COLOR_FOREST_LIGHT

	edge_priority = 7
	fertility = 1.0

/turf/open/rimworld/grass/forest/light
	color = GRASS_COLOR_FOREST_LIGHT
	base_color = GRASS_COLOR_FOREST_LIGHT

	edge_priority = 8
	fertility = 1.1

/turf/open/rimworld/grass/forest/tall
	color = GRASS_COLOR_FOREST_TALL
	base_color = GRASS_COLOR_FOREST_TALL

	edge_priority = 9
	fertility = 1.4
	slowdown = 1.0


/turf/open/rimworld/grass/jungle
	name = "Jungle grass"

	color = GRASS_COLOR_JUNGLE
	base_color = GRASS_COLOR_JUNGLE

	edge_priority = 7
	fertility = 1.3
	slowdown = 0.7

/turf/open/rimworld/grass/jungle/light
	color = GRASS_COLOR_JUNGLE_LIGHT
	base_color = GRASS_COLOR_JUNGLE_LIGHT

	edge_priority = 8
	fertility = 1.4

/turf/open/rimworld/grass/jungle/tall
	color = GRASS_COLOR_JUNGLE_TALL
	base_color = GRASS_COLOR_JUNGLE_TALL

	edge_priority = 9
	fertility = 1.6
	slowdown = 1.2


/turf/open/rimworld/grass/savanna
	name = "Savanna grass"

	color = GRASS_COLOR_SAVANNA
	base_color = GRASS_COLOR_SAVANNA

	edge_priority = 7
	fertility = 0.85
	slowdown = 0.4

/turf/open/rimworld/grass/savanna/light
	color = GRASS_COLOR_SAVANNA_LIGHT
	base_color = GRASS_COLOR_SAVANNA_LIGHT

	edge_priority = 8
	fertility = 0.9

/turf/open/rimworld/grass/savanna/tall
	color = GRASS_COLOR_SAVANNA_TALL
	base_color = GRASS_COLOR_SAVANNA_TALL

	edge_priority = 9
	fertility = 1.1
	slowdown = 0.9


/turf/open/rimworld/sand
	name = "Sand"
	desc = "Warm and soft sand."

	icon = 'fenysha_events/icons/turf/floors/nature/grayscale/sand_grayscale.dmi'
	icon_state = "0"

	baseturfs = /turf/open/rimworld/sand
	color = SAND_COLOR_NORMAL
	base_color = SAND_COLOR_NORMAL
	fertility = 0.0
	can_be_tilled = FALSE
	edge_priority = 5

	footstep = FOOTSTEP_SAND
	barefootstep = FOOTSTEP_SAND
	clawfootstep = FOOTSTEP_SAND
	leave_footprints = TRUE

	slowdown = 0.25
	var/variant_amount = 4

/turf/open/rimworld/sand/Initialize(mapload)
	icon_state = "[rand(0, variant_amount)]"
	. = ..()

/turf/open/rimworld/sand/chalk
	name = "Chalk sand"
	desc = "Pale, almost white sand that crumbles easily between your fingers. Reminds you of old chalk cliffs."

	color = SAND_COLOR_CHALK
	base_color = SAND_COLOR_CHALK
	baseturfs = /turf/open/rimworld/sand/chalk
	slowdown = 0.2

/turf/open/rimworld/sand/red
	name = "Red sand"
	desc = "Warm terracotta-colored sand. It holds the heat of the sun long after dusk."

	color = SAND_COLOR_RED
	base_color = SAND_COLOR_RED
	baseturfs = /turf/open/rimworld/sand/red
	slowdown = 0.3

/turf/open/rimworld/sand/black
	name = "Black sand"
	desc = "Dark volcanic sand, coarse and heavy. It still smells faintly of ash and sulfur."

	color = SAND_COLOR_BLACK
	base_color = SAND_COLOR_BLACK
	baseturfs = /turf/open/rimworld/sand/black
	slowdown = 0.35

/turf/open/rimworld/sand/white
	name = "White sand"
	desc = "Fine, almost pure white sand. Soft underfoot and cool even under the midday sun."

	color = SAND_COLOR_WHITE
	base_color = SAND_COLOR_WHITE
	baseturfs = /turf/open/rimworld/sand/white
	slowdown = 0.2

/turf/open/rimworld/sand/yellow
	name = "Yellow sand"
	desc = "Bright yellow sand that glitters faintly in the light. Typical of open desert dunes."

	color = SAND_COLOR_YELLOW
	base_color = SAND_COLOR_YELLOW
	baseturfs = /turf/open/rimworld/sand/yellow

/turf/open/rimworld/sand/orange
	name = "Orange sand"
	desc = "Rusty orange sand with a slightly metallic tint. It stains everything it touches."

	color = SAND_COLOR_ORANGE
	base_color = SAND_COLOR_ORANGE
	baseturfs = /turf/open/rimworld/sand/orange
	slowdown = 0.3

/turf/open/rimworld/sand/pink
	name = "Pink sand"
	desc = "Unusual pinkish sand, soft and fine. Looks almost artificial against the landscape."

	color = SAND_COLOR_PINK
	base_color = SAND_COLOR_PINK
	baseturfs = /turf/open/rimworld/sand/pink
	slowdown = 0.2

/turf/open/rimworld/sand/silver
	name = "Silver sand"
	desc = "Cool, metallic-looking sand with a subtle silvery sheen. It feels strangely smooth."

	color = SAND_COLOR_SILVER
	base_color = SAND_COLOR_SILVER
	baseturfs = /turf/open/rimworld/sand/silver
	slowdown = 0.25

/turf/open/rimworld/sand/golden
	name = "Golden sand"
	desc = "Rich golden sand that catches the light beautifully. Warm and pleasant to walk on."

	color = SAND_COLOR_GOLDEN
	base_color = SAND_COLOR_GOLDEN
	baseturfs = /turf/open/rimworld/sand/golden
	slowdown = 0.25

/turf/open/rimworld/sand/dark
	name = "Dark sand"
	desc = "Deep brownish sand, denser than usual. It packs firmly underfoot."

	color = SAND_COLOR_DARK
	base_color = SAND_COLOR_DARK
	baseturfs = /turf/open/rimworld/sand/dark
	slowdown = 0.35

/turf/open/rimworld/sand/ash
	name = "Ash sand"
	desc = "Gray, lifeless sand mixed with fine ash. Nothing grows here, and the air feels dry."

	color = SAND_COLOR_ASH
	base_color = SAND_COLOR_ASH
	baseturfs = /turf/open/rimworld/sand/ash
	slowdown = 0.3

/turf/open/rimworld/rock
	name = "rock"
	desc = "solid rock"

	icon = 'fenysha_events/icons/turf/floors/nature/grayscale/cave_grayscale.dmi'
	icon_state = "0"

	baseturfs = /turf/open/rimworld/rock
	fertility = 0.0
	can_be_tilled = FALSE

	footstep = FOOTSTEP_CONCRETE
	barefootstep = FOOTSTEP_CONCRETE
	clawfootstep = FOOTSTEP_CONCRETE
	leave_footprints = FALSE

	var/datum/material/rimworld_material/material
	var/material_type
	var/varian_amount = 13

	slowdown = 0.1

/turf/open/rimworld/rock/Initialize(mapload)
	if(!stamp_visual)
		icon_state = "[rand(0, varian_amount)]"
		if(material_type && ispath(material_type, /datum/material/rimworld_material))
			apply_material(SSmaterials.get_material(material_type))
	. = ..()

/turf/open/rimworld/rock/examine(mob/user)
	. = ..()
	if(material)
		. += span_notice("It seems like this rock is made of [material.name]")

/turf/open/rimworld/rock/proc/apply_material(datum/material/rimworld_material/mat)
	if(!mat)
		return FALSE
	set_base_color(mat.color)
	name = "[mat.name] [name]"
	return TRUE

/turf/open/rimworld/rock/auto
	baseturfs = /turf/open/rimworld/rock/auto

/turf/open/rimworld/rock/auto/Initialize(mapload)
	. = ..()
	if(!stamp_visual)
		set_regional_effects()

/turf/open/rimworld/rock/auto/proc/set_regional_effects()
	var/datum/planet_cell/my_cell = get_planet_cell(src)
	if(!my_cell)
		return FALSE
	var/datum/material/rimworld_material/my_mat = \
		SSmaterials.get_material(RW_MATERIAL_NAME_TO_TYPE[my_cell.material])
	if(!my_mat)
		return FALSE
	return apply_material(my_mat)
