/datum/biome/rimworld/taiga
	parent_type = /datum/biome/rimworld/land

	biome_key = RW_BIOME_TAIGA

	speed_modifier = 1.2

	open_turf_by_height = list(
		RW_HEIGHT_BAND_KEY_0  = /turf/open/rimworld/dirt,
		RW_HEIGHT_BAND_KEY_1  = /turf/open/rimworld/grass/forest,
		RW_HEIGHT_BAND_KEY_2  = /turf/open/rimworld/grass/forest,
		RW_HEIGHT_BAND_KEY_3  = /turf/open/rimworld/grass/forest/light,
		RW_HEIGHT_BAND_KEY_4  = /turf/open/rimworld/grass/forest,
		RW_HEIGHT_BAND_KEY_5  = /turf/open/rimworld/grass/forest/tall,
		RW_HEIGHT_BAND_KEY_6  = /turf/open/rimworld/grass/forest,
		RW_HEIGHT_BAND_KEY_7  = /turf/open/rimworld/grass/forest/light,
		RW_HEIGHT_BAND_KEY_8  = /turf/open/rimworld/grass/forest,
		RW_HEIGHT_BAND_KEY_9  = /turf/open/rimworld/sand/white,
		RW_HEIGHT_BAND_KEY_10 = /turf/open/rimworld/sand/white,
	)

	open_turf_by_height_transition = list(
		RW_HEIGHT_BAND_KEY_0  = /turf/open/rimworld/dirt,
		RW_HEIGHT_BAND_KEY_1  = /turf/open/rimworld/grass/forest/light,
		RW_HEIGHT_BAND_KEY_2  = /turf/open/rimworld/grass/forest,
		RW_HEIGHT_BAND_KEY_3  = /turf/open/rimworld/grass/forest/tall,
		RW_HEIGHT_BAND_KEY_4  = /turf/open/rimworld/grass/forest,
		RW_HEIGHT_BAND_KEY_5  = /turf/open/rimworld/grass/forest/light,
		RW_HEIGHT_BAND_KEY_6  = /turf/open/rimworld/grass/forest/tall,
		RW_HEIGHT_BAND_KEY_7  = /turf/open/rimworld/grass/forest,
		RW_HEIGHT_BAND_KEY_8  = /turf/open/rimworld/grass/forest/light,
		RW_HEIGHT_BAND_KEY_9  = /turf/open/rimworld/sand/chalk,
		RW_HEIGHT_BAND_KEY_10 = /turf/open/rimworld/sand/white,
	)

	open_turf_type = /turf/open/rimworld/grass/forest


/datum/biome/rimworld/temperate_forest
	parent_type = /datum/biome/rimworld/land

	biome_key = RW_BIOME_TEMPERATE_FOREST

	speed_modifier = 1.3

	open_turf_by_height = list(
		RW_HEIGHT_BAND_KEY_0  = /turf/open/rimworld/dirt,
		RW_HEIGHT_BAND_KEY_1  = /turf/open/rimworld/grass/forest,
		RW_HEIGHT_BAND_KEY_2  = /turf/open/rimworld/grass/forest,
		RW_HEIGHT_BAND_KEY_3  = /turf/open/rimworld/grass/forest/light,
		RW_HEIGHT_BAND_KEY_4  = /turf/open/rimworld/grass/forest/tall,
		RW_HEIGHT_BAND_KEY_5  = /turf/open/rimworld/grass/forest,
		RW_HEIGHT_BAND_KEY_6  = /turf/open/rimworld/grass/forest/light,
		RW_HEIGHT_BAND_KEY_7  = /turf/open/rimworld/grass/forest/tall,
		RW_HEIGHT_BAND_KEY_8  = /turf/open/rimworld/grass/forest,
		RW_HEIGHT_BAND_KEY_9  = /turf/open/rimworld/grass/forest/light,
		RW_HEIGHT_BAND_KEY_10 = /turf/open/rimworld/grass/forest,
	)

	open_turf_by_height_transition = list(
		RW_HEIGHT_BAND_KEY_0  = /turf/open/rimworld/dirt,
		RW_HEIGHT_BAND_KEY_1  = /turf/open/rimworld/grass/forest/light,
		RW_HEIGHT_BAND_KEY_2  = /turf/open/rimworld/grass/forest,
		RW_HEIGHT_BAND_KEY_3  = /turf/open/rimworld/grass/forest/tall,
		RW_HEIGHT_BAND_KEY_4  = /turf/open/rimworld/grass/forest,
		RW_HEIGHT_BAND_KEY_5  = /turf/open/rimworld/grass/forest/light,
		RW_HEIGHT_BAND_KEY_6  = /turf/open/rimworld/grass/forest/tall,
		RW_HEIGHT_BAND_KEY_7  = /turf/open/rimworld/grass/forest,
		RW_HEIGHT_BAND_KEY_8  = /turf/open/rimworld/grass/forest/light,
		RW_HEIGHT_BAND_KEY_9  = /turf/open/rimworld/grass/forest,
		RW_HEIGHT_BAND_KEY_10 = /turf/open/rimworld/grass/forest/light,
	)

	open_turf_type = /turf/open/rimworld/grass/forest


