/obj/structure/rimworld
	name = "rimworld structure"


/obj/structure/rimworld/flora
	name = "wild plant"
	desc = "A wild plant."

	icon = 'icons/obj/fluff/flora/snowflora.dmi'
	icon_state = "snowgrass1gb"

	resistance_flags = FLAMMABLE
	max_integrity = 80
	anchored = TRUE
	density = FALSE
	drag_slowdown = 1

	var/action_in_progress = FALSE

	var/harvestable = TRUE
	var/harvest_with_hands = TRUE
	var/list/harvest_tools

	var/harvest_verb = "harvest"
	var/harvest_time = 3 SECONDS

	var/harvest_amount_low = 1
	var/harvest_amount_high = 3

	var/list/harvest_products
	var/list/seed_products
	var/seed_chance = 20

	var/harvested = FALSE
	var/harvested_name
	var/harvested_desc
	var/harvested_icon_state

	var/regrowth_time_low = 5 MINUTES
	var/regrowth_time_high = 10 MINUTES

	var/can_uproot = TRUE
	var/uprooted = FALSE
	var/uproot_time = 4 SECONDS
	var/uprooted_name
	var/uprooted_desc
	var/previous_rotation = 0

	var/can_destroy = FALSE
	var/list/destroy_tools
	var/destroy_time = 4 SECONDS
	var/destroy_verb = "destroy"
	var/destroy_amount_low = 1
	var/destroy_amount_high = 1
	var/list/destroy_products

	var/list/uproot_products
	var/uproot_amount_low = 1
	var/uproot_amount_high = 1


/obj/structure/rimworld/flora/Initialize(mapload)
	. = ..()
	if(isnull(harvest_tools))
		harvest_tools = list()
	if(isnull(harvest_products))
		harvest_products = list()
	if(isnull(seed_products))
		seed_products = list()
	if(isnull(destroy_tools))
		destroy_tools = list()
	if(isnull(destroy_products))
		destroy_products = list()
	if(isnull(uproot_products))
		uproot_products = list()


/obj/structure/rimworld/flora/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(user.combat_mode)
		return NONE
	if(flags_1 & HOLOGRAM_1)
		balloon_alert(user, "it goes right through!")
		return ITEM_INTERACT_BLOCKING
	if(action_in_progress)
		return ITEM_INTERACT_BLOCKING

	if(can_uproot && tool.tool_behaviour == TOOL_SHOVEL)
		if(uprooted)
			start_replant(user, tool)
		else
			start_uproot(user, tool)
		return ITEM_INTERACT_SUCCESS

	if(can_destroy(user, tool))
		start_destroy(user, tool)
		return ITEM_INTERACT_SUCCESS

	if(can_harvest(user, tool))
		start_harvest(user, tool)
		return ITEM_INTERACT_SUCCESS

	return NONE


/obj/structure/rimworld/flora/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(.)
		return
	if(action_in_progress)
		return
	if(!can_harvest(user))
		return
	start_harvest(user)


/obj/structure/rimworld/flora/proc/can_harvest(mob/user, obj/item/harvesting_item)
	if(flags_1 & HOLOGRAM_1)
		return FALSE
	if(harvested || !harvestable)
		return FALSE
	if(harvesting_item)
		return (harvesting_item.tool_behaviour in harvest_tools)
	return harvest_with_hands


/obj/structure/rimworld/flora/proc/start_harvest(mob/living/user, obj/item/tool)
	if(action_in_progress)
		return FALSE
	action_in_progress = TRUE
	var/tool_speed = tool ? tool.toolspeed : 1
	if(user)
		user.visible_message(
			span_notice("[user] starts to [harvest_verb] [src]..."),
			span_notice("You start to [harvest_verb] [src]...")
		)
	if(tool)
		tool.play_tool_sound(src, 50)
	if(!do_after(user, harvest_time * tool_speed, src))
		action_in_progress = FALSE
		return FALSE
	if(!can_harvest(user, tool))
		action_in_progress = FALSE
		return FALSE
	if(user)
		visible_message(
			span_notice("[user] [harvest_verb]s [src]."),
			span_notice("You [harvest_verb] [src].")
		)
	perform_harvest(user)
	action_in_progress = FALSE
	return TRUE


