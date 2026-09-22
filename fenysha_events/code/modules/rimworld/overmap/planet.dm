/datum/rimworld_planet_object
	var/id
	var/object_type = RW_OBJECT_TYPE_OBJECT
	var/name = "Unknown"
	var/x = 1
	var/y = 1
	var/icon = RW_PLANET_CELL_TOWN_ICON
	var/list/data = list()

/datum/rimworld_planet_object/New(new_id, new_x, new_y, new_name = null)
	id = new_id
	x = new_x
	y = new_y
	if(new_name)
		name = new_name
	. = ..()

/**
 * Returns a serializable copy of this object's data.
 */
/datum/rimworld_planet_object/proc/get_data()
	return list(
		"id" = id,
		"type" = object_type,
		"name" = name,
		"x" = x,
		"y" = y,
		"icon" = icon,
		"data" = data.Copy()
	)

/datum/rimworld_planet_object/settlement
	object_type = RW_OBJECT_TYPE_SETTLEMENT
	icon = RW_PLANET_CELL_TOWN

/datum/rimworld_planet_object/settlement/New(new_id, new_x, new_y, new_name = RW_OBJECT_NAME_SETTLEMENT)
	. = ..(new_id, new_x, new_y, new_name)
	data = list(
		"population" = 0,
		"faction" = null,
		"settlement_type" = "village"
	)

/**
 * Sets the settlement population (clamped to >= 0).
 */
/datum/rimworld_planet_object/settlement/proc/set_population(value)
	data["population"] = max(0, value)

/**
 * Sets the settlement faction.
 */
/datum/rimworld_planet_object/settlement/proc/set_faction(faction)
	data["faction"] = faction

/datum/rimworld_planet_object/point_of_interest
	object_type = RW_OBJECT_TYPE_POINT_OF_INTEREST

/datum/rimworld_planet_object/point_of_interest/New(new_id, new_x, new_y, new_name = RW_OBJECT_NAME_POINT_OF_INTEREST)
	. = ..(new_id, new_x, new_y, new_name)
	data = list(
		"poi_type" = RW_POI_TYPE_UNKNOWN,
		"discovered" = FALSE
	)

/datum/rimworld_planet_object/road
	object_type = RW_OBJECT_TYPE_ROAD
	var/start_x
	var/start_y
	var/end_x
	var/end_y

/datum/rimworld_planet_object/road/New(new_id, new_start_x, new_start_y, new_end_x, new_end_y)
	. = ..(new_id, new_start_x, new_start_y, RW_OBJECT_NAME_ROAD)
	start_x = new_start_x
	start_y = new_start_y
	end_x = new_end_x
	end_y = new_end_y
	data = list(
		"start_x" = start_x,
		"start_y" = start_y,
		"end_x" = end_x,
		"end_y" = end_y
	)

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
	/// Layer grid size, set from grid_frequency: see planet_hexgrid.dm
	var/map_width
	var/map_height
	var/rotation_angle = 0.0
	var/rotation_speed = 0.001
	var/auto_rotate = TRUE

	var/time_of_day = 0
	var/total_days = 0
	var/current_year = RW_STARTING_YEAR
	var/day_of_year = RW_STARTING_DAY_OF_YEAR
	var/current_quadrum = RW_QUADRUM_APRIMAY
	var/day_of_quadrum = 1
	var/daylight_fraction = RW_DEFAULT_DAYLIGHT_FRACTION

	var/list/possible_biomes

	/**
	 * The entire generator surface, from the player/admin's point of view:
	 * five simple sliders, each -5..5. Rust derives every noise scale,
	 * elevation band and climate threshold from these; DM never touches
	 * those internals directly anymore.
	 */
	var/slider_mountains = RW_SLIDER_DEFAULT
	var/slider_ocean = RW_SLIDER_DEFAULT
	var/slider_humidity = RW_SLIDER_DEFAULT
	var/slider_temperature = RW_SLIDER_DEFAULT
	/// Used for settlement generation, not by the terrain generator itself.
	var/slider_population = RW_SLIDER_DEFAULT

	// Derived seeds (currently unused by Rust; kept for future / compatibility)
	var/terrain_seed
	var/heat_seed
	var/humidity_seed
	var/geology_seed
	var/precipitation_seed

	/// Generated layer names -> TRUE
	var/list/generated_layers = list()
	/// Generated layer names -> exported file path
	var/list/layer_files = list()
	/// Simple cache: "layer:x:y" -> value
	var/list/cell_cache = list()

	var/list/objects = list()
	var/list/settlements = list()
	var/list/points_of_interest = list()
	var/list/roads = list()
	var/list/discovered_regions = list()

	/// Incremented whenever generator parameters change
	var/generation_revision = 0
	/// Sparse overlay art: "[x]:[y]" -> asset key/url
	var/list/tile_images = list()
	/// Optional biome -> asset key/url
	var/list/biome_images = list()

