/datum/rimworld_planet_object

	var/id
	var/object_type = "object"
	var/name = "Unknown"
	var/x = 1
	var/y = 1
	var/icon = null
	var/list/data = list()


/datum/rimworld_planet_object/New(new_id, new_x, new_y, new_name = null)
	id = new_id
	x = new_x
	y = new_y

	if(new_name)
		name = new_name

	. = ..()


/datum/rimworld_planet_object/proc/get_data()
	return list("id" = id, "type" = object_type, "name" = name, "x" = x, "y" = y, "icon" = icon, "data" = data.Copy())


/datum/rimworld_planet_object/settlement
	object_type = "settlement"


/datum/rimworld_planet_object/settlement/New(new_id, new_x, new_y, new_name = "Settlement")
	. = ..(new_id, new_x, new_y, new_name)

	data = list("population" = 0, "faction" = null, "settlement_type" = "village")


/datum/rimworld_planet_object/settlement/proc/set_population(value)
	data["population"] = max(0, value)


/datum/rimworld_planet_object/settlement/proc/set_faction(faction)
	data["faction"] = faction


/datum/rimworld_planet_object/point_of_interest
	object_type = "point_of_interest"


/datum/rimworld_planet_object/point_of_interest/New(new_id, new_x, new_y, new_name = "Point of Interest")
	. = ..(new_id, new_x, new_y, new_name)

	data = list("poi_type" = "unknown", "discovered" = FALSE)


/datum/rimworld_planet_object/road

	object_type = "road"

	var/start_x
	var/start_y
	var/end_x
	var/end_y


/datum/rimworld_planet_object/road/New(new_id, new_start_x, new_start_y, new_end_x, new_end_y)
	. = ..(new_id, new_start_x, new_start_y, "Road")

	start_x = new_start_x
	start_y = new_start_y
	end_x = new_end_x
	end_y = new_end_y

	data = list("start_x" = start_x, "start_y" = start_y, "end_x" = end_x, "end_y" = end_y)


/datum/rimworld_planet_object/road/get_data()
	. = ..()

	.["start_x"] = start_x
	.["start_y"] = start_y
	.["end_x"] = end_x
	.["end_y"] = end_y


/datum/rimworld_planet

	var/name = "Unnamed Planet"
	var/seed
	var/planet_type = RW_PLANET_PRESET_TERRAN

	var/map_width = 2048
	var/map_height = 1024

	var/terrain_scale = RW_ELEVATION_STAMP_SIZE
	var/heat_scale = RW_HEAT_STAMP_SIZE
	var/humidity_scale = RW_HUMIDITY_STAMP_SIZE

	var/heat_threshold_low = RW_TERRAN_HEAT_LOW
	var/heat_threshold_high = RW_TERRAN_HEAT_HIGH

	var/humidity_threshold_low = RW_TERRAN_HUMIDITY_LOW
	var/humidity_threshold_high = RW_TERRAN_HUMIDITY_HIGH

	var/elevation_ocean_low = RW_TERRAN_OCEAN_LOW
	var/elevation_ocean_high = RW_TERRAN_OCEAN_HIGH

	var/elevation_coast_low = RW_TERRAN_COAST_LOW
	var/elevation_coast_high = RW_TERRAN_COAST_HIGH

	var/elevation_lowland_low = RW_TERRAN_LOWLAND_LOW
	var/elevation_lowland_high = RW_TERRAN_LOWLAND_HIGH

	var/elevation_highland_low = RW_TERRAN_HIGHLAND_LOW
	var/elevation_highland_high = RW_TERRAN_HIGHLAND_HIGH

	var/elevation_mountain_low = RW_TERRAN_MOUNTAIN_LOW
	var/elevation_mountain_high = RW_TERRAN_MOUNTAIN_HIGH

	var/elevation_snow_low = RW_TERRAN_SNOW_LOW
	var/elevation_snow_high = RW_TERRAN_SNOW_HIGH

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

	/// Incremented whenever generator parameters change. Clients rebuild from this.
	var/generation_revision = 0

	/// Sparse overlay art: "[x]:[y]" -> asset key/url. Never a full-grid payload.
	var/list/tile_images = list()

	/// Optional biome -> asset key/url. Empty until tile art exists.
	var/list/biome_images = list()