/obj/structure/rimworld/flora/proc/perform_harvest(mob/living/user, product_amount_multiplier = 1)
	if(harvested)
		return FALSE
	var/list/products = get_harvest_products()
	if(!LAZYLEN(products))
		return FALSE
	var/list/created_products = spawn_products(products, harvest_amount_low, harvest_amount_high, product_amount_multiplier)
	if(LAZYLEN(seed_products) && prob(seed_chance))
		var/list/seeds = get_weighted_product_list(seed_products, 1, 1)
		created_products += spawn_products(seeds, 1, 1, product_amount_multiplier)
	harvested = TRUE
	if(harvested_name)
		name = harvested_name
	if(harvested_desc)
		desc = harvested_desc
	if(harvested_icon_state)
		icon_state = harvested_icon_state
	if(regrowth_time_high > 0)
		addtimer(CALLBACK(src, PROC_REF(regrow)), rand(regrowth_time_low, regrowth_time_high))
	return created_products


/obj/structure/rimworld/flora/proc/get_harvest_products()
	return harvest_products


/obj/structure/rimworld/flora/proc/get_weighted_product_list(list/potential_products, amount_low, amount_high)
	if(!LAZYLEN(potential_products))
		return null
	var/list/result = list()
	var/amount = rand(amount_low, amount_high)
	for(var/i in 1 to amount)
		var/product = pick_weight(potential_products)
		if(!result[product])
			result[product] = 0
		result[product]++
	return result


/obj/structure/rimworld/flora/proc/spawn_products(list/products, amount_low = 1, amount_high = 1, amount_multiplier = 1)
	if(!LAZYLEN(products))
		return list()
	var/list/generated = get_weighted_product_list(products, amount_low, amount_high)
	if(!LAZYLEN(generated))
		return list()
	var/turf/drop_turf = get_turf(src)
	var/list/created = list()
	for(var/product_type in generated)
		var/amount = round(generated[product_type] * amount_multiplier, 1)
		if(amount <= 0)
			continue
		if(ispath(product_type, /obj/item/stack))
			var/remaining = amount
			while(remaining > 0)
				var/obj/item/stack/new_stack = new product_type(drop_turf)
				var/stack_amount = min(remaining, new_stack.max_amount)
				new_stack.amount = stack_amount
				remaining -= stack_amount
				created += new_stack
			continue
		for(var/i in 1 to amount)
			created += new product_type(drop_turf)
	return created


/obj/structure/rimworld/flora/proc/regrow()
	if(QDELETED(src))
		return
	name = initial(name)
	desc = initial(desc)
	icon_state = initial(icon_state)
	harvested = FALSE


/obj/structure/rimworld/flora/proc/start_uproot(mob/living/user, obj/item/tool)
	if(action_in_progress || uprooted || !can_uproot)
		return FALSE
	action_in_progress = TRUE
	user.visible_message(
		span_notice("[user] starts digging up [src]..."),
		span_notice("You start digging up [src]...")
	)
	tool.play_tool_sound(src, 50)
	if(!do_after(user, uproot_time * tool.toolspeed, src))
		action_in_progress = FALSE
		return FALSE
	if(uprooted || !can_uproot)
		action_in_progress = FALSE
		return FALSE
	user.visible_message(
		span_notice("[user] digs up [src]."),
		span_notice("You dig up [src].")
	)
	uproot(user)
	action_in_progress = FALSE
	return TRUE


/obj/structure/rimworld/flora/proc/uproot(mob/living/user)
	if(uprooted)
		return FALSE
	anchored = FALSE
	uprooted = TRUE
	if(uprooted_name)
		name = uprooted_name
	if(uprooted_desc)
		desc = uprooted_desc
	var/matrix/M = matrix(transform)
	previous_rotation = pick(-90, 90)
	transform = M.Turn(previous_rotation)
	if(LAZYLEN(uproot_products))
		spawn_products(uproot_products, uproot_amount_low, uproot_amount_high)
	return TRUE


/obj/structure/rimworld/flora/proc/start_replant(mob/living/user, obj/item/tool)
	if(action_in_progress || !uprooted)
		return FALSE
	action_in_progress = TRUE
	user.visible_message(
		span_notice("[user] starts replanting [src]..."),
		span_notice("You start replanting [src]...")
	)
	tool.play_tool_sound(src, 50)
	if(!do_after(user, uproot_time * tool.toolspeed, src))
		action_in_progress = FALSE
		return FALSE
	if(!uprooted)
		action_in_progress = FALSE
		return FALSE
	user.visible_message(
		span_notice("[user] replants [src]."),
		span_notice("You replant [src].")
	)
	replant(user)
	action_in_progress = FALSE
	return TRUE


/obj/structure/rimworld/flora/proc/replant(mob/living/user)
	if(!uprooted)
		return FALSE
	anchored = initial(anchored)
	uprooted = FALSE
	var/matrix/M = matrix(transform)
	transform = M.Turn(-previous_rotation)
	name = initial(name)
	desc = initial(desc)
	return TRUE


