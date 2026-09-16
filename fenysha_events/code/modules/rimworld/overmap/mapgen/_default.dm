/datum/map_generator/sub_level
	var/datum/rimworld_planet/planet

	var/planet_x = 1
	var/planet_y = 1

	var/list/elevation_matrix

	/**
	 * Height above which the terrain becomes closed terrain.
	 *
	 * This is intentionally high because the heightmap represents continuous
	 * terrain rather than a direct "open/closed" mask.
	 */
	var/closed_height_threshold = 0.86

	/**
	 * Height difference required to classify a cell as a geological transition.
	 */
	var/transition_height_delta = 0.10

	/**
	 * Enables cave generation.
	 *
	 * This value is forwarded directly to Rust.
	 */
	var/generate_caves = TRUE

/datum/map_generator/sub_level/proc/setup_planet_context(datum/rimworld_planet/P, px, py)
	planet = P
	planet_x = px
	planet_y = py

	cache_planetary_neighborhood()

/datum/map_generator/sub_level/proc/cache_planetary_neighborhood()
	elevation_matrix = list()

	for(var/dx in -1 to 1)
		elevation_matrix["[dx]"] = list()

		for(var/dy in -1 to 1)
			var/target_x = planet_x + dx
			var/target_y = planet_y + dy

			if(planet.is_valid_coordinate(target_x, target_y))
				elevation_matrix["[dx]"]["[dy]"] = planet.get_elevation_level(target_x, target_y)
			else
				elevation_matrix["[dx]"]["[dy]"] = planet.get_elevation_level(planet_x, planet_y)

/**
 * Returns the biome datum instance used by this sub-level.
 */
/datum/map_generator/sub_level/proc/get_target_biome()
	var/macro_elevation = planet.get_elevation_level(planet_x, planet_y)
	var/macro_heat = planet.get_heat_level(planet_x, planet_y)
	var/macro_humidity = planet.get_humidity_level(planet_x, planet_y)

	var/macro_biome = planet.get_biome(
		planet_x,
		planet_y,
		macro_elevation,
		macro_heat,
		macro_humidity
	)

	var/datum/biome_type = planet.get_possible_biomes()[macro_biome]
	var/datum/biome/rimworld/target_biome

	if(biome_type)
		target_biome = SSmapping.biomes[biome_type]

	if(!istype(target_biome))
		target_biome = SSmapping.biomes[/datum/biome/plains]

	return target_biome


/**
 * Returns TRUE when this cell is close to a strong geological height
 * transition.
 *
 * This must be performed against the heightmap itself rather than the
 * already-generated turfs, because the whole open-turf pass happens first.
 */
/datum/map_generator/sub_level/proc/is_geological_transition(
	turf/T,
	list/heights,
	list/index_cache,
	width,
	height,
	datum/turf_reservation/sub_level/reservation
)
	var/local_x = index_cache[T]["x"]
	var/local_y = index_cache[T]["y"]

	var/current_index = width * (local_y - 1) + local_x
	var/current_height = text2num("[heights[current_index]]")

	for(var/dir in GLOB.cardinals)
		var/turf/N = get_step(T, dir)
		if(!N || !reservation.contains_turf(N))
			continue

		var/coords = index_cache[N]
		if(!coords)
			continue

		var/nx = coords["x"]
		var/ny = coords["y"]

		var/neighbor_index = width * (ny - 1) + nx
		var/neighbor_height = text2num("[heights[neighbor_index]]")

		if(abs(current_height - neighbor_height) >= transition_height_delta)
			return TRUE

	return FALSE


/**
 * Generates a complete SS13 sub-level from a Rust heightmap.
 *
 * Generation order:
 *
 * 1. Request continuous heightmap from Rust.
 * 2. Place every open turf according to its height.
 * 3. Mark the highest cells as closed terrain.
 * 4. Apply cave mask.
 * 5. Run standard biome population.
 */
