/datum/controller/subsystem/atoms/proc/NewUninitialized(atom_path, atom/newloc)
	if(!ispath(atom_path, /atom))
		CRASH("NewUninitialized: [atom_path] is not an /atom path")

	var/static/uid = 0
	uid = WRAP_UID(uid + 1)

	var/source = "NewUninitialized [uid]"

	set_tracked_initalized(INITIALIZATION_INSSATOMS, source)

	var/atom/created = new atom_path(newloc)

	clear_tracked_initalize(source)

	return created


/datum/controller/subsystem/atoms/proc/NewUninitializedArgs(
	atom_path,
	atom/newloc,
	list/extra_args
)
	if(!ispath(atom_path, /atom))
		CRASH("NewUninitializedArgs: [atom_path] is not an /atom path")

	var/static/uid = 0
	uid = WRAP_UID(uid + 1)

	var/source = "NewUninitializedArgs [uid]"

	set_tracked_initalized(INITIALIZATION_INSSATOMS, source)

	var/atom/created

	if(length(extra_args))
		created = new atom_path(arglist(list(newloc) + extra_args))
	else
		created = new atom_path(newloc)

	clear_tracked_initalize(source)

	return created



/datum/map_generator/sub_level
	var/datum/rimworld_planet/planet
	var/datum/planet_cell/cell

	var/planet_x = 1
	var/planet_y = 1

	/// The planet tile's hex ring: list(list("elevation", "bearing"), ...), bearing clockwise from north
	var/list/hex_neighbourhood

	var/generate_caves = TRUE

	var/list/heights
	var/list/cave_mask

	var/width = 0
	var/height = 0

	var/datum/biome/rimworld/target_biome
	var/sub_biome = RW_SUBBIOME_PLAINS
	var/area/rimworld/rimworld_area

	var/list/generated_turfs = list()
	var/list/generated_open_turfs = list()
	/// Parallel to generated_open_turfs: TRUE if that open turf is a cave tile.
	var/list/generated_open_is_cave = list()
	var/list/pending_init = list()

	var/turfs_initialized = FALSE


/datum/map_generator/sub_level/proc/setup_planet_context(
	datum/rimworld_planet/P,
	px,
	py,
	datum/planet_cell/C
)
	planet = P
	planet_x = px
	planet_y = py
	cell = C
	cache_planetary_neighborhood()


/datum/map_generator/sub_level/proc/cache_planetary_neighborhood()
	if(!planet)
		return FALSE

	hex_neighbourhood = list()
	for(var/list/neighbour as anything in planet.get_neighbor_ring(planet_x, planet_y))
		// Locals, not neighbour["x"] inline: quotes nested in an embedded expression break DM's parser
		var/neighbour_x = neighbour["x"]
		var/neighbour_y = neighbour["y"]
		var/elevation_text = planet.get_elevation_level(neighbour_x, neighbour_y)
		var/value = text2num("[elevation_text]")
		if(isnull(value))
			log_world(
				"RimWorld sub-level: invalid elevation value for planetary coordinate [neighbour_x],[neighbour_y]."
			)
			return FALSE
		hex_neighbourhood += list(list(
			"elevation" = clamp(round(value), 0, 5),
			"bearing" = neighbour["bearing"],
		))

	return TRUE


/datum/map_generator/sub_level/proc/get_target_biome(
	elevation = null,
	heat = null,
	humidity = null,
	biome = null
)
	if(!planet)
		return null

	var/macro_elevation = isnull(elevation) \
		? planet.get_elevation_level(planet_x, planet_y) \
		: elevation

	var/macro_heat = isnull(heat) \
		? planet.get_heat_level(planet_x, planet_y) \
		: heat

	var/macro_humidity = isnull(humidity) \
		? planet.get_humidity_level(planet_x, planet_y) \
		: humidity

	var/macro_biome = isnull(biome) \
		? planet.get_biome(
			planet_x,
			planet_y,
			macro_elevation,
			macro_heat,
			macro_humidity
		) \
		: biome

	var/biome_type = planet.get_possible_biomes()[macro_biome]

	var/datum/biome/rimworld/resolved_biome

	if(biome_type)
		resolved_biome = SSmapping.biomes[biome_type]

	if(!istype(resolved_biome, /datum/biome/rimworld))
		resolved_biome = SSmapping.biomes[/datum/biome/rimworld/grassland]

	return resolved_biome


