/obj/structure/rimworld/flora/grayscale/tree
	name = "tree"
	desc = "A large tree."

	density = TRUE
	anchored = TRUE
	max_integrity = 230
	drag_slowdown = 1.5

	flora_flags = FLORA_GROWS
	growth_stage = PLANT_GROW_STAGE_MATURE
	max_growth_stage = PLANT_GROW_STAGE_MATURE
	growth_stage_time = 30 MINUTES

	harvestable = FALSE
	can_uproot = FALSE

	can_destroy = TRUE
	destroy_tools = list(TOOL_SAW, TOOL_AXE)

	destroy_time = 6 SECONDS
	/// Cutting a tree by hand is intentionally very slow.
	destroy_hand_time = 45 SECONDS

	destroy_verb = "cut down"
	/// XP awarded for successfully cutting down the tree.
	destroy_skill_points = 5

	destroy_amount_low = 20
	destroy_amount_high = 30

	destroy_products = list(
		/obj/item/grown/log/tree = 1
	)

	foliage_color = GRASS_COLOR_FOREST
	seasonal_color = TRUE

	var/variants = 1


	/// Duration of the falling animation.
	var/fall_time = 1.5 SECONDS

	/**
	 * Conditional height of the tree in tiles.
	 *
	 * This determines how far the tree reaches when falling
	 * and how many tiles are affected by the impact.
	 */
	var/fall_height = 3

	/// Damage dealt per tile of the falling tree.
	var/fall_damage_per_tile = 15

	/// Knockdown applied by the tree impact.
	var/fall_knockdown_time = 4 SECONDS

	/// Direction in which the tree is currently falling.
	var/fall_dir = SOUTH

	/// Rotation applied during the fall.
	var/fall_angle = 0

	/// Whether the tree is currently falling.
	var/falling = FALSE

	/**
	 * Pivot position relative to the object's origin.
	 *
	 * The lower this is, the closer the rotation pivot is
	 * to the ground under the tree.
	 */
	var/fall_pivot_x = 0
	var/fall_pivot_y = -48

	/// Stump created after the tree has fallen.
	var/stump_type = /obj/structure/rimworld/flora/grayscale/tree/stump

	/// Products created when the tree falls.
	var/list/fall_products

	var/list/fall_sounds = list(
		'fenysha_events/sounds/effects/rimworld/rw_tree_fall_1.ogg',
		'fenysha_events/sounds/effects/rimworld/rw_tree_fall_2.ogg',
		'fenysha_events/sounds/effects/rimworld/rw_tree_fall_3.ogg',
		'fenysha_events/sounds/effects/rimworld/rw_tree_fall_4.ogg',
	)

	/// Damage type used by the falling tree.
	var/fall_damage_type = BRUTE

	/// Attack flag used for armor checks.
	var/fall_damage_flag = MELEE

	/// Time victims are paralyzed after being crushed.
	var/fall_paralyze_time = 4 SECONDS

	/// How much tree damage is transferred to RW walls.
	var/fall_wall_damage_multiplier = 1

	/// Duration of the squish element applied to carbon victims.
	var/fall_squish_time = 80 SECONDS


/obj/structure/rimworld/flora/grayscale/tree/Initialize(mapload)
	if(!visual_ready)
		icon_state = "[base_icon_state][rand(1, variants)]"

	. = ..()

	if(isnull(fall_products))
		fall_products = destroy_products

	if(get_seethrough_map())
		AddComponent(/datum/component/seethrough, get_seethrough_map())


/obj/structure/rimworld/flora/grayscale/tree/can_destroy(mob/user, obj/item/tool)
	if(falling || !can_destroy)
		return FALSE

	if(!tool)
		return destroy_hand_time > 0

	return tool.tool_behaviour in destroy_tools


/obj/structure/rimworld/flora/grayscale/tree/attack_hand(mob/living/user, list/modifiers)
	if(action_in_progress || falling)
		return

	if(!can_destroy(user, null))
		return

	start_destroy(user, null)


/obj/structure/rimworld/flora/grayscale/tree/examine(mob/user)
	. = ..()

	if(falling || !can_destroy)
		return

	. += span_notice("You can cut down this tree with your hands, but an axe or saw will be much faster.")

	if(fall_height > 1)
		. += span_notice("The falling tree will crush anything in its path.")


/obj/structure/rimworld/flora/grayscale/tree/destroy(mob/living/user, obj/item/tool)
	if(falling)
		return FALSE

	return fell(user, tool)


