#define RW_WEATHER_CLEAR "clear"
#define RW_WEATHER_CLOUDY "cloudy"
#define RW_WEATHER_RAIN "rain"
#define RW_WEATHER_SNOW "snow"
#define RW_WEATHER_ASH "ash"
#define RW_WEATHER_STORM "storm"
#define RW_WEATHER_FOG "fog"

/// Map string weather id -> stock /datum/weather path. null = state only (no visual datum).
/proc/rw_weather_type_path(weather_id)
	switch(weather_id)
		if(RW_WEATHER_RAIN)
			return /datum/weather/particle/rain_storm/rw_cell_directional
		if(RW_WEATHER_SNOW)
			return /datum/weather/particle/rw_cell_snow
		if(RW_WEATHER_ASH)
			return /datum/weather/particle/rw_cell_sandstorm
		if(RW_WEATHER_STORM)
			return /datum/weather/particle/rain_storm/rw_cell_directional/storm
		if(RW_WEATHER_FOG)
			return /datum/weather/fog
	return null

/**
 * Planet cells store humidity as a categorical level (RW_CLIMATE_LOW/MEDIUM/HIGH, may be a text like "2"),
 * while the weather model needs a 0..1 fraction. Numbers in 0..1 pass through unchanged.
 */
/proc/rw_climate_level_to_fraction(level)
	if(isnull(level))
		return 0
	if(istext(level))
		switch(lowertext(level))
			if("low")
				return 0.15
			if("medium", "mid")
				return 0.5
			if("high")
				return 0.85
		level = text2num(level)
		if(isnull(level))
			return 0
	if(!isnum(level))
		return 0
	if(level >= 0 && level <= 1)
		return level
	// Discrete 0/1/2 level.
	return clamp((level + 0.5) / 3, 0, 1)

GLOBAL_LIST_INIT(rw_weather_defs, init_rw_weather_defs())

/proc/init_rw_weather_defs()
	var/list/out = list()
	for(var/path in subtypesof(/datum/rw_weather_def))
		var/datum/rw_weather_def/D = new path
		out[D.id] = D
	return out

/datum/rw_weather_def
	var/id
	var/name = "Unknown"
	/// C added to the outdoor temperature while active.
	var/temp_offset = 0
	/// Extra C felt by mobs standing outdoors (wind / wet). Not added to zone air.
	var/exposure_offset = 0
	/// Multiplier of the day/night swing: clouds hold heat in at night and block the sun by day.
	var/diurnal_mult = 1
	/// Weather lifetime, measured in full planetary days rather than world.time.
	var/min_duration_days = 0.2
	var/max_duration_days = 0.8
	var/min_intensity = 0.3
	var/max_intensity = 0.8
	/// Wind range in km/h while this weather is active.
	var/min_wind_speed = 2
	var/max_wind_speed = 18

/// Relative chance that this weather is picked next in `cell`. 0 = impossible.
/datum/rw_weather_def/proc/get_weight(datum/planet_cell/cell, outdoor_temp, precip, rain, snow, humidity)
	return 0

/datum/rw_weather_def/clear
	id = RW_WEATHER_CLEAR
	name = "Clear"
	min_duration_days = 0.35
	max_duration_days = 1.1
	min_intensity = 0
	max_intensity = 0
	min_wind_speed = 1
	max_wind_speed = 14

/datum/rw_weather_def/clear/get_weight(datum/planet_cell/cell, outdoor_temp, precip, rain, snow, humidity)
	return 3 + (1 - precip) * 9

/datum/rw_weather_def/cloudy
	id = RW_WEATHER_CLOUDY
	name = "Overcast"
	temp_offset = -1.5
	diurnal_mult = 0.55
	min_intensity = 0.2
	max_intensity = 0.5
	min_duration_days = 0.25
	max_duration_days = 0.9
	min_wind_speed = 4
	max_wind_speed = 24

/datum/rw_weather_def/cloudy/get_weight(datum/planet_cell/cell, outdoor_temp, precip, rain, snow, humidity)
	return 1.5 + precip * 5 + humidity * 1.5

