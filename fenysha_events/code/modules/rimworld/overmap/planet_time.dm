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
 * Unsigned — fine for intensity falloff, which is symmetric around noon.
 */
/datum/rimworld_planet/proc/get_solar_angle(x, y)
	return abs(get_solar_hour_angle(x, y))


/**
 * Signed angular offset of the tile from the subsolar point, in -180..180.
 * Positive = tile hasn't reached the sun yet (morning side), negative = tile is
 * past the sun (afternoon/evening side). Needed to recover a real 0-24h local
 * time — get_solar_angle() alone can't, since it discards this sign.
 */
/datum/rimworld_planet/proc/get_solar_hour_angle(x, y)
	var/lon = get_longitude(x, y)
	var/sun = get_sun_longitude()
	var/delta = lon - sun
	// Normalize to -180..180
	delta = ((delta + 180) % 360 + 360) % 360 - 180
	return delta


/**
 * Local solar clock hour (0-24) at the tile. Unlike get_solar_angle(), this keeps
 * the morning/afternoon sign, so sunrise- and sunset-side tiles resolve to their
 * own correct phase (and colour) instead of both collapsing onto the morning half.
 */
/datum/rimworld_planet/proc/get_solar_hour(x, y)
	var/delta = get_solar_hour_angle(x, y) // >0 morning, <0 afternoon
	var/hour = 12 - (delta / 180) * 12
	hour = hour % 24
	if(hour < 0)
		hour += 24
	return hour


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