/datum/rimworld_planet/New(new_seed = null, new_planet_type = RW_PLANET_PRESET_TERRAN, list/custom_params)
	. = ..()
	map_width = 10 * grid_frequency
	map_height = grid_frequency + 1
	if(isnull(new_seed))
		seed = rand(1, 100000)
	else
		seed = new_seed
	apply_preset(new_planet_type)
	derive_seeds()
	apply_custom_params(custom_params)

/**
 * Applies optional custom generation parameters.
 */
/datum/rimworld_planet/proc/apply_custom_params(list/params)
	if(!params || !islist(params))
		return

	if(!isnull(params["terrainSeed"]))
		terrain_seed = params["terrainSeed"]
	if(!isnull(params["heatSeed"]))
		heat_seed = params["heatSeed"]
	if(!isnull(params["humiditySeed"]))
		humidity_seed = params["humiditySeed"]
	if(!isnull(params["geologySeed"]))
		geology_seed = params["geologySeed"]
	if(!isnull(params["precipitationSeed"]))
		precipitation_seed = params["precipitationSeed"]

	if(!isnull(params["mountains"]))
		slider_mountains = clamp_generator_slider(params["mountains"])
	if(!isnull(params["ocean"]))
		slider_ocean = clamp_generator_slider(params["ocean"])
	if(!isnull(params["humidity"]))
		slider_humidity = clamp_generator_slider(params["humidity"])
	if(!isnull(params["temperature"]))
		slider_temperature = clamp_generator_slider(params["temperature"])
	if(!isnull(params["population"]))
		slider_population = clamp_generator_slider(params["population"])

/**
 * Clamps a generator slider to the supported -5..5 range.
 */
/datum/rimworld_planet/proc/clamp_generator_slider(value)
	return clamp(value, RW_SLIDER_MIN, RW_SLIDER_MAX)

/**
 * Applies a named planet preset (Terran, Ice, Desert, Ocean).
 */
/datum/rimworld_planet/proc/apply_preset(new_planet_type)
	switch(new_planet_type)
		if(RW_PLANET_PRESET_TERRAN)
			planet_type = RW_PLANET_PRESET_TERRAN
			name = "Terran Planet"
			slider_mountains = RW_TERRAN_SLIDER_MOUNTAINS
			slider_ocean = RW_TERRAN_SLIDER_OCEAN
			slider_humidity = RW_TERRAN_SLIDER_HUMIDITY
			slider_temperature = RW_TERRAN_SLIDER_TEMPERATURE
			slider_population = RW_TERRAN_SLIDER_POPULATION
		if(RW_PLANET_PRESET_ICE)
			planet_type = RW_PLANET_PRESET_ICE
			name = "Ice Planet"
			slider_mountains = RW_ICE_SLIDER_MOUNTAINS
			slider_ocean = RW_ICE_SLIDER_OCEAN
			slider_humidity = RW_ICE_SLIDER_HUMIDITY
			slider_temperature = RW_ICE_SLIDER_TEMPERATURE
			slider_population = RW_ICE_SLIDER_POPULATION
		if(RW_PLANET_PRESET_DESERT)
			planet_type = RW_PLANET_PRESET_DESERT
			name = "Desert Planet"
			slider_mountains = RW_DESERT_SLIDER_MOUNTAINS
			slider_ocean = RW_DESERT_SLIDER_OCEAN
			slider_humidity = RW_DESERT_SLIDER_HUMIDITY
			slider_temperature = RW_DESERT_SLIDER_TEMPERATURE
			slider_population = RW_DESERT_SLIDER_POPULATION
		if(RW_PLANET_PRESET_OCEAN)
			planet_type = RW_PLANET_PRESET_OCEAN
			name = "Ocean Planet"
			slider_mountains = RW_OCEAN_SLIDER_MOUNTAINS
			slider_ocean = RW_OCEAN_SLIDER_OCEAN
			slider_humidity = RW_OCEAN_SLIDER_HUMIDITY
			slider_temperature = RW_OCEAN_SLIDER_TEMPERATURE
			slider_population = RW_OCEAN_SLIDER_POPULATION
		else
			apply_preset(RW_PLANET_PRESET_TERRAN)

// 6-digit seed space (000000 .. 999999)
#define RW_SEED_MODULUS 1000000
#define RW_SEED_MULTIPLIER 1103515
#define RW_SEED_INCREMENT 12345

/**
 * Derives secondary seeds from the main 6-digit seed.
 * Uses a small LCG so intermediate values stay within BYOND numeric precision.
 * Note: the Rust generator currently uses only the main seed + fixed offsets;
 * these derived seeds are kept for UI / future use.
 */
