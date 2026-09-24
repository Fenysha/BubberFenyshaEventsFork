GLOBAL_LIST_INIT(rimworld_areas, list())


/area/rimworld
	name = "Rim"
	icon_state = "green"
	area_flags = VALID_TERRITORY | BLOBS_ALLOWED | CULT_PERMITTED
	area_flags_mapping = CAVES_ALLOWED | FLORA_ALLOWED | MOB_SPAWN_ALLOWED
	default_gravity = TRUE
	outdoors = TRUE
	daylight = TRUE

	var/datum/planet_cell/cell
	/// Last applied local intensity (−1 = never applied).
	var/rimworld_sun_intensity = -1
	var/rimworld_sun_color = null
	var/rimworld_forced_intensity = null
	var/rimworld_forced_color = null


/area/rimworld/Initialize(mapload)
	. = ..()
	GLOB.rimworld_areas |= src

	var/datum/planet_cell/cell = get_planet_cell(src)
	if(cell)
		INVOKE_ASYNC(src, PROC_REF(bind_planet_cell), cell)

/area/rimworld/Destroy()
	cell = null
	GLOB.rimworld_areas -= src
	return ..()


/area/rimworld/proc/bind_planet_cell(datum/planet_cell/new_cell)
	cell = new_cell
	if(daylight)
		update_rimworld_daylight(force = TRUE)


/area/rimworld/proc/get_local_solar_hour()
	if(isnull(rimworld_forced_intensity) && cell?.planet)
		// BUG FIX: get_solar_angle() is unsigned (0..180), so the old code here
		// could never tell dawn from dusk — every tile past noon collapsed back
		// onto the 0-12h morning range and got dawn/sunrise colours in the
		// afternoon/evening. get_solar_hour() keeps the sign, giving a real 0-24h.
		return cell.get_solar_hour()
	return SSrimworld_planetmap?.time_of_day || 12


/area/rimworld/proc/get_local_sun_intensity()
	if(!isnull(rimworld_forced_intensity))
		return clamp(rimworld_forced_intensity, 0, 1)
	if(cell)
		return cell.get_sun_intensity()
	if(SSrimworld_planetmap)
		var/tod = SSrimworld_planetmap.time_of_day
		var/dist = abs(tod - 12)
		if(dist > 12)
			dist = 24 - dist
		return max(0, cos(dist * 15))
	return 1


/area/rimworld/proc/update_rimworld_daylight(force = FALSE)
	if(!daylight || QDELETED(src))
		return
	var/intensity = get_local_sun_intensity()
	var/hour = get_local_solar_hour()
	var/list/phase_state = SSdaylight.get_phase_light_state_for_hour(hour)
	var/color = rimworld_forced_color || phase_state["color"] || "#ffffff"
	var/phase_i = phase_state["intensity"]
	if(!isnull(phase_i))
		intensity = clamp(intensity * phase_i, 0, 1)

	var/new_strength = round(clamp(intensity, 0, 1) * 255, 1)
	var/old_strength = round(clamp(rimworld_sun_intensity >= 0 ? rimworld_sun_intensity : -1, 0, 1) * 255, 1)
	if(!force && rimworld_sun_intensity >= 0 && new_strength == old_strength && color == rimworld_sun_color)
		return

	rimworld_sun_intensity = intensity
	rimworld_sun_color = color
	apply_rimworld_daylight_overlay(intensity, color)
	SEND_SIGNAL(src, COMSIG_RIMWORLD_AREA_DAYLIGHT_UPDATE, intensity, color, hour)


/area/rimworld/proc/apply_rimworld_daylight_overlay(intensity = 1, color = "#ffffff")
	if(!daylight)
		return
	var/strength = round(clamp(intensity, 0, 1) * 255, 1)
	if(strength <= 0)
		if(daylight_lit)
			clear_daylight_overlay()
		return

	SSdaylight.daylight_areas |= src
	daylight_lit = TRUE
	var/list/own_turfs = list()
	for(var/turf/area_turf in src)
		apply_daylight_wash(area_turf, strength)
		own_turfs += area_turf
		CHECK_TICK
	relight_daylight_leaks_scaled(own_turfs, intensity)


/area/rimworld/proc/relight_daylight_leaks_scaled(list/source_turfs, intensity = 1)
	for(var/turf/leaked in daylight_leaked)
		if(isturf(leaked))
			clear_daylight_wash(leaked)
		CHECK_TICK
	daylight_leaked = null

	if(!length(source_turfs))
		return

	var/list/scaled = list()
	for(var/v in GLOB.daylight_leak_falloff)
		scaled += round(v * clamp(intensity, 0, 1), 1)

	LAZYINITLIST(daylight_leaked)
	var/list/visited = list()
	var/list/frontier = list()
	for(var/turf/seed in source_turfs)
		if(!isturf(seed))
			continue
		visited[seed] = TRUE
		frontier += seed

	for(var/ring in 1 to length(scaled))
		if(scaled[ring] <= 0)
			break
		var/list/next_frontier = list()
		for(var/turf/frontier_turf in frontier)
			if(!isturf(frontier_turf) || frontier_turf.opacity)
				continue
			for(var/dir in GLOB.cardinals)
				var/turf/neighbor = get_step(frontier_turf, dir)
				if(!isturf(neighbor) || visited[neighbor])
					continue
				visited[neighbor] = TRUE
				var/area/neighbor_area = neighbor.loc
				if(neighbor_area?.daylight)
					continue
				var/mutable_appearance/leak = apply_daylight_wash(neighbor, scaled[ring])
				daylight_leaked[neighbor] = leak
				next_frontier += neighbor
		frontier = next_frontier
		CHECK_TICK


