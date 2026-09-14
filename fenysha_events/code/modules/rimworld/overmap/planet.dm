/*
 * RimWorld planetary map
 *
 * Procedural planet data.
 *
 * The planet is completely determined by its master seed and generator
 * parameters. Interactive objects are stored separately and do not affect
 * procedural terrain generation.
 *
 * Generation model:
 *
 *      master seed
 *           |
 *     +-----+------+----------------+
 *     |            |                |
 * elevation      heat           humidity
 *     |            |                |
 *     +------------+----------------+
 *                  |
 *                biome
 *
 * The same parameters should later be implemented in TGUI so the client
 * can reconstruct the visual map locally without receiving every tile.
 */


/*
 * --------------------------------------------------------------------------
 * Planet generation constants
 * --------------------------------------------------------------------------
 */

/*
 * Climate levels.
 *
 * These intentionally mirror the LOW / MEDIUM / HIGH approach used by
 * TG's cave biome generator.
 */

#define RW_CLIMATE_LOW "0"
#define RW_CLIMATE_MEDIUM "1"
#define RW_CLIMATE_HIGH "2"


/*
 * Elevation levels.
 */

#define RW_ELEVATION_OCEAN "0"
#define RW_ELEVATION_COAST "1"
#define RW_ELEVATION_LOWLAND "2"
#define RW_ELEVATION_HIGHLAND "3"
#define RW_ELEVATION_MOUNTAIN "4"
#define RW_ELEVATION_SNOW "5"


/*
 * Biome identifiers.
 *
 * Keep these as stable strings because they will eventually be sent to TGUI.
 */

#define RW_BIOME_OCEAN "ocean"
#define RW_BIOME_BEACH "beach"
#define RW_BIOME_TUNDRA "tundra"
#define RW_BIOME_TAIGA "taiga"
#define RW_BIOME_TEMPERATE_FOREST "temperate_forest"
#define RW_BIOME_GRASSLAND "grassland"
#define RW_BIOME_SAVANNA "savanna"
#define RW_BIOME_DESERT "desert"
#define RW_BIOME_TROPICAL_FOREST "tropical_forest"
#define RW_BIOME_RAINFOREST "rainforest"
#define RW_BIOME_MOUNTAINS "mountains"
#define RW_BIOME_SNOW "snow"


/*
 * Terrain noise configuration.
 *
 * DBP is used in the same general way TG uses it:
 * a seed + scale + thresholds produces a deterministic binary noise map.
 *
 * These values are intentionally centralized so TGUI can later receive
 * exactly the same configuration.
 */

#define RW_TERRAIN_NOISE_SCALE 60
#define RW_ELEVATION_STAMP_SIZE 64
#define RW_HEAT_STAMP_SIZE 90
#define RW_HUMIDITY_STAMP_SIZE 90

#define RW_LOW_THRESHOLD -0.30
#define RW_HIGH_THRESHOLD -0.10


/proc/get_dist_2d(x1, y1, x2, y2)
	return sqrt(((x2 - x1) ** 2) + ((y2 - y1) ** 2))


/*
 * Planet object types
 */

/datum/rimworld_planet_object
	/// Unique persistent identifier.
	var/id

	/// Type identifier used by TGUI.
	var/object_type = "object"

	/// Display name.
	var/name = "Unknown"

	/// Logical planet coordinates.
	var/x = 1
	var/y = 1

	/// Optional icon identifier for TGUI.
	var/icon = null

	/// Arbitrary object-specific data.
	var/list/data = list()


/datum/rimworld_planet_object/New(
		new_id,
		new_x,
		new_y,
		new_name = null,
	)
	id = new_id
	x = new_x
	y = new_y

	if(new_name)
		name = new_name

	..()


/datum/rimworld_planet_object/proc/get_data()
	return list(
		"id" = id,
		"type" = object_type,
		"name" = name,
		"x" = x,
		"y" = y,
		"icon" = icon,
		"data" = data.Copy(),
	)


/*
 * Settlement
 */

/datum/rimworld_planet_object/settlement
	object_type = "settlement"


/datum/rimworld_planet_object/settlement/New(
		new_id,
		new_x,
		new_y,
		new_name = "Settlement",
	)
	. = ..(
		new_id,
		new_x,
		new_y,
		new_name,
	)

	data = list(
		"population" = 0,
		"faction" = null,
		"settlement_type" = "village",
	)