/datum/map_generator/sub_level/proc/generate_sub_level_terrain(datum/turf_reservation/sub_level/reservation)
	if(!planet || !reservation)
		return FALSE

	var/list/turf/turfs = reservation.get_all_turfs()
	if(!length(turfs))
		return FALSE

	var/width = reservation.width
	var/height = reservation.height


	// 1. Build the 3x3 planetary neighbourhood.
	var/list/neigh = list(
		elevation_matrix["-1"]["-1"],
		elevation_matrix["0"]["-1"],
		elevation_matrix["1"]["-1"],

		elevation_matrix["-1"]["0"],
		elevation_matrix["0"]["0"],
		elevation_matrix["1"]["0"],

		elevation_matrix["-1"]["1"],
		elevation_matrix["0"]["1"],
		elevation_matrix["1"]["1"]
	)

	var/list/config = list(
		"planet_seed" = planet.seed,
		"planet_x" = planet_x,
		"planet_y" = planet_y,

		"width" = width,
		"height" = height,

		"neighbourhood" = neigh,

		"local_seed" = 0,

		"density_bias" = 0.0,

		"smooth_passes" = 1,

		"caves" = generate_caves
	)

	var/json_config = json_encode(config)
	var/result = rustg_tp_sublevel_generate(json_config)

	if(!result)
		log_world("Sub-level heightmap generation failed: Rust returned no result.")
		return FALSE

	if(findtext(result, "ERROR:") == 1)
		log_world("Sub-level heightmap generation failed: [result]")
		return FALSE

	var/list/export
	try
		export = json_decode(result) //It's can take a while
	catch
		log_world("Sub-level generation returned invalid JSON.")
		return FALSE

	if(!export || export["status"] != "ok")
		log_world("Sub-level generation returned bad payload.")
		return FALSE


	// 2. Validate heightmap.
	var/list/heights = export["heights"]

	if(!islist(heights))
		log_world("Sub-level generator did not return a heightmap.")
		return FALSE

	if(length(heights) != width * height)
		log_world("Sub-level heightmap size mismatch.")
		return FALSE

	// Every height value must be normalized.
	for(var/i in 1 to length(heights))
		var/value = text2num("[heights[i]]")

		if(isnull(value))
			log_world("Sub-level heightmap contains a non-numeric value at index [i].")
			return FALSE

		heights[i] = clamp(value, 0, 1)


	// 3. Validate cave mask.
	var/list/cave_mask = export["cave_mask"]

	if(!islist(cave_mask))
		cave_mask = list()

	if(length(cave_mask) && length(cave_mask) != width * height)
		log_world("Sub-level cave mask size mismatch.")
		return FALSE

	// 4. Resolve target biome.
	var/datum/biome/rimworld/target_biome = get_target_biome()

	if(!target_biome)
		log_world("Unable to resolve sub-level biome.")
		return FALSE


	// 5. Cache local coordinates.
	//
	// We do this because the same coordinate calculation is needed for both
	// open and closed passes.
	var/turf/BL = reservation.get_bottom_left_turf()
	var/list/index_cache = list()
	for(var/turf/T in turfs)
		index_cache[T] = list(
			"x" = T.x - BL.x + 1,
			"y" = T.y - BL.y + 1
		)


	// 6. Open terrain pass.
	var/list/generated_open_turfs = list()
	var/list/closed_candidates = list()

	for(var/turf/T in turfs)
		var/list/coords = index_cache[T]

		var/local_x = coords["x"]
		var/local_y = coords["y"]

		var/index = width * (local_y - 1) + local_x
		var/terrain_height = text2num("[heights[index]]")

		var/is_cave = FALSE

		if(length(cave_mask))
			is_cave = text2num("[cave_mask[index]]") != 0

		var/is_highest = terrain_height >= closed_height_threshold

		// Cave cells must remain open.
		//
		// The cave mask represents terrain which belongs to a subterranean
		// geological structure and therefore has priority over the normal
		// high-height wall rule.
		if(is_highest && !is_cave)
			closed_candidates[T] = terrain_height

		var/is_transition = is_geological_transition(
			T,
			heights,
			index_cache,
			width,
			height,
			reservation
		)

		var/turf_type = target_biome.pick_open_turf(
			T,
			terrain_height,
			is_transition,
			is_cave
		)

		if(!turf_type)
			turf_type = /turf/open/genturf

		var/turf/new_turf = new turf_type(T)

		generated_open_turfs += new_turf

		CHECK_TICK

	// 7. Closed terrain pass.
	for(var/turf/T in closed_candidates)
		var/is_transition = is_geological_transition(
			T,
			heights,
			index_cache,
			width,
			height,
			reservation
		)

		var/turf_type = target_biome.pick_closed_turf(T, is_transition)
		if(!turf_type)
			turf_type = /turf/closed/rw_wall
		var/turf/new_turf = new turf_type(T)
		if(T.turf_flags & NO_RUINS)
			new_turf.turf_flags |= NO_RUINS

		CHECK_TICK
	// 8. Populate the final open terrain.
	if(length(generated_open_turfs))
		var/area/A = get_area(generated_open_turfs[1])

		target_biome.populate_turfs(
			generated_open_turfs,
			(A.area_flags_mapping & FLORA_ALLOWED),
			(A.area_flags_mapping & FLORA_ALLOWED),
			(A.area_flags_mapping & MOB_SPAWN_ALLOWED)
		)

	return TRUE