/datum/rimworld_planet/proc/derive_seeds()
	var/s = seed % RW_SEED_MODULUS

	terrain_seed = ((s * RW_SEED_MULTIPLIER) + RW_SEED_INCREMENT) % RW_SEED_MODULUS
	heat_seed = ((terrain_seed * RW_SEED_MULTIPLIER) + RW_SEED_INCREMENT) % RW_SEED_MODULUS
	humidity_seed = ((heat_seed * RW_SEED_MULTIPLIER) + RW_SEED_INCREMENT) % RW_SEED_MODULUS
	geology_seed = ((humidity_seed * RW_SEED_MULTIPLIER) + RW_SEED_INCREMENT) % RW_SEED_MODULUS
	precipitation_seed = ((geology_seed * RW_SEED_MULTIPLIER) + RW_SEED_INCREMENT) % RW_SEED_MODULUS

#undef RW_SEED_MODULUS
#undef RW_SEED_MULTIPLIER
#undef RW_SEED_INCREMENT

/datum/rimworld_planet/proc/get_terrain_seed()
	return terrain_seed

/datum/rimworld_planet/proc/get_heat_seed()
	return heat_seed

/datum/rimworld_planet/proc/get_humidity_seed()
	return humidity_seed

/datum/rimworld_planet/proc/get_geology_seed()
	return geology_seed

/datum/rimworld_planet/proc/get_precipitation_seed()
	return precipitation_seed

/**
 * Returns whether the given coordinates are a tile on this planet's hex grid.
 */
/datum/rimworld_planet/proc/is_valid_coordinate(x, y)
	if(y == grid_frequency + 1)
		return x == 1 || x == 2
	return x >= 1 && x <= map_width && y >= 1 && y <= grid_frequency

/**
 * Converts 2D coordinates into a linear index (1-based).
 */
/datum/rimworld_planet/proc/get_coordinate_index(x, y)
	if(!is_valid_coordinate(x, y))
		return null
	return map_width * (y - 1) + x

/**
 * Clears generated layer metadata and the cell cache.
 */
/datum/rimworld_planet/proc/clear_noise_maps()
	generated_layers = list()
	layer_files = list()
	cell_cache = list()

/**
 * Returns whether the elevation layer has been generated.
 */
/datum/rimworld_planet/proc/maps_generated()
	return generated_layers["elevation"] == TRUE

/**
 * Ensures all planet layers exist; generates them if needed.
 */
/datum/rimworld_planet/proc/ensure_maps()
	if(maps_generated())
		return TRUE
	return generate()

/**
 * Generates all planet layers via Rust and records their file paths.
 */
/datum/rimworld_planet/proc/generate()
	var/start_time = REALTIMEOFDAY
	derive_seeds()
	clear_noise_maps()

	// Rust derives every noise scale, elevation band and climate threshold
	// from these 5 sliders — see derive_generation_params() in tp_planet.rs.
	var/list/config = list(
		"seed" = seed,
		"frequency" = grid_frequency,
		"output_dir" = "data/rimworld_planets/[seed]",
		"mountains" = slider_mountains,
		"ocean" = slider_ocean,
		"humidity" = slider_humidity,
		"temperature" = slider_temperature,
		"population" = slider_population
	)

	var/json_config = json_encode(config)
	var/result = rustg_tp_planet_generate(json_config)

	if(!result)
		log_world("[name] planetary generation failed: Rust returned no result.")
		return FALSE

	if(findtext(result, "ERROR:") == 1)
		log_world("[name] planetary generation failed: [result]")
		return FALSE
	var/list/export_data
	try
		export_data = json_decode(result)
	catch
		log_world("[name] planetary generation returned invalid JSON: [result]")
		return FALSE

	if(!export_data || export_data["status"] != "ok")
		log_world("[name] planetary generation returned an invalid result: [result]")
		return FALSE

	var/list/exported_layers = export_data["layers"]
	if(!islist(exported_layers))
		log_world("[name] planetary generator did not return layer information.")
		return FALSE

	generated_layers = list()
	layer_files = list()

	for(var/list/layer in exported_layers)
		var/layer_name = layer["name"]
		var/layer_path = layer["path"]
		if(!layer_name || !layer_path)
			continue
		generated_layers[layer_name] = TRUE
		layer_files[layer_name] = layer_path

	if(!maps_generated())
		log_world("[name] planetary generator did not create the elevation layer.")
		return FALSE

	generation_revision++
	GLOB.rimworld_planet_noise_revision = generation_revision
	var/datum/asset/simple/rimworld_planet_layers/asset = get_asset_datum(/datum/asset/simple/rimworld_planet_layers)
	asset.register_for_planet(src)
	log_world("[name] planetary parameters ready in [(REALTIMEOFDAY - start_time) / 10]s. Generated [length(generated_layers)] planet layers.")
	return TRUE

/**
 * Returns the file path of a generated layer, or null.
 */
/datum/rimworld_planet/proc/get_layer_file(layer_name)
	if(!generated_layers[layer_name])
		return null
	return layer_files[layer_name]

