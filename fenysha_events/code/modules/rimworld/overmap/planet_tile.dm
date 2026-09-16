/area/rimworld
	name = "Rim"
/**
 * /datum/planet_cell
 *
 * Central physical representation of an ALREADY generated cell
 * on the global planetary map (/datum/rimworld_planet).
 *
 * Stores a full snapshot of tile data, manages local generation
 * (sub-level), objects, weather, zones and the cell lifecycle.
 *
 * The cell is created from coordinates of an existing planet and
 * automatically synchronizes its data with it.
 */

/datum/planet_cell
	abstract_type = /datum/planet_cell
	/// Parent planet
	var/datum/rimworld_planet/planet

	/// Cell coordinates on the global map (1-based)
	var/x = 1
	var/y = 1

	// Should cell map be loaded on Intitialize
	var/generate_on_init = TRUE

	/// Unique cell identifier (generated on creation)
	var/id
	var/static/unic_id = 0

	var/elevation
	var/heat
	var/humidity
	var/material
	var/latitude
	var/temperature
	var/precipitation
	var/rainfall
	var/snowfall
	var/water_availability
	var/biome
	var/sub_biome

	/// List of objects located in this cell (copies of get_data())
	var/list/objects = list()

	/// Optional tile image overlay
	var/tile_image

	/// Whether planet layer data was loaded at creation/refresh time
	var/maps_loaded = FALSE


	/// Local generation state (sub-level)

	/// ID of the reserved sub-level (if generated)
	var/sub_level_id

	/// Reference to the turf_reservation (if still alive)
	var/datum/turf_reservation/sub_level/reservation

	/// Whether local content (turfs, flora, mobs) has been generated
	var/is_generated = FALSE

	/// Whether the cell is currently being generated
	var/is_generating = FALSE

	/// Local map size (defaults match generate_sub_level_at)
	var/local_width = 128
	var/local_height = 128


	/// Weather

	/// Current weather type (string identifier, to be extended later)
	var/weather_type = "clear"

	/// Weather intensity (0.0 - 1.0)
	var/weather_intensity = 0.0

	/// Time until next weather change (in deciseconds)
	var/weather_timer = 0

	/// Zones / areas

	/// List of active zones inside the cell (stub for now)
	var/list/zones = list()

	/// Internal

	/// Timestamp of the last data refresh from the planet
	var/last_refresh_time = 0

	/// Whether the cell is marked for deletion
	var/qdel_pending = FALSE


// TODO: move to SS code
/datum/planet_cell/New(datum/rimworld_planet/parent_planet, cell_x, cell_y)
	. = ..()
	unic_id++
	return Initialize(parent_planet, cell_x, cell_y)




/datum/planet_cell/proc/Initialize(datum/rimworld_planet/parent_planet, cell_x, cell_y, ...)
	if(!parent_planet)
		stack_trace("planet_cell created without parent planet")
		return

	if(!parent_planet.is_valid_coordinate(cell_x, cell_y))
		stack_trace("planet_cell created with invalid coordinates ([cell_x],[cell_y])")
		return

	planet = parent_planet
	x = cell_x
	y = cell_y
	id = "cell_[planet.seed]_[x]_[y]_[unic_id]"

	if(generate_on_init)
		generate_local_content()

	refresh_from_planet()

/datum/planet_cell/Destroy(force)
	qdel_pending = TRUE

	// Unload local generation
	unload_local_content()

	// Break references
	planet = null
	reservation = null
	objects = null
	zones = null

	return ..()


/**
 * Fully refreshes all cached cell data from the parent planet.
 * Safe to call at any time.
 */
/datum/planet_cell/proc/refresh_from_planet()
	if(!planet || qdel_pending)
		return FALSE

	var/list/tile = planet.get_tile_data(x, y)
	if(!tile)
		return FALSE

	maps_loaded = tile["mapsLoaded"]

	elevation          = tile["elevation"]
	heat               = tile["heat"]
	humidity           = tile["humidity"]
	material           = tile["material"]
	latitude           = tile["latitude"]
	temperature        = tile["temperature"]
	precipitation      = tile["precipitation"]
	rainfall           = tile["rainfall"]
	snowfall           = tile["snowfall"]
	water_availability = tile["waterAvailability"]
	biome              = tile["biome"]
	sub_biome          = tile["subBiome"]
	tile_image         = tile["image"]

	// Objects — copy the data list
	objects.Cut()
	var/list/raw_objects = tile["objects"]
	if(islist(raw_objects))
		for(var/list/obj_data in raw_objects)
			objects += list(obj_data.Copy())

	last_refresh_time = REALTIMEOFDAY
	return TRUE