/datum/rimworld_planet/New(new_seed = null, new_planet_type = RW_PLANET_PRESET_TERRAN)
	. = ..()

	if(isnull(new_seed))
		seed = rand(1, 2000000000)
	else
		seed = new_seed

	apply_preset(new_planet_type)
	derive_seeds()


/datum/rimworld_planet/proc/apply_preset(new_planet_type)

	switch(new_planet_type)

		if(RW_PLANET_PRESET_TERRAN)
			planet_type = RW_PLANET_PRESET_TERRAN
			name = "Terran Planet"

			terrain_scale = RW_ELEVATION_STAMP_SIZE
			heat_scale = RW_HEAT_STAMP_SIZE
			humidity_scale = RW_HUMIDITY_STAMP_SIZE

			heat_threshold_low = RW_TERRAN_HEAT_LOW
			heat_threshold_high = RW_TERRAN_HEAT_HIGH
			humidity_threshold_low = RW_TERRAN_HUMIDITY_LOW
			humidity_threshold_high = RW_TERRAN_HUMIDITY_HIGH

			elevation_ocean_low = RW_TERRAN_OCEAN_LOW
			elevation_ocean_high = RW_TERRAN_OCEAN_HIGH
			elevation_coast_low = RW_TERRAN_COAST_LOW
			elevation_coast_high = RW_TERRAN_COAST_HIGH
			elevation_lowland_low = RW_TERRAN_LOWLAND_LOW
			elevation_lowland_high = RW_TERRAN_LOWLAND_HIGH
			elevation_highland_low = RW_TERRAN_HIGHLAND_LOW
			elevation_highland_high = RW_TERRAN_HIGHLAND_HIGH
			elevation_mountain_low = RW_TERRAN_MOUNTAIN_LOW
			elevation_mountain_high = RW_TERRAN_MOUNTAIN_HIGH
			elevation_snow_low = RW_TERRAN_SNOW_LOW
			elevation_snow_high = RW_TERRAN_SNOW_HIGH

		if(RW_PLANET_PRESET_ICE)
			planet_type = RW_PLANET_PRESET_ICE
			name = "Ice Planet"

			terrain_scale = 72
			heat_scale = 120
			humidity_scale = 100

			heat_threshold_low = RW_ICE_HEAT_LOW
			heat_threshold_high = RW_ICE_HEAT_HIGH
			humidity_threshold_low = RW_ICE_HUMIDITY_LOW
			humidity_threshold_high = RW_ICE_HUMIDITY_HIGH

			elevation_ocean_low = RW_ICE_OCEAN_LOW
			elevation_ocean_high = RW_ICE_OCEAN_HIGH
			elevation_coast_low = RW_ICE_COAST_LOW
			elevation_coast_high = RW_ICE_COAST_HIGH
			elevation_lowland_low = RW_ICE_LOWLAND_LOW
			elevation_lowland_high = RW_ICE_LOWLAND_HIGH
			elevation_highland_low = RW_ICE_HIGHLAND_LOW
			elevation_highland_high = RW_ICE_HIGHLAND_HIGH
			elevation_mountain_low = RW_ICE_MOUNTAIN_LOW
			elevation_mountain_high = RW_ICE_MOUNTAIN_HIGH
			elevation_snow_low = RW_ICE_SNOW_LOW
			elevation_snow_high = RW_ICE_SNOW_HIGH

		if(RW_PLANET_PRESET_DESERT)
			planet_type = RW_PLANET_PRESET_DESERT
			name = "Desert Planet"

			terrain_scale = 68
			heat_scale = 100
			humidity_scale = 120

			heat_threshold_low = RW_DESERT_HEAT_LOW
			heat_threshold_high = RW_DESERT_HEAT_HIGH
			humidity_threshold_low = RW_DESERT_HUMIDITY_LOW
			humidity_threshold_high = RW_DESERT_HUMIDITY_HIGH

			elevation_ocean_low = RW_DESERT_OCEAN_LOW
			elevation_ocean_high = RW_DESERT_OCEAN_HIGH
			elevation_coast_low = RW_DESERT_COAST_LOW
			elevation_coast_high = RW_DESERT_COAST_HIGH
			elevation_lowland_low = RW_DESERT_LOWLAND_LOW
			elevation_lowland_high = RW_DESERT_LOWLAND_HIGH
			elevation_highland_low = RW_DESERT_HIGHLAND_LOW
			elevation_highland_high = RW_DESERT_HIGHLAND_HIGH
			elevation_mountain_low = RW_DESERT_MOUNTAIN_LOW
			elevation_mountain_high = RW_DESERT_MOUNTAIN_HIGH
			elevation_snow_low = RW_DESERT_SNOW_LOW
			elevation_snow_high = RW_DESERT_SNOW_HIGH

		if(RW_PLANET_PRESET_OCEAN)
			planet_type = RW_PLANET_PRESET_OCEAN
			name = "Ocean Planet"

			terrain_scale = 100
			heat_scale = 110
			humidity_scale = 110

			heat_threshold_low = RW_OCEAN_HEAT_LOW
			heat_threshold_high = RW_OCEAN_HEAT_HIGH
			humidity_threshold_low = RW_OCEAN_HUMIDITY_LOW
			humidity_threshold_high = RW_OCEAN_HUMIDITY_HIGH

			elevation_ocean_low = RW_OCEAN_OCEAN_LOW
			elevation_ocean_high = RW_OCEAN_OCEAN_HIGH
			elevation_coast_low = RW_OCEAN_COAST_LOW
			elevation_coast_high = RW_OCEAN_COAST_HIGH
			elevation_lowland_low = RW_OCEAN_LOWLAND_LOW
			elevation_lowland_high = RW_OCEAN_LOWLAND_HIGH
			elevation_highland_low = RW_OCEAN_HIGHLAND_LOW
			elevation_highland_high = RW_OCEAN_HIGHLAND_HIGH
			elevation_mountain_low = RW_OCEAN_MOUNTAIN_LOW
			elevation_mountain_high = RW_OCEAN_MOUNTAIN_HIGH
			elevation_snow_low = RW_OCEAN_SNOW_LOW
			elevation_snow_high = RW_OCEAN_SNOW_HIGH

		else
			apply_preset(RW_PLANET_PRESET_TERRAN)