/**
 * Determines the direction in which the tree falls.
 *
 * The tree falls away from the person cutting it.
 */
/obj/structure/rimworld/flora/grayscale/tree/proc/get_fall_direction(mob/living/user)
	var/turf/tree_turf = get_turf(src)
	var/turf/user_turf = get_turf(user)

	if(!tree_turf || !user_turf)
		return pick(NORTH, SOUTH, EAST, WEST)

	var/dx = tree_turf.x - user_turf.x
	var/dy = tree_turf.y - user_turf.y

	if(!dx && !dy)
		return pick(NORTH, SOUTH, EAST, WEST)

	if(abs(dx) > abs(dy))
		return dx > 0 ? EAST : WEST

	return dy > 0 ? NORTH : SOUTH


/obj/structure/rimworld/flora/grayscale/tree/proc/get_fall_angle(direction)
	switch(direction)
		if(NORTH)
			return 0

		if(EAST)
			return -90

		if(SOUTH)
			return 180

		if(WEST)
			return 90

	return 0


/**
 * Creates a transformation which rotates the tree around
 * its base instead of around its visual center.
 */
/obj/structure/rimworld/flora/grayscale/tree/proc/get_fall_transform(angle)
	var/matrix/M = matrix(transform)

	M.Translate(-fall_pivot_x, -fall_pivot_y)
	M.Turn(angle)
	M.Translate(fall_pivot_x, fall_pivot_y)

	return M


/obj/structure/rimworld/flora/grayscale/tree/proc/fell(mob/living/user, obj/item/tool)
	if(falling)
		return FALSE

	var/turf/tree_turf = get_turf(src)

	if(!tree_turf)
		return FALSE

	falling = TRUE
	action_in_progress = TRUE
	anchored = FALSE
	density = FALSE

	fall_dir = get_fall_direction(user)
	fall_angle = get_fall_angle(fall_dir)

	var/matrix/final_transform = get_fall_transform(fall_angle)

	if(has_gravity(tree_turf))
		playsound(tree_turf, pick(fall_sounds), 100, FALSE, extrarange = 5)

	visible_message(
		span_warning("[src] starts falling toward [dir2text(fall_dir)]!")
	)

	animate(
		src,
		transform = final_transform,
		time = fall_time,
		easing = QUAD_EASING
	)

	addtimer(CALLBACK(src, PROC_REF(finish_fall)), fall_time)

	return TRUE


/**
 * Applies impact along the full length of the fallen tree.
 *
 * The closer the tile is to the trunk, the stronger the impact.
 */
/obj/structure/rimworld/flora/grayscale/tree/proc/apply_fall_impact()
	var/turf/tree_turf = get_turf(src)

	if(!tree_turf)
		return

	for(var/distance = 1, distance <= fall_height, distance++)
		var/turf/impact_turf = get_ranged_target_turf(tree_turf, fall_dir, distance)

		if(!impact_turf)
			break

		var/impact_damage = fall_damage_per_tile * (fall_height - distance + 1)

		/*
		 * RW walls are the actual turf being crushed, so handle them
		 * separately from normal atoms.
		 */
		if(istype(impact_turf, /turf/closed/rw_wall))
			var/turf/closed/rw_wall/wall = impact_turf

			if(!wall.destroying)
				var/wall_damage = round(impact_damage * fall_wall_damage_multiplier)

				if(wall_damage > 0)
					wall.take_brute_damage(wall_damage, null, src)

					wall.visible_message(
						span_danger("[wall] is smashed by the falling [src]!")
					)

		for(var/atom/atom_target in impact_turf.contents)
			if(atom_target == src || isarea(atom_target))
				continue

			if(SEND_SIGNAL(atom_target, COMSIG_PRE_TILT_AND_CRUSH, src) & COMPONENT_IMMUNE_TO_TILT_AND_CRUSH)
				continue

			var/crushed = FALSE

			if(isliving(atom_target))
				crushed = TRUE

				var/mob/living/living_target = atom_target
				var/blocked = living_target.run_armor_check(attack_flag = fall_damage_flag)

				if(iscarbon(living_target))
					var/mob/living/carbon/carbon_target = living_target

					if(prob(30))
						carbon_target.apply_damage(
							max(0, impact_damage),
							fall_damage_type,
							blocked = blocked,
							forced = TRUE,
							spread_damage = TRUE,
							attack_direction = fall_dir
						)
					else
						var/brute = fall_damage_type == BRUTE ? impact_damage * 0.5 : 0
						var/burn = fall_damage_type == BURN ? impact_damage * 0.5 : 0

						carbon_target.take_bodypart_damage(
							brute,
							burn,
							check_armor = TRUE,
							wound_bonus = 5
						)

						carbon_target.take_bodypart_damage(
							brute,
							burn,
							check_armor = TRUE,
							wound_bonus = 5
						)

					carbon_target.AddElement(/datum/element/squish, fall_squish_time)
				else
					living_target.apply_damage(
						impact_damage,
						fall_damage_type,
						blocked = blocked,
						forced = TRUE,
						attack_direction = fall_dir
					)

				living_target.Paralyze(fall_paralyze_time)
				living_target.emote("scream")

				playsound(
					living_target,
					'sound/effects/blob/blobattack.ogg',
					40,
					TRUE
				)

				playsound(
					living_target,
					'sound/effects/splat.ogg',
					50,
					TRUE
				)

				living_target.visible_message(
					span_danger("[living_target] is crushed under the falling [src]!"),
					span_userdanger("The falling [src] crushes you!")
				)

			else if(check_atom_crushable(atom_target))
				atom_target.take_damage(
					impact_damage,
					fall_damage_type,
					fall_damage_flag,
					FALSE,
					fall_dir
				)

				crushed = TRUE

				atom_target.visible_message(
					span_danger("[atom_target] is crushed by the falling [src]!"),
					span_userdanger("You are crushed by the falling [src]!")
				)

			if(crushed)
				SEND_SIGNAL(atom_target, COMSIG_POST_TILT_AND_CRUSH, src)