/datum/rw_weather_def/rain
	id = RW_WEATHER_RAIN
	name = "Rain"
	temp_offset = -3
	exposure_offset = -4
	diurnal_mult = 0.4
	min_duration_days = 0.08
	max_duration_days = 0.35
	min_wind_speed = 8
	max_wind_speed = 32

/datum/rw_weather_def/rain/get_weight(datum/planet_cell/cell, outdoor_temp, precip, rain, snow, humidity)
	// Rain only above freezing.
	if(outdoor_temp <= 1 || precip < 0.15)
		return 0
	return precip * 9 * (0.35 + rain)

/datum/rw_weather_def/snow
	id = RW_WEATHER_SNOW
	name = "Snow"
	temp_offset = -2
	exposure_offset = -5
	diurnal_mult = 0.45
	min_duration_days = 0.08
	max_duration_days = 0.4
	min_wind_speed = 6
	max_wind_speed = 28

/datum/rw_weather_def/snow/get_weight(datum/planet_cell/cell, outdoor_temp, precip, rain, snow, humidity)
	if(outdoor_temp > 2)
		return 0
	// Dry polar air still snows a little.
	return max(0.4, precip * 9 * (0.35 + snow))

/datum/rw_weather_def/storm
	id = RW_WEATHER_STORM
	name = "Storm"
	temp_offset = -5
	exposure_offset = -9
	diurnal_mult = 0.3
	min_duration_days = 0.025
	max_duration_days = 0.12
	min_intensity = 0.7
	max_intensity = 1
	min_wind_speed = 45
	max_wind_speed = 110

/datum/rw_weather_def/storm/get_weight(datum/planet_cell/cell, outdoor_temp, precip, rain, snow, humidity)
	if(precip < 0.5)
		return 0
	return (precip - 0.45) * 7

/datum/rw_weather_def/fog
	id = RW_WEATHER_FOG
	name = "Fog"
	temp_offset = -1
	diurnal_mult = 0.7
	min_intensity = 0.3
	max_intensity = 0.7
	min_duration_days = 0.1
	max_duration_days = 0.45
	min_wind_speed = 0
	max_wind_speed = 12

/datum/rw_weather_def/fog/get_weight(datum/planet_cell/cell, outdoor_temp, precip, rain, snow, humidity)
	if(outdoor_temp < -8 || outdoor_temp > 22)
		return 0
	return humidity * (0.3 + precip) * 3

/datum/rw_weather_def/sandstorm
	id = RW_WEATHER_ASH
	name = "Sandstorm"
	temp_offset = 2
	exposure_offset = -3
	diurnal_mult = 0.8
	min_duration_days = 0.04
	max_duration_days = 0.18
	min_intensity = 0.5
	max_intensity = 1
	min_wind_speed = 20
	max_wind_speed = 75

/datum/rw_weather_def/sandstorm/get_weight(datum/planet_cell/cell, outdoor_temp, precip, rain, snow, humidity)
	if(cell.get_biome() != RW_BIOME_DESERT || precip > 0.3)
		return 0
	return 1.5

/**
 * Fractional in-game day. Weather continues from the planet's calendar and
 * therefore freezes naturally when calendar progression is paused.
 */
/proc/rw_get_planet_elapsed_days()
	if(!SSrimworld_planetmap)
		return 0
	return SSrimworld_planetmap.total_days + (SSrimworld_planetmap.rotation_angle / 360)

/datum/looping_sound/rw_cell_wind
	mid_sounds = list(
		'sound/ambience/weather/ashstorm/outside/weak_mid1.ogg' = 1,
		'sound/ambience/weather/ashstorm/outside/weak_mid2.ogg' = 1,
		'sound/ambience/weather/ashstorm/outside/weak_mid3.ogg' = 1,
	)
	mid_length = 8 SECONDS
	volume = 25
	extra_range = 24
	pressure_affected = FALSE
	use_reverb = FALSE
	ignore_walls = FALSE