/**
 * Returns a full snapshot of cell data as an assoc list
 * (compatible with get_tile_data + extra cell fields).
 */
/datum/planet_cell/proc/get_data()
	return list(
		"id"                = id,
		"x"                 = x,
		"y"                 = y,
		"elevation"         = elevation,
		"heat"              = heat,
		"humidity"          = humidity,
		"material"          = material,
		"latitude"          = latitude,
		"temperature"       = temperature,
		"precipitation"     = precipitation,
		"rainfall"          = rainfall,
		"snowfall"          = snowfall,
		"waterAvailability" = water_availability,
		"biome"             = biome,
		"subBiome"          = sub_biome,
		"objects"           = objects.Copy(),
		"image"             = tile_image,
		"mapsLoaded"        = maps_loaded,
		"isGenerated"       = is_generated,
		"isGenerating"      = is_generating,
		"subLevelId"        = sub_level_id,
		"weatherType"       = weather_type,
		"weatherIntensity"  = weather_intensity,
		"localWidth"        = local_width,
		"localHeight"       = local_height,
	)


/**
 * Checks whether the cell coordinates are still valid on the current planet.
 */
/datum/planet_cell/proc/is_valid()
	if(!planet || qdel_pending)
		return FALSE
	return planet.is_valid_coordinate(x, y)

/**
 * Returns TRUE when local terrain is currently loaded.
 */
/datum/planet_cell/proc/is_loaded()
	return is_generated && reservation && !qdel_pending


/**
 * Ensures that local terrain exists.
 *
 * Returns TRUE if the cell is already loaded or was successfully loaded.
 */
/datum/planet_cell/proc/ensure_loaded(poi_name = null)
	if(!is_valid())
		return FALSE

	if(is_loaded())
		return TRUE

	if(is_generating)
		return FALSE

	return generate_local_content(poi_name)


/**
 * Local generation / unloading
 */


/**
 * Generation order:
 *
 * 1. Allocate a sub-level reservation.
 * 2. Assign /area/rimworld to the entire reservation.
 * 3. Create the sub-level terrain generator.
 * 4. Pass planet context into the generator.
 * 5. Generate the terrain from the Rust heightmap.
 * 6. Store the reservation and generation state.
 *
 * The planet_cell owns the reservation after successful generation.
 */
/datum/planet_cell/proc/generate_local_content(poi_name = null)
	if(!is_valid())
		return FALSE

	if(is_generated || is_generating)
		return FALSE

	is_generating = TRUE
	Master.StartLoadingMap()
	// 1. Allocate local map space.
	var/datum/turf_reservation/sub_level/new_reservation = \
		SSsub_levels.create_sub_level(
			local_width,
			local_height,
			0,
			poi_name || "Cell ([x],[y])"
		)

	if(!new_reservation)
		is_generating = FALSE
		log_world("Failed to allocate sub-level for planet cell [x],[y].")
		Master.StopLoadingMap()
		return FALSE

	// 2. Create a dedicated area for the generated terrain.
	var/area/rimworld/rimworld_area = new /area/rimworld

	if(!rimworld_area)
		qdel(new_reservation)
		is_generating = FALSE
		log_world("Failed to create /area/rimworld for planet cell [x],[y].")
		Master.StopLoadingMap()
		return FALSE

	var/list/turf/turfs = new_reservation.get_all_turfs()

	if(!length(turfs))
		qdel(rimworld_area)
		qdel(new_reservation)
		is_generating = FALSE
		log_world("Sub-level reservation for planet cell [x],[y] contains no turfs.")
		Master.StopLoadingMap()
		Master.StopLoadingMap()
		return FALSE

	for(var/turf/T as anything in turfs)
		T.change_area(get_area(T), rimworld_area)
		CHECK_TICK


	// 3. Create and configure the actual terrain generator.
	var/datum/map_generator/sub_level/generator = new()

	if(!generator)
		qdel(rimworld_area)
		qdel(new_reservation)
		is_generating = FALSE
		log_world("Failed to create sub-level generator for planet cell [x],[y].")
		Master.StopLoadingMap()
		return FALSE

	generator.setup_planet_context(planet, x, y)

	// 4. Generate terrain.
	var/generated = generator.generate_sub_level_terrain(new_reservation)
	if(!generated)
		qdel(generator)
		qdel(rimworld_area)
		qdel(new_reservation)

		is_generating = FALSE

		log_world("Sub-level terrain generation failed for planet cell [x],[y].")
		Master.StopLoadingMap()
		return FALSE

	Master.StopLoadingMap()
	// 5. Store generated state.
	reservation = new_reservation
	sub_level_id = new_reservation.id
	is_generated = TRUE
	is_generating = FALSE
	qdel(generator)
	refresh_from_planet()
	return TRUE