/datum/rimworld_planet_object/settlement/proc/set_population(value)
	data["population"] = max(0, value)


/datum/rimworld_planet_object/settlement/proc/set_faction(faction)
	data["faction"] = faction


/*
 * Point of interest
 */

/datum/rimworld_planet_object/point_of_interest
	object_type = "point_of_interest"


/datum/rimworld_planet_object/point_of_interest/New(
		new_id,
		new_x,
		new_y,
		new_name = "Point of Interest",
	)
	. = ..(
		new_id,
		new_x,
		new_y,
		new_name,
	)

	data = list(
		"poi_type" = "unknown",
		"discovered" = FALSE,
	)


/*
 * Road
 *
 * Roads are represented as a connection between two logical objects/points.
 * The actual geometry can later be generated client-side.
 */

/datum/rimworld_planet_object/road
	object_type = "road"

	var/start_x
	var/start_y

	var/end_x
	var/end_y


/datum/rimworld_planet_object/road/New(
		new_id,
		new_start_x,
		new_start_y,
		new_end_x,
		new_end_y,
	)
	. = ..(
		new_id,
		new_start_x,
		new_start_y,
		"Road",
	)

	start_x = new_start_x
	start_y = new_start_y

	end_x = new_end_x
	end_y = new_end_y

	data = list(
		"start_x" = start_x,
		"start_y" = start_y,
		"end_x" = end_x,
		"end_y" = end_y,
	)


/datum/rimworld_planet_object/road/get_data()
	. = ..()

	.["start_x"] = start_x
	.["start_y"] = start_y

	.["end_x"] = end_x
	.["end_y"] = end_y


/*
 * Planet
 */

/datum/rimworld_planet

	var/name = "Unnamed Planet"

	/*
	 * Master seed.
	 *
	 * Everything procedural must ultimately originate from this value.
	 */
	var/seed

	/*
	 * Logical dimensions of the strategic map.
	 *
	 * This is NOT BYOND map size.
	 *
	 * These are planetary coordinates.
	 */
	var/map_width = 2048
	var/map_height = 1024

	// Base terrain scale.
	var/terrain_scale = RW_ELEVATION_STAMP_SIZE

	// Climate noise scales.
	var/heat_scale = RW_HEAT_STAMP_SIZE
	var/humidity_scale = RW_HUMIDITY_STAMP_SIZE

	/*
	 * Number of climate divisions.
	 *
	 * Currently three:
	 *
	 * LOW
	 * MEDIUM
	 * HIGH
	 */
	var/heat_threshold_low = RW_LOW_THRESHOLD
	var/heat_threshold_high = RW_HIGH_THRESHOLD

	var/humidity_threshold_low = RW_LOW_THRESHOLD
	var/humidity_threshold_high = RW_HIGH_THRESHOLD

	/*
	 * Never generate these randomly.
	 *
	 * They must always be derived from the master seed, otherwise loading
	 * the same planet would produce a different world.
	 */
	var/terrain_seed
	var/heat_seed
	var/humidity_seed

	var/list/elevation_maps
	var/list/heat_maps
	var/list/humidity_maps

	var/list/objects = list()

	var/list/settlements = list()
	var/list/points_of_interest = list()
	var/list/roads = list()
	var/list/discovered_regions = list()


/datum/rimworld_planet/New(new_seed = null)
	. = ..()

	if(isnull(new_seed))
		seed = rand(1, 2000000000)
	else
		seed = new_seed

	derive_seeds()


/*
 * Seed derivation
 *
 * Используем маленький диапазон (0..50000), как в cave_generator,
 * чтобы избежать переполнения и проблем с точностью в BYOND.
 */
/datum/rimworld_planet/proc/derive_seeds()
	var/base = abs(seed) % 50001

	terrain_seed = base
	heat_seed = (base + 10000) % 50001
	humidity_seed = (base + 20000) % 50001


/datum/rimworld_planet/proc/get_terrain_seed()
	return terrain_seed


/datum/rimworld_planet/proc/get_heat_seed()
	return heat_seed


/datum/rimworld_planet/proc/get_humidity_seed()
	return humidity_seed


/datum/rimworld_planet/proc/is_valid_coordinate(x, y)
	return ((x >= 1) && (x <= map_width) && (y >= 1) && (y <= map_height))


