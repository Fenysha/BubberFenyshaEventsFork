/turf/closed/rw_wall/rock
	name = "rock"
	icon = MAP_SWITCH('fenysha_events/icons/turf/closed/mountain_wall.dmi', 'icons/turf/mining.dmi')
	icon_state = "mountain_wall-0"
	smoothing_groups = SMOOTH_GROUP_CLOSED_TURFS + SMOOTH_GROUP_MINERAL_WALLS
	canSmoothWith = SMOOTH_GROUP_MINERAL_WALLS
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_BORDER
	baseturfs = /turf/open/bottom_or_region
	opacity = TRUE
	density = TRUE

	plane = WALL_PLANE
	layer = EDGED_TURF_LAYER
	base_icon_state = "mountain_wall"

	transform = MAP_SWITCH(TRANSLATE_MATRIX(-4, -4), matrix())
	can_repair = FALSE
	max_integrity = 600

	/// How long it takes to complete one mine step with tools
	var/mine_speed = 25 SECONDS
	/// Amount of times we need to mine this turf to actually have result
	var/mine_steps = 3
	/// Current progress
	var/mine_progress = 0

	/// Mining skill level at which mining uses the base duration.
	var/mine_ideal_skill = 10

	/// Skill XP awarded for every successfully completed mining step.
	var/mine_skill_points = 5

	/// Should this rock give stone chunk on mine
	var/give_stone_chunk = TRUE
	/// Type of stone chunk this rock gives
	var/stone_chunk_type = /obj/item/rock_chunk

	/// Object type we want to give after mine
	var/obj/item/mine_result
	var/mine_amout = 20
	var/mine_amount_affected_by_skill

	/// Material this wall relate to
	var/datum/material/rimworld_material/material
	var/material_type
	var/stamp_visual = FALSE

	/// Path to the ore type this rock contains (null = pure stone)
	var/obj/item/stack/ore/rimworld/ore_type = null
	/// How much ore to drop on full mine
	var/ore_amount = 1
	/// Overlay currently applied for the ore
	var/mutable_appearance/ore_overlay


/turf/closed/rw_wall/rock/Initialize(mapload)
	. = ..()
	if(stamp_visual)
		return
	var/wall_icon_state = "[base_icon_state]-255"
	add_large_wall_overlay(icon, wall_icon_state)

	if(ore_type)
		add_ore(ore_type, ore_amount)


/turf/closed/rw_wall/rock/examine(mob/user)
	. = ..()
	if(material)
		. += span_notice("It seems like this rock is made of [material.name].")
	if(has_ore())
		var/obj/item/stack/ore/rimworld/dummy = ore_type
		. += span_notice("You can see veins of [initial(dummy.name)] running through it.")


/turf/closed/rw_wall/rock/Destroy(force)
	cut_ore_overlay()
	return ..()


/turf/closed/rw_wall/rock/proc/add_ore(ore_path, amount = 1)
	if(!ispath(ore_path, /obj/item/stack/ore/rimworld))
		return FALSE

	ore_type = ore_path
	ore_amount = max(1, amount)

	cut_ore_overlay()

	var/fragment_state = "ore_fragments-0"
	if(istext(icon_state) && findtext(icon_state, "-"))
		var/list/parts = splittext(icon_state, "-")
		if(length(parts) >= 2)
			fragment_state = "ore_fragments-[parts[length(parts)]]"

	ore_overlay = mutable_appearance(
		'fenysha_events/icons/turf/closed/ore_fragments.dmi',
		fragment_state,
		layer = layer + 0.1,
		plane = plane,
		appearance_flags = RESET_COLOR | RESET_ALPHA | RESET_TRANSFORM | KEEP_APART
	)
	ore_overlay.color = initial(ore_type.rimworld_mat.color)
	add_overlay(ore_overlay)
	return TRUE


/turf/closed/rw_wall/rock/proc/has_ore()
	return !isnull(ore_type)


/turf/closed/rw_wall/rock/proc/cut_ore_overlay()
	if(ore_overlay)
		cut_overlay(ore_overlay)
		ore_overlay = null