/**
 * Returns whether the named layer has been generated.
 */
/datum/rimworld_planet/proc/has_layer(layer_name)
	return generated_layers[layer_name] == TRUE

/**
 * Reads a single packed value from a layer file (with simple caching).
 */
/datum/rimworld_planet/proc/get_layer_value(layer_name, x, y)
	if(!is_valid_coordinate(x, y))
		return null
	if(!generated_layers[layer_name])
		return null

	var/cache_key = "[layer_name]:[x]:[y]"
	if(!isnull(cell_cache[cache_key]))
		return cell_cache[cache_key]

	var/path = layer_files[layer_name]
	if(!path)
		return null

	var/value = rustg_tp_planet_get_cell(path, x, y)
	if(isnull(value))
		return null

	cell_cache[cache_key] = value
	return value

/**
 * Bitmask of the neighbours a river connects this tile to (0 for no river); bits follow
 * get_neighbors_with_bits().
 */
/datum/rimworld_planet/proc/get_river_mask(x, y)
	if(!is_valid_coordinate(x, y))
		return 0
	return get_layer_value("rivers", x, y) || 0

/datum/rimworld_planet/proc/has_river(x, y)
	return get_river_mask(x, y) != 0

/// The tiles this tile's river flows to or from, as list(list(x, y), ...).
/datum/rimworld_planet/proc/get_river_connections(x, y)
	var/mask = get_river_mask(x, y)
	var/list/result = list()
	if(!mask)
		return result
	for(var/list/tile as anything in get_neighbors_with_bits(x, y))
		if(mask & (1 << tile[3]))
			result += list(list(tile[1], tile[2]))
	return result

/**
 * Returns the elevation level at the given coordinates.
 */
/datum/rimworld_planet/proc/get_elevation_level(x, y)
	if(!is_valid_coordinate(x, y))
		return RW_ELEVATION_OCEAN

	var/value = get_layer_value("elevation", x, y)
	if(isnull(value))
		return RW_ELEVATION_OCEAN

	switch(value)
		if(0)
			return RW_ELEVATION_OCEAN
		if(1)
			return RW_ELEVATION_COAST
		if(2)
			return RW_ELEVATION_LOWLAND
		if(3)
			return RW_ELEVATION_HIGHLAND
		if(4)
			return RW_ELEVATION_MOUNTAIN
		if(5)
			return RW_ELEVATION_SNOW
	return RW_ELEVATION_OCEAN

/**
 * Returns the heat (climate) level at the given coordinates.
 */
/datum/rimworld_planet/proc/get_heat_level(x, y)
	if(!is_valid_coordinate(x, y))
		return RW_CLIMATE_LOW

	var/value = get_layer_value("heat", x, y)
	if(isnull(value))
		return RW_CLIMATE_LOW

	switch(value)
		if(0)
			return RW_CLIMATE_LOW
		if(1)
			return RW_CLIMATE_MEDIUM
		if(2)
			return RW_CLIMATE_HIGH
	return RW_CLIMATE_LOW

/**
 * Returns the humidity (climate) level at the given coordinates.
 */
/datum/rimworld_planet/proc/get_humidity_level(x, y)
	if(!is_valid_coordinate(x, y))
		return RW_CLIMATE_LOW

	var/value = get_layer_value("humidity", x, y)
	if(isnull(value))
		return RW_CLIMATE_LOW

	switch(value)
		if(0)
			return RW_CLIMATE_LOW
		if(1)
			return RW_CLIMATE_MEDIUM
		if(2)
			return RW_CLIMATE_HIGH
	return RW_CLIMATE_LOW

/**
 * Returns a small latitude-based climate offset.
 */
/datum/rimworld_planet/proc/get_latitude_offset(x, y, heat = null, humidity = null, elevation = null)
	var/h = isnull(heat) ? get_heat_level(x, y) : heat
	var/hm = isnull(humidity) ? get_humidity_level(x, y) : humidity
	var/e = isnull(elevation) ? get_elevation_level(x, y) : elevation

	var/list/lat_lon = get_tile_lat_lon(x, y)
	var/base_lat = (lat_lon[1] + 90) / 180
	var/polar_fade = sin(base_lat * 180)
	var/climate_offset = 0.0

	if(h == RW_CLIMATE_HIGH)
		climate_offset += 0.08
	else if(h == RW_CLIMATE_LOW)
		climate_offset -= 0.08

	if(hm == RW_CLIMATE_HIGH)
		climate_offset -= 0.04
	else if(hm == RW_CLIMATE_LOW)
		climate_offset += 0.04

	if(e == RW_ELEVATION_MOUNTAIN || e == RW_ELEVATION_HIGHLAND)
		climate_offset -= 0.07
	else if(e == RW_ELEVATION_SNOW)
		climate_offset -= 0.12

	var/s = seed % 10000
	// Longitude/latitude on a 2048 x 1024 scale, so the wave stays continuous across diamonds
	var/wave_x = (lat_lon[2] + 180) * (2048 / 360)
	var/wave_y = (lat_lon[1] + 90) * (1024 / 180)
	// %% keeps the fraction; % truncates to integers and drifts from tgui's generator
	var/angle1 = ((wave_x * 0.35 + wave_y * 0.15 + s) %% 360)
	var/angle2 = ((wave_x * 0.85 - wave_y * 0.45 + s * 1.3) %% 360)
	var/angle3 = ((wave_x * 1.7 + wave_y * 1.1 + s * 2.1) %% 360)
	var/wave = ((sin(angle1) * 0.06) + (cos(angle2) * 0.04) + (sin(angle3) * 0.02)) * polar_fade

	return climate_offset + wave

