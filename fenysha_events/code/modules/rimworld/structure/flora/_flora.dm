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


	/// Controls automatic lifecycle behaviour.
	var/flora_flags = NONE

	/// Current growth stage.
	var/growth_stage = 1

	/// Last available growth stage.
	var/max_growth_stage = PLANT_GROW_STAGE_MAX

	/// Time required to advance one growth stage.
	var/growth_stage_time = 10 MINUTES

	/// Current progress towards the next growth stage.
	var/growth_progress = 0

	/**
	 * Optional icon states for individual growth stages.
	 *
	 * Example:
	 * list("1" = "crop_1", "2" = "crop_2", "3" = "crop_3")
	 */
	var/list/growth_icon_states

	/// Whether the plant currently has a harvestable product.
	var/product_ready = FALSE

	/// Time required to regrow one harvested product.
	var/product_regrow_time = 10 MINUTES

	/// Current progress towards product regeneration.
	var/product_regrow_progress = 0

	var/plants_skill_id = RW_SKILL_PLANTS
	var/plants_ideal_skill = 10
	var/plants_minimum_action_time = 1 SECONDS


	var/harvestable = TRUE
	var/harvest_with_hands = TRUE
	var/list/harvest_tools

	var/harvest_verb = "harvest"
	var/harvest_time = 3 SECONDS
	var/harvest_skill_points = 1

	var/harvest_amount_low = 1
	var/harvest_amount_high = 3

	var/list/harvest_products
	var/list/seed_products
	var/seed_chance = 20

	/*
	 * Legacy harvested state is retained for visual/name changes
	 * and compatibility with existing flora.
	 */
	var/harvested = FALSE
	var/harvested_name
	var/harvested_desc
	var/harvested_icon_state

	/*
	 * Legacy values are used as a fallback when
	 * product_regrow_time is not explicitly configured.
	 */
	var/regrowth_time_low = 30 MINUTES
	var/regrowth_time_high = 60 MINUTES


	var/can_uproot = TRUE
	var/uprooted = FALSE
	var/uproot_time = 4 SECONDS
	var/uproot_skill_points = 1

	var/uprooted_name
	var/uprooted_desc
	var/previous_rotation = 0

	var/list/uproot_products
	var/uproot_amount_low = 1
	var/uproot_amount_high = 1


	var/can_destroy = FALSE
	var/list/destroy_tools

	var/destroy_time = 4 SECONDS
	var/destroy_hand_time = 0
	var/destroy_verb = "destroy"
	var/destroy_skill_points = 1

	var/destroy_amount_low = 1
	var/destroy_amount_high = 1
	var/list/destroy_products


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

	if((flora_flags & FLORA_PRODUCT_REGROW) && product_regrow_time <= 0)
		product_regrow_time = rand(regrowth_time_low, regrowth_time_high)

	if(flora_flags)
		SSflora.register_flora(src)

	if((flora_flags & FLORA_PRODUCES_PRODUCT) && is_mature())
		product_ready = TRUE


/obj/structure/rimworld/flora/Destroy(force)
	SSflora?.unregister_flora(src)
	return ..()


/obj/structure/rimworld/flora/proc/process_flora()
	if(QDELETED(src))
		return

	process_growth()
	process_product_regrowth()


/obj/structure/rimworld/flora/proc/process_growth()
	if(!(flora_flags & FLORA_GROWS))
		return

	if(is_mature() || growth_stage_time <= 0)
		return

	growth_progress += SSflora.wait

	while(growth_progress >= growth_stage_time && !is_mature())
		growth_progress -= growth_stage_time
		growth_stage++
		on_growth_stage_changed()


/obj/structure/rimworld/flora/proc/process_product_regrowth()
	if(!(flora_flags & FLORA_PRODUCES_PRODUCT))
		return

	if(!is_mature() || product_ready)
		return

	if(!(flora_flags & FLORA_PRODUCT_REGROW))
		return

	if(product_regrow_time <= 0)
		product_regrow_time = rand(regrowth_time_low, regrowth_time_high)

	product_regrow_progress += SSflora.wait

	if(product_regrow_progress < product_regrow_time)
		return

	product_regrow_progress = 0
	set_product_ready(TRUE)


/obj/structure/rimworld/flora/proc/is_mature()
	return growth_stage >= max_growth_stage


/obj/structure/rimworld/flora/proc/set_growth_stage(new_stage)
	new_stage = clamp(round(new_stage), 1, max_growth_stage)

	if(growth_stage == new_stage)
		return FALSE

	growth_stage = new_stage
	growth_progress = 0
	on_growth_stage_changed()

	return TRUE


