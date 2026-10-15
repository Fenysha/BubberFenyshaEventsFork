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
	/// While the cell is being stamped, turf changes must not schedule a second paint sweep.
	var/cell_loading = FALSE
	/// Last applied local intensity (−1 = never applied).
	var/rimworld_sun_intensity = -1
	var/rimworld_sun_color = null
	/// Last plate alpha actually written. -1 forces the first write.
	var/rimworld_sun_alpha_bucket = -1
	var/rimworld_forced_intensity = null
	var/rimworld_forced_color = null
	/// Visual sun. Turf overlays mirror this; ticks only change its color and alpha.
	var/obj/rimworld_daylight_plate/sun_plate
	/// TRUE after outdoor and leak overlays have been attached once.
	var/daylight_overlays_ready = FALSE


/area/rimworld/Initialize(mapload)
	. = ..()
	GLOB.rimworld_areas |= src

	var/datum/planet_cell/cell = get_planet_cell(src)
	if(cell)
		INVOKE_ASYNC(src, PROC_REF(bind_planet_cell), cell)

/area/rimworld/Destroy()
	daylight_overlays_ready = FALSE
	QDEL_NULL(sun_plate)
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


/area/rimworld/apply_daylight_overlay()
	if(cell_loading)
		return
	update_rimworld_daylight(force = TRUE)


/area/rimworld/clear_daylight_overlay()
	daylight_overlays_ready = FALSE
	..()
	QDEL_NULL(sun_plate)


/area/rimworld/proc/ensure_sun_plate()
	if(sun_plate && !QDELETED(sun_plate))
		return sun_plate
	sun_plate = new /obj/rimworld_daylight_plate(null, src)
	return sun_plate


/area/rimworld/proc/sync_sun_plate(intensity = 1, color = "#ffffff")
	var/obj/rimworld_daylight_plate/plate = ensure_sun_plate()
	if(QDELETED(plate))
		return
	// One assignment. Restarting animate() every tick was a steady appearance send.
	animate(plate)
	plate.color = color
	plate.alpha = rimworld_daylight_alpha_bucket(intensity)


/area/rimworld/proc/apply_plate_wash(turf/target, strength = 255)
	if(!sun_plate || QDELETED(sun_plate) || !sun_plate.render_target)
		return
	var/atom/holder = daylight_overlay_holder(target)
	if(isnull(holder))
		return
	clear_daylight_wash(target)
	var/mutable_appearance/wash = get_rimworld_daylight_appearance(sun_plate.render_target, strength, target)
	holder.add_overlay(wash)
	holder.daylight_wash_applied = wash
	return wash


/area/rimworld/proc/update_rimworld_daylight(force = FALSE)
	if(!daylight || QDELETED(src) || cell_loading)
		return
	var/intensity = get_local_sun_intensity()
	var/hour = get_local_solar_hour()
	var/list/phase_state = SSdaylight.get_phase_light_state_for_hour(hour)
	var/color = rimworld_forced_color || phase_state["color"] || "#ffffff"
	var/phase_i = phase_state["intensity"]
	if(!isnull(phase_i))
		intensity = clamp(intensity * phase_i, 0, 1)

	var/bucket_alpha = rimworld_daylight_alpha_bucket(intensity)
	var/bucket_color = rimworld_quantize_daylight_color(color)
	if(!force && daylight_overlays_ready && bucket_alpha == rimworld_sun_alpha_bucket && bucket_color == rimworld_sun_color)
		return

	rimworld_sun_intensity = bucket_alpha / 255
	rimworld_sun_color = bucket_color
	rimworld_sun_alpha_bucket = bucket_alpha
	sync_sun_plate(rimworld_sun_intensity, bucket_color)
	if(!daylight_overlays_ready)
		attach_daylight_overlays()
	SEND_SIGNAL(src, COMSIG_RIMWORLD_AREA_DAYLIGHT_UPDATE, rimworld_sun_intensity, bucket_color, hour)


