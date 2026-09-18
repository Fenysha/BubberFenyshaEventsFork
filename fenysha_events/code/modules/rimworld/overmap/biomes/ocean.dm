/// You can't actually create oceans and seas, or cross them - you can only fly over them.
/datum/biome/rimworld/ocean
	parent_type = /datum/biome/rimworld/water

	biome_key = RW_BIOME_OCEAN

	passable = FALSE
	passable_flying = TRUE
	loadable = FALSE

	speed_modifier = 2.0

	open_turf_by_height = list(
		RW_HEIGHT_BAND_KEY_0  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_1  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_2  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_3  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_4  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_5  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_6  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_7  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_8  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_9  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_10 = /turf/open/water,
	)

	open_turf_by_height_transition = list(
		RW_HEIGHT_BAND_KEY_0  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_1  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_2  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_3  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_4  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_5  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_6  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_7  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_8  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_9  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_10 = /turf/open/water,
	)

	open_turf_type = /turf/open/water

/datum/biome/rimworld/coast
	parent_type = /datum/biome/rimworld/land

	biome_key = RW_BIOME_COAST

	speed_modifier = 0.9

	open_turf_by_height = list(
		RW_HEIGHT_BAND_KEY_0  = /turf/open/water/beach,
		RW_HEIGHT_BAND_KEY_1  = /turf/open/water/beach,
		RW_HEIGHT_BAND_KEY_2  = /turf/open/rimworld/sand,
		RW_HEIGHT_BAND_KEY_3  = /turf/open/rimworld/sand/white,
		RW_HEIGHT_BAND_KEY_4  = /turf/open/rimworld/dirt,
		RW_HEIGHT_BAND_KEY_5  = /turf/open/rimworld/grass/forest,
		RW_HEIGHT_BAND_KEY_6  = /turf/open/rimworld/grass/forest/light,
		RW_HEIGHT_BAND_KEY_7  = /turf/open/rimworld/grass/forest,
		RW_HEIGHT_BAND_KEY_8  = /turf/open/rimworld/grass/forest/tall,
		RW_HEIGHT_BAND_KEY_9  = /turf/open/rimworld/grass/forest,
		RW_HEIGHT_BAND_KEY_10 = /turf/open/rimworld/grass/forest/light,
	)

	open_turf_by_height_transition = list(
		RW_HEIGHT_BAND_KEY_0  = /turf/open/water/beach,
		RW_HEIGHT_BAND_KEY_1  = /turf/open/rimworld/sand/white,
		RW_HEIGHT_BAND_KEY_2  = /turf/open/rimworld/sand,
		RW_HEIGHT_BAND_KEY_3  = /turf/open/rimworld/dirt,
		RW_HEIGHT_BAND_KEY_4  = /turf/open/rimworld/grass/forest,
		RW_HEIGHT_BAND_KEY_5  = /turf/open/rimworld/grass/forest/light,
		RW_HEIGHT_BAND_KEY_6  = /turf/open/rimworld/grass/forest/tall,
		RW_HEIGHT_BAND_KEY_7  = /turf/open/rimworld/grass/forest,
		RW_HEIGHT_BAND_KEY_8  = /turf/open/rimworld/grass/forest/light,
		RW_HEIGHT_BAND_KEY_9  = /turf/open/rimworld/grass/forest,
		RW_HEIGHT_BAND_KEY_10 = /turf/open/rimworld/grass/forest/light,
	)

	open_turf_type = /turf/open/rimworld/grass/forest


/datum/biome/rimworld/river
	parent_type = /datum/biome/rimworld/water

	biome_key = RW_BIOME_RIVER

	passable = FALSE
	passable_flying = TRUE
	loadable = FALSE

	speed_modifier = 1.5

	open_turf_by_height = list(
		RW_HEIGHT_BAND_KEY_0  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_1  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_2  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_3  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_4  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_5  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_6  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_7  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_8  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_9  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_10 = /turf/open/water,
	)

	open_turf_by_height_transition = list(
		RW_HEIGHT_BAND_KEY_0  = /turf/open/water/beach,
		RW_HEIGHT_BAND_KEY_1  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_2  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_3  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_4  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_5  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_6  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_7  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_8  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_9  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_10 = /turf/open/water,
	)

	open_turf_type = /turf/open/water


/datum/biome/rimworld/lake
	parent_type = /datum/biome/rimworld/water

	biome_key = RW_BIOME_LAKE

	passable = FALSE
	passable_flying = TRUE
	loadable = FALSE

	speed_modifier = 1.8

	open_turf_by_height = list(
		RW_HEIGHT_BAND_KEY_0  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_1  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_2  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_3  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_4  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_5  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_6  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_7  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_8  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_9  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_10 = /turf/open/water,
	)

	open_turf_by_height_transition = list(
		RW_HEIGHT_BAND_KEY_0  = /turf/open/water/beach,
		RW_HEIGHT_BAND_KEY_1  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_2  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_3  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_4  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_5  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_6  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_7  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_8  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_9  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_10 = /turf/open/water,
	)

	open_turf_type = /turf/open/water