/datum/rimworld_planet/proc/get_coordinate_index(x, y)
	if(!is_valid_coordinate(x, y))
		return null

	return map_width * (y - 1) + x


/*
 * Noise generation
 */
/datum/rimworld_planet/proc/generate_climate_maps()
	heat_maps = list()
	humidity_maps = list()

	// HIGH heat
	heat_maps[RW_CLIMATE_HIGH] = rustg_dbp_generate("[heat_seed]", "60", "[heat_scale]", "[map_width]", "[heat_threshold_high]", "1.1")

	// MEDIUM heat
	heat_maps[RW_CLIMATE_MEDIUM] = rustg_dbp_generate("[heat_seed]", "60", "[heat_scale]", "[map_width]", "[heat_threshold_low]", "[heat_threshold_high]")

	// HIGH humidity
	humidity_maps[RW_CLIMATE_HIGH] = rustg_dbp_generate("[humidity_seed]", "60", "[humidity_scale]", "[map_width]", "[humidity_threshold_high]", "1.1")

	// MEDIUM humidity
	humidity_maps[RW_CLIMATE_MEDIUM] = rustg_dbp_generate("[humidity_seed]", "60", "[humidity_scale]", "[map_width]", "[humidity_threshold_low]", "[humidity_threshold_high]")


/datum/rimworld_planet/proc/generate_elevation_maps()
	elevation_maps = list()

	// Ocean
	elevation_maps[RW_ELEVATION_OCEAN] = rustg_dbp_generate("[terrain_seed]", "60", "[terrain_scale]", "[map_width]", "-1.0", "-0.25")

	// Coast
	elevation_maps[RW_ELEVATION_COAST] = rustg_dbp_generate("[terrain_seed]", "60", "[terrain_scale]", "[map_width]", "-0.25", "-0.08")

	// Lowland
	elevation_maps[RW_ELEVATION_LOWLAND] = rustg_dbp_generate("[terrain_seed]", "60", "[terrain_scale]", "[map_width]", "-0.08", "0.12")

	// Highland
	elevation_maps[RW_ELEVATION_HIGHLAND] = rustg_dbp_generate("[terrain_seed]", "60", "[terrain_scale]", "[map_width]", "0.12", "0.28")

	// Mountain
	elevation_maps[RW_ELEVATION_MOUNTAIN] = rustg_dbp_generate("[terrain_seed]", "60", "[terrain_scale]", "[map_width]", "0.28", "0.48")

	// Snow
	elevation_maps[RW_ELEVATION_SNOW] = rustg_dbp_generate("[terrain_seed]", "60", "[terrain_scale]", "[map_width]", "0.48", "1.1")


/datum/rimworld_planet/proc/is_noise_value_true(map, x, y)
	if(!map)
		return FALSE

	// Точно такой же расчёт координаты, как в cave_generator
	var/coordinate = map_width * (y - 1) + x

	// Защита (на случай если height > width или строка короче)
	if(coordinate < 1 || coordinate > length(map))
		return FALSE

	return text2num(map[coordinate])


/datum/rimworld_planet/proc/get_heat_level(x, y)
	if(!is_valid_coordinate(x, y))
		return RW_CLIMATE_LOW

	// Сначала HIGH, потом MEDIUM — точно как в biome-коде cave_generator
	if(is_noise_value_true(heat_maps[RW_CLIMATE_HIGH], x, y))
		return RW_CLIMATE_HIGH

	if(is_noise_value_true(heat_maps[RW_CLIMATE_MEDIUM], x, y))
		return RW_CLIMATE_MEDIUM

	return RW_CLIMATE_LOW


/datum/rimworld_planet/proc/get_humidity_level(x, y)
	if(!is_valid_coordinate(x, y))
		return RW_CLIMATE_LOW

	if(is_noise_value_true(humidity_maps[RW_CLIMATE_HIGH], x, y))
		return RW_CLIMATE_HIGH

	if(is_noise_value_true(humidity_maps[RW_CLIMATE_MEDIUM], x, y))
		return RW_CLIMATE_MEDIUM

	return RW_CLIMATE_LOW