#define RW_SEED_MODULUS 2147483647
#define RW_SEED_MULTIPLIER 1103515245
#define RW_SEED_INCREMENT 12345


/datum/rimworld_planet/proc/derive_seeds()
	terrain_seed = ((seed * RW_SEED_MULTIPLIER) + RW_SEED_INCREMENT) % RW_SEED_MODULUS
	heat_seed = ((terrain_seed * RW_SEED_MULTIPLIER) + RW_SEED_INCREMENT) % RW_SEED_MODULUS
	humidity_seed = ((heat_seed * RW_SEED_MULTIPLIER) + RW_SEED_INCREMENT) % RW_SEED_MODULUS


#undef RW_SEED_MODULUS
#undef RW_SEED_MULTIPLIER
#undef RW_SEED_INCREMENT


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


/datum/rimworld_planet/proc/generate_climate_maps()

	heat_maps = list()
	humidity_maps = list()

	heat_maps[RW_CLIMATE_HIGH] = rustg_dbp_generate("[heat_seed]", "[RW_TERRAIN_NOISE_SCALE]", "[heat_scale]", "[map_width]", "[heat_threshold_high]", "1.1")
	heat_maps[RW_CLIMATE_MEDIUM] = rustg_dbp_generate("[heat_seed]", "[RW_TERRAIN_NOISE_SCALE]", "[heat_scale]", "[map_width]", "[heat_threshold_low]", "[heat_threshold_high]")

	humidity_maps[RW_CLIMATE_HIGH] = rustg_dbp_generate("[humidity_seed]", "[RW_TERRAIN_NOISE_SCALE]", "[humidity_scale]", "[map_width]", "[humidity_threshold_high]", "1.1")
	humidity_maps[RW_CLIMATE_MEDIUM] = rustg_dbp_generate("[humidity_seed]", "[RW_TERRAIN_NOISE_SCALE]", "[humidity_scale]", "[map_width]", "[humidity_threshold_low]", "[humidity_threshold_high]")