/datum/biome/rimworld/grassland
	parent_type = /datum/biome/rimworld/land

	biome_key = RW_BIOME_GRASSLAND

	speed_modifier = 0.95

	open_turf_by_height = list(
		RW_HEIGHT_BAND_KEY_0  = /turf/open/rimworld/dirt,
		RW_HEIGHT_BAND_KEY_1  = /turf/open/rimworld/grass,
		RW_HEIGHT_BAND_KEY_2  = /turf/open/rimworld/grass,
		RW_HEIGHT_BAND_KEY_3  = /turf/open/rimworld/grass/light,
		RW_HEIGHT_BAND_KEY_4  = /turf/open/rimworld/grass,
		RW_HEIGHT_BAND_KEY_5  = /turf/open/rimworld/grass/tall,
		RW_HEIGHT_BAND_KEY_6  = /turf/open/rimworld/grass,
		RW_HEIGHT_BAND_KEY_7  = /turf/open/rimworld/grass/light,
		RW_HEIGHT_BAND_KEY_8  = /turf/open/rimworld/grass/tall,
		RW_HEIGHT_BAND_KEY_9  = /turf/open/rimworld/grass,
		RW_HEIGHT_BAND_KEY_10 = /turf/open/rimworld/grass/light,
	)

	open_turf_by_height_transition = list(
		RW_HEIGHT_BAND_KEY_0  = /turf/open/rimworld/dirt,
		RW_HEIGHT_BAND_KEY_1  = /turf/open/rimworld/grass/light,
		RW_HEIGHT_BAND_KEY_2  = /turf/open/rimworld/grass,
		RW_HEIGHT_BAND_KEY_3  = /turf/open/rimworld/grass/tall,
		RW_HEIGHT_BAND_KEY_4  = /turf/open/rimworld/grass,
		RW_HEIGHT_BAND_KEY_5  = /turf/open/rimworld/grass/light,
		RW_HEIGHT_BAND_KEY_6  = /turf/open/rimworld/grass/tall,
		RW_HEIGHT_BAND_KEY_7  = /turf/open/rimworld/grass,
		RW_HEIGHT_BAND_KEY_8  = /turf/open/rimworld/grass/light,
		RW_HEIGHT_BAND_KEY_9  = /turf/open/rimworld/grass,
		RW_HEIGHT_BAND_KEY_10 = /turf/open/rimworld/grass/light,
	)

	open_turf_type = /turf/open/rimworld/grass