/datum/rimworld_planet/proc/get_elevation_level(x, y)
	if(!is_valid_coordinate(x, y))
		return RW_ELEVATION_OCEAN

	// Приоритет от самого высокого уровня к самому низкому
	if(is_noise_value_true(elevation_maps[RW_ELEVATION_SNOW], x, y))
		return RW_ELEVATION_SNOW

	if(is_noise_value_true(elevation_maps[RW_ELEVATION_MOUNTAIN], x, y))
		return RW_ELEVATION_MOUNTAIN

	if(is_noise_value_true(elevation_maps[RW_ELEVATION_HIGHLAND], x, y))
		return RW_ELEVATION_HIGHLAND

	if(is_noise_value_true(elevation_maps[RW_ELEVATION_LOWLAND], x, y))
		return RW_ELEVATION_LOWLAND

	if(is_noise_value_true(elevation_maps[RW_ELEVATION_COAST], x, y))
		return RW_ELEVATION_COAST

	if(is_noise_value_true(elevation_maps[RW_ELEVATION_OCEAN], x, y))
		return RW_ELEVATION_OCEAN

	return RW_ELEVATION_LOWLAND

/datum/rimworld_planet/proc/generate()
	var/start_time = REALTIMEOFDAY

	derive_seeds()

	generate_climate_maps()
	generate_elevation_maps()

	var/message = "[name] planetary generation finished in [(REALTIMEOFDAY - start_time) / 10]s."
	log_world(message)

	return TRUE



/*
 * Temperature
 *
 * Normalized conceptual value derived from:
 *
 *     heat noise level
 *     latitude
 *
 * Planetary temperature naturally becomes colder toward the poles.
 */

/datum/rimworld_planet/proc/get_temperature(x, y)
	if(!is_valid_coordinate(x, y))
		return 0

	var/latitude = abs(((y - 1) / max(1, map_height - 1)) * 2 - 1)

	/*
	 * Latitude factor:
	 * 0 = equator
	 * 1 = pole
	 */
	var/latitude_modifier = 1 - latitude

	var/heat_level = get_heat_level(x, y)

	var/heat_modifier

	switch(heat_level)
		if(RW_CLIMATE_HIGH)
			heat_modifier = 1.0
		if(RW_CLIMATE_MEDIUM)
			heat_modifier = 0.6
		else
			heat_modifier = 0.2

	/*
	 * Weighted combination.
	 */
	return clamp((latitude_modifier * 0.55) + (heat_modifier * 0.45), 0, 1)


/*
 * Biome selection
 *
 * Elevation has priority over climate.
 *
 * Then heat + humidity determine the terrestrial biome.
 */

/datum/rimworld_planet/proc/get_biome(x, y)
	if(!is_valid_coordinate(x, y))
		return RW_BIOME_OCEAN

	var/elevation = get_elevation_level(x, y)
	var/heat = get_heat_level(x, y)
	var/humidity = get_humidity_level(x, y)

	/*
	 * Water.
	 */
	if(elevation == RW_ELEVATION_OCEAN)
		return RW_BIOME_OCEAN

	if(elevation == RW_ELEVATION_COAST)
		return RW_BIOME_BEACH

	/*
	 * Mountains / high elevation.
	 */
	if(elevation == RW_ELEVATION_SNOW)
		return RW_BIOME_SNOW

	if(elevation == RW_ELEVATION_MOUNTAIN)
		return RW_BIOME_MOUNTAINS

	/*
	 * Cold climates.
	 */
	if(heat == RW_CLIMATE_LOW)
		switch(humidity)
			if(RW_CLIMATE_HIGH)
				return RW_BIOME_TAIGA
			if(RW_CLIMATE_MEDIUM)
				return RW_BIOME_TUNDRA
			else
				return RW_BIOME_TUNDRA

	/*
	 * Medium heat.
	 */
	if(heat == RW_CLIMATE_MEDIUM)
		switch(humidity)
			if(RW_CLIMATE_HIGH)
				return RW_BIOME_TEMPERATE_FOREST
			if(RW_CLIMATE_MEDIUM)
				return RW_BIOME_GRASSLAND
			else
				return RW_BIOME_SAVANNA

	/*
	 * Hot climates.
	 */
	switch(humidity)
		if(RW_CLIMATE_HIGH)
			return RW_BIOME_RAINFOREST
		if(RW_CLIMATE_MEDIUM)
			return RW_BIOME_TROPICAL_FOREST
		else
			return RW_BIOME_DESERT