/datum/map_generator/sub_level/proc/is_geological_transition_xy(
	local_x,
	local_y
)
	if(!length(heights))
		return FALSE

	if(local_x < 1 || local_x > width)
		return FALSE

	if(local_y < 1 || local_y > height)
		return FALSE

	var/index = width * (local_y - 1) + local_x
	var/current_height = heights[index]

	if(local_x > 1)
		if(abs(current_height - heights[index - 1]) >= RW_HEIGHT_TRANSITION_DELTA)
			return TRUE

	if(local_x < width)
		if(abs(current_height - heights[index + 1]) >= RW_HEIGHT_TRANSITION_DELTA)
			return TRUE

	if(local_y > 1)
		if(abs(current_height - heights[index - width]) >= RW_HEIGHT_TRANSITION_DELTA)
			return TRUE

	if(local_y < height)
		if(abs(current_height - heights[index + width]) >= RW_HEIGHT_TRANSITION_DELTA)
			return TRUE

	return FALSE


/datum/map_generator/sub_level/proc/prepare_sub_level_terrain(
	datum/turf_reservation/sub_level/reservation
)
	if(!planet || !cell || !reservation)
		return FALSE

	var/turf/BL = reservation.get_inner_bottom_left_turf()
	var/turf/TR = reservation.get_inner_top_right_turf()

	if(!BL || !TR)
		return FALSE

	width = reservation.inner_width
	height = reservation.inner_height

	if(
		width != RW_SUBLEVEL_INNER_WIDTH \
		|| height != RW_SUBLEVEL_INNER_HEIGHT
	)
		return FALSE

	/*
	 * Resolve the macro planetary context once.
	 */
	var/macro_elevation = planet.get_elevation_level(
		planet_x,
		planet_y
	)

	var/macro_heat = planet.get_heat_level(
		planet_x,
		planet_y
	)

	var/macro_humidity = planet.get_humidity_level(
		planet_x,
		planet_y
	)

	var/macro_biome = planet.get_biome(
		planet_x,
		planet_y,
		macro_elevation,
		macro_heat,
		macro_humidity
	)

	target_biome = get_target_biome(
		macro_elevation,
		macro_heat,
		macro_humidity,
		macro_biome
	)

	if(!target_biome)
		log_world(
			"RimWorld sub-level: unable to resolve biome for [planet_x],[planet_y]."
		)
		return FALSE

	/*
	 * Resolve the current planetary sub-biome.
	 *
	 * This is deliberately the sub-biome of the current macro tile,
	 * not one of the neighbouring tiles.
	 */
	sub_biome = planet.get_sub_biome(
		planet_x,
		planet_y,
		macro_biome,
		macro_elevation
	)

	if(!sub_biome)
		sub_biome = RW_SUBBIOME_PLAINS

	if(!length(hex_neighbourhood))
		cache_planetary_neighborhood()

	if(!length(hex_neighbourhood))
		return FALSE

	var/centre_elevation = clamp(round(text2num("[planet.get_elevation_level(planet_x, planet_y)]")), 0, 5)

	// Планетарная река на этом тайле (слой rivers из tp_planet.rs)
	var/has_river = planet.has_river(planet_x, planet_y)

	var/list/config = list(
		"planet_seed" = planet.seed,
		"planet_x" = planet_x,
		"planet_y" = planet_y,
		"width" = width,
		"height" = height,

		"centre_elevation" = centre_elevation,
		"neighbourhood_hex" = hex_neighbourhood,
		"biome" = macro_biome,
		"sub_biome" = sub_biome,
		"has_river" = has_river,

		"local_seed" = 0,
		"density_bias" = 0.0,
		"smooth_passes" = 1,          // 0..=5 — how many times we smooth height


		"relief_scale" = 1.0,
		"detail_scale" = 1.0,
		"river_strength" = 1.0,
		"lake_strength" = 1.0,
		"cave_strength" = 1.0,
		"water_bias" = 0.0,

		"caves" = generate_caves \
			? RW_CAVEGUN_TRUE \
			: RW_CAVEGUN_FALSE
	)

	var/result = rustg_tp_sublevel_generate(
		json_encode(config)
	)

	if(!result || findtext(result, "ERROR:") == 1)
		log_world(
			"Sub-level heightmap generation failed for [planet_x],[planet_y]: [result]"
		)
		return FALSE

	var/list/export = json_decode(result)

	if(!islist(export) || export["status"] != "ok")
		log_world(
			"Sub-level generation returned bad payload for [planet_x],[planet_y]."
		)
		return FALSE

	heights = export["heights"]

	if(!islist(heights))
		log_world(
			"Sub-level generation returned no heightmap."
		)
		return FALSE

	if(length(heights) != width * height)
		log_world(
			"Sub-level heightmap size mismatch. Expected [width * height], got [length(heights)]."
		)
		return FALSE

	for(var/i in 1 to length(heights))
		var/value = text2num("[heights[i]]")

		if(isnull(value))
			log_world(
				"Sub-level heightmap contains a non-numeric value at index [i]."
			)
			return FALSE

		heights[i] = clamp(value, 0, 1)

	cave_mask = export["cave_mask"]

	if(!islist(cave_mask))
		cave_mask = list()

	else if(generate_caves && (length(cave_mask) != width * height))
		log_world(
			"Sub-level cave mask size mismatch."
		)
		return FALSE

	if(length(cave_mask))
		for(var/i in 1 to length(cave_mask))
			cave_mask[i] = text2num("[cave_mask[i]]") != 0

	/*
	rimworld_area = SSatoms.NewUninitialized(
		/area/rimworld,
		null
	)
	*/
	rimworld_area = new()

	if(!rimworld_area)
		return FALSE

	rimworld_area.cell = cell
	rimworld_area.name = "Rim ([planet_x],[planet_y])"
	rimworld_area.daylight = TRUE
	rimworld_area.outdoors = TRUE

	pending_init = list(/* rimworld_area */)
	generated_turfs = list()
	generated_open_turfs = list()
	generated_open_is_cave = list()
	turfs_initialized = FALSE

	return TRUE