/datum/biome/rimworld/savanna
	parent_type = /datum/biome/rimworld/land

	biome_key = RW_BIOME_SAVANNA

	speed_modifier = 0.85

	open_turf_by_height = list(
		RW_HEIGHT_BAND_KEY_0  = /turf/open/rimworld/sand/yellow,
		RW_HEIGHT_BAND_KEY_1  = /turf/open/rimworld/grass/savanna,
		RW_HEIGHT_BAND_KEY_2  = /turf/open/rimworld/grass/savanna,
		RW_HEIGHT_BAND_KEY_3  = /turf/open/rimworld/grass/savanna/light,
		RW_HEIGHT_BAND_KEY_4  = /turf/open/rimworld/grass/savanna,
		RW_HEIGHT_BAND_KEY_5  = /turf/open/rimworld/grass/savanna/tall,
		RW_HEIGHT_BAND_KEY_6  = /turf/open/rimworld/grass/savanna,
		RW_HEIGHT_BAND_KEY_7  = /turf/open/rimworld/grass/savanna/light,
		RW_HEIGHT_BAND_KEY_8  = /turf/open/rimworld/sand/orange,
		RW_HEIGHT_BAND_KEY_9  = /turf/open/rimworld/sand/yellow,
		RW_HEIGHT_BAND_KEY_10 = /turf/open/rimworld/sand,
	)

	open_turf_by_height_transition = list(
		RW_HEIGHT_BAND_KEY_0  = /turf/open/rimworld/sand,
		RW_HEIGHT_BAND_KEY_1  = /turf/open/rimworld/grass/savanna/light,
		RW_HEIGHT_BAND_KEY_2  = /turf/open/rimworld/grass/savanna,
		RW_HEIGHT_BAND_KEY_3  = /turf/open/rimworld/grass/savanna/tall,
		RW_HEIGHT_BAND_KEY_4  = /turf/open/rimworld/grass/savanna,
		RW_HEIGHT_BAND_KEY_5  = /turf/open/rimworld/grass/savanna/light,
		RW_HEIGHT_BAND_KEY_6  = /turf/open/rimworld/grass/savanna/tall,
		RW_HEIGHT_BAND_KEY_7  = /turf/open/rimworld/sand/orange,
		RW_HEIGHT_BAND_KEY_8  = /turf/open/rimworld/sand/yellow,
		RW_HEIGHT_BAND_KEY_9  = /turf/open/rimworld/sand,
		RW_HEIGHT_BAND_KEY_10 = /turf/open/rimworld/sand,
	)

	open_turf_type = /turf/open/rimworld/grass/savanna


/datum/biome/rimworld/tropical_forest
	parent_type = /datum/biome/rimworld/land

	biome_key = RW_BIOME_TROPICAL_FOREST

	speed_modifier = 1.35

	open_turf_by_height = list(
		RW_HEIGHT_BAND_KEY_0  = /turf/open/rimworld/dirt,
		RW_HEIGHT_BAND_KEY_1  = /turf/open/rimworld/grass/jungle,
		RW_HEIGHT_BAND_KEY_2  = /turf/open/rimworld/grass/jungle,
		RW_HEIGHT_BAND_KEY_3  = /turf/open/rimworld/grass/jungle/light,
		RW_HEIGHT_BAND_KEY_4  = /turf/open/rimworld/grass/jungle/tall,
		RW_HEIGHT_BAND_KEY_5  = /turf/open/rimworld/grass/jungle,
		RW_HEIGHT_BAND_KEY_6  = /turf/open/rimworld/grass/jungle/light,
		RW_HEIGHT_BAND_KEY_7  = /turf/open/rimworld/grass/jungle/tall,
		RW_HEIGHT_BAND_KEY_8  = /turf/open/rimworld/grass/jungle,
		RW_HEIGHT_BAND_KEY_9  = /turf/open/rimworld/grass/jungle/light,
		RW_HEIGHT_BAND_KEY_10 = /turf/open/rimworld/grass/jungle/tall,
	)

	open_turf_by_height_transition = list(
		RW_HEIGHT_BAND_KEY_0  = /turf/open/rimworld/dirt,
		RW_HEIGHT_BAND_KEY_1  = /turf/open/rimworld/grass/jungle/light,
		RW_HEIGHT_BAND_KEY_2  = /turf/open/rimworld/grass/jungle,
		RW_HEIGHT_BAND_KEY_3  = /turf/open/rimworld/grass/jungle/tall,
		RW_HEIGHT_BAND_KEY_4  = /turf/open/rimworld/grass/jungle,
		RW_HEIGHT_BAND_KEY_5  = /turf/open/rimworld/grass/jungle/light,
		RW_HEIGHT_BAND_KEY_6  = /turf/open/rimworld/grass/jungle/tall,
		RW_HEIGHT_BAND_KEY_7  = /turf/open/rimworld/grass/jungle,
		RW_HEIGHT_BAND_KEY_8  = /turf/open/rimworld/grass/jungle/light,
		RW_HEIGHT_BAND_KEY_9  = /turf/open/rimworld/grass/jungle/tall,
		RW_HEIGHT_BAND_KEY_10 = /turf/open/rimworld/grass/jungle,
	)

	open_turf_type = /turf/open/rimworld/grass/jungle