/area/rimworld/proc/attach_daylight_overlays()
	if(!daylight || cell_loading || daylight_overlays_ready)
		return
	// Initialize() runs this before the generator has stamped any turfs in; the loader attaches later.
	if(!length(contents))
		return
	daylight_overlays_ready = TRUE
	ensure_sun_plate()
	SSdaylight.daylight_areas |= src
	daylight_lit = TRUE
	var/list/own_turfs = list()
	for(var/turf/area_turf in src)
		apply_plate_wash(area_turf, 255)
		own_turfs += area_turf
		CHECK_TICK
	attach_daylight_leaks(own_turfs)


/area/rimworld/proc/attach_daylight_leaks(list/source_turfs)
	if(!length(source_turfs))
		return
	var/list/leak_falloff = GLOB.daylight_leak_falloff
	LAZYINITLIST(daylight_leaked)
	var/list/visited = list()
	var/list/frontier = list()
	for(var/turf/seed in source_turfs)
		if(!isturf(seed))
			continue
		visited[seed] = TRUE
		frontier += seed

	for(var/ring in 1 to length(leak_falloff))
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
				var/mutable_appearance/leak = apply_plate_wash(neighbor, leak_falloff[ring])
				daylight_leaked[neighbor] = leak
				next_frontier += neighbor
		frontier = next_frontier
		CHECK_TICK


/area/rimworld/relight_daylight_leaks()
	if(!daylight_overlays_ready)
		return
	for(var/turf/leaked in daylight_leaked)
		if(isturf(leaked))
			clear_daylight_wash(leaked)
		CHECK_TICK
	daylight_leaked = null
	var/list/own_turfs = list()
	for(var/turf/area_turf in src)
		own_turfs += area_turf
		CHECK_TICK
	attach_daylight_leaks(own_turfs)


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

	/// Active /datum/weather instance for this cell's z-level (if any)
	var/datum/weather/active_weather
	/// In-game day on which the current weather should end; survives map unloads.
	var/weather_end_game_day = 0
	/// Wind speed is stored in km/h; direction is one of the eight BYOND directions.
	var/wind_speed = 8
	var/wind_direction = NORTH
	var/wind_next_shift_game_day = 0
	/// Sound loops attached to outdoor turfs while this cell is loaded.
	var/list/wind_sound_trackers = list()
	/// Marks this cell as a player's first/start settlement map.
	var/is_starting_settlement = FALSE
	/// Persistent relative template placements, reused whenever this cell is reloaded.
	var/list/structure_placement_plan = list()
	var/structure_plan_created = FALSE
	var/structures_generated = FALSE
	var/ancient_danger_generated = FALSE

	/// Forced weather override (admin / scenario); null = climate-driven
	var/forced_weather_type = null

	/// Zones / areas

	/// List of active zones inside the cell (stub for now)
	var/list/zones = list()

	/// Internal

	/// Timestamp of the last data refresh from the planet
	var/last_refresh_time = 0

	/// Whether the cell is marked for deletion
	var/qdel_pending = FALSE

	/// RimWorld storyteller queue owned by this runtime cell. It survives map unloads.
	var/datum/storyteller_cell_plan/storyteller_plan

	/// Asynchronous sub-level loading job, if one is currently running.
	var/datum/rimworld_sublevel_load_job/loading_job

/datum/planet_cell/Destroy(force)
	stop_cell_weather(FALSE)
	QDEL_NULL(storyteller_plan)
	return ..()

/datum/planet_cell/proc/get_storyteller_plan()
	RETURN_TYPE(/datum/storyteller_cell_plan)
	if(!storyteller_plan)
		storyteller_plan = new(src)
	return storyteller_plan

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
	ensure_climate()
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
		"annualMeanTemperature" = climate_ready ? annual_mean_c : null,
		"currentTemperature" = climate_ready ? get_outdoor_temperature() : null,
		"windSpeed" = wind_speed,
		"windDirection" = get_wind_direction_name(),
		"windStrength" = get_wind_strength_label(),
		"localWidth"        = local_width,
		"localHeight"       = local_height,
	)