/obj/structure/rimworld/flora/proc/can_destroy(mob/user, obj/item/tool)
	if(!can_destroy || !tool)
		return FALSE
	return (tool.tool_behaviour in destroy_tools)


/obj/structure/rimworld/flora/proc/start_destroy(mob/living/user, obj/item/tool)
	if(action_in_progress)
		return FALSE
	action_in_progress = TRUE
	user.visible_message(
		span_notice("[user] starts to [destroy_verb] [src]..."),
		span_notice("You start to [destroy_verb] [src]...")
	)
	tool.play_tool_sound(src, 50)
	if(!do_after(user, destroy_time * tool.toolspeed, src))
		action_in_progress = FALSE
		return FALSE
	if(!can_destroy(user, tool))
		action_in_progress = FALSE
		return FALSE
	user.visible_message(
		span_notice("[user] [destroy_verb]s [src]."),
		span_notice("You [destroy_verb] [src].")
	)
	destroy(user, tool)
	action_in_progress = FALSE
	return TRUE


/obj/structure/rimworld/flora/proc/destroy(mob/living/user, obj/item/tool)
	var/list/products = get_destroy_products()
	if(LAZYLEN(products))
		spawn_products(products, destroy_amount_low, destroy_amount_high)
	qdel(src)


/obj/structure/rimworld/flora/proc/get_destroy_products()
	return destroy_products


/obj/structure/rimworld/flora/proc/special_destroy(mob/living/user)
	if(!can_destroy || action_in_progress)
		return FALSE
	destroy(user, null)
	return TRUE


/obj/structure/rimworld/flora/grayscale
	name = "plant"
	desc = "A plant."
	/// Grayscale icon file (leaves/body tinted by color)
	var/icon_grayscale
	var/icon_state_grayscale
	var/mutable_appearance/grayscale_overlay
	/// Whether this flora follows planetary seasons
	var/seasonal_color = TRUE
	/// Default foliage tint (also used as base_color)
	var/foliage_color = GRASS_COLOR_FOREST


/obj/structure/rimworld/flora/grayscale/Initialize(mapload)
	. = ..()
	setup_grayscale_visuals()
	if(seasonal_color)
		AddElement(/datum/element/season_visual, CALLBACK(src, PROC_REF(update_season_visual)))


/obj/structure/rimworld/flora/grayscale/proc/setup_grayscale_visuals()
	if(icon_state_grayscale)
		if(!icon_grayscale)
			icon_grayscale = icon

		if(grayscale_overlay)
			cut_overlay(grayscale_overlay)

		var/overlay_icon_state = "[icon_state]_[icon_state_grayscale]"

		grayscale_overlay = mutable_appearance(
			icon_grayscale,
			overlay_icon_state,
			layer = src.layer + 0.1,
			appearance_flags = RESET_COLOR | RESET_ALPHA | KEEP_APART,
		)

		grayscale_overlay.color = foliage_color
		add_overlay(grayscale_overlay)
		return

	if(foliage_color)
		set_base_color(foliage_color)


/obj/structure/rimworld/flora/grayscale/proc/update_season_visual(atom/host, hemisphere, old_season, new_season, quadrum, year)
	if(!seasonal_color)
		return

	if(!base_color)
		base_color = foliage_color

	var/tint
	var/amount

	switch(new_season)
		if(RW_SEASON_SPRING)
			tint = RW_SEASON_TINT_SPRING
			amount = RW_SEASON_TINT_AMOUNT_SPRING

		if(RW_SEASON_SUMMER)
			tint = RW_SEASON_TINT_SUMMER
			amount = RW_SEASON_TINT_AMOUNT_SUMMER

		if(RW_SEASON_FALL)
			tint = RW_SEASON_TINT_FALL
			amount = RW_SEASON_TINT_AMOUNT_FALL

		if(RW_SEASON_WINTER)
			tint = RW_SEASON_TINT_WINTER
			amount = RW_SEASON_TINT_AMOUNT_WINTER

		else
			if(grayscale_overlay)
				animate(
					grayscale_overlay,
					color = base_color,
					time = 0.5,
					easing = LINEAR_EASING
				)
			else
				reset_to_base_color(0.5)
			return

	var/new_color = blend_towards(base_color, tint, amount)

	if(grayscale_overlay)
		animate(
			grayscale_overlay,
			color = new_color,
			time = 0.5,
			easing = LINEAR_EASING
		)
	else
		var/old_color = color

		animate(
			src,
			color = new_color,
			time = 0.5,
			easing = LINEAR_EASING
		)

		on_color_updated(old_color, new_color, 0.5)


