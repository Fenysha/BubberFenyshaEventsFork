/**
 * Cell-level weather management.
 *
 * Bridges /datum/planet_cell climate (temperature, rainfall, snowfall)
 * with the global /datum/weather system so loaded sub-levels experience
 * area-scoped weather that respects local temperature.
 *
 * Weather types are string ids mapped to /datum/weather subtypes.
 */

#define RW_WEATHER_CLEAR "clear"
#define RW_WEATHER_RAIN "rain"
#define RW_WEATHER_SNOW "snow"
#define RW_WEATHER_ASH "ash"
#define RW_WEATHER_STORM "storm"
#define RW_WEATHER_FOG "fog"

/// Map string weather type → /datum/weather path (override/extend as you add subtypes)
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
 * Chooses a climate-appropriate weather id from cell temperature / precipitation.
 */
/datum/planet_cell/proc/pick_climate_weather()
	if(forced_weather_type)
		return forced_weather_type

	// Temperature thresholds roughly Celsius-like from planet climate
	var/temp = temperature
	var/rain = rainfall || 0
	var/snow = snowfall || 0
	var/precip = precipitation || 0

	if(precip < 0.15 && rain < 0.1 && snow < 0.1)
		return RW_WEATHER_CLEAR

	if(temp <= 0 || snow > rain)
		if(precip > 0.55)
			return RW_WEATHER_STORM
		return RW_WEATHER_SNOW

	if(precip > 0.7)
		return RW_WEATHER_STORM
	if(rain > 0.25 || precip > 0.35)
		return RW_WEATHER_RAIN
	if(precip > 0.2)
		return RW_WEATHER_FOG

	return RW_WEATHER_CLEAR

/**
 * Starts weather on the cell's loaded z-level using the stock weather datum.
 * area_type should cover /area/rimworld bound to this cell.
 */
/datum/planet_cell/proc/start_cell_weather(weather_id = null, intensity = null, duration = null)
	if(!is_loaded())
		return FALSE

	if(isnull(weather_id))
		weather_id = pick_climate_weather()

	if(weather_id == RW_WEATHER_CLEAR)
		return stop_cell_weather()

	var/weather_path = rw_weather_type_path(weather_id)
	if(!weather_path)
		// Soft fallback: store type for UI / ambient only
		set_weather(weather_id, intensity || 0.5, duration)
		return TRUE

	// Stop previous
	stop_cell_weather()

	var/z = reservation?.z || null
	if(isnull(z) && reservation)
		var/turf/BL = get_bottom_left_turf()
		if(BL)
			z = BL.z
	if(isnull(z))
		set_weather(weather_id, intensity || 0.5, duration)
		return FALSE

	var/list/z_list = list(z)
	var/list/weather_data = list()
	if(!isnull(duration))
		weather_data[WEATHER_FORCED_DURATION] = duration

	// Temperature of reagents / bodytemp driven by cell climate
	var/datum/weather/W = new weather_path(z_list, weather_data)
	W.weather_temperature = temperature || T20C
	if(!isnull(intensity))
		W.turf_weather_chance = clamp(intensity * 0.05, 0.002, 0.08)

	// Restrict to rimworld areas of this cell when possible
	W.area_type = /area/rimworld

	active_weather = W
	weather_type = weather_id
	weather_intensity = clamp(intensity || 0.5, 0, 1)
	if(!isnull(duration))
		weather_timer = duration
	else
		weather_timer = rand(15 MINUTES, 30 MINUTES)

	W.telegraph(weather_data)
	return TRUE

/datum/planet_cell/proc/stop_cell_weather()
	if(active_weather)
		active_weather.end()
		QDEL_NULL(active_weather)
	return clear_weather()

/**
 * Extended process_weather: climate-driven transitions + active weather tick.
 */
/datum/planet_cell/proc/process_weather_full(delta_time = 1)
	process_weather(delta_time)

	if(!is_loaded())
		return TRUE

	if(weather_timer <= 0 && !forced_weather_type)
		// Roll next weather from climate
		if(prob(8)) // ~8% chance per tick when idle
			var/next = pick_climate_weather()
			if(next != weather_type)
				start_cell_weather(next)
		return TRUE

	return TRUE

/**
 * Admin / faction control: force weather on this cell.
 */
/datum/planet_cell/proc/force_weather(weather_id, intensity = 0.6, duration = 5 MINUTES)
	forced_weather_type = (weather_id == RW_WEATHER_CLEAR) ? null : weather_id
	return start_cell_weather(weather_id, intensity, duration)

/**
 * After cell load: bind areas then optionally start ambient weather.
 */
/datum/planet_cell/proc/on_loaded_start_weather()
	if(!is_loaded())
		return
	bind_areas_to_cell()
	var/id = pick_climate_weather()
	if(id != RW_WEATHER_CLEAR)
		start_cell_weather(id, intensity = 0.35, duration = rand(90 SECONDS, 4 MINUTES))
