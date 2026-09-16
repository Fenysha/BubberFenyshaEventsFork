/datum/biome/rimworld
	var/biome_key

	/// Weighted list of possible open turf types. If empty, falls back to open_turf_type.
	var/list/open_turf_types = list()
	/// Weighted list of possible closed (wall / mineral) turf types. If empty, falls back to closed_turf_type.
	var/list/closed_turf_types = list()

	/// Optional secondary open turf used for transitional / edge geological features.
	var/open_turf_type_secondary
	/// Optional secondary closed turf used for transitional / edge geological features.
	var/closed_turf_type_secondary

	/// Chance (0-100) that a turf will use the secondary type when a geological transition is detected.
	var/transition_chance = 35

/datum/biome/rimworld/New()
	. = ..()
	if(length(open_turf_types))
		open_turf_types = expand_weights(fill_with_ones(open_turf_types))
	if(length(closed_turf_types))
		closed_turf_types = expand_weights(fill_with_ones(closed_turf_types))

/// Picks an open turf type, optionally using secondary types for geological transitions.
/datum/biome/rimworld/proc/pick_open_turf(turf/gen_turf, is_transition = FALSE)
	if(is_transition && open_turf_type_secondary && prob(transition_chance))
		return open_turf_type_secondary
	if(length(open_turf_types))
		return pick(open_turf_types)
	return open_turf_type

/// Picks a closed turf type, optionally using secondary types for geological transitions.
/datum/biome/rimworld/proc/pick_closed_turf(turf/gen_turf, is_transition = FALSE)
	if(is_transition && closed_turf_type_secondary && prob(transition_chance))
		return closed_turf_type_secondary
	if(length(closed_turf_types))
		return pick(closed_turf_types)
	return closed_turf_type

/datum/biome/rimworld/generate_turf_for_terrain(turf/gen_turf, closed)
	// Detect a simple transition by looking at neighbouring turfs that already exist.
	// This is cheap and works because the generator processes in a roughly coherent order.
	var/is_transition = FALSE
	for(var/dir in GLOB.cardinals)
		var/turf/neighbor = get_step(gen_turf, dir)
		if(!neighbor)
			continue
		// If the neighbour is already a different open/closed state we treat this as an edge.
		if(istype(neighbor, /turf/closed) != closed)
			is_transition = TRUE
			break

	var/turf_type
	if(closed)
		turf_type = pick_closed_turf(gen_turf, is_transition)
	else
		turf_type = pick_open_turf(gen_turf, is_transition)

	var/turf/new_turf = new turf_type(gen_turf)
	return new_turf


/datum/rimworld_planet
	var/list/possible_biomes


/datum/rimworld_planet/proc/get_possible_biomes()
	RETURN_TYPE(/list)
	if(!possible_biomes)
		possible_biomes = list()
		for(var/type in subtypesof(/datum/biome/rimworld))
			var/datum/biome/rimworld/b = type
			if(!b:biome_key)
				qdel(b)
				continue
			possible_biomes[b:biome_key] = b
	return possible_biomes.Copy()

/datum/rimworld_planet/proc/generate_sub_level_at(x, y, req_w = 64, req_h = 64, poi_name = null)
	if(!is_valid_coordinate(x, y))
		return null

	var/datum/turf_reservation/sub_level/reservation = null
	for(var/datum/map_spatial_node/root in SSsub_levels.root_nodes)
		reservation = root.allocate_sub_level(req_w, req_h, 0, poi_name ? poi_name : "Sub-Level ([x],[y])")
		if(reservation)
			break

	if(!reservation)
		var/datum/map_spatial_node/new_root = SSsub_levels.allocate_new_root_z_level()
		reservation = new_root.allocate_sub_level(req_w, req_h, 0, poi_name ? poi_name : "Sub-Level ([x],[y])")

	if(!reservation)
		return null

	var/datum/map_generator/sub_level/generator = new()
	generator.setup_planet_context(src, x, y)
	generator.generate_sub_level_terrain(reservation)

	var/macro_biome = get_biome(x, y)
	var/generated_name = poi_name ? poi_name : "Location: [macro_biome]"
	var/datum/rimworld_planet_object/point_of_interest/POI = create_point_of_interest(x, y, generated_name)

	if(POI)
		POI.data["sub_level_id"] = reservation.id
		POI.data["discovered"] = TRUE
		POI.data["biome"] = macro_biome

	return reservation



/datum/map_generator/sub_level
	var/datum/rimworld_planet/planet
	var/planet_x = 1
	var/planet_y = 1
	var/perlin_zoom = 25
	var/list/elevation_matrix

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