/*
 * This is intended for server-side requests:
 *
 *     click tile
 *         ↓
 *     get_tile_data()
 *         ↓
 *     detailed response
 *
 * It is NOT intended to be sent for the whole planet.
 */

/datum/rimworld_planet/proc/get_tile_data(x, y)
	if(!is_valid_coordinate(x, y))
		return null

	return list(
		"x" = x,
		"y" = y,
		"elevation" = get_elevation_level(x, y),
		"temperature" = get_temperature(x, y),
		"heat" = get_heat_level(x, y),
		"humidity" = get_humidity_level(x, y),
		"biome" = get_biome(x, y),
		"objects" = get_objects_at(x, y),
	)


/*
 * --------------------------------------------------------------------------
 * Object ID generation
 * --------------------------------------------------------------------------
 *
 * IDs are intentionally separate from coordinates.
 *
 * An object can later be moved without changing its identity.
 */

/datum/rimworld_planet/proc/generate_object_id(prefix = "object")
	var/id

	do
		id = "[prefix]_[rand(1, 2000000000)]"
	while(objects[id])

	return id


/*
 * --------------------------------------------------------------------------
 * Object placement
 * --------------------------------------------------------------------------
 */

/datum/rimworld_planet/proc/add_object(datum/rimworld_planet_object/object)
	if(!object)
		return FALSE

	if(!is_valid_coordinate(object.x, object.y))
		return FALSE

	if(objects[object.id])
		return FALSE

	objects[object.id] = object

	if(istype(object, /datum/rimworld_planet_object/settlement))
		settlements[object.id] = object
	else if(istype(object, /datum/rimworld_planet_object/point_of_interest))
		points_of_interest[object.id] = object
	else if(istype(object, /datum/rimworld_planet_object/road))
		roads[object.id] = object

	return TRUE


/*
 * --------------------------------------------------------------------------
 * Object removal
 * --------------------------------------------------------------------------
 */

/datum/rimworld_planet/proc/remove_object(object_id)
	var/datum/rimworld_planet_object/object = objects[object_id]

	if(!object)
		return FALSE

	objects -= object_id
	settlements -= object_id
	points_of_interest -= object_id
	roads -= object_id

	return TRUE


/*
 * --------------------------------------------------------------------------
 * Object lookup
 * --------------------------------------------------------------------------
 */

/datum/rimworld_planet/proc/get_object(object_id)
	return objects[object_id]


/datum/rimworld_planet/proc/get_objects_at(x, y)
	var/list/result = list()

	for(var/object_id in objects)
		var/datum/rimworld_planet_object/object = objects[object_id]

		if(object.x == x && object.y == y)
			result += list(object.get_data())

	return result


/*
 * --------------------------------------------------------------------------
 * Objects near coordinates
 * --------------------------------------------------------------------------
 */

/datum/rimworld_planet/proc/get_objects_in_radius(x, y, radius)
	var/list/result = list()

	for(var/object_id in objects)
		var/datum/rimworld_planet_object/object = objects[object_id]

		if(get_dist_2d(x, y, object.x, object.y) <= radius)
			result += list(object.get_data())

	return result


/*
 * --------------------------------------------------------------------------
 * Moving objects
 * --------------------------------------------------------------------------
 */

/datum/rimworld_planet/proc/move_object(object_id, new_x, new_y)
	var/datum/rimworld_planet_object/object = objects[object_id]

	if(!object)
		return FALSE

	if(!is_valid_coordinate(new_x, new_y))
		return FALSE

	object.x = new_x
	object.y = new_y

	/*
	 * Roads store their own endpoints, so they do not use this procedure
	 * in normal operation.
	 */
	return TRUE


/*
 * --------------------------------------------------------------------------
 * Placement helpers
 * --------------------------------------------------------------------------
 */

/datum/rimworld_planet/proc/create_settlement(
		x,
		y,
		settlement_name = "Settlement",
	)
	if(!is_valid_coordinate(x, y))
		return null

	var/id = generate_object_id("settlement")

	var/datum/rimworld_planet_object/settlement/object = new /datum/rimworld_planet_object/settlement(
		id,
		x,
		y,
		settlement_name,
	)

	if(!add_object(object))
		qdel(object)
		return null

	return object