/**
 * Returns latitude in degrees (-90 .. 90).
 */
/datum/rimworld_planet/proc/get_latitude(x, y)
	if(!is_valid_coordinate(x, y))
		return 0
	return get_tile_lat_lon(x, y)[1]

/**
 * Returns the surface material at the given coordinates.
 */
/datum/rimworld_planet/proc/get_material(x, y, elevation = null)
	if(!is_valid_coordinate(x, y))
		return RW_MATERIAL_NONE

	var/e = isnull(elevation) ? get_elevation_level(x, y) : elevation
	if(e == RW_ELEVATION_OCEAN)
		return RW_MATERIAL_NONE

	var/geo = get_geology_value(x, y)
	switch(geo)
		if(0, 1)
			return RW_MATERIAL_GRANITE
		if(2)
			return RW_MATERIAL_LIMESTONE
		if(3)
			return RW_MATERIAL_SANDSTONE
		if(4)
			return RW_MATERIAL_SLATE
		if(5)
			return RW_MATERIAL_MARBLE
		if(6)
			return RW_MATERIAL_OBSIDIAN
	return RW_MATERIAL_GRANITE

/**
 * Returns the raw geology value (0-6) at the given coordinates.
 */
/datum/rimworld_planet/proc/get_geology_value(x, y)
	if(!is_valid_coordinate(x, y))
		return 0
	var/value = get_layer_value("geology", x, y)
	if(isnull(value))
		return 0
	return value

/**
 * Returns a temperature modifier based on material.
 */
/datum/rimworld_planet/proc/get_material_temperature_modifier(material)
	switch(material)
		if(RW_MATERIAL_GRANITE)
			return -0.005
		if(RW_MATERIAL_LIMESTONE)
			return 0
		if(RW_MATERIAL_SANDSTONE)
			return 0.012
		if(RW_MATERIAL_SLATE)
			return -0.008
		if(RW_MATERIAL_MARBLE)
			return 0.008
		if(RW_MATERIAL_OBSIDIAN)
			return 0.018
		if(RW_MATERIAL_JADE)
			return 0.004
	return 0

/**
 * Returns normalized temperature (0-1) at the given coordinates.
 */
/datum/rimworld_planet/proc/get_temperature(x, y, heat_level = null, elevation = null, material = null)
	if(!is_valid_coordinate(x, y))
		return 0

	var/heat = heat_level
	if(isnull(heat))
		heat = get_heat_level(x, y)

	var/e = elevation
	if(isnull(e))
		e = get_elevation_level(x, y)

	var/m = material
	if(isnull(m))
		m = get_material(x, y, e)

	var/latitude_offset = get_latitude_offset(x, y, heat)
	var/base_lat = (get_latitude(x, y) + 90) / 180
	var/normalized_latitude = clamp(base_lat + latitude_offset, 0, 1)
	var/latitude_distance = abs(normalized_latitude - 0.5) * 2.0
	var/latitude_temperature = (max(0, 1.0 - latitude_distance) ** 1.8)

	var/heat_modifier = -0.15
	if(heat == RW_CLIMATE_MEDIUM)
		heat_modifier = 0.05
	else if(heat == RW_CLIMATE_HIGH)
		heat_modifier = 0.22

	var/elevation_modifier = 0.0
	switch(e)
		if(RW_ELEVATION_HIGHLAND)
			elevation_modifier = -0.10
		if(RW_ELEVATION_MOUNTAIN)
			elevation_modifier = -0.22
		if(RW_ELEVATION_SNOW)
			elevation_modifier = -0.35

	var/material_modifier = get_material_temperature_modifier(m)
	var/temperature = (latitude_temperature * 0.60) + ((heat_modifier + 0.15) * 0.25) + ((elevation_modifier + 0.35) * 0.15) + material_modifier
	return clamp(temperature, 0, 1)

/**
 * Returns the precipitation noise category (low/medium/high).
 */