/datum/map_generator/sub_level/proc/calculate_geological_threshold(local_x, local_y, width, height)
	var/u = (width > 1) ? (local_x - 1) / (width - 1) : 0.5
	var/v = (height > 1) ? (local_y - 1) / (height - 1) : 0.5

	var/dx1 = (u < 0.5) ? -1 : 0
	var/dx2 = (u < 0.5) ? 0 : 1
	var/dy1 = (v < 0.5) ? -1 : 0
	var/dy2 = (v < 0.5) ? 0 : 1

	var/tx = (u < 0.5) ? (u + 0.5) : (u - 0.5)
	var/ty = (v < 0.5) ? (v + 0.5) : (v - 0.5)

	var/e00 = elevation_matrix["[dx1]"]["[dy1]"]
	var/e10 = elevation_matrix["[dx2]"]["[dy1]"]
	var/e01 = elevation_matrix["[dx1]"]["[dy2]"]
	var/e11 = elevation_matrix["[dx2]"]["[dy2]"]

	var/bottom_interp = e00 + (e10 - e00) * tx
	var/top_interp = e01 + (e11 - e01) * tx
	var/interpolated_elevation = bottom_interp + (top_interp - bottom_interp) * ty

	var/base_threshold = 0.25 + (interpolated_elevation / 100) * 0.50

	var/center_e = elevation_matrix["0"]["0"]
	var/west_e   = elevation_matrix["-1"]["0"]
	var/east_e   = elevation_matrix["1"]["0"]
	var/north_e  = elevation_matrix["0"]["1"]
	var/south_e  = elevation_matrix["0"]["-1"]


	if(west_e > center_e && east_e > center_e)
		var/center_dist = abs(u - 0.5)
		base_threshold += (0.35 - center_dist * 0.7)


	else if(north_e > center_e && south_e > center_e)
		var/center_dist = abs(v - 0.5)
		base_threshold += (0.35 - center_dist * 0.7)

	else if(north_e > center_e + 20)
		base_threshold += (v - 0.3) * 0.4

	return clamp(base_threshold, 0.15, 0.85)

/datum/map_generator/sub_level/proc/get_biome_datum_type(macro_biome)
	return planet.get_possible_biomes()[macro_biome]

/datum/map_generator/sub_level/proc/generate_sub_level_terrain(datum/turf_reservation/sub_level/reservation)
	if(!planet || !reservation)
		return FALSE

	var/list/turf/turfs = reservation.get_all_turfs()
	if(!length(turfs))
		return FALSE

	var/macro_elevation = planet.get_elevation_level(planet_x, planet_y)
	var/macro_heat = planet.get_heat_level(planet_x, planet_y)
	var/macro_humidity = planet.get_humidity_level(planet_x, planet_y)
	var/macro_biome_str = planet.get_biome(planet_x, planet_y, macro_elevation, macro_heat, macro_humidity)

	var/datum/biome/selected_biome_type = get_biome_datum_type(macro_biome_str)
	var/datum/biome/target_biome = SSmapping.biomes[selected_biome_type]
	if(!target_biome)
		target_biome = SSmapping.biomes[/datum/biome/plains]

	var/local_seed = rand(1, 50000)
	var/width = reservation.width
	var/height = reservation.height
	var/local_noise = rustg_dbp_generate("[local_seed]", "30", "[perlin_zoom]", "[width]", "-0.2", "0.2")

	var/turf/BL = reservation.get_bottom_left_turf()
	var/list/grid = list()

	for(var/turf/T in turfs)
		var/local_x = T.x - BL.x + 1
		var/local_y = T.y - BL.y + 1
		var/index = width * (local_y - 1) + local_x

		var/noise_val = text2num(local_noise[index])
		var/dynamic_threshold = calculate_geological_threshold(local_x, local_y, width, height)

		grid[T] = (noise_val > dynamic_threshold) ? 1 : 0

	apply_neighborhood_shaping(grid, reservation, target_biome)
	return TRUE

/datum/map_generator/sub_level/proc/apply_neighborhood_shaping(list/grid, datum/turf_reservation/sub_level/reservation, datum/biome/target_biome)
	var/list/next_grid = grid.Copy()
	for(var/turf/T in grid)
		var/closed_neighbors = 0

		for(var/dir in GLOB.alldirs)
			var/turf/neighbor = get_step(T, dir)
			if(!neighbor || !reservation.contains_turf(neighbor))
				closed_neighbors++
				continue

			if(grid[neighbor] == 1)
				closed_neighbors++

		if(grid[T] == 1)
			next_grid[T] = (closed_neighbors < 4) ? 0 : 1
		else
			next_grid[T] = (closed_neighbors >= 5) ? 1 : 0

	var/list/open_generated_turfs = list()

	for(var/turf/T in next_grid)
		var/is_closed = (next_grid[T] == 1)
		var/turf/new_turf = target_biome.generate_turf_for_terrain(T, is_closed)

		if(!is_closed && new_turf)
			open_generated_turfs += new_turf

	if(length(open_generated_turfs))
		var/area/A = get_area(open_generated_turfs[1])
		target_biome.populate_turfs(
			open_generated_turfs,
			(A.area_flags_mapping & FLORA_ALLOWED),
			(A.area_flags_mapping & FLORA_ALLOWED),
			(A.area_flags_mapping & MOB_SPAWN_ALLOWED)
		)