/obj/structure/rimworld/flora/grayscale/proc/refresh_grayscale_overlay_color()
	if(!grayscale_overlay)
		return
	cut_overlay(grayscale_overlay)
	grayscale_overlay.color = color
	add_overlay(grayscale_overlay)


/obj/structure/rimworld/flora/grayscale/regrow()
	. = ..()
	setup_grayscale_visuals()
	if(seasonal_color && SSrimworld_planetmap)
		var/season = SSrimworld_planetmap.get_season_for_hemisphere("north")
		update_season_visual(src, "north", null, season, SSrimworld_planetmap.current_quadrum, SSrimworld_planetmap.current_year)


/obj/structure/rimworld/flora/grayscale/tree
	name = "tree"
	desc = "A large tree."

	density = TRUE
	anchored = TRUE
	max_integrity = 180
	drag_slowdown = 1.5

	harvestable = FALSE
	can_uproot = FALSE

	can_destroy = TRUE
	destroy_tools = list(TOOL_SAW, TOOL_AXE)
	destroy_time = 6 SECONDS
	destroy_verb = "cut down"
	destroy_amount_low = 6
	destroy_amount_high = 12
	destroy_products = list(/obj/item/grown/log/tree = 1)

	foliage_color = GRASS_COLOR_FOREST
	seasonal_color = TRUE

	var/variants = 1
	var/fall_time = 0.8 SECONDS
	var/fall_angle = 90
	var/falling = FALSE
	var/stump_type = /obj/structure/rimworld/flora/grayscale/tree/stump
	var/list/fall_products


/obj/structure/rimworld/flora/grayscale/tree/Initialize(mapload)
	icon_state = "[base_icon_state][rand(1, variants)]"
	. = ..()
	if(isnull(fall_products))
		fall_products = destroy_products
	if(get_seethrough_map())
		AddComponent(/datum/component/seethrough, get_seethrough_map())

/obj/structure/rimworld/flora/grayscale/tree/can_destroy(mob/user, obj/item/tool)
	if(falling)
		return FALSE
	return ..()


/obj/structure/rimworld/flora/grayscale/tree/destroy(mob/living/user, obj/item/tool)
	if(falling)
		return FALSE
	fell(user, tool)
	return TRUE


/obj/structure/rimworld/flora/grayscale/tree/proc/fell(mob/living/user, obj/item/tool)
	if(falling)
		return FALSE
	falling = TRUE
	action_in_progress = TRUE
	anchored = FALSE
	density = FALSE
	var/turf/tree_turf = get_turf(src)
	if(has_gravity(tree_turf))
		playsound(tree_turf, 'sound/effects/meteorimpact.ogg', 100, FALSE, extrarange = 5)
	fall_angle = pick(-90, 90)
	var/matrix/M = matrix(transform)
	var/matrix/final_transform = M.Turn(fall_angle)
	var/fall_pixel_x = pixel_x + (fall_angle > 0 ? 16 : -16)
	var/fall_pixel_y = pixel_y - 8
	animate(src, transform = final_transform, pixel_x = fall_pixel_x, pixel_y = fall_pixel_y, time = fall_time)
	addtimer(CALLBACK(src, PROC_REF(finish_fall)), fall_time)
	return TRUE


/obj/structure/rimworld/flora/grayscale/tree/proc/finish_fall()
	if(QDELETED(src))
		return
	var/turf/tree_turf = get_turf(src)
	if(stump_type)
		var/obj/structure/rimworld/flora/grayscale/tree/stump/new_stump = new stump_type(tree_turf)
		new_stump.name = "[name] stump"
	if(LAZYLEN(fall_products))
		spawn_products(fall_products, destroy_amount_low, destroy_amount_high)
	qdel(src)


/obj/structure/rimworld/flora/grayscale/tree/get_destroy_products()
	return fall_products

/obj/structure/rimworld/flora/grayscale/tree/proc/get_seethrough_map()
	return SEE_THROUGH_MAP_DEFAULT


/obj/structure/rimworld/flora/grayscale/tree/stump
	name = "tree stump"
	desc = "The remains of a felled tree."
	icon = 'icons/obj/fluff/flora/pinetrees.dmi'
	icon_state = "tree_stump"
	density = FALSE
	anchored = TRUE
	can_uproot = TRUE
	seasonal_color = FALSE
	can_destroy = TRUE
	destroy_tools = list(TOOL_SHOVEL, TOOL_SAW, TOOL_AXE)
	destroy_time = 3 SECONDS
	destroy_verb = "remove"
	destroy_amount_low = 1
	destroy_amount_high = 3
	destroy_products = list(/obj/item/grown/log/tree = 1)
	regrowth_time_high = 0


