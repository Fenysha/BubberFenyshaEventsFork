/**
 * Returns longitude in degrees (-180 .. 180) for the tile.
 * Relies on existing get_tile_lat_lon().
 */
/datum/rimworld_planet/proc/get_longitude(x, y)
	if(!is_valid_coordinate(x, y))
		return 0
	return get_tile_lat_lon(x, y)[2]


/// Wraps degrees into -180..180.
/proc/rw_wrap_degrees(degrees)
	var/wrapped = MODULUS(degrees + 180, 360)
	if(wrapped < 0)
		wrapped += 360
	return wrapped - 180


/// Solar hour (0-24) for a signed hour angle; 12 = sun on the meridian, positive = morning side.
/proc/rw_hour_angle_to_hour(delta)
	var/hour = MODULUS(12 - delta / 15, RW_HOURS_PER_DAY)
	if(hour < 0)
		hour += RW_HOURS_PER_DAY
	return hour


/**
 * Planet-local longitude the sun is over. Mirrors the globe UI: a sun fixed in
 * world space (RW_SUN_DIRECTION) and a planet spun about its axis by rotation_angle.
 */
/datum/rimworld_planet/proc/get_sun_longitude()
	return rw_wrap_degrees(rotation_angle + RW_SUN_LONGITUDE_OFFSET)


/// Unit vector to the subsolar point in planet-local space (same frame as get_tile_center).
/datum/rimworld_planet/proc/get_sun_vector()
	var/lon = get_sun_longitude()
	var/lat = RW_SUN_LATITUDE
	return list(cos(lat) * cos(lon), sin(lat), cos(lat) * sin(lon))


/**
 * Great-circle angle from the tile to the subsolar point (0 = noon, 180 = midnight).
 * Unsigned — fine for intensity falloff, which is symmetric around noon.
 */
/datum/rimworld_planet/proc/get_solar_angle(x, y)
	if(!is_valid_coordinate(x, y))
		return 180
	var/cosine = clamp(rw_vec_dot(get_tile_center(x, y), get_sun_vector()), -1, 1)
	return arccos(cosine)


/**
 * Signed longitude offset of the tile from the subsolar meridian, in -180..180.
 * Positive = tile hasn't reached the sun yet (morning side), negative = tile is
 * past the sun (afternoon/evening side). Needed to recover a real 0-24h local
 * time — get_solar_angle() alone can't, since it discards this sign.
 */
/datum/rimworld_planet/proc/get_solar_hour_angle(x, y)
	return rw_wrap_degrees(get_longitude(x, y) - get_sun_longitude())


/**
 * Local solar clock hour (0-24) at the tile. Unlike get_solar_angle(), this keeps
 * the morning/afternoon sign, so sunrise- and sunset-side tiles resolve to their
 * own correct phase (and colour) instead of both collapsing onto the morning half.
 */
/datum/rimworld_planet/proc/get_solar_hour(x, y)
	return rw_hour_angle_to_hour(get_solar_hour_angle(x, y))


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
