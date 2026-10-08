/datum/rimworld_planet_object
	var/id
	var/object_type = RW_OBJECT_TYPE_OBJECT
	var/name = "Unknown"
	var/x = 1
	var/y = 1
	var/icon = RW_PLANET_CELL_TOWN_ICON
	/// Multiplies the map sprite. White leaves the texture unchanged.
	var/color = "#ffffff"
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
		"color" = color,
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

/datum/rimworld_planet_object/settlement/proc/is_player_settlement()
	var/datum/rw_faction/faction = SSfactions.get_faction(data["faction"])
	return faction?.player_faction

/**
 * Sets the settlement faction.
 */
/datum/rimworld_planet_object/settlement/proc/set_faction(faction_id)
	data["faction"] = faction_id
	var/datum/rw_faction/faction = SSfactions.get_faction(faction_id)
	if(!faction)
		return
	if(faction.color)
		color = faction.color
	if(faction.icon_state)
		icon = faction.icon_state

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
	var/rotation_speed = 0.2
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
	// Before registering assets: this also writes the roads layer, which the bake draws
	generate_settlements()
	bake_surface()
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


/datum/rimworld_planet/proc/generate_roads(list/settlement_points)
	var/list/settlements_json = list()
	for(var/list/point in settlement_points)
		settlements_json += list(list("x" = point["x"], "y" = point["y"], "tier" = point["tier"] || RW_ROAD_DIRT))

	var/list/config = list(
		"seed" = seed,
		"frequency" = grid_frequency,
		"output_dir" = "data/rimworld_planets/[seed]",
		"settlements" = settlements_json,
	)

	var/result = rustg_tp_planet_generate_roads(json_encode(config))
	if(!result || findtext(result, "ERROR:") == 1)
		log_world("[name] road generation failed: [result]")
		return FALSE

	var/list/decoded
	try
		decoded = json_decode(result)
	catch
		log_world("[name] road generation returned invalid JSON.")
		return FALSE

	if(!decoded || decoded["status"] != "ok")
		return FALSE

	for(var/layer_key in list("layer", "types_layer"))
		var/list/layer = decoded[layer_key]
		if(layer && layer["name"] && layer["path"])
			generated_layers[layer["name"]] = TRUE
			layer_files[layer["name"]] = layer["path"]
	cell_cache = list()

	log_world("[name] generated roads: [decoded["edges"]] segments, [decoded["road_tiles"]] tiles, [decoded["networks"]] networks, [decoded["skipped_settlements"]] settlements skipped.")
	return TRUE

/// Pre-renders the planet view's textures; without them clients fall back to baking their own.
/datum/rimworld_planet/proc/bake_surface()
	var/list/config = list(
		"seed" = seed,
		"terrain_seed" = terrain_seed,
		"frequency" = grid_frequency,
		"output_dir" = "data/rimworld_planets/[seed]",
	)
	var/result = rustg_tp_planet_bake_surface(json_encode(config))
	if(!result || findtext(result, "ERROR:") == 1)
		log_world("[name] surface bake failed: [result]")
		return FALSE

	var/list/decoded
	try
		decoded = json_decode(result)
	catch
		log_world("[name] surface bake returned invalid JSON.")
		return FALSE
	if(!decoded || decoded["status"] != "ok")
		return FALSE

	generated_layers["surface_color"] = TRUE
	layer_files["surface_color"] = decoded["color"]
	generated_layers["surface_decor"] = TRUE
	layer_files["surface_decor"] = decoded["decor"]
	return TRUE

/// Overland route as list(list(x, y), ...) from start to end inclusive, or null when there is none.
/datum/rimworld_planet/proc/find_path(from_x, from_y, to_x, to_y, use_roads = TRUE)
	var/list/config = list(
		"seed" = seed,
		"frequency" = grid_frequency,
		"output_dir" = "data/rimworld_planets/[seed]",
		"from" = list(from_x, from_y),
		"to" = list(to_x, to_y),
		"use_roads" = !!use_roads,
	)
	var/result = rustg_tp_planet_find_path(json_encode(config))
	if(!result || findtext(result, "ERROR:") == 1)
		log_world("[name] path [from_x],[from_y] -> [to_x],[to_y] failed: [result]")
		return null
	var/list/decoded = json_decode(result)
	if(decoded["status"] != "ok")
		return null
	return normalize_rust_path(decoded["path"])

/// json_decode of [[x, y], ...] into list(list(x, y), ...). Drops malformed steps.
/datum/rimworld_planet/proc/normalize_rust_path(list/raw)
	var/list/path = list()
	if(!islist(raw))
		return path
	for(var/step in raw)
		if(!islist(step) || length(step) < 2)
			continue
		var/sx = step[1]
		var/sy = step[2]
		if(istext(sx))
			sx = text2num(sx)
		if(istext(sy))
			sy = text2num(sy)
		if(!isnum(sx) || !isnum(sy))
			continue
		path += list(list(round(sx), round(sy)))
	return path

/datum/rimworld_planet/proc/get_road_mask(x, y)
	if(!is_valid_coordinate(x, y))
		return 0
	return get_layer_value("roads", x, y) || 0

/// RW_ROAD_* grade of the road on this tile; meaningless where has_road() is false
/datum/rimworld_planet/proc/get_road_type(x, y)
	if(!is_valid_coordinate(x, y))
		return RW_ROAD_DIRT
	return get_layer_value("road_types", x, y) || RW_ROAD_DIRT

/datum/rimworld_planet/proc/has_road(x, y)
	return get_road_mask(x, y) != 0

/datum/rimworld_planet/proc/get_road_connections(x, y)
	var/mask = get_road_mask(x, y)
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
 * Returns latitude in degrees (-90 .. 90).
 */