/datum/planet_cell/proc/get_wind_direction_name()
	switch(wind_direction)
		if(NORTH)
			return "North"
		if(SOUTH)
			return "South"
		if(EAST)
			return "East"
		if(WEST)
			return "West"
		if(NORTHEAST)
			return "North-East"
		if(NORTHWEST)
			return "North-West"
		if(SOUTHEAST)
			return "South-East"
		if(SOUTHWEST)
			return "South-West"
	return "Variable"

/datum/planet_cell/proc/get_wind_strength_label()
	if(wind_speed < 2)
		return "Calm"
	if(wind_speed < 6)
		return "Light air"
	if(wind_speed < 12)
		return "Light breeze"
	if(wind_speed < 20)
		return "Gentle breeze"
	if(wind_speed < 29)
		return "Moderate breeze"
	if(wind_speed < 39)
		return "Fresh breeze"
	if(wind_speed < 50)
		return "Strong breeze"
	if(wind_speed < 62)
		return "Near gale"
	if(wind_speed < 75)
		return "Gale"
	if(wind_speed < 89)
		return "Severe gale"
	if(wind_speed < 103)
		return "Storm"
	return "Violent storm"

/datum/planet_cell/proc/apply_wind_to_active_weather()
	if(!istype(active_weather, /datum/weather/particle))
		return
	var/datum/weather/particle/P = active_weather
	if(!P.uses_cell_wind)
		return
	var/dx = 0
	var/dy = 0
	switch(wind_direction)
		if(NORTH)
			dy = -1
		if(SOUTH)
			dy = 1
		if(EAST)
			dx = -1
		if(WEST)
			dx = 1
		if(NORTHEAST)
			dx = -0.707
			dy = -0.707
		if(NORTHWEST)
			dx = 0.707
			dy = -0.707
		if(SOUTHEAST)
			dx = -0.707
			dy = 0.707
		if(SOUTHWEST)
			dx = 0.707
			dy = 0.707
	// wind_direction describes where the wind comes from, so particles travel in the opposite direction.
	// Scale the force separately from rain intensity so strong winds visibly push the particles harder.
	var/wind_scale = clamp(wind_speed / 35, 0.2, 2)
	P.cell_wind_vector = list(dx * wind_scale, dy * wind_scale)
	P.wind_sign = dx ? (dx > 0 ? 1 : -1) : (dy ? (dy > 0 ? 1 : -1) : 1)
	P.optimal_severity = clamp(round(LERP(12, 90, clamp(wind_speed / 110, 0, 1))), P.min_severity, P.max_severity)
	if(P.severity > 0)
		P.animate_severity(P.severity)

/datum/planet_cell/proc/refresh_cell_wind(force = FALSE)
	var/datum/rw_weather_def/D = get_weather_def()
	if(!D)
		return
	var/current_day = rw_get_planet_elapsed_days()
	if(!force && wind_next_shift_game_day > current_day)
		return
	if(force || prob(65))
		var/list/directions = list(NORTH, NORTHEAST, EAST, SOUTHEAST, SOUTH, SOUTHWEST, WEST, NORTHWEST)
		wind_direction = pick(directions)
	wind_speed = round(LERP(D.min_wind_speed, D.max_wind_speed, rand()), 1)
	wind_next_shift_game_day = current_day + LERP(0.08, 0.22, rand())
	apply_wind_to_active_weather()
	update_wind_sound_trackers()

/datum/planet_cell/proc/stop_wind_sound_trackers()
	if(!islist(wind_sound_trackers))
		wind_sound_trackers = list()
		return
	for(var/datum/looping_sound/L as anything in wind_sound_trackers)
		if(L && !QDELETED(L))
			qdel(L)
	wind_sound_trackers.Cut()

/datum/planet_cell/proc/update_wind_sound_trackers()
	if(!is_loaded())
		stop_wind_sound_trackers()
		return
	if(!length(wind_sound_trackers))
		start_wind_sound_trackers()
	var/volume = clamp(round(LERP(12, 50, clamp(wind_speed / 100, 0, 1))), 8, 50)
	for(var/datum/looping_sound/rw_cell_wind/L as anything in wind_sound_trackers)
		if(L && !QDELETED(L))
			L.volume = volume