/datum/rimworld_planet/proc/get_precipitation_noise_category(x, y)
	if(!is_valid_coordinate(x, y))
		return RW_PRECIPITATION_CATEGORY_LOW

	var/value = get_layer_value("precipitation", x, y)
	if(isnull(value))
		return RW_PRECIPITATION_CATEGORY_LOW

	switch(value)
		if(0)
			return RW_PRECIPITATION_CATEGORY_LOW
		if(1)
			return RW_PRECIPITATION_CATEGORY_MEDIUM
		if(2)
			return RW_PRECIPITATION_CATEGORY_HIGH
	return RW_PRECIPITATION_CATEGORY_LOW

/**
 * Returns the base precipitation value for a category.
 */
/datum/rimworld_planet/proc/get_precipitation_base(category)
	switch(category)
		if(RW_PRECIPITATION_CATEGORY_HIGH)
			return 0.78
		if(RW_PRECIPITATION_CATEGORY_MEDIUM)
			return 0.50
	return 0.20

/**
 * Returns normalized precipitation (0-1) at the given coordinates.
 */
/datum/rimworld_planet/proc/get_precipitation(x, y, temperature = null, humidity = null, elevation = null)
	if(!is_valid_coordinate(x, y))
		return 0

	var/t = isnull(temperature) ? get_temperature(x, y) : temperature
	var/hm = isnull(humidity) ? get_humidity_level(x, y) : humidity
	var/e = isnull(elevation) ? get_elevation_level(x, y) : elevation

	var/category = get_precipitation_noise_category(x, y)
	var/precipitation = get_precipitation_base(category)

	if(hm == RW_CLIMATE_HIGH)
		precipitation += 0.06
	else if(hm == RW_CLIMATE_LOW)
		precipitation -= 0.05

	var/latitude = abs(get_latitude(x, y)) / 90
	precipitation += ((1 - latitude) * 0.08) - (latitude * 0.05)
	precipitation += (t - 0.5) * 0.10

	if(e == RW_ELEVATION_HIGHLAND)
		precipitation += 0.025
	else if(e == RW_ELEVATION_MOUNTAIN)
		precipitation += 0.055

	return clamp(precipitation, 0, 1)

/**
 * Returns rainfall amount (precipitation that falls as rain).
 */
/datum/rimworld_planet/proc/get_rainfall(x, y, temperature = null, precipitation = null)
	var/t = isnull(temperature) ? get_temperature(x, y) : temperature
	var/p = isnull(precipitation) ? get_precipitation(x, y) : precipitation
	var/rain_factor = clamp((t - 0.20) / 0.18, 0, 1)
	return p * rain_factor

/**
 * Returns snowfall amount (precipitation that falls as snow).
 */
/datum/rimworld_planet/proc/get_snowfall(x, y, temperature = null, precipitation = null)
	var/t = isnull(temperature) ? get_temperature(x, y) : temperature
	var/p = isnull(precipitation) ? get_precipitation(x, y, t) : precipitation
	return max(0, p - get_rainfall(x, y, t, p))

/**
 * Returns water availability (0-1) at the given coordinates.
 */
/datum/rimworld_planet/proc/get_water_availability(x, y, precipitation = null, elevation = null)
	var/p = isnull(precipitation) ? get_precipitation(x, y) : precipitation
	var/e = isnull(elevation) ? get_elevation_level(x, y) : elevation

	var/value = p * 0.78
	if(e == RW_ELEVATION_LOWLAND)
		value += 0.08
	else if(e == RW_ELEVATION_HIGHLAND)
		value += 0.03
	else if(e == RW_ELEVATION_MOUNTAIN)
		value -= 0.04

	return clamp(value, 0, 1)

/**
 * Returns the sub-biome at the given coordinates.
 */
/datum/rimworld_planet/proc/get_sub_biome(x, y, biome = null, elevation = null, precipitation = null, temperature = null)
	if(!is_valid_coordinate(x, y))
		return RW_SUBBIOME_PLAINS

	var/e = isnull(elevation) ? get_elevation_level(x, y) : elevation
	var/b = isnull(biome) ? get_biome(x, y) : biome
	var/p = isnull(precipitation) ? get_precipitation(x, y, temperature, null, e) : precipitation
	var/t = isnull(temperature) ? get_temperature(x, y, null, e) : temperature

	if(e == RW_ELEVATION_OCEAN)
		if(b == RW_BIOME_SEA_ICE)
			return RW_SUBBIOME_FROZEN_OCEAN
		return RW_SUBBIOME_DEEP_OCEAN
	if(b == RW_BIOME_SEA_ICE || b == RW_BIOME_SNOW)
		return RW_SUBBIOME_SNOWFIELDS
	if(e == RW_ELEVATION_COAST || b == RW_BIOME_BEACH || b == RW_BIOME_COAST)
		return RW_SUBBIOME_SHORE
	if(e == RW_ELEVATION_MOUNTAIN || b == RW_BIOME_MOUNTAINS)
		return RW_SUBBIOME_ROCKY_HILLS
	if(e == RW_ELEVATION_HIGHLAND)
		if(b == RW_BIOME_TEMPERATE_FOREST || b == RW_BIOME_TROPICAL_FOREST || b == RW_BIOME_RAINFOREST || b == RW_BIOME_TAIGA)
			return RW_SUBBIOME_FOREST_HILLS
		return RW_SUBBIOME_HILLS
	if(e == RW_ELEVATION_LOWLAND && p >= 0.72 && t > 0.24)
		return RW_SUBBIOME_MARSH
	if(b == RW_BIOME_TEMPERATE_FOREST || b == RW_BIOME_TROPICAL_FOREST || b == RW_BIOME_RAINFOREST || b == RW_BIOME_TAIGA)
		return RW_SUBBIOME_FOREST
	if(b == RW_BIOME_TUNDRA)
		return RW_SUBBIOME_TUNDRA_PLAINS
	return RW_SUBBIOME_PLAINS