/datum/rimworld_planet/proc/get_latitude(x, y)
	if(!is_valid_coordinate(x, y))
		return 0
	return get_tile_lat_lon(x, y)[1]

/**
 * A tile's climate as Rust's model computes it (tp_planet_climate.rs, the only copy of it):
 * material, temperature, precipitation, rainfall, snowfall, water_availability, biome, sub_biome.
 */
/datum/rimworld_planet/proc/get_tile_climate(x, y)
	if(!is_valid_coordinate(x, y) || !maps_generated())
		return null
	var/cache_key = "climate:[x]:[y]"
	var/list/climate = cell_cache[cache_key]
	if(climate)
		return climate
	var/result = rustg_tp_planet_tile_info("data/rimworld_planets/[seed]", seed, x, y)
	if(!result || findtext(result, "ERROR:") == 1)
		log_world("[name] tile climate lookup failed at [x],[y]: [result]")
		return null
	climate = json_decode(result)
	cell_cache[cache_key] = climate
	return climate

/datum/rimworld_planet/proc/get_material(x, y)
	var/list/climate = get_tile_climate(x, y)
	return climate ? climate["material"] : RW_MATERIAL_NONE

/// Normalized temperature, 0-1
/datum/rimworld_planet/proc/get_temperature(x, y)
	var/list/climate = get_tile_climate(x, y)
	return climate ? climate["temperature"] : 0

/// Normalized precipitation, 0-1
/datum/rimworld_planet/proc/get_precipitation(x, y)
	var/list/climate = get_tile_climate(x, y)
	return climate ? climate["precipitation"] : 0

/datum/rimworld_planet/proc/get_rainfall(x, y)
	var/list/climate = get_tile_climate(x, y)
	return climate ? climate["rainfall"] : 0

/datum/rimworld_planet/proc/get_snowfall(x, y)
	var/list/climate = get_tile_climate(x, y)
	return climate ? climate["snowfall"] : 0

/// Water availability, 0-1
/datum/rimworld_planet/proc/get_water_availability(x, y)
	var/list/climate = get_tile_climate(x, y)
	return climate ? climate["water_availability"] : 0

/datum/rimworld_planet/proc/get_biome(x, y)
	var/list/climate = get_tile_climate(x, y)
	return climate ? climate["biome"] : RW_BIOME_OCEAN

/datum/rimworld_planet/proc/get_sub_biome(x, y)
	var/list/climate = get_tile_climate(x, y)
	return climate ? climate["sub_biome"] : RW_SUBBIOME_PLAINS

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

	var/list/climate = get_tile_climate(x, y)
	if(climate)
		tile["elevation"] = get_elevation_level(x, y)
		tile["heat"] = get_heat_level(x, y)
		tile["humidity"] = get_humidity_level(x, y)
		tile["material"] = climate["material"]
		tile["latitude"] = get_latitude(x, y)
		tile["temperature"] = climate["temperature"]
		tile["isDaylight"] = is_daylight(x, y)
		tile["sunIntensity"] = get_sun_intensity(x, y)
		tile["season"] = get_season(x, y)
		tile["solarAngle"] = get_solar_angle(x, y)
		tile["precipitation"] = climate["precipitation"]
		tile["rainfall"] = climate["rainfall"]
		tile["snowfall"] = climate["snowfall"]
		tile["waterAvailability"] = climate["water_availability"]
		tile["biome"] = climate["biome"]
		tile["subBiome"] = climate["sub_biome"]
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
		"objects" = get_dynamic_objects(),
		"generationRevision" = generation_revision,
		"tileImages" = get_tile_images_payload(),
		"mapsLoaded" = maps_generated(),
		"calendar" = get_calendar_data(),
		"timeOfDay" = time_of_day,
		"rotationAngle" = rotation_angle,
		"generatedLayers" = generated_layers.Copy()
	)


/**
 * Rebuilds staticObjects for all open views of this planet.
 * Call after remove_object / destroy settlement / road rebuild.
 */
/datum/rimworld_planet/proc/push_static_objects()
	for(var/datum/planetmap_view/view as anything in SSrimworld_planetmap.get_views_for_planet(src))
		if(QDELETED(view))
			continue
		view.update_static_data_for_all_viewers()

/**
 * Static map objects: non-player settlements + roads.
 * Sent once via ui_static_data; refresh via push_static_objects().
 */
/datum/rimworld_planet/proc/get_static_objects()
	var/list/result = list()
	for(var/object_id in objects)
		var/datum/rimworld_planet_object/object = objects[object_id]
		if(!object)
			continue
		if(object.object_type == RW_OBJECT_TYPE_ROAD)
			result += list(object.get_data())
			continue
		if(object.object_type != RW_OBJECT_TYPE_SETTLEMENT)
			continue
		var/datum/rimworld_planet_object/settlement/settlement = object
		// Player settlements stay dynamic
		if(settlement.is_player_settlement())
			continue
		result += list(object.get_data())
	return result


/**
 * Dynamic objects only (player settlements, POIs, etc.).
 */
/datum/rimworld_planet/proc/get_dynamic_objects()
	var/list/result = list()
	for(var/object_id in objects)
		var/datum/rimworld_planet_object/object = objects[object_id]
		if(!object)
			continue
		if(object.object_type == RW_OBJECT_TYPE_ROAD)
			continue
		if(object.object_type == RW_OBJECT_TYPE_SETTLEMENT)
			var/datum/rimworld_planet_object/settlement/settlement = object
			if(!settlement.is_player_settlement())
				continue
		result += list(object.get_data())
	return result


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