/datum/rimworld_planet/proc/generate_elevation_maps()

	elevation_maps = list()

	elevation_maps[RW_ELEVATION_OCEAN] = rustg_dbp_generate("[terrain_seed]", "[RW_TERRAIN_NOISE_SCALE]", "[terrain_scale]", "[map_width]", "[elevation_ocean_low]", "[elevation_ocean_high]")
	elevation_maps[RW_ELEVATION_COAST] = rustg_dbp_generate("[terrain_seed]", "[RW_TERRAIN_NOISE_SCALE]", "[terrain_scale]", "[map_width]", "[elevation_coast_low]", "[elevation_coast_high]")
	elevation_maps[RW_ELEVATION_LOWLAND] = rustg_dbp_generate("[terrain_seed]", "[RW_TERRAIN_NOISE_SCALE]", "[terrain_scale]", "[map_width]", "[elevation_lowland_low]", "[elevation_lowland_high]")
	elevation_maps[RW_ELEVATION_HIGHLAND] = rustg_dbp_generate("[terrain_seed]", "[RW_TERRAIN_NOISE_SCALE]", "[terrain_scale]", "[map_width]", "[elevation_highland_low]", "[elevation_highland_high]")
	elevation_maps[RW_ELEVATION_MOUNTAIN] = rustg_dbp_generate("[terrain_seed]", "[RW_TERRAIN_NOISE_SCALE]", "[terrain_scale]", "[map_width]", "[elevation_mountain_low]", "[elevation_mountain_high]")
	elevation_maps[RW_ELEVATION_SNOW] = rustg_dbp_generate("[terrain_seed]", "[RW_TERRAIN_NOISE_SCALE]", "[terrain_scale]", "[map_width]", "[elevation_snow_low]", "[elevation_snow_high]")


/datum/rimworld_planet/proc/is_noise_value_true(map, x, y)

	if(!map)
		return FALSE

	var/coordinate = map_width * (y - 1) + x

	if(coordinate < 1 || coordinate > length(map))
		return FALSE

	return text2num(map[coordinate])


/datum/rimworld_planet/proc/get_heat_level(x, y)

	if(!is_valid_coordinate(x, y))
		return RW_CLIMATE_LOW

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

	return RW_ELEVATION_OCEAN


/datum/rimworld_planet/proc/get_temperature(x, y)

	if(!is_valid_coordinate(x, y))
		return 0

	var/latitude = abs(((y - 1) / max(1, map_height - 1)) * 2 - 1)
	var/latitude_modifier = 1 - latitude
	var/heat_level = get_heat_level(x, y)

	var/heat_modifier = 0.2

	if(heat_level == RW_CLIMATE_HIGH)
		heat_modifier = 1.0
	else if(heat_level == RW_CLIMATE_MEDIUM)
		heat_modifier = 0.6

	return clamp((latitude_modifier * 0.55) + (heat_modifier * 0.45), 0, 1)


/datum/rimworld_planet/proc/get_biome(x, y)

	if(!is_valid_coordinate(x, y))
		return RW_BIOME_OCEAN

	var/elevation = get_elevation_level(x, y)
	var/heat = get_heat_level(x, y)
	var/humidity = get_humidity_level(x, y)

	if(elevation == RW_ELEVATION_OCEAN)
		return RW_BIOME_OCEAN

	if(elevation == RW_ELEVATION_COAST)
		return RW_BIOME_BEACH

	if(elevation == RW_ELEVATION_SNOW)
		return RW_BIOME_SNOW

	if(elevation == RW_ELEVATION_MOUNTAIN)
		return RW_BIOME_MOUNTAINS

	if(heat == RW_CLIMATE_LOW)
		if(humidity == RW_CLIMATE_HIGH)
			return RW_BIOME_TAIGA

		return RW_BIOME_TUNDRA

	if(heat == RW_CLIMATE_MEDIUM)
		if(humidity == RW_CLIMATE_HIGH)
			return RW_BIOME_TEMPERATE_FOREST

		if(humidity == RW_CLIMATE_MEDIUM)
			return RW_BIOME_GRASSLAND

		return RW_BIOME_SAVANNA

	if(humidity == RW_CLIMATE_HIGH)
		return RW_BIOME_RAINFOREST

	if(humidity == RW_CLIMATE_MEDIUM)
		return RW_BIOME_TROPICAL_FOREST

	return RW_BIOME_DESERT


