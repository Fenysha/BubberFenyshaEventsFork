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
			return /datum/weather/particle/rain_storm
		if(RW_WEATHER_SNOW)
			return /datum/weather/snow_storm
		if(RW_WEATHER_ASH)
			return /datum/weather/sand_storm
		if(RW_WEATHER_STORM)
			return /datum/weather/particle/rain_storm
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
	var/min_duration = 4 MINUTES
	var/max_duration = 10 MINUTES
	var/min_intensity = 0.3
	var/max_intensity = 0.8

/// Relative chance that this weather is picked next in `cell`. 0 = impossible.
/datum/rw_weather_def/proc/get_weight(datum/planet_cell/cell, outdoor_temp, precip, rain, snow, humidity)
	return 0

/datum/rw_weather_def/clear
	id = RW_WEATHER_CLEAR
	name = "Clear"
	min_duration = 6 MINUTES
	max_duration = 16 MINUTES
	min_intensity = 0
	max_intensity = 0

/datum/rw_weather_def/clear/get_weight(datum/planet_cell/cell, outdoor_temp, precip, rain, snow, humidity)
	return 3 + (1 - precip) * 9

/datum/rw_weather_def/cloudy
	id = RW_WEATHER_CLOUDY
	name = "Overcast"
	temp_offset = -1.5
	diurnal_mult = 0.55
	min_intensity = 0.2
	max_intensity = 0.5

/datum/rw_weather_def/cloudy/get_weight(datum/planet_cell/cell, outdoor_temp, precip, rain, snow, humidity)
	return 1.5 + precip * 5 + humidity * 1.5

/datum/rw_weather_def/rain
	id = RW_WEATHER_RAIN
	name = "Rain"
	temp_offset = -3
	exposure_offset = -4
	diurnal_mult = 0.4

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
	min_duration = 2 MINUTES
	max_duration = 6 MINUTES
	min_intensity = 0.7
	max_intensity = 1

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
	min_duration = 2 MINUTES
	max_duration = 5 MINUTES
	min_intensity = 0.5
	max_intensity = 1

/datum/rw_weather_def/sandstorm/get_weight(datum/planet_cell/cell, outdoor_temp, precip, rain, snow, humidity)
	if(cell.get_biome() != RW_BIOME_DESERT || precip > 0.3)
		return 0
	return 1.5

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
	return D.exposure_offset * max(weather_intensity, 0.35)

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
/datum/planet_cell/proc/start_cell_weather(weather_id = null, intensity = null, duration = null)
	if(!is_loaded())
		return FALSE

	if(isnull(weather_id))
		weather_id = pick_climate_weather()

	var/datum/rw_weather_def/D = GLOB.rw_weather_defs[weather_id] || GLOB.rw_weather_defs[RW_WEATHER_CLEAR]
	if(isnull(intensity))
		intensity = D.max_intensity > D.min_intensity ? LERP(D.min_intensity, D.max_intensity, rand()) : D.min_intensity
	if(isnull(duration))
		duration = rand(D.min_duration, D.max_duration)

	// Tear down the previous visual weather first.
	if(active_weather)
		active_weather.end()
		QDEL_NULL(active_weather)

	set_weather(weather_id, intensity, duration)
	sync_weather_temperature()

	var/weather_path = rw_weather_type_path(weather_id)
	if(!weather_path)
		return TRUE // state-only weather (clear / overcast)

	var/z = reservation?.z || null
	if(isnull(z))
		var/turf/BL = get_bottom_left_turf()
		if(BL)
			z = BL.z
	if(isnull(z))
		return FALSE

	var/list/weather_data = list()
	weather_data[WEATHER_FORCED_DURATION] = duration

	var/datum/weather/W = new weather_path(list(z), weather_data)
	W.weather_temperature = RW_TO_K(get_outdoor_temperature())
	W.turf_weather_chance = clamp(intensity * 0.05, 0.002, 0.08)
	W.area_type = /area/rimworld

	active_weather = W
	W.telegraph(weather_data)
	return TRUE

/datum/planet_cell/proc/stop_cell_weather()
	if(active_weather)
		active_weather.end()
		QDEL_NULL(active_weather)
	clear_weather()
	sync_weather_temperature()
	return TRUE

/**
 * Driven by SSrw_environment. delta_ds in deciseconds.
 */
/datum/planet_cell/proc/process_environment(delta_ds)
	if(!is_loaded())
		return FALSE

	process_temperature_events(delta_ds)

	// Keep an active weather's reagent temperature in step with the day cycle.
	if(active_weather)
		active_weather.weather_temperature = RW_TO_K(get_outdoor_temperature())

	if(weather_timer > 0)
		weather_timer = max(0, weather_timer - delta_ds)
		if(weather_timer > 0)
			return TRUE

	// Timer ran out: the forced override ends, then the climate picks what comes next.
	forced_weather_type = null
	var/next = pick_climate_weather()
	start_cell_weather(next)
	return TRUE

/// Admin / scenario control.
/datum/planet_cell/proc/force_weather(weather_id, intensity = 0.6, duration = 5 MINUTES)
	forced_weather_type = (weather_id == RW_WEATHER_CLEAR) ? null : weather_id
	return start_cell_weather(weather_id, intensity, duration)

/**
 * After cell load: bind areas, roll the first weather and join the environment subsystem.
 */
/datum/planet_cell/proc/on_loaded_start_weather()
	if(!is_loaded())
		return
	bind_areas_to_cell()
	ensure_climate()
	SSrw_environment.register_cell(src)
	start_cell_weather(pick_climate_weather(), duration = rand(90 SECONDS, 4 MINUTES))

/// One-line description for debug / UI.
/datum/planet_cell/proc/get_climate_summary()
	var/datum/rw_weather_def/D = get_weather_def()
	var/temp_text = "[round(get_outdoor_temperature(), 0.1)]C (mean [round(get_annual_mean_temperature(), 0.1)]C)"
	return "[D.name], [temp_text][temp_event_name ? ", [temp_event_name]" : ""]"
