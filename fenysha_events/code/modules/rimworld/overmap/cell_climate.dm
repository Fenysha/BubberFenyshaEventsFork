GLOBAL_LIST_INIT(rw_climate_profiles, init_rw_climate_profiles())

/proc/init_rw_climate_profiles()
	var/list/p = list()
	p["default"] = list("offset" = 0, "season" = 1, "diurnal" = 7)
	p[RW_BIOME_OCEAN] = list("offset" = 2, "season" = 0.35, "diurnal" = 2)
	p[RW_BIOME_SEA_ICE] = list("offset" = -22, "season" = 0.6, "diurnal" = 3)
	p[RW_BIOME_DESERT] = list("offset" = 7, "season" = 0.8, "diurnal" = 20)
	p[RW_BIOME_TUNDRA] = list("offset" = -6, "season" = 1.2, "diurnal" = 5)
	p[RW_BIOME_SNOW] = list("offset" = -14, "season" = 1.0, "diurnal" = 5)
	p[RW_BIOME_MOUNTAINS] = list("offset" = -5, "season" = 1.0, "diurnal" = 10)
	p[RW_BIOME_BEACH] = list("offset" = 1, "season" = 0.6, "diurnal" = 4)
	p[RW_BIOME_TAIGA] = list("offset" = -4, "season" = 1.3, "diurnal" = 6)
	p[RW_BIOME_TEMPERATE_FOREST] = list("offset" = 0, "season" = 1.0, "diurnal" = 6)
	p[RW_BIOME_GRASSLAND] = list("offset" = 1, "season" = 1.0, "diurnal" = 9)
	p[RW_BIOME_SAVANNA] = list("offset" = 3, "season" = 0.7, "diurnal" = 11)
	p[RW_BIOME_TROPICAL_FOREST] = list("offset" = 2, "season" = 0.4, "diurnal" = 5)
	p[RW_BIOME_RAINFOREST] = list("offset" = 1, "season" = 0.35, "diurnal" = 4)
	return p


/// Annual mean (C) at the equator and at the pole for a "neutral" biome (offset 0).
#define RW_CLIMATE_EQUATOR_MEAN_C 28
#define RW_CLIMATE_POLE_MEAN_C -24
/// Extra cooling that only bites near the pole: subtracted as EXTRA * (lat/90)^EXP.
/// Pole mean becomes -24 - 36 = -60; with biome offset, winter and night the coldest point reaches ~-100.
#define RW_CLIMATE_POLAR_EXTRA_C 36
#define RW_CLIMATE_POLAR_EXP 5
/// C per point of the planet's temperature slider (-5..5). Keeps ice/desert presets meaningful.
#define RW_CLIMATE_SLIDER_C 2.5


/proc/rw_latitude_mean_celsius(lat_deg)
	lat_deg = clamp(abs(lat_deg), 0, 90)
	var/base = LERP(RW_CLIMATE_POLE_MEAN_C, RW_CLIMATE_EQUATOR_MEAN_C, cos(lat_deg))
	return base - RW_CLIMATE_POLAR_EXTRA_C * ((lat_deg / 90) ** RW_CLIMATE_POLAR_EXP)

/datum/planet_cell
	var/annual_mean_c
	var/season_amplitude_c = 8
	var/diurnal_amplitude_c = 7
	var/climate_ready = FALSE

	/// Temperature event (cold snap / heat wave) currently pushing the temperature, C.
	var/temp_event_offset = 0
	var/temp_event_name
	/// Deciseconds left. 0 = none.
	var/temp_event_timer = 0

	/// Added by the active weather
	var/weather_temp_offset = 0

	var/cached_outdoor_temp
	var/cached_outdoor_temp_time = -999

	/// The season factor only changes once a day, so it is cached per day_of_year.
	var/cached_season_day = -1
	var/cached_season_factor = 0


/**
 * Climate is derived from three things only:
 *   latitude -> annual mean, season amplitude, day/night swing
 *   biome    -> offset, season scale, diurnal swing (rw_climate_profiles)
 *   planet   -> optional global shift from the temperature slider
 * Season and time of day are applied on top in get_outdoor_temperature().
 */
