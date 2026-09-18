/datum/biome/rimworld/sea_ice
	parent_type = /datum/biome/rimworld/water

	biome_key = RW_BIOME_SEA_ICE

	passable = TRUE
	passable_flying = TRUE
	loadable = TRUE

	speed_modifier = 1.15

	/// White sand is used as the visual/terrain placeholder.
	open_turf_by_height = list(
		RW_HEIGHT_BAND_KEY_0  = /turf/open/rimworld/sand/white,
		RW_HEIGHT_BAND_KEY_1  = /turf/open/rimworld/sand/white,
		RW_HEIGHT_BAND_KEY_2  = /turf/open/rimworld/sand/chalk,
		RW_HEIGHT_BAND_KEY_3  = /turf/open/rimworld/sand/white,
		RW_HEIGHT_BAND_KEY_4  = /turf/open/rimworld/sand/white,
		RW_HEIGHT_BAND_KEY_5  = /turf/open/rimworld/sand/white,
		RW_HEIGHT_BAND_KEY_6  = /turf/open/rimworld/sand/white,
		RW_HEIGHT_BAND_KEY_7  = /turf/open/rimworld/sand/chalk,
		RW_HEIGHT_BAND_KEY_8  = /turf/open/rimworld/sand/white,
		RW_HEIGHT_BAND_KEY_9  = /turf/open/rimworld/sand/white,
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