/datum/planet_cell/proc/start_wind_sound_trackers()
	stop_wind_sound_trackers()
	if(!is_loaded())
		return FALSE
	var/turf/BL = reservation.get_inner_bottom_left_turf()
	var/turf/TR = reservation.get_inner_top_right_turf()
	if(!BL || !TR)
		return FALSE
	var/map_width = TR.x - BL.x + 1
	var/map_height = TR.y - BL.y + 1
	var/list/fractions = list(0.15, 0.5, 0.85)
	for(var/fx in fractions)
		for(var/fy in fractions)
			var/turf/T = locate(BL.x + round((map_width - 1) * fx), BL.y + round((map_height - 1) * fy), BL.z)
			if(!T)
				continue
			var/area/A = get_area(T)
			if(!istype(A, /area/rimworld) || istype(A, /area/rimworld/zone))
				continue
			var/datum/looping_sound/rw_cell_wind/L = new(T)
			L.volume = clamp(round(LERP(12, 50, clamp(wind_speed / 100, 0, 1))), 8, 50)
			L.start()
			wind_sound_trackers += L
	return length(wind_sound_trackers) > 0

/datum/planet_cell/proc/get_weather_def()
	return GLOB.rw_weather_defs[weather_type] || GLOB.rw_weather_defs[RW_WEATHER_CLEAR]

/datum/planet_cell/proc/get_weather_diurnal_mult()
	var/datum/rw_weather_def/D = get_weather_def()
	return D ? D.diurnal_mult : 1

/// Extra degrees a mob feels while standing outdoors (wind chill, wet). Scales with intensity.
/datum/planet_cell/proc/get_weather_exposure_offset()
	var/datum/rw_weather_def/D = get_weather_def()
	if(!D)
		return 0
	var/exposure = D.exposure_offset * max(weather_intensity, 0.35)
	var/air_temp = get_outdoor_temperature()
	if(air_temp < 10 && wind_speed > 5)
		exposure -= min(8, (wind_speed - 5) * 0.06 * (10 - air_temp))
	return exposure

/// Rebuilds the cached temperature offset after the weather id/intensity changed.
/datum/planet_cell/proc/sync_weather_temperature()
	var/datum/rw_weather_def/D = get_weather_def()
	weather_temp_offset = D ? D.temp_offset * max(weather_intensity, 0.35) : 0
	invalidate_outdoor_temperature()

/**
 * Chooses a weather id from the cell's real climate.
 * The *current* weather gets a persistence bonus so it does not flicker.
 */
/datum/planet_cell/proc/pick_climate_weather()
	if(forced_weather_type)
		return forced_weather_type

	// Base the decision on the temperature without the current weather's own cooling,
	// otherwise rain would "cool itself" into snow.
	ensure_climate()
	var/base_temp = annual_mean_c \
		+ get_season_factor() * season_amplitude_c \
		+ get_day_cycle_factor() * diurnal_amplitude_c \
		+ temp_event_offset

	var/precip = clamp(rw_climate_level_to_fraction(precipitation), 0, 1)
	var/rain = clamp(rw_climate_level_to_fraction(rainfall), 0, 1)
	var/snow = clamp(rw_climate_level_to_fraction(snowfall), 0, 1)
	var/hum = clamp(rw_climate_level_to_fraction(humidity), 0, 1)

	var/list/weights = list()
	var/total = 0
	for(var/id in GLOB.rw_weather_defs)
		var/datum/rw_weather_def/D = GLOB.rw_weather_defs[id]
		var/w = D.get_weight(src, base_temp, precip, rain, snow, hum)
		if(w <= 0)
			continue
		if(id == weather_type)
			w *= 1.5
		weights[id] = w
		total += w
	if(!total)
		return RW_WEATHER_CLEAR
	return pick_weight(weights)

/**
 * Starts weather on the loaded z-level. area_type covers the outdoor rimworld area;
 * protect_indoors keeps enclosed zones dry.
 */