/turf/closed/rw_wall/rock/proc/create_vein(ore_path = ore_type, radius = 2, chance = 60, min_amount = 1, max_amount = 3)
	if(!ore_path)
		return 0

	var/created = 0
	for(var/turf/closed/rw_wall/rock/neighbor in RANGE_TURFS(radius, src))
		if(neighbor == src)
			continue
		if(neighbor.has_ore())
			continue
		if(!prob(chance))
			continue

		var/amt = rand(min_amount, max_amount)
		if(neighbor.add_ore(ore_path, amt))
			created++

	return created



/turf/closed/rw_wall/rock/hand_interaction(mob/user, list/modifiers)
	if(user.do_after_count())
		return TRUE

	INVOKE_ASYNC(src, PROC_REF(try_mine), user, null)
	return TRUE

/turf/closed/rw_wall/rock/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(user.combat_mode || user.do_after_count())
		return ..()

	if(tool.tool_behaviour == TOOL_MINING || tool.tool_behaviour == TOOL_CROWBAR || tool.tool_behaviour == TOOL_WRENCH)
		try_mine(user, tool)
		return ITEM_INTERACT_SUCCESS

	return ..()


/turf/closed/rw_wall/rock/proc/try_mine(mob/living/user, obj/item/tool)
	if(!user || destroying)
		return FALSE

	var/speed = mine_speed

	if(tool)
		speed = tool.toolspeed * (mine_speed * 0.4 + 1)
	else
		speed = mine_speed * 2.5
		to_chat(user, span_notice("You start clawing at the [name] with your bare hands..."))

	user.visible_message(
		span_notice("[user] starts mining [src]..."),
		span_notice("You start mining [src]...")
	)

	if(!rw_do_after(
		user,
		speed,
		src,
		RW_SKILL_MINING,
		mine_ideal_skill,
		1 SECONDS,
		mine_skill_points
	))
		return FALSE

	mine_progress++

	playsound(src, 'sound/effects/break_stone.ogg', 50, TRUE)
	if(mine_progress < mine_steps)
		to_chat(user, span_notice("You chip away at the rock."))

		take_brute_damage(max_integrity * 0.15, user, tool)
		return try_mine(user, tool)

	finish_mine(user, tool)
	return TRUE


/turf/closed/rw_wall/rock/proc/finish_mine(mob/living/user, obj/item/tool)
	if(give_stone_chunk && stone_chunk_type)
		var/obj/item/rock_chunk/chunk = new stone_chunk_type(src)
		if(material)
			chunk.material = material
			chunk.name = "[material.name] [chunk.name]"
			chunk.color = material.color

	if(has_ore())
		var/obj/item/stack/ore/dropped = new ore_type(src, ore_amount)
		user.visible_message(
			span_notice("[user] mines out some [dropped.name]!"),
			span_notice("You mine out [ore_amount] [dropped.singular_name]\s!")
		)
	else
		user.visible_message(
			span_notice("[user] finishes mining the [name]."),
			span_notice("You finish mining the [name]. Only stone remains.")
		)


	break_wall(devastated = TRUE)


/turf/closed/rw_wall/rock/auto

/turf/closed/rw_wall/rock/auto/Initialize(mapload)
	if(!stamp_visual)
		set_regional_effects()
	. = ..()

/turf/closed/rw_wall/rock/auto/proc/set_regional_effects()
	var/datum/planet_cell/my_cell = get_planet_cell(src)
	if(!my_cell)
		return FALSE
	var/datum/material/rimworld_material/my_mat = SSmaterials.get_material(RW_MATERIAL_NAME_TO_TYPE[my_cell.material])
	if(!my_mat)
		return FALSE
	set_base_color(my_mat.color)
	name = "[my_mat.name] [name]"
	max_integrity = max_integrity * my_mat.get_hp_factor()
	mine_steps = round(mine_steps * my_mat.get_hp_factor())
	material = my_mat
	return TRUE
