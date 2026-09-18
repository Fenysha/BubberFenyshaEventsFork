/datum/biome/rimworld/tundra
	parent_type = /datum/biome/rimworld/land

	biome_key = RW_BIOME_TUNDRA

	speed_modifier = 1.15

	open_turf_by_height = list(
		RW_HEIGHT_BAND_KEY_0  = /turf/open/rimworld/dirt,
		RW_HEIGHT_BAND_KEY_1  = /turf/open/rimworld/dirt,
		RW_HEIGHT_BAND_KEY_2  = /turf/open/rimworld/grass,
		RW_HEIGHT_BAND_KEY_3  = /turf/open/rimworld/grass,
		RW_HEIGHT_BAND_KEY_4  = /turf/open/rimworld/grass/forest,
		RW_HEIGHT_BAND_KEY_5  = /turf/open/rimworld/grass/forest/light,
		RW_HEIGHT_BAND_KEY_6  = /turf/open/rimworld/sand/chalk,
		RW_HEIGHT_BAND_KEY_7  = /turf/open/rimworld/sand/white,
		RW_HEIGHT_BAND_KEY_8  = /turf/open/rimworld/sand/white,
		RW_HEIGHT_BAND_KEY_9  = /turf/open/rimworld/sand/white,
		RW_HEIGHT_BAND_KEY_10 = /turf/open/rimworld/sand/white,
	)

	open_turf_by_height_transition = list(
		RW_HEIGHT_BAND_KEY_0  = /turf/open/rimworld/dirt,
		RW_HEIGHT_BAND_KEY_1  = /turf/open/rimworld/grass,
		RW_HEIGHT_BAND_KEY_2  = /turf/open/rimworld/dirt,
		RW_HEIGHT_BAND_KEY_3  = /turf/open/rimworld/grass/forest,
		RW_HEIGHT_BAND_KEY_4  = /turf/open/rimworld/grass/forest/light,
		RW_HEIGHT_BAND_KEY_5  = /turf/open/rimworld/sand/chalk,
		RW_HEIGHT_BAND_KEY_6  = /turf/open/rimworld/sand/white,
		RW_HEIGHT_BAND_KEY_7  = /turf/open/rimworld/sand/chalk,
		RW_HEIGHT_BAND_KEY_8  = /turf/open/rimworld/sand/white,
		RW_HEIGHT_BAND_KEY_9  = /turf/open/rimworld/sand/chalk,
		RW_HEIGHT_BAND_KEY_10 = /turf/open/rimworld/sand/white,
	)

	open_turf_type = /turf/open/rimworld/dirt