/datum/rimworld_planet/proc/get_tile_data(x, y)

	if(!is_valid_coordinate(x, y))
		return null

	var/list/tile = list(
		"x" = x,
		"y" = y,
		"objects" = get_objects_at(x, y),
		"image" = get_tile_image(x, y),
		"mapsLoaded" = maps_generated(),
	)

	if(maps_generated())
		var/elevation = get_elevation_level(x, y)
		var/heat = get_heat_level(x, y)
		var/humidity = get_humidity_level(x, y)

		tile["elevation"] = elevation
		tile["heat"] = heat
		tile["humidity"] = humidity
		tile["temperature"] = get_temperature(x, y)
		tile["biome"] = get_biome(x, y)

	return tile


/datum/rimworld_planet/proc/clear_noise_maps()
	elevation_maps = null
	heat_maps = null
	humidity_maps = null


/datum/rimworld_planet/proc/maps_generated()
	return !isnull(elevation_maps) && length(elevation_maps) && !isnull(heat_maps) && length(heat_maps) && !isnull(humidity_maps) && length(humidity_maps)


/datum/rimworld_planet/proc/ensure_maps()
	if(maps_generated())
		return TRUE

	generate_climate_maps()
	generate_elevation_maps()

	return maps_generated()


/datum/rimworld_planet/proc/generate()

	var/start_time = REALTIMEOFDAY

	derive_seeds()
	clear_noise_maps()
	generation_revision++

	log_world("[name] planetary parameters ready in [(REALTIMEOFDAY - start_time) / 10]s. Terrain is reconstructed on clients from seeds.")

	return TRUE


/datum/rimworld_planet/proc/generate_object_id(prefix = "object")

	var/id

	do
		id = "[prefix]_[rand(1, 2000000000)]"
	while(objects[id])

	return id


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


/datum/rimworld_planet/proc/remove_object(object_id)

	var/datum/rimworld_planet_object/object = objects[object_id]

	if(!object)
		return FALSE

	objects -= object_id
	settlements -= object_id
	points_of_interest -= object_id
	roads -= object_id

	return TRUE


/datum/rimworld_planet/proc/get_object(object_id)
	return objects[object_id]


/datum/rimworld_planet/proc/get_objects_at(x, y)

	var/list/result = list()

	for(var/object_id in objects)

		var/datum/rimworld_planet_object/object = objects[object_id]

		if(object.x == x && object.y == y)
			result += list(object.get_data())

	return result


/datum/rimworld_planet/proc/get_objects_in_radius(x, y, radius)

	var/list/result = list()

	for(var/object_id in objects)

		var/datum/rimworld_planet_object/object = objects[object_id]

		if(get_dist_2d(x, y, object.x, object.y) <= radius)
			result += list(object.get_data())

	return result


/datum/rimworld_planet/proc/move_object(object_id, new_x, new_y)

	var/datum/rimworld_planet_object/object = objects[object_id]

	if(!object)
		return FALSE

	if(!is_valid_coordinate(new_x, new_y))
		return FALSE

	object.x = new_x
	object.y = new_y

	return TRUE


/datum/rimworld_planet/proc/create_settlement(x, y, settlement_name = "Settlement")

	if(!is_valid_coordinate(x, y))
		return null

	var/id = generate_object_id("settlement")
	var/datum/rimworld_planet_object/settlement/object = new /datum/rimworld_planet_object/settlement(id, x, y, settlement_name)

	if(!add_object(object))
		qdel(object)
		return null

	return object


/datum/rimworld_planet/proc/create_point_of_interest(x, y, poi_name = "Point of Interest")

	if(!is_valid_coordinate(x, y))
		return null

	var/id = generate_object_id("poi")
	var/datum/rimworld_planet_object/point_of_interest/object = new /datum/rimworld_planet_object/point_of_interest(id, x, y, poi_name)

	if(!add_object(object))
		qdel(object)
		return null

	return object


/datum/rimworld_planet/proc/create_road(start_x, start_y, end_x, end_y)

	if(!is_valid_coordinate(start_x, start_y))
		return null

	if(!is_valid_coordinate(end_x, end_y))
		return null

	var/id = generate_object_id("road")
	var/datum/rimworld_planet_object/road/object = new /datum/rimworld_planet_object/road(id, start_x, start_y, end_x, end_y)

	if(!add_object(object))
		qdel(object)
		return null

	return object