/datum/planet_cell/proc/start_cell_weather(weather_id = null, intensity = null, duration = null, preserve_wind = FALSE)
	if(!is_loaded())
		return FALSE

	if(isnull(weather_id))
		weather_id = pick_climate_weather()
	var/datum/rw_weather_def/D = GLOB.rw_weather_defs[weather_id] || GLOB.rw_weather_defs[RW_WEATHER_CLEAR]
	if(!D)
		return FALSE
	if(isnull(intensity))
		intensity = D.max_intensity > D.min_intensity ? LERP(D.min_intensity, D.max_intensity, rand()) : D.min_intensity
	if(isnull(duration))
		duration = LERP(D.min_duration_days, D.max_duration_days, rand())

	// Remove only the visual effect; the weather state is rewritten below.
	if(active_weather)
		active_weather.end()
		QDEL_NULL(active_weather)

	set_weather(weather_id, intensity, duration)
	sync_weather_temperature()
	if(!preserve_wind || !wind_next_shift_game_day || wind_next_shift_game_day <= rw_get_planet_elapsed_days())
		refresh_cell_wind(TRUE)
	else
		update_wind_sound_trackers()

	var/weather_path = rw_weather_type_path(weather_id)
	if(!weather_path)
		return TRUE // clear / overcast are state-only weather

	var/turf/BL = get_bottom_left_turf()
	if(!BL)
		return FALSE
	var/z = BL.z

	// The cell calendar controls duration. Keep the stock visual datum alive
	// long enough that it cannot expire early on real-time world.time.
	var/list/weather_data = list()
	weather_data[WEATHER_FORCED_DURATION] = 30 DAYS

	var/datum/weather/W = new weather_path(list(z), weather_data)
	W.weather_temperature = RW_TO_K(get_outdoor_temperature())
	W.turf_weather_chance = clamp(intensity * 0.05, 0.002, 0.08)
	W.area_type = /area/rimworld
	active_weather = W
	apply_wind_to_active_weather()
	W.telegraph(weather_data)
	return TRUE

/datum/planet_cell/proc/stop_cell_weather(preserve_state = FALSE)
	if(active_weather)
		active_weather.end()
		QDEL_NULL(active_weather)
	stop_wind_sound_trackers()
	if(!preserve_state)
		forced_weather_type = null
		weather_end_game_day = 0
		clear_weather()
	sync_weather_temperature()
	return TRUE

/**
 * Called by SSrw_environment. Weather lifetime and wind shifts use in-game days,
 * while delta_ds remains available for short-lived temperature events.
 */
/datum/planet_cell/proc/process_environment(delta_ds)
	if(!is_loaded())
		return FALSE

	process_temperature_events(delta_ds)
	var/current_day = rw_get_planet_elapsed_days()

	if(active_weather)
		active_weather.weather_temperature = RW_TO_K(get_outdoor_temperature())

	refresh_cell_wind()

	if(weather_end_game_day > 0 && current_day >= weather_end_game_day)
		forced_weather_type = null
		start_cell_weather(pick_climate_weather())
	return TRUE

/// Admin / scenario control; duration is measured in planetary days.
/datum/planet_cell/proc/force_weather(weather_id, intensity = 0.6, duration = 0.15)
	if(!(weather_id in GLOB.rw_weather_defs))
		return FALSE
	forced_weather_type = (weather_id == RW_WEATHER_CLEAR) ? null : weather_id
	return start_cell_weather(weather_id, intensity, duration)

/**
 * After cell load: bind areas, resume still-active weather, or pick a new local state.
 */
/datum/planet_cell/proc/on_loaded_start_weather()
	if(!is_loaded())
		return
	bind_areas_to_cell()
	ensure_climate()
	SSrw_environment.register_cell(src)
	var/current_day = rw_get_planet_elapsed_days()
	if(weather_end_game_day > current_day)
		start_cell_weather(weather_type, weather_intensity, weather_end_game_day - current_day, TRUE)
	else
		forced_weather_type = null
		start_cell_weather(pick_climate_weather())

/datum/planet_cell/proc/get_climate_summary()
	var/datum/rw_weather_def/D = get_weather_def()
	var/temp_text = "[round(get_outdoor_temperature(), 0.1)]C (mean [round(get_annual_mean_temperature(), 0.1)]C)"
	return "[D.name], [temp_text][temp_event_name ? ", [temp_event_name]" : ""]"