/**
 * Returns the biome at the given coordinates.
 */
/datum/rimworld_planet/proc/get_biome(x, y, elevation = null, heat = null, humidity = null)
	if(!is_valid_coordinate(x, y))
		return RW_BIOME_OCEAN

	var/e = isnull(elevation) ? get_elevation_level(x, y) : elevation
	var/h = isnull(heat) ? get_heat_level(x, y) : heat
	var/hm = isnull(humidity) ? get_humidity_level(x, y) : humidity
	var/material = get_material(x, y, e)
	var/temperature = get_temperature(x, y, h, e, material)
	var/latitude_offset = get_latitude_offset(x, y, h, hm, e)
	var/base_lat = (get_latitude(x, y) + 90) / 180
	var/normalized_latitude = clamp(base_lat + latitude_offset, 0, 1)
	var/polar_distance = abs((normalized_latitude - 0.5) * 2.0)

	if(polar_distance >= 0.82)
		if(e == RW_ELEVATION_OCEAN || e == RW_ELEVATION_COAST)
			return RW_BIOME_SEA_ICE
		return RW_BIOME_SNOW

	if(polar_distance >= 0.70)
		var/polar_temperature = temperature
		var/polar_strength = (polar_distance - 0.70) / 0.12
		polar_strength = clamp(polar_strength, 0, 1)
		polar_temperature = polar_temperature * (1.0 - polar_strength)
		if(e == RW_ELEVATION_OCEAN || e == RW_ELEVATION_COAST)
			if(polar_temperature <= 0.24)
				return RW_BIOME_SEA_ICE
		else
			if(polar_temperature <= 0.22 || e == RW_ELEVATION_SNOW)
				return RW_BIOME_SNOW

	if(e == RW_ELEVATION_OCEAN)
		if(temperature <= 0.14)
			return RW_BIOME_SEA_ICE
		return RW_BIOME_OCEAN

	if(e == RW_ELEVATION_COAST)
		if(temperature <= 0.10)
			return RW_BIOME_SEA_ICE
		if(temperature >= 0.45 && hm == RW_CLIMATE_LOW)
			return RW_BIOME_BEACH
		return RW_BIOME_COAST

	if(temperature <= 0.10 || e == RW_ELEVATION_SNOW)
		return RW_BIOME_SNOW
	if(temperature <= 0.20 && e == RW_ELEVATION_MOUNTAIN)
		return RW_BIOME_SNOW
	if(e == RW_ELEVATION_MOUNTAIN)
		return RW_BIOME_MOUNTAINS
	if(temperature < 0.30)
		if(hm == RW_CLIMATE_HIGH)
			return RW_BIOME_TAIGA
		return RW_BIOME_TUNDRA
	if(temperature < 0.55)
		if(hm == RW_CLIMATE_HIGH)
			return RW_BIOME_TEMPERATE_FOREST
		if(hm == RW_CLIMATE_MEDIUM)
			return RW_BIOME_GRASSLAND
		return RW_BIOME_SAVANNA
	if(hm == RW_CLIMATE_HIGH)
		return RW_BIOME_RAINFOREST
	if(hm == RW_CLIMATE_MEDIUM)
		return RW_BIOME_TROPICAL_FOREST
	return RW_BIOME_DESERT