/datum/biome/rimworld/rainforest
	parent_type = /datum/biome/rimworld/land

	biome_key = RW_BIOME_RAINFOREST

	speed_modifier = 1.5

	open_turf_by_height = list(
		RW_HEIGHT_BAND_KEY_0  = /turf/open/rimworld/dirt,
		RW_HEIGHT_BAND_KEY_1  = /turf/open/rimworld/grass/jungle,
		RW_HEIGHT_BAND_KEY_2  = /turf/open/rimworld/grass/jungle/light,
		RW_HEIGHT_BAND_KEY_3  = /turf/open/rimworld/grass/jungle/tall,
		RW_HEIGHT_BAND_KEY_4  = /turf/open/rimworld/grass/jungle,
		RW_HEIGHT_BAND_KEY_5  = /turf/open/rimworld/grass/jungle/light,
		RW_HEIGHT_BAND_KEY_6  = /turf/open/rimworld/grass/jungle/tall,
		RW_HEIGHT_BAND_KEY_7  = /turf/open/rimworld/grass/jungle,
		RW_HEIGHT_BAND_KEY_8  = /turf/open/rimworld/grass/jungle/tall,
		RW_HEIGHT_BAND_KEY_9  = /turf/open/rimworld/grass/jungle/light,
		RW_HEIGHT_BAND_KEY_10 = /turf/open/rimworld/grass/jungle/tall,
	)

	open_turf_by_height_transition = list(
		RW_HEIGHT_BAND_KEY_0  = /turf/open/rimworld/dirt,
		RW_HEIGHT_BAND_KEY_1  = /turf/open/rimworld/grass/jungle/light,
		RW_HEIGHT_BAND_KEY_2  = /turf/open/rimworld/grass/jungle,
		RW_HEIGHT_BAND_KEY_3  = /turf/open/rimworld/grass/jungle/tall,
		RW_HEIGHT_BAND_KEY_4  = /turf/open/rimworld/grass/jungle/light,
		RW_HEIGHT_BAND_KEY_5  = /turf/open/rimworld/grass/jungle/tall,
		RW_HEIGHT_BAND_KEY_6  = /turf/open/rimworld/grass/jungle,
		RW_HEIGHT_BAND_KEY_7  = /turf/open/rimworld/grass/jungle/tall,
		RW_HEIGHT_BAND_KEY_8  = /turf/open/rimworld/grass/jungle/light,
		RW_HEIGHT_BAND_KEY_9  = /turf/open/rimworld/grass/jungle/tall,
		RW_HEIGHT_BAND_KEY_10 = /turf/open/rimworld/grass/jungle,
	)

	open_turf_type = /turf/open/rimworld/grass/jungle