/datum/rimworld_planet/proc/create_point_of_interest(
		x,
		y,
		poi_name = "Point of Interest",
	)
	if(!is_valid_coordinate(x, y))
		return null

	var/id = generate_object_id("poi")

	var/datum/rimworld_planet_object/point_of_interest/object = new /datum/rimworld_planet_object/point_of_interest(
		id,
		x,
		y,
		poi_name,
	)

	if(!add_object(object))
		qdel(object)
		return null

	return object


/datum/rimworld_planet/proc/create_road(
		start_x,
		start_y,
		end_x,
		end_y,
	)
	if(!is_valid_coordinate(start_x, start_y))
		return null

	if(!is_valid_coordinate(end_x, end_y))
		return null

	var/id = generate_object_id("road")

	var/datum/rimworld_planet_object/road/object = new /datum/rimworld_planet_object/road(
		id,
		start_x,
		start_y,
		end_x,
		end_y,
	)

	if(!add_object(object))
		qdel(object)
		return null

	return object


/*
 * --------------------------------------------------------------------------
 * Planet serialization for TGUI
 * --------------------------------------------------------------------------
 *
 * This deliberately sends NO tile data.
 *
 * The complete terrain is reconstructed client-side from:
 *
 *     seed
 *     dimensions
 *     generator parameters
 *
 * Only interactive objects are serialized.
 */

/datum/rimworld_planet/proc/get_interactive_objects()
	var/list/result = list()

	for(var/object_id in objects)
		var/datum/rimworld_planet_object/object = objects[object_id]
		result += list(object.get_data())

	return result


/datum/rimworld_planet/proc/get_map_data()
	return list(
		/*
		 * Planet.
		 */
		"name" = name,
		"seed" = seed,
		"width" = map_width,
		"height" = map_height,

		/*
		 * Generator configuration.
		 *
		 * TGUI needs these values to produce the exact same visual map.
		 */
		"terrainScale" = terrain_scale,
		"heatScale" = heat_scale,
		"humidityScale" = humidity_scale,
		"noiseScale" = RW_TERRAIN_NOISE_SCALE,
		"heatThresholdLow" = heat_threshold_low,
		"heatThresholdHigh" = heat_threshold_high,
		"humidityThresholdLow" = humidity_threshold_low,
		"humidityThresholdHigh" = humidity_threshold_high,

		/*
		 * Interactive objects.
		 */
		"objects" = get_interactive_objects(),

		/*
		 * Generator version.
		 *
		 * This is important.
		 *
		 * Once worlds exist in production, changing the generation algorithm
		 * should bump this value instead of silently breaking old worlds.
		 */
		"generatorVersion" = 2,
	)


/*
 * --------------------------------------------------------------------------
 * Cleanup
 * --------------------------------------------------------------------------
 */

/datum/rimworld_planet/Destroy()
	elevation_maps = null
	heat_maps = null
	humidity_maps = null

	objects = null
	settlements = null
	points_of_interest = null
	roads = null
	discovered_regions = null

	return ..()


#undef RW_CLIMATE_LOW
#undef RW_CLIMATE_MEDIUM
#undef RW_CLIMATE_HIGH

#undef RW_ELEVATION_OCEAN
#undef RW_ELEVATION_COAST
#undef RW_ELEVATION_LOWLAND
#undef RW_ELEVATION_HIGHLAND
#undef RW_ELEVATION_MOUNTAIN
#undef RW_ELEVATION_SNOW

#undef RW_BIOME_OCEAN
#undef RW_BIOME_BEACH
#undef RW_BIOME_TUNDRA
#undef RW_BIOME_TAIGA
#undef RW_BIOME_TEMPERATE_FOREST
#undef RW_BIOME_GRASSLAND
#undef RW_BIOME_SAVANNA
#undef RW_BIOME_DESERT
#undef RW_BIOME_TROPICAL_FOREST
#undef RW_BIOME_RAINFOREST
#undef RW_BIOME_MOUNTAINS
#undef RW_BIOME_SNOW

#undef RW_TERRAIN_NOISE_SCALE
#undef RW_ELEVATION_STAMP_SIZE
#undef RW_HEAT_STAMP_SIZE
#undef RW_HUMIDITY_STAMP_SIZE

#undef RW_LOW_THRESHOLD
#undef RW_HIGH_THRESHOLD