/**
 * Returns a full data packet for a single tile.
 */
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
		var/material = get_material(x, y, elevation)
		var/temperature = get_temperature(x, y, heat, elevation, material)
		var/precipitation = get_precipitation(x, y, temperature, humidity, elevation)
		var/biome = get_biome(x, y, elevation, heat, humidity)
		var/sub_biome = get_sub_biome(x, y, biome, elevation, precipitation, temperature)

		tile["elevation"] = elevation
		tile["heat"] = heat
		tile["humidity"] = humidity
		tile["material"] = material
		tile["latitude"] = get_latitude(x, y)
		tile["temperature"] = temperature
		tile["isDaylight"] = is_daylight(x, y)
		tile["sunIntensity"] = get_sun_intensity(x, y)
		tile["season"] = get_season(x, y)
		tile["solarAngle"] = get_solar_angle(x, y)
		tile["precipitation"] = precipitation
		tile["rainfall"] = get_rainfall(x, y, temperature, precipitation)
		tile["snowfall"] = get_snowfall(x, y, temperature, precipitation)
		tile["waterAvailability"] = get_water_availability(x, y, precipitation, elevation)
		tile["biome"] = biome
		tile["subBiome"] = sub_biome
		tile["river"] = has_river(x, y)

	return tile

/**
 * Returns static generator / planet configuration data.
 */
/datum/rimworld_planet/proc/get_generator_data()
	return list(
		"name" = name,
		"seed" = seed,
		"planetType" = planet_type,
		"autoRotate" = auto_rotate,
		"terrainSeed" = terrain_seed,
		"heatSeed" = heat_seed,
		"humiditySeed" = humidity_seed,
		"geologySeed" = geology_seed,
		"precipitationSeed" = precipitation_seed,
		"width" = map_width,
		"height" = map_height,
		"gridFrequency" = grid_frequency,
		"mountains" = slider_mountains,
		"ocean" = slider_ocean,
		"humidity" = slider_humidity,
		"temperature" = slider_temperature,
		"population" = slider_population,
		"sliderMin" = RW_SLIDER_MIN,
		"sliderMax" = RW_SLIDER_MAX,
		"generatedLayers" = generated_layers.Copy(),
		"layerFiles" = layer_files.Copy(),
		"generatorVersion" = RW_PLANET_GENERATOR_VERSION,
		"generationRevision" = generation_revision,
		"presets" = list(
			RW_PLANET_PRESET_TERRAN,
			RW_PLANET_PRESET_ICE,
			RW_PLANET_PRESET_DESERT,
			RW_PLANET_PRESET_OCEAN
		),
		"biomeImages" = get_biome_images_payload()
	)

/**
 * Returns runtime data (objects, revision, tile images, etc.).
 */
/datum/rimworld_planet/proc/get_runtime_data()
	return list(
		"objects" = get_interactive_objects(),
		"generationRevision" = generation_revision,
		"tileImages" = get_tile_images_payload(),
		"mapsLoaded" = maps_generated(),
		"calendar" = get_calendar_data(),
		"timeOfDay" = time_of_day,
		"rotationAngle" = rotation_angle,
		"generatedLayers" = generated_layers.Copy()
	)

/**
 * Returns the full map payload (generator + runtime).
 */
/datum/rimworld_planet/proc/get_map_data()
	. = get_generator_data()
	var/list/runtime = get_runtime_data()
	for(var/key in runtime)
		.[key] = runtime[key]

/**
 * Builds a cache key for a tile image.
 */
/datum/rimworld_planet/proc/tile_image_key(x, y)
	return "[x]:[y]"

/**
 * Sets or clears a sparse tile image overlay.
 */
/datum/rimworld_planet/proc/set_tile_image(x, y, image_ref)
	if(!is_valid_coordinate(x, y))
		return FALSE
	if(!image_ref)
		tile_images -= tile_image_key(x, y)
		return TRUE
	tile_images[tile_image_key(x, y)] = image_ref
	return TRUE

/**
 * Returns the tile image (if any) at the given coordinates.
 */
/datum/rimworld_planet/proc/get_tile_image(x, y)
	if(!length(tile_images))
		return null
	return tile_images[tile_image_key(x, y)]

/**
 * Sets or clears a biome image.
 */
/datum/rimworld_planet/proc/set_biome_image(biome, image_ref)
	if(!biome)
		return FALSE
	if(!image_ref)
		biome_images -= biome
		return TRUE
	biome_images[biome] = image_ref
	return TRUE

/**
 * Returns the sparse tile images payload for the client.
 */
/datum/rimworld_planet/proc/get_tile_images_payload()
	var/list/result = list()
	for(var/key in tile_images)
		var/list/coords = splittext(key, ":")
		if(length(coords) < 2)
			continue
		result += list(list(
			"x" = text2num(coords[1]),
			"y" = text2num(coords[2]),
			"src" = tile_images[key]
		))
	return result

/**
 * Returns the biome images payload.
 */
/datum/rimworld_planet/proc/get_biome_images_payload()
	return biome_images?.Copy() || list()

/datum/rimworld_planet/Destroy()
	if(cells)
		for(var/key in cells)
			var/datum/planet_cell/cell = cells[key]
			if(cell)
				qdel(cell)

	cells = null
	clear_noise_maps()

	objects = null
	settlements = null
	points_of_interest = null
	roads = null
	discovered_regions = null
	tile_images = null
	biome_images = null

	return ..()
