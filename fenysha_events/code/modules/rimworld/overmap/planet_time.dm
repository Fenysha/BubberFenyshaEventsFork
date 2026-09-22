/**
 * Returns longitude in degrees (-180 .. 180) for the tile.
 * Relies on existing get_tile_lat_lon().
 */
/datum/rimworld_planet/proc/get_longitude(x, y)
	if(!is_valid_coordinate(x, y))
		return 0
	return get_tile_lat_lon(x, y)[2]


/**
 * Solar longitude of the "sun" on the planet surface.
 * rotation_angle 0 = sun over longitude 0 (you can shift by a constant if needed).
 */
/datum/rimworld_planet/proc/get_sun_longitude()
	// Map 0-360 rotation → -180..180 solar long
	var/sun = rotation_angle
	if(sun > 180)
		sun -= 360
	return sun


/**
 * Angular distance from the tile to the subsolar point (0 = noon, 180 = midnight).
 */
/datum/rimworld_planet/proc/get_solar_angle(x, y)
	var/lon = get_longitude(x, y)
	var/sun = get_sun_longitude()
	var/delta = abs(lon - sun)
	if(delta > 180)
		delta = 360 - delta
	return delta


/**
 * TRUE if the tile is currently on the day side.
 * daylight_fraction = width of the day arc around noon (0.5 ≈ 12 h day).
 */
/datum/rimworld_planet/proc/is_daylight(x, y, fraction = null)
	if(isnull(fraction))
		fraction = daylight_fraction
	var/max_angle = fraction * 180 // half-width in degrees from noon
	return get_solar_angle(x, y) <= max_angle


/datum/rimworld_planet/proc/is_night(x, y, fraction = null)
	return !is_daylight(x, y, fraction)


/**
 * 0 = deep night, 1 = solar noon. Smooth cosine falloff.
 */
/datum/rimworld_planet/proc/get_sun_intensity(x, y)
	var/angle = get_solar_angle(x, y) // 0..180
	// cos from 1 at 0° to 0 at 90° and negative on night side → clamp
	return max(0, cos(angle))


/**
 * Season at coordinates (uses latitude sign for hemisphere).
 */
/datum/rimworld_planet/proc/get_season(x, y)
	var/lat = get_latitude(x, y)
	var/hemisphere = lat >= 0 ? "north" : "south"
	return SSrimworld_planetmap.get_season_for_hemisphere(hemisphere)


/**
 * Convenience wrappers that delegate to the subsystem.
 */
/datum/rimworld_planet/proc/get_calendar_data()
	return SSrimworld_planetmap.get_calendar_data()

/datum/rimworld_planet/proc/get_quadrum_name()
	return SSrimworld_planetmap.get_quadrum_name(current_quadrum)