/datum/planet_cell/proc/ensure_climate()
	if(climate_ready)
		return
	climate_ready = TRUE
	var/biome_id = get_biome()
	var/list/profile = (biome_id && GLOB.rw_climate_profiles[biome_id]) || GLOB.rw_climate_profiles["default"]
	if(!profile)
		profile = list("offset" = 0, "season" = 1, "diurnal" = 7)

	var/lat_deg = clamp(abs(isnum(latitude) ? latitude : 0), 0, 90)

	var/mean = rw_latitude_mean_celsius(lat_deg) + profile["offset"]
	if(planet)
		mean += planet.slider_temperature * RW_CLIMATE_SLIDER_C
	annual_mean_c = clamp(mean, RW_CLIMATE_MIN_C, RW_CLIMATE_MAX_C)

	season_amplitude_c = (2 + 20 * sin(lat_deg)) * profile["season"]
	diurnal_amplitude_c = profile["diurnal"] * LERP(0.45, 1.0, clamp(lat_deg / 50, 0, 1))

/datum/planet_cell/proc/get_annual_mean_temperature()
	ensure_climate()
	return annual_mean_c


/datum/planet_cell/proc/get_season_factor()
	var/day = SSrimworld_planetmap?.day_of_year || 1
	if(day == cached_season_day)
		return cached_season_factor
	var/year_len = (isnum(RW_DAYS_PER_YEAR) && RW_DAYS_PER_YEAR) ? RW_DAYS_PER_YEAR : 60
	var/peak = 23
	if((latitude || 0) < 0)
		peak = MODULUS(peak + year_len / 2, year_len)
	cached_season_day = day
	cached_season_factor = cos(360 * (day - peak) / year_len)
	return cached_season_factor


/datum/planet_cell/proc/get_day_cycle_factor()
	// Hottest at 14:30 local solar time, coldest at 02:30.
	return cos(360 * (get_solar_hour() - 14.5) / 24)

/**
 * The temperature (C) of the open air in this cell right now.
 * Cached for a few seconds because mobs, zones and UI all ask for it.
 */
/datum/planet_cell/proc/get_outdoor_temperature()
	if(world.time < cached_outdoor_temp_time + 5 SECONDS && !isnull(cached_outdoor_temp))
		return cached_outdoor_temp
	ensure_climate()
	var/diurnal = diurnal_amplitude_c * get_weather_diurnal_mult()
	var/temp = annual_mean_c \
		+ get_season_factor() * season_amplitude_c \
		+ get_day_cycle_factor() * diurnal \
		+ weather_temp_offset \
		+ temp_event_offset
	cached_outdoor_temp = clamp(temp, RW_CLIMATE_MIN_C, RW_CLIMATE_MAX_C + 15)
	cached_outdoor_temp_time = world.time
	return cached_outdoor_temp

/datum/planet_cell/proc/invalidate_outdoor_temperature()
	cached_outdoor_temp_time = -999

/**
 * Cold snaps and heat waves. Rolled from process_environment().
 * Probability is expressed per real second so it does not depend on subsystem wait.
 */
/datum/planet_cell/proc/process_temperature_events(delta_ds)
	if(temp_event_timer > 0)
		temp_event_timer = max(0, temp_event_timer - delta_ds)
		if(temp_event_timer <= 0)
			temp_event_offset = 0
			temp_event_name = null
			invalidate_outdoor_temperature()
		return

	var/chance = (delta_ds / 10) / (40 * 60)
	if(rand() >= chance)
		return
	ensure_climate()
	var/warm_bias = clamp(0.5 + get_season_factor() * 0.3, 0.1, 0.9)
	var/hot = rand() < warm_bias
	if(hot && annual_mean_c > 38)
		hot = FALSE
	if(!hot && annual_mean_c < -90)
		hot = TRUE
	var/magnitude = rand(10, 22)
	temp_event_offset = hot ? magnitude : -magnitude
	temp_event_name = hot ? "heat wave" : "cold snap"
	temp_event_timer = rand(4 MINUTES, 12 MINUTES)
	invalidate_outdoor_temperature()

/datum/planet_cell/proc/force_temperature_event(offset, duration = 6 MINUTES, name = null)
	temp_event_offset = offset
	temp_event_timer = duration
	temp_event_name = name || (offset >= 0 ? "heat wave" : "cold snap")
	invalidate_outdoor_temperature()

/datum/planet_cell/proc/reset_climate()
	climate_ready = FALSE
	invalidate_outdoor_temperature()


/datum/planet_cell/proc/debug_climate()
	ensure_climate()
	return "biome=[get_biome()] lat=[latitude] mean=[round(annual_mean_c, 0.1)] season=[round(get_season_factor(), 0.01)]*[round(season_amplitude_c, 0.1)] day=[round(get_day_cycle_factor(), 0.01)]*[round(diurnal_amplitude_c, 0.1)] weather=[weather_temp_offset] event=[temp_event_offset] => [round(get_outdoor_temperature(), 0.1)]C"