/**
 * Unloads the cell's local content (frees the reservation).
 * Does not delete the cell itself.
 */
/datum/planet_cell/proc/unload_local_content()
	if(reservation)
		// Assumes the reservation has a proper Destroy / free
		qdel(reservation)
		reservation = null

	sub_level_id = null
	is_generated = FALSE
	is_generating = FALSE
	return TRUE

/**
 * Unloads local terrain while keeping the planet cell itself alive.
 */
/datum/planet_cell/proc/unload()
	if(qdel_pending)
		return FALSE

	if(!is_generated && !reservation)
		return TRUE

	return unload_local_content()

/**
 * Loads local terrain for this cell.
 *
 * This is the preferred public entry point for runtime loading.
 */
/datum/planet_cell/proc/load(poi_name = null)
	return ensure_loaded(poi_name)


/**
 * Reloads local terrain from scratch.
 */
/datum/planet_cell/proc/reload(poi_name = null)
	if(qdel_pending || !is_valid())
		return FALSE

	unload_local_content()

	refresh_from_planet()

	return generate_local_content(poi_name)

/**
 * Fully recreates local content (unload + generate).
 */
/datum/planet_cell/proc/regenerate_local_content(poi_name = null)
	unload_local_content()
	return generate_local_content(poi_name)


/**
 * Returns the bottom-left turf of the loaded local map.
 */
/datum/planet_cell/proc/get_bottom_left_turf()
	if(!is_loaded())
		return null

	return reservation.get_bottom_left_turf()

/**
 * Returns all turfs belonging to the loaded local map.
 */
/datum/planet_cell/proc/get_local_turfs()
	if(!is_loaded())
		return null

	return reservation.get_all_turfs()



/**
 * ------------------------------------------------------------------
 * Weather (skeleton)
 * ------------------------------------------------------------------
 */

/**
 * Sets weather type and intensity.
 */
/datum/planet_cell/proc/set_weather(new_type, intensity = 0.5, duration = null)
	weather_type = new_type || "clear"
	weather_intensity = clamp(intensity, 0, 1)

	if(!isnull(duration))
		weather_timer = duration
	else
		weather_timer = 0

	return TRUE


/**
 * Resets weather to clear state.
 */
/datum/planet_cell/proc/clear_weather()
	return set_weather("clear", 0, 0)


/**
 * Weather tick (called externally, e.g. by a subsystem).
 * Currently only decrements the timer.
 */
/datum/planet_cell/proc/process_weather(delta_time = 1)
	if(weather_timer > 0)
		weather_timer = max(0, weather_timer - delta_time)
		if(weather_timer <= 0)
			clear_weather()
	return TRUE


/**
 * ------------------------------------------------------------------
 * Zones (skeleton)
 * ------------------------------------------------------------------
 */

/**
 * Adds a zone to the cell.
 * Accepts any datum with an id (or just a string/assoc).
 */
/datum/planet_cell/proc/add_zone(zone)
	if(!zone)
		return FALSE
	zones |= zone
	return TRUE


/**
 * Removes a zone.
 */
/datum/planet_cell/proc/remove_zone(zone)
	zones -= zone
	return TRUE


/**
 * Clears all zones.
 */
/datum/planet_cell/proc/clear_zones()
	zones.Cut()
	return TRUE


/**
 * ------------------------------------------------------------------
 * Utilities
 * ------------------------------------------------------------------
 */

/**
 * Returns distance to another cell (or coordinates).
 */
/datum/planet_cell/proc/get_distance_to(target_x, target_y)
	return get_dist_2d(x, y, target_x, target_y)


/**
 * Returns distance to another planet_cell.
 */
/datum/planet_cell/proc/get_distance_to_cell(datum/planet_cell/other)
	if(!other)
		return null
	return get_distance_to(other.x, other.y)


/**
 * Synchronizes the cell's objects with the planet (useful after external changes).
 */
/datum/planet_cell/proc/sync_objects()
	if(!planet)
		return FALSE

	objects.Cut()
	var/list/raw = planet.get_objects_at(x, y)
	if(islist(raw))
		for(var/list/obj_data in raw)
			objects += list(obj_data.Copy())
	return TRUE


/**
 * Convenience biome getter (with fallback).
 */
/datum/planet_cell/proc/get_biome()
	return biome || RW_BIOME_OCEAN


/**
 * Convenience sub-biome getter.
 */
/datum/planet_cell/proc/get_sub_biome()
	return sub_biome || RW_SUBBIOME_PLAINS
