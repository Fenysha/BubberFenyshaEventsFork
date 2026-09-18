/datum/biome/rimworld/desert
	parent_type = /datum/biome/rimworld/land

	biome_key = RW_BIOME_DESERT

	speed_modifier = 0.9

	open_turf_by_height = list(
		RW_HEIGHT_BAND_KEY_0  = /turf/open/rimworld/sand,
		RW_HEIGHT_BAND_KEY_1  = /turf/open/rimworld/sand/yellow,
		RW_HEIGHT_BAND_KEY_2  = /turf/open/rimworld/sand/orange,
		RW_HEIGHT_BAND_KEY_3  = /turf/open/rimworld/sand/red,
		RW_HEIGHT_BAND_KEY_4  = /turf/open/rimworld/sand,
		RW_HEIGHT_BAND_KEY_5  = /turf/open/rimworld/sand/yellow,
		RW_HEIGHT_BAND_KEY_6  = /turf/open/rimworld/sand/orange,
		RW_HEIGHT_BAND_KEY_7  = /turf/open/rimworld/sand/red,
		RW_HEIGHT_BAND_KEY_8  = /turf/open/rimworld/sand/black,
		RW_HEIGHT_BAND_KEY_9  = /turf/open/rimworld/sand/dark,
		RW_HEIGHT_BAND_KEY_10 = /turf/open/rimworld/sand/black,
	)

	open_turf_by_height_transition = list(
		RW_HEIGHT_BAND_KEY_0  = /turf/open/rimworld/sand/white,
		RW_HEIGHT_BAND_KEY_1  = /turf/open/rimworld/sand,
		RW_HEIGHT_BAND_KEY_2  = /turf/open/rimworld/sand/yellow,
		RW_HEIGHT_BAND_KEY_3  = /turf/open/rimworld/sand/orange,
		RW_HEIGHT_BAND_KEY_4  = /turf/open/rimworld/sand/red,
		RW_HEIGHT_BAND_KEY_5  = /turf/open/rimworld/sand,
		RW_HEIGHT_BAND_KEY_6  = /turf/open/rimworld/sand/yellow,
		RW_HEIGHT_BAND_KEY_7  = /turf/open/rimworld/sand/orange,
		RW_HEIGHT_BAND_KEY_8  = /turf/open/rimworld/sand/dark,
		RW_HEIGHT_BAND_KEY_9  = /turf/open/rimworld/sand/black,
		RW_HEIGHT_BAND_KEY_10 = /turf/open/rimworld/sand/dark,
	)

	open_turf_type = /turf/open/rimworld/sand