/area/rimworld/proc/set_forced_daylight(intensity = null, color = null)
	rimworld_forced_intensity = intensity
	rimworld_forced_color = color
	update_rimworld_daylight(force = TRUE)


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
	var/generate_on_init = FALSE

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

	/// Cached last known daylight state (optional, for change detection)
	var/was_daylight = null

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

	/// Asynchronous sub-level loading job, if one is currently running.
	var/datum/rimworld_sublevel_load_job/loading_job

// TODO: move to SS code
/datum/planet_cell/New(
	datum/rimworld_planet/parent_planet,
	cell_x,
	cell_y,
	should_generate = FALSE
)
	. = ..()

	unic_id++

	generate_on_init = should_generate

	return Initialize(parent_planet, cell_x, cell_y)


/datum/planet_cell/proc/Initialize(
	datum/rimworld_planet/parent_planet,
	cell_x,
	cell_y,
	...
)
	if(!parent_planet)
		stack_trace("planet_cell created without parent planet")
		return FALSE

	if(!parent_planet.is_valid_coordinate(cell_x, cell_y))
		stack_trace("planet_cell created with invalid coordinates ([cell_x],[cell_y])")
		return FALSE

	planet = parent_planet
	x = cell_x
	y = cell_y

	id = "cell_[planet.seed]_[x]_[y]_[unic_id]"

	// Planetary data must be available before local generation.
	if(!refresh_from_planet())
		return FALSE

	if(generate_on_init)
		generate_local_content()

	return TRUE


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
	return is_generated \
		&& reservation \
		&& !QDELETED(reservation) \
		&& !qdel_pending


/**
 * Ensures that local terrain exists.
 *
 * Returns TRUE if the cell is already loaded or was successfully loaded.
 */
/datum/planet_cell/proc/ensure_loaded(poi_name = null, datum/callback/post_load_callback = null)
	if(!is_valid())
		return FALSE

	if(is_loaded())
		if(post_load_callback)
			post_load_callback.Invoke(src, TRUE)

		return TRUE

	if(is_generating)
		if(loading_job && post_load_callback)
			loading_job.add_callback(post_load_callback)

		return TRUE

	return generate_local_content(poi_name, post_load_callback)


/**
 * Queues local terrain generation.
 *
 * The actual generation is performed asynchronously by
 * SSrimworld_sublevel_loader.
 *
 * post_load_callback, when provided, is invoked as:
 *
 *     callback.Invoke(cell, success)
 *
 * after the complete local map has finished loading.
 */
/datum/planet_cell/proc/generate_local_content(poi_name = null, datum/callback/post_load_callback = null)
	if(!is_valid())
		return FALSE

	if(is_loaded())
		if(post_load_callback)
			post_load_callback.Invoke(src, TRUE)

		return TRUE

	return SSrimworld_sublevel_loader.queue_cell(
		src,
		poi_name,
		post_load_callback
	)



/**
 * After local map is loaded: bind every /area/rimworld on the reservation to this cell.
 */
/datum/planet_cell/proc/bind_areas_to_cell()
	if(!is_loaded())
		return FALSE
	var/list/turfs = get_local_turfs()
	if(!turfs)
		return FALSE
	var/list/seen = list()
	for(var/turf/T as anything in turfs)
		var/area/rimworld/A = get_area(T)
		if(!istype(A) || seen[A])
			continue
		seen[A] = TRUE
		A.bind_planet_cell(src)



/**
 * Unloads the cell's local content (frees the reservation).
 * Does not delete the cell itself.
 */
/datum/planet_cell/proc/unload_local_content()
	if(loading_job)
		SSrimworld_sublevel_loader.cancel_cell(src)

	if(reservation)
		qdel(reservation)
		reservation = null

	sub_level_id = null
	is_generated = FALSE
	is_generating = FALSE
	loading_job = null

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

/datum/planet_cell/proc/load(poi_name = null, datum/callback/post_load_callback = null)
	return ensure_loaded(
		poi_name,
		post_load_callback
	)

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
 * Daylight process
 */


/**
 * Whether this cell is currently on the sunny side of the planet.
 */
/datum/planet_cell/proc/is_daylight(fraction = null)
	if(!planet)
		return FALSE
	return planet.is_daylight(x, y, fraction)


/datum/planet_cell/proc/is_night(fraction = null)
	return !is_daylight(fraction)


/datum/planet_cell/proc/get_sun_intensity()
	if(!planet)
		return 0
	return planet.get_sun_intensity(x, y)


/datum/planet_cell/proc/get_season()
	if(!planet)
		return RW_SEASON_SPRING
	return planet.get_season(x, y)


/datum/planet_cell/proc/get_solar_angle()
	if(!planet)
		return 180
	return planet.get_solar_angle(x, y)


/// Local solar clock hour (0-24), correctly distinguishing morning from afternoon.
/datum/planet_cell/proc/get_solar_hour()
	if(!planet)
		return 12
	return planet.get_solar_hour(x, y)

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
	return planet.get_tile_distance(x, y, target_x, target_y)


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