/datum/map_generator/sub_level/proc/place_sub_level_turf(
	datum/turf_reservation/sub_level/reservation,
	local_x,
	local_y
)
	if(!reservation || !target_biome)
		return null

	if(local_x < 1 || local_x > width)
		return null

	if(local_y < 1 || local_y > height)
		return null

	var/turf/inner_BL = reservation.get_inner_bottom_left_turf()
	if(!inner_BL)
		return null

	var/world_x = inner_BL.x + local_x - 1
	var/world_y = inner_BL.y + local_y - 1

	var/turf/source_turf = locate(world_x, world_y, inner_BL.z)
	if(!source_turf)
		return null

	source_turf.change_area(get_area(source_turf), rimworld_area)

	var/index = width * (local_y - 1) + local_x
	if(index < 1 || index > length(heights))
		return null

	var/terrain_height = heights[index]

	var/is_cave = FALSE
	if(length(cave_mask))
		is_cave = cave_mask[index]

	var/is_transition = is_geological_transition_xy(local_x, local_y)

	var/turf_type = target_biome.get_turf_for_height(
		terrain_height,
		sub_biome,
		is_cave,
		is_transition
	)

	if(!turf_type)
		turf_type = /turf/open/genturf

	var/turf/new_turf = SSatoms.NewUninitialized(turf_type, source_turf)
	if(!new_turf)
		return null

	if(SSmapping.used_turfs[source_turf] == reservation)
		SSmapping.used_turfs -= source_turf

	SSmapping.used_turfs[new_turf] = reservation

	new_turf.turf_flags = \
		(new_turf.turf_flags | RESERVATION_TURF) \
		& ~UNUSED_RESERVATION_TURF

	generated_turfs += new_turf
	pending_init += new_turf

	if(!istype(new_turf, /turf/closed))
		generated_open_turfs += new_turf
		generated_open_is_cave += is_cave

	return new_turf


/datum/map_generator/sub_level/proc/populate_turf(
	turf/target_turf,
	flora_allowed,
	features_allowed,
	fauna_allowed,
	is_cave = FALSE
)
	if(!target_turf || !target_biome)
		return FALSE

	if(istype(target_turf, /turf/closed))
		return TRUE

	var/result = target_biome.populate_turf(
		target_turf,
		flora_allowed,
		features_allowed,
		fauna_allowed,
		is_cave,
		sub_biome,
		pending_init
	)

	return result


/datum/map_generator/sub_level/proc/get_generated_turf(index)
	if(index < 1 || index > length(generated_turfs))
		return null

	return generated_turfs[index]


/datum/map_generator/sub_level/proc/get_generated_open_turf(index)
	if(index < 1 || index > length(generated_open_turfs))
		return null

	return generated_open_turfs[index]


/datum/map_generator/sub_level/proc/get_generated_turf_count()
	return length(generated_turfs)

/datum/map_generator/sub_level/proc/get_generated_open_is_cave(index)
	if(index < 1 || index > length(generated_open_is_cave))
		return FALSE
	return generated_open_is_cave[index]

/datum/map_generator/sub_level/proc/get_generated_open_turf_count()
	return length(generated_open_turfs)