/obj/structure/rimworld/flora/grayscale/tree/stump/can_harvest(mob/user, obj/item/harvesting_item)
	return FALSE


/obj/structure/rimworld/flora/grayscale/tree/stump/uproot(mob/living/user)
	anchored = FALSE
	uprooted = TRUE
	qdel(src)
	return TRUE


/obj/structure/rimworld/flora/grayscale/tree/forest
	name = "forest tree"
	foliage_color = GRASS_COLOR_FOREST

	icon = 'fenysha_events/icons/structures/nature/talltree.dmi'
	icon_state = "tree1"
	base_icon_state = "tree"
	icon_state_grayscale = "overlay"

	max_integrity = 220
	destroy_amount_low = 8
	destroy_amount_high = 14

	pixel_x = -48
	pixel_y = -20



/obj/structure/rimworld/flora/grayscale/bush
	name = "bush"
	desc = "A leafy bush."
	icon = 'icons/obj/fluff/flora/snowflora.dmi'
	icon_state = "snowgrass1gb"
	density = FALSE
	harvestable = TRUE
	harvest_with_hands = TRUE
	harvest_verb = "forage"
	foliage_color = GRASS_COLOR_FOREST
	harvest_products = list() // fill with berries/herbs as needed

/obj/structure/rimworld/flora/grayscale/bush/forest
	name = "forest bush"
	foliage_color = GRASS_COLOR_FOREST

/obj/structure/rimworld/flora/grayscale/bush/forest/light
	name = "light forest bush"
	foliage_color = GRASS_COLOR_FOREST_LIGHT


// --- Jungle / rainforest ---
/obj/structure/rimworld/flora/grayscale/tree/jungle
	name = "jungle tree"
	foliage_color = GRASS_COLOR_JUNGLE
	max_integrity = 200

/obj/structure/rimworld/flora/grayscale/tree/jungle/tall
	name = "tall jungle tree"
	foliage_color = GRASS_COLOR_JUNGLE_TALL
	max_integrity = 260
	destroy_amount_low = 10
	destroy_amount_high = 16

/obj/structure/rimworld/flora/grayscale/bush/jungle
	name = "jungle undergrowth"
	foliage_color = GRASS_COLOR_JUNGLE_LIGHT


// --- Savanna ---
/obj/structure/rimworld/flora/grayscale/tree/savanna
	name = "savanna tree"
	desc = "A sparse, hardy tree of the open plains."
	foliage_color = GRASS_COLOR_SAVANNA
	max_integrity = 140
	destroy_amount_low = 4
	destroy_amount_high = 8

/obj/structure/rimworld/flora/grayscale/bush/savanna
	name = "dry scrub"
	foliage_color = GRASS_COLOR_SAVANNA_LIGHT
	// Milder fall tint feels odd on already-yellow foliage; still seasonal
	seasonal_color = TRUE


// --- Taiga / snow ---
/obj/structure/rimworld/flora/grayscale/tree/taiga
	name = "pine tree"
	desc = "A needle-leaf tree adapted to cold climates."
	icon = 'icons/obj/fluff/flora/pinetrees.dmi'
	icon_state = "pine_1"
	foliage_color = "#3D6B4F"
	// Evergreens: weak seasonal shift
	seasonal_color = TRUE

/obj/structure/rimworld/flora/grayscale/tree/taiga/update_season_visual(atom/host, hemisphere, old_season, new_season, quadrum, year)
	// Evergreen: only a slight winter desaturation
	if(!seasonal_color || !base_color)
		return
	var/tint
	var/amount
	switch(new_season)
		if(RW_SEASON_WINTER)
			tint = RW_SEASON_TINT_WINTER
			amount = 0.2
		if(RW_SEASON_FALL)
			tint = RW_SEASON_TINT_FALL
			amount = 0.08
		else
			reset_to_base_color()
			refresh_grayscale_overlay_color()
			return
	modulate_color_towards(tint, amount)
	refresh_grayscale_overlay_color()


/obj/structure/rimworld/flora/grayscale/cactus
	name = "cactus"
	desc = "A spiny desert plant."
	foliage_color = "#6B8F5E"
	seasonal_color = FALSE
	can_uproot = TRUE
	harvestable = FALSE
	density = FALSE


/obj/structure/rimworld/flora/grayscale/bush/tundra
	name = "tundra shrub"
	foliage_color = "#7A8B6A"
	seasonal_color = TRUE

