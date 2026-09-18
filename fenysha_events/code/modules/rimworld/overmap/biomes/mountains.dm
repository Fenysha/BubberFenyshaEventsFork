/datum/biome/rimworld/mountains
	parent_type = /datum/biome/rimworld/land

	biome_key = RW_BIOME_MOUNTAINS

	speed_modifier = 2.0

	open_turf_by_height = list(
		RW_HEIGHT_BAND_KEY_0  = /turf/open/rimworld/rock/auto,
		RW_HEIGHT_BAND_KEY_1  = /turf/open/rimworld/rock/auto,
		RW_HEIGHT_BAND_KEY_2  = /turf/open/rimworld/rock/auto,
		RW_HEIGHT_BAND_KEY_3  = /turf/open/rimworld/rock/auto,
		RW_HEIGHT_BAND_KEY_4  = /turf/open/rimworld/rock/auto,
		RW_HEIGHT_BAND_KEY_5  = /turf/open/rimworld/rock/auto,
		RW_HEIGHT_BAND_KEY_6  = /turf/open/rimworld/rock/auto,
		RW_HEIGHT_BAND_KEY_7  = /turf/open/rimworld/rock/auto,
		RW_HEIGHT_BAND_KEY_8  = /turf/open/rimworld/rock/auto,
		RW_HEIGHT_BAND_KEY_9  = /turf/open/rimworld/rock/auto,
		RW_HEIGHT_BAND_KEY_10 = /turf/open/rimworld/rock/auto,
	)

	open_turf_by_height_transition = list(
		RW_HEIGHT_BAND_KEY_0  = /turf/open/rimworld/rock/auto,
		RW_HEIGHT_BAND_KEY_1  = /turf/open/rimworld/rock/auto,
		RW_HEIGHT_BAND_KEY_2  = /turf/open/rimworld/rock/auto,
		RW_HEIGHT_BAND_KEY_3  = /turf/open/rimworld/rock/auto,
		RW_HEIGHT_BAND_KEY_4  = /turf/open/rimworld/rock/auto,
		RW_HEIGHT_BAND_KEY_5  = /turf/open/rimworld/rock/auto,
		RW_HEIGHT_BAND_KEY_6  = /turf/open/rimworld/rock/auto,
		RW_HEIGHT_BAND_KEY_7  = /turf/open/rimworld/rock/auto,
		RW_HEIGHT_BAND_KEY_8  = /turf/open/rimworld/rock/auto,
		RW_HEIGHT_BAND_KEY_9  = /turf/open/rimworld/rock/auto,
		RW_HEIGHT_BAND_KEY_10 = /turf/open/rimworld/rock/auto,
	)

	closed_turf_by_height = list(
		RW_HEIGHT_BAND_KEY_SOLID = /turf/closed/rw_wall/rock/auto,
	)

	closed_turf_by_height_transition = list(
		RW_HEIGHT_BAND_KEY_SOLID = /turf/closed/rw_wall/rock/auto,
	)

	open_turf_type = /turf/open/rimworld/rock/auto
	closed_turf_type = /turf/closed/rw_wall/rock/auto


/datum/biome/rimworld/snow
	parent_type = /datum/biome/rimworld/land

	biome_key = RW_BIOME_SNOW

	speed_modifier = 1.4

	open_turf_by_height = list(
		RW_HEIGHT_BAND_KEY_0  = /turf/open/rimworld/sand/white,
		RW_HEIGHT_BAND_KEY_1  = /turf/open/rimworld/sand/white,
		RW_HEIGHT_BAND_KEY_2  = /turf/open/rimworld/sand/chalk,
		RW_HEIGHT_BAND_KEY_3  = /turf/open/rimworld/sand/white,
		RW_HEIGHT_BAND_KEY_4  = /turf/open/rimworld/sand/white,
		RW_HEIGHT_BAND_KEY_5  = /turf/open/rimworld/sand/chalk,
		RW_HEIGHT_BAND_KEY_6  = /turf/open/rimworld/sand/white,
		RW_HEIGHT_BAND_KEY_7  = /turf/open/rimworld/sand/chalk,
		RW_HEIGHT_BAND_KEY_8  = /turf/open/rimworld/sand/white,
		RW_HEIGHT_BAND_KEY_9  = /turf/open/rimworld/sand/chalk,
		RW_HEIGHT_BAND_KEY_10 = /turf/open/rimworld/sand/white,
	)

	open_turf_by_height_transition = list(
		RW_HEIGHT_BAND_KEY_0  = /turf/open/rimworld/sand/chalk,
		RW_HEIGHT_BAND_KEY_1  = /turf/open/rimworld/sand/white,
		RW_HEIGHT_BAND_KEY_2  = /turf/open/rimworld/sand/chalk,
		RW_HEIGHT_BAND_KEY_3  = /turf/open/rimworld/sand/white,
		RW_HEIGHT_BAND_KEY_4  = /turf/open/rimworld/sand/chalk,
		RW_HEIGHT_BAND_KEY_5  = /turf/open/rimworld/sand/white,
		RW_HEIGHT_BAND_KEY_6  = /turf/open/rimworld/sand/chalk,
		RW_HEIGHT_BAND_KEY_7  = /turf/open/rimworld/sand/white,
		RW_HEIGHT_BAND_KEY_8  = /turf/open/rimworld/sand/chalk,
		RW_HEIGHT_BAND_KEY_9  = /turf/open/rimworld/sand/white,
		RW_HEIGHT_BAND_KEY_10 = /turf/open/rimworld/sand/chalk,
	)

	open_turf_type = /turf/open/rimworld/sand/white