/obj/structure/rimworld/flora/proc/on_growth_stage_changed()
	var/new_icon_state = growth_icon_states?[num2text(growth_stage)]

	if(new_icon_state)
		icon_state = new_icon_state

	if(is_mature() && (flora_flags & FLORA_PRODUCES_PRODUCT) && !product_ready)
		set_product_ready(TRUE)


/obj/structure/rimworld/flora/proc/set_product_ready(value)
	value = !!value

	if(product_ready == value)
		return FALSE

	product_ready = value
	product_regrow_progress = 0

	if(product_ready)
		harvested = FALSE

		if(harvested_name)
			name = initial(name)

		if(harvested_desc)
			desc = initial(desc)

		if(harvested_icon_state)
			on_growth_stage_changed()

	return TRUE


/obj/structure/rimworld/flora/proc/regrow()
	if(QDELETED(src) || !is_mature())
		return FALSE

	return set_product_ready(TRUE)



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

	if(. || action_in_progress)
		return

	if(!can_harvest(user))
		return

	start_harvest(user)



/obj/structure/rimworld/flora/proc/can_harvest(mob/user, obj/item/harvesting_item)
	if(flags_1 & HOLOGRAM_1)
		return FALSE

	if(!harvestable || !is_mature())
		return FALSE

	if(flora_flags & FLORA_PRODUCES_PRODUCT)
		if(!product_ready)
			return FALSE
	else if(harvested)
		return FALSE

	if(harvesting_item)
		return harvesting_item.tool_behaviour in harvest_tools

	return harvest_with_hands


/obj/structure/rimworld/flora/proc/start_harvest(mob/living/user, obj/item/tool)
	if(action_in_progress || !can_harvest(user, tool))
		return FALSE

	action_in_progress = TRUE

	var/tool_speed = tool ? tool.toolspeed : 1

	user?.visible_message(
		span_notice(
			"[user] starts to [harvest_verb] [src]..."),
			span_notice("You start to [harvest_verb] [src]...")
		)

	if(tool)
		tool.play_tool_sound(src, 50)

	if(!rw_do_after(
		user,
		harvest_time * tool_speed,
		src,
		plants_skill_id,
		plants_ideal_skill,
		plants_minimum_action_time, 0))

		action_in_progress = FALSE
		return FALSE

	if(!can_harvest(user, tool))
		action_in_progress = FALSE
		return FALSE

	var/list/created_products = perform_harvest(user)

	if(!LAZYLEN(created_products))
		action_in_progress = FALSE
		return FALSE

	user?.visible_message(
		span_notice("[user] [harvest_verb]s [src]."),
		span_notice("You [harvest_verb] [src].")
	)

	if(harvest_skill_points > 0)
		rw_train_skill(user, plants_skill_id, harvest_skill_points)

	action_in_progress = FALSE
	return TRUE


/obj/structure/rimworld/flora/proc/perform_harvest(mob/living/user, product_amount_multiplier = 1)
	var/list/products = get_harvest_products()

	if(!LAZYLEN(products))
		return FALSE

	if(flora_flags & FLORA_PRODUCES_PRODUCT)
		if(!product_ready)
			return FALSE
	else if(harvested)
		return FALSE

	var/list/created_products = spawn_products(products, harvest_amount_low, harvest_amount_high, product_amount_multiplier)

	if(LAZYLEN(seed_products) && prob(seed_chance))
		var/list/seeds = get_weighted_product_list(seed_products, 1, 1)
		created_products += spawn_products(seeds, 1, 1, product_amount_multiplier)

	if(flora_flags & FLORA_PRODUCES_PRODUCT)
		set_product_ready(FALSE)

	harvested = TRUE

	if(harvested_name)
		name = harvested_name

	if(harvested_desc)
		desc = harvested_desc

	if(harvested_icon_state)
		icon_state = harvested_icon_state

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