/datum/rimworld_planet/proc/get_interactive_objects()

	var/list/result = list()

	for(var/object_id in objects)

		var/datum/rimworld_planet_object/object = objects[object_id]

		result += list(object.get_data())

	return result


/datum/rimworld_planet/proc/get_generator_data()

	return list(
		"name" = name,
		"seed" = seed,
		"planetType" = planet_type,

		"terrainSeed" = terrain_seed,
		"heatSeed" = heat_seed,
		"humiditySeed" = humidity_seed,

		"width" = map_width,
		"height" = map_height,

		"terrainScale" = terrain_scale,
		"heatScale" = heat_scale,
		"humidityScale" = humidity_scale,
		"noiseScale" = RW_TERRAIN_NOISE_SCALE,

		"elevationOceanLow" = elevation_ocean_low,
		"elevationOceanHigh" = elevation_ocean_high,

		"elevationCoastLow" = elevation_coast_low,
		"elevationCoastHigh" = elevation_coast_high,

		"elevationLowlandLow" = elevation_lowland_low,
		"elevationLowlandHigh" = elevation_lowland_high,

		"elevationHighlandLow" = elevation_highland_low,
		"elevationHighlandHigh" = elevation_highland_high,

		"elevationMountainLow" = elevation_mountain_low,
		"elevationMountainHigh" = elevation_mountain_high,

		"elevationSnowLow" = elevation_snow_low,
		"elevationSnowHigh" = elevation_snow_high,

		"heatThresholdLow" = heat_threshold_low,
		"heatThresholdHigh" = heat_threshold_high,

		"humidityThresholdLow" = humidity_threshold_low,
		"humidityThresholdHigh" = humidity_threshold_high,

		"generatorVersion" = RW_PLANET_GENERATOR_VERSION,
		"generationRevision" = generation_revision,
		"presets" = list(RW_PLANET_PRESET_TERRAN, RW_PLANET_PRESET_ICE, RW_PLANET_PRESET_DESERT, RW_PLANET_PRESET_OCEAN),
		"biomeImages" = get_biome_images_payload(),
	)


/datum/rimworld_planet/proc/get_runtime_data()

	return list(
		"objects" = get_interactive_objects(),
		"generationRevision" = generation_revision,
		"tileImages" = get_tile_images_payload(),
		"mapsLoaded" = maps_generated(),
	)


/datum/rimworld_planet/proc/get_map_data()

	. = get_generator_data()

	var/list/runtime = get_runtime_data()

	for(var/key in runtime)
		.[key] = runtime[key]


/datum/rimworld_planet/proc/tile_image_key(x, y)
	return "[x]:[y]"


/datum/rimworld_planet/proc/set_tile_image(x, y, image_ref)

	if(!is_valid_coordinate(x, y))
		return FALSE

	if(!image_ref)
		tile_images -= tile_image_key(x, y)
		return TRUE

	tile_images[tile_image_key(x, y)] = image_ref

	return TRUE


/datum/rimworld_planet/proc/get_tile_image(x, y)

	if(!length(tile_images))
		return null

	return tile_images[tile_image_key(x, y)]


/datum/rimworld_planet/proc/set_biome_image(biome, image_ref)

	if(!biome)
		return FALSE

	if(!image_ref)
		biome_images -= biome
		return TRUE

	biome_images[biome] = image_ref

	return TRUE


/datum/rimworld_planet/proc/get_tile_images_payload()

	var/list/result = list()

	for(var/key in tile_images)
		var/list/coords = splittext(key, ":")

		if(length(coords) < 2)
			continue

		result += list(list("x" = text2num(coords[1]), "y" = text2num(coords[2]), "src" = tile_images[key]))

	return result


/datum/rimworld_planet/proc/get_biome_images_payload()
	return biome_images?.Copy() || list()


/datum/rimworld_planet/Destroy()

	clear_noise_maps()

	objects = null
	settlements = null
	points_of_interest = null
	roads = null
	discovered_regions = null
	tile_images = null
	biome_images = null

	return ..()