/datum/planet_cell/proc/get_name()
	return "[x]:[y]"

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
/datum/planet_cell/proc/ensure_loaded(
	poi_name = null,
	datum/callback/post_load_callback = null,
	datum/callback/progress_callback = null
)
	if(!is_valid())
		return FALSE

	if(is_loaded())
		if(post_load_callback)
			post_load_callback.Invoke(src, TRUE)

		return TRUE

	if(is_generating)
		if(loading_job)
			if(post_load_callback)
				loading_job.add_callback(post_load_callback)

			if(progress_callback)
				loading_job.add_progress_callback(progress_callback)

		return TRUE

	return generate_local_content(
		poi_name,
		post_load_callback,
		progress_callback
	)


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
/datum/planet_cell/proc/generate_local_content(
	poi_name = null,
	datum/callback/post_load_callback = null,
	datum/callback/progress_callback = null
)
	if(!is_valid())
		return FALSE

	if(is_loaded())
		if(post_load_callback)
			post_load_callback.Invoke(src, TRUE)

		return TRUE

	return SSrimworld_sublevel_loader.queue_cell(
		src,
		poi_name,
		post_load_callback,
		progress_callback
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

	// Stop visual weather and sound sources before their z-level is released,
	// but preserve the cell's weather/wind state and in-game expiration time.
	stop_cell_weather(TRUE)
	SSrw_environment.unregister_cell(src)
	// Structures are part of the released reservation and must be reloaded next time.
	structures_generated = FALSE
	ancient_danger_generated = FALSE

	clear_edge_markers()
	exit_cooldown_until = 0

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

	teardown_rust_zones()
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
 * Sets weather type and intensity.
 */
/datum/planet_cell/proc/set_weather(new_type, intensity = 0.5, duration = null)
	weather_type = new_type || "clear"
	weather_intensity = clamp(intensity, 0, 1)
	weather_timer = 0 // legacy real-time timer intentionally unused
	if(isnum(duration) && duration > 0)
		weather_end_game_day = rw_get_planet_elapsed_days() + duration
	else if(weather_type == "clear")
		weather_end_game_day = 0
	return TRUE

/datum/planet_cell/proc/clear_weather()
	weather_end_game_day = 0
	return set_weather("clear", 0, null)

/datum/planet_cell/proc/process_weather(delta_time = 1)
	// Weather now advances by the planetary calendar, not real world.time.
	if(weather_end_game_day && rw_get_planet_elapsed_days() >= weather_end_game_day)
		return TRUE
	return TRUE



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


// ---------------------------------------------------------------------------
// Map-template placement for ruins and the required starting ancient danger.
// The template paths are intentionally strings: template classes are supplied
// by the content pack, so missing templates do not break compilation.
// ---------------------------------------------------------------------------

GLOBAL_LIST_INIT(rw_cell_structure_definitions, init_rw_cell_structure_definitions())

/proc/init_rw_cell_structure_definitions()
	var/list/definitions = list()
	for(var/path in subtypesof(/datum/rw_cell_structure_definition))
		var/datum/rw_cell_structure_definition/D = new path
		if(D.id)
			definitions[D.id] = D
	return definitions

/datum/rw_cell_structure_definition
	var/id
	var/name = "Ruin"
	/// Type path of a /datum/map_template subclass, stored as text for compile safety.
	var/template_path
	var/chance = 50
	var/min_count = 1
	var/max_count = 1
	var/mandatory = FALSE
	var/starting_only = FALSE
	var/min_separation = 8

/datum/rw_cell_structure_definition/ancient_danger
	id = "ancient_danger"
	name = "Ancient danger"
	template_path = "/datum/map_template/rw/ancient_danger"
	chance = 100
	min_count = 1
	max_count = 1
	mandatory = TRUE
	starting_only = TRUE
	min_separation = 0

/datum/rw_cell_structure_definition/small_ruin
	id = "small_ruin"
	name = "Small ruin"
	template_path = "/datum/map_template/rw/ruin/small"
	chance = 70
	min_count = 1
	max_count = 2
	min_separation = 12

/datum/rw_cell_structure_definition/medium_ruin
	id = "medium_ruin"
	name = "Medium ruin"
	template_path = "/datum/map_template/rw/ruin/medium"
	chance = 35
	min_count = 1
	max_count = 1
	min_separation = 18

/datum/rw_cell_structure_definition/wreckage
	id = "wreckage"
	name = "Wreckage"
	template_path = "/datum/map_template/rw/wreckage"
	chance = 45
	min_count = 1
	max_count = 2
	min_separation = 10

/datum/planet_cell/proc/create_structure_placement_plan()
	if(structure_plan_created)
		return structure_placement_plan
	structure_plan_created = TRUE
	structure_placement_plan = list()
	var/turf/BL = reservation?.get_inner_bottom_left_turf()
	var/turf/TR = reservation?.get_inner_top_right_turf()
	var/map_width = (BL && TR) ? (TR.x - BL.x + 1) : local_width
	var/map_height = (BL && TR) ? (TR.y - BL.y + 1) : local_height
	var/list/placed_boxes = list()
	var/list/ordered_ids = list()
	if(is_starting_settlement && GLOB.rw_cell_structure_definitions["ancient_danger"])
		ordered_ids += "ancient_danger"
	for(var/definition_id in GLOB.rw_cell_structure_definitions)
		if(definition_id != "ancient_danger")
			ordered_ids += definition_id

	for(var/id in ordered_ids)
		var/datum/rw_cell_structure_definition/D = GLOB.rw_cell_structure_definitions[id]
		if(!D || !D.template_path || (D.starting_only && !is_starting_settlement))
			continue
		if(!D.mandatory && !prob(D.chance))
			continue

		var/template_type = text2path(D.template_path)
		if(!template_type || !ispath(template_type, /datum/map_template))
			log_world("RW structures: [D.name] template path '[D.template_path]' is missing or invalid; add the template class to enable it.")
			continue

		var/count = D.mandatory ? max(1, D.min_count) : rand(D.min_count, max(D.min_count, D.max_count))
		for(var/i in 1 to count)
			var/datum/map_template/T = new template_type
			if(!T || T.width <= 0 || T.height <= 0)
				log_world("RW structures: template '[D.template_path]' has invalid dimensions.")
				qdel(T)
				continue

			var/padding = 5
			if(T.width + padding * 2 > map_width || T.height + padding * 2 > map_height)
				log_world("RW structures: template '[D.template_path]' ([T.width]x[T.height]) does not fit cell [x],[y].")
				qdel(T)
				continue

			var/found_position = FALSE
			var/place_x = 0
			var/place_y = 0
			for(var/attempt in 1 to 80)
				place_x = rand(padding, map_width - T.width - padding + 1)
				place_y = rand(padding, map_height - T.height - padding + 1)
				var/blocked = FALSE
				for(var/list/box as anything in placed_boxes)
					var/box_x = box["x"]
					var/box_y = box["y"]
					var/box_w = box["w"]
					var/box_h = box["h"]
					var/gap = D.min_separation
					if(place_x < box_x + box_w + gap && place_x + T.width + gap > box_x && place_y < box_y + box_h + gap && place_y + T.height + gap > box_y)
						blocked = TRUE
						break
				if(!blocked)
					found_position = TRUE
					break

			if(!found_position)
				if(D.mandatory)
					log_world("RW structures: could not place mandatory [D.name] in cell [x],[y]; cell may be too crowded.")
				qdel(T)
				continue

			structure_placement_plan += list(list(
				"id" = D.id,
				"name" = D.name,
				"template_path" = D.template_path,
				"x" = place_x,
				"y" = place_y,
				"width" = T.width,
				"height" = T.height,
				"mandatory" = D.mandatory
			))
			placed_boxes += list(list("x" = place_x, "y" = place_y, "w" = T.width, "h" = T.height))
			qdel(T)
	return structure_placement_plan

/datum/planet_cell/proc/place_starting_ancient_danger()
	if(ancient_danger_generated)
		return TRUE
	if(!is_starting_settlement || !is_loaded())
		return FALSE
	var/datum/rw_cell_structure_definition/definition = GLOB.rw_cell_structure_definitions["ancient_danger"]
	var/template_path = definition?.template_path || "/datum/map_template/rw/ancient_danger"
	var/template_type = text2path(template_path)
	if(!template_type || !ispath(template_type, /datum/map_template))
		log_world("RW structures: required starting ancient danger template '[template_path]' is missing.")
		return FALSE
	var/datum/map_template/T = new template_type
	if(!T || T.width <= 0 || T.height <= 0)
		qdel(T)
		return FALSE
	var/turf/BL = reservation.get_inner_bottom_left_turf()
	var/turf/TR = reservation.get_inner_top_right_turf()
	if(!BL || !TR)
		qdel(T)
		return FALSE
	var/map_width = TR.x - BL.x + 1
	var/map_height = TR.y - BL.y + 1
	if(T.width + 10 > map_width || T.height + 10 > map_height)
		log_world("RW structures: ancient danger template does not fit starting cell [x],[y].")
		qdel(T)
		return FALSE
	var/found_position = FALSE
	var/place_x = 0
	var/place_y = 0
	for(var/attempt in 1 to 100)
		place_x = rand(5, map_width - T.width - 4)
		place_y = rand(5, map_height - T.height - 4)
		var/blocked = FALSE
		for(var/list/entry as anything in structure_placement_plan)
			var/gap = 5
			if(place_x < entry["x"] + entry["width"] + gap && place_x + T.width + gap > entry["x"] && place_y < entry["y"] + entry["height"] + gap && place_y + T.height + gap > entry["y"])
				blocked = TRUE
				break
		if(!blocked)
			found_position = TRUE
			break
	if(!found_position)
		qdel(T)
		log_world("RW structures: could not find a position for the starting ancient danger in cell [x],[y].")
		return FALSE
	var/template_width = T.width
	var/template_height = T.height
	var/turf/placement = locate(BL.x + place_x - 1, BL.y + place_y - 1, BL.z)
	var/list/bounds = placement ? T.load(placement, centered = FALSE) : null
	qdel(T)
	if(!bounds)
		log_world("RW structures: failed to load the starting ancient danger in cell [x],[y].")
		return FALSE
	ancient_danger_generated = TRUE
	structure_placement_plan += list(list(
		"id" = "ancient_danger",
		"name" = "Ancient danger",
		"template_path" = template_path,
		"x" = place_x,
		"y" = place_y,
		"width" = template_width,
		"height" = template_height,
		"mandatory" = TRUE
	))
	return TRUE

/datum/planet_cell/proc/place_cell_structures(datum/turf_reservation/sub_level/target_reservation)
	if(!target_reservation || QDELETED(target_reservation))
		return FALSE
	if(structures_generated)
		return TRUE

	var/turf/BL = target_reservation.get_inner_bottom_left_turf()
	if(!BL)
		log_world("RW structures: cell [x],[y] has no inner placement origin.")
		return FALSE

	create_structure_placement_plan()
	var/success_count = 0
	for(var/list/entry as anything in structure_placement_plan)
		var/template_type = text2path(entry["template_path"])
		if(!template_type || !ispath(template_type, /datum/map_template))
			continue
		var/datum/map_template/T = new template_type
		if(!T || T.width <= 0 || T.height <= 0)
			qdel(T)
			continue
		var/turf/placement = locate(BL.x + entry["x"] - 1, BL.y + entry["y"] - 1, BL.z)
		if(!placement)
			log_world("RW structures: no turf for '[entry["id"]]' in cell [x],[y].")
			qdel(T)
			continue
		var/list/bounds = T.load(placement, centered = FALSE)
		if(bounds)
			success_count++
			if(entry["id"] == "ancient_danger")
				ancient_danger_generated = TRUE
		else
			log_world("RW structures: failed to load template '[entry["template_path"]]' for cell [x],[y].")
		qdel(T)

	structures_generated = TRUE
	log_world("RW structures: loaded [success_count]/[length(structure_placement_plan)] structures in cell [x],[y] (starting=[is_starting_settlement]).")
	return TRUE