/obj/structure/rimworld/flora/grayscale/tree/proc/finish_fall()
	if(QDELETED(src))
		return

	var/turf/tree_turf = get_turf(src)

	if(!tree_turf)
		qdel(src)
		return

	apply_fall_impact()

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

	destroy_products = list(
		/obj/item/grown/log/tree = 1
	)

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

	max_integrity = 300

	growth_stage = PLANT_GROW_STAGE_MATURE
	max_growth_stage = PLANT_GROW_STAGE_MATURE

	destroy_hand_time = 60 SECONDS
	destroy_amount_low = 8
	destroy_amount_high = 14

	fall_height = 4
	fall_damage_per_tile = 18

	pixel_x = -48
	pixel_y = -20


/obj/structure/rimworld/flora/grayscale/tree/jungle
	name = "jungle tree"
	foliage_color = GRASS_COLOR_JUNGLE

	max_integrity = 200

	growth_stage = PLANT_GROW_STAGE_MAX
	max_growth_stage = PLANT_GROW_STAGE_MATURE

	destroy_hand_time = 50 SECONDS

	fall_height = 3
	fall_damage_per_tile = 15


/obj/structure/rimworld/flora/grayscale/tree/jungle/tall
	name = "tall jungle tree"
	foliage_color = GRASS_COLOR_JUNGLE_TALL

	max_integrity = 260

	growth_stage = PLANT_GROW_STAGE_MAX
	max_growth_stage = PLANT_GROW_STAGE_MATURE

	destroy_hand_time = 65 SECONDS

	destroy_amount_low = 10
	destroy_amount_high = 16

	fall_height = 4
	fall_damage_per_tile = 20


/obj/structure/rimworld/flora/grayscale/tree/savanna
	name = "savanna tree"
	desc = "A sparse, hardy tree of the open plains."

	foliage_color = GRASS_COLOR_SAVANNA
	max_integrity = 140

	growth_stage = PLANT_GROW_STAGE_MAX
	max_growth_stage = PLANT_GROW_STAGE_MATURE

	destroy_hand_time = 35 SECONDS

	destroy_amount_low = 4
	destroy_amount_high = 8

	fall_height = 2
	fall_damage_per_tile = 12


/obj/structure/rimworld/flora/grayscale/tree/taiga
	name = "pine tree"
	desc = "A needle-leaf tree adapted to cold climates."

	icon = 'icons/obj/fluff/flora/pinetrees.dmi'
	icon_state = "pine_1"

	foliage_color = "#3D6B4F"

	growth_stage = PLANT_GROW_STAGE_MAX
	max_growth_stage = PLANT_GROW_STAGE_MATURE

	destroy_hand_time = 55 SECONDS

	fall_height = 3
	fall_damage_per_tile = 16