/obj/structure/rimworld/flora/proc/start_uproot(mob/living/user, obj/item/tool)
	if(action_in_progress || uprooted || !can_uproot)
		return FALSE

	action_in_progress = TRUE

	user.visible_message(
		span_notice("[user] starts digging up [src]..."),
		span_notice("You start digging up [src]...")
	)
	tool.play_tool_sound(src, 50)

	if(!rw_do_after(
		user,
		uproot_time * tool.toolspeed,
		src,
		plants_skill_id,
		plants_ideal_skill,
		plants_minimum_action_time, 0))

		action_in_progress = FALSE
		return FALSE

	if(uprooted || !can_uproot)
		action_in_progress = FALSE
		return FALSE

	user.visible_message(
		span_notice("[user] digs up [src]."),
		span_notice("You dig up [src].")
	)

	var/success = uproot(user)

	if(success && uproot_skill_points > 0)
		rw_train_skill(user, plants_skill_id, uproot_skill_points)

	action_in_progress = FALSE
	return success


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

	if(!rw_do_after(user, uproot_time * tool.toolspeed, src, plants_skill_id, plants_ideal_skill, plants_minimum_action_time, 0))
		action_in_progress = FALSE
		return FALSE

	if(!uprooted)
		action_in_progress = FALSE
		return FALSE

	user.visible_message(
		span_notice("[user] replants [src]."),
		span_notice("You replant [src].")
	)

	var/success = replant(user)

	if(success && uproot_skill_points > 0)
		rw_train_skill(user, plants_skill_id, uproot_skill_points)

	action_in_progress = FALSE
	return success


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
	if(!can_destroy)
		return FALSE

	if(!tool)
		return destroy_hand_time > 0

	return tool.tool_behaviour in destroy_tools


/obj/structure/rimworld/flora/proc/start_destroy(mob/living/user, obj/item/tool)
	if(action_in_progress || !can_destroy(user, tool))
		return FALSE

	action_in_progress = TRUE

	var/action_time = tool ? destroy_time * tool.toolspeed : destroy_hand_time

	if(action_time <= 0)
		action_in_progress = FALSE
		return FALSE

	user.visible_message(
		span_notice("[user] starts to [destroy_verb] [src]..."),
		span_notice("You start to [destroy_verb] [src]...")
	)

	if(tool)
		tool.play_tool_sound(src, 50)

	if(!rw_do_after(
		user,
		action_time,
		src,
		plants_skill_id,
		plants_ideal_skill,
		plants_minimum_action_time, 0))

		action_in_progress = FALSE
		return FALSE

	if(!can_destroy(user, tool))
		action_in_progress = FALSE
		return FALSE

	user.visible_message(
		span_notice("[user] [destroy_verb]s [src]."),
		span_notice("You [destroy_verb] [src].")
	)

	var/success = destroy(user, tool)

	if(success && destroy_skill_points > 0)
		rw_train_skill(user, plants_skill_id, destroy_skill_points)

	action_in_progress = FALSE
	return success


/obj/structure/rimworld/flora/proc/destroy(mob/living/user, obj/item/tool)
	var/list/products = get_destroy_products()

	if(LAZYLEN(products))
		spawn_products(products, destroy_amount_low, destroy_amount_high)

	qdel(src)
	return TRUE


/obj/structure/rimworld/flora/proc/get_destroy_products()
	return destroy_products


/obj/structure/rimworld/flora/proc/special_destroy(mob/living/user)
	if(!can_destroy || action_in_progress)
		return FALSE

	var/success = destroy(user, null)

	if(success && destroy_skill_points > 0)
		rw_train_skill(user, plants_skill_id, destroy_skill_points)

	return success


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
	var/visual_ready = FALSE


/obj/structure/rimworld/flora/grayscale/Initialize(mapload)
	. = ..()
	if(visual_ready)
		if(grayscale_overlay)
			add_overlay(grayscale_overlay)
		if(seasonal_color)
			AddElement(/datum/element/season_visual, CALLBACK(src, PROC_REF(update_season_visual)))
		return
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
	if(visual_ready && !old_season)
		return
	visual_ready = FALSE

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
		refresh_grayscale_overlay_color(new_color)
	else
		var/old_color = color

		animate(
			src,
			color = new_color,
			time = 0.5,
			easing = LINEAR_EASING
		)

		on_color_updated(old_color, new_color, 0.5)


/obj/structure/rimworld/flora/grayscale/proc/refresh_grayscale_overlay_color(new_color)
	if(!grayscale_overlay)
		return
	cut_overlay(grayscale_overlay)
	grayscale_overlay.color = new_color ? new_color : foliage_color
	add_overlay(grayscale_overlay)


/obj/structure/rimworld/flora/grayscale/regrow()
	. = ..()
	setup_grayscale_visuals()
	if(seasonal_color && SSrimworld_planetmap)
		var/season = SSrimworld_planetmap.get_season_for_hemisphere("north")
		update_season_visual(src, "north", null, season, SSrimworld_planetmap.current_quadrum, SSrimworld_planetmap.current_year)

