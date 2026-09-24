/// Cold coniferous belt — dense pines, sparse undergrowth, rocky high ground.
/datum/biome/rimworld/taiga
	parent_type = /datum/biome/rimworld/land

	biome_key = RW_BIOME_TAIGA
	speed_modifier = 1.2

	open_turf_by_height = list(
		RW_HEIGHT_BAND_KEY_0  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_1  = /turf/open/rimworld/dirt,
		RW_HEIGHT_BAND_KEY_2  = /turf/open/rimworld/grass/forest,
		RW_HEIGHT_BAND_KEY_3  = /turf/open/rimworld/grass/forest/light,
		RW_HEIGHT_BAND_KEY_4  = /turf/open/rimworld/grass/forest,
		RW_HEIGHT_BAND_KEY_5  = /turf/open/rimworld/grass/forest/tall,
		RW_HEIGHT_BAND_KEY_6  = /turf/open/rimworld/grass/forest,
		RW_HEIGHT_BAND_KEY_7  = /turf/open/rimworld/grass/forest/tall,
		RW_HEIGHT_BAND_KEY_8  = /turf/open/rimworld/grass/forest/tall,
		RW_HEIGHT_BAND_KEY_9  = /turf/open/rimworld/dirt,
		RW_HEIGHT_BAND_KEY_10 = /turf/open/rimworld/rock/auto,
	)

	open_turf_by_height_transition = list(
		RW_HEIGHT_BAND_KEY_0  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_1  = /turf/open/rimworld/dirt,
		RW_HEIGHT_BAND_KEY_2  = /turf/open/rimworld/grass/forest,
		RW_HEIGHT_BAND_KEY_3  = /turf/open/rimworld/grass/forest/light,
		RW_HEIGHT_BAND_KEY_4  = /turf/open/rimworld/grass/forest,
		RW_HEIGHT_BAND_KEY_5  = /turf/open/rimworld/grass/forest/tall,
		RW_HEIGHT_BAND_KEY_6  = /turf/open/rimworld/grass/forest,
		RW_HEIGHT_BAND_KEY_7  = /turf/open/rimworld/grass/forest/tall,
		RW_HEIGHT_BAND_KEY_8  = /turf/open/rimworld/grass/forest/tall,
		RW_HEIGHT_BAND_KEY_9  = /turf/open/rimworld/dirt,
		RW_HEIGHT_BAND_KEY_10 = /turf/open/rimworld/rock/auto,
	)

	open_turf_type = /turf/open/rimworld/grass/forest
	open_turf_type_cave = /turf/open/rimworld/rock/auto

	flora_density = 55
	feature_density = 4
	fauna_density = 0

	// Weights: higher = more common after expand_weights
	flora_types = list(
		/obj/structure/rimworld/flora/grayscale/tree/taiga = 12,
		/obj/structure/rimworld/flora/grayscale/bush/tundra = 6,
		/obj/structure/rimworld/flora/grayscale/grass = 4,
		/obj/structure/rimworld/flora/grayscale/grass/alt = 2,
	)

	// Caves: almost no green life
	cave_flora_types = list(
		/obj/structure/rimworld/flora/grayscale/bush/tundra = 1,
	)

	flora_soft_radius = 3
	flora_soft_penalty = 0.4


/// Mixed temperate woodland — trees + bushes + grass carpet.
/datum/biome/rimworld/temperate_forest
	parent_type = /datum/biome/rimworld/land

	biome_key = RW_BIOME_TEMPERATE_FOREST
	speed_modifier = 1.3

	open_turf_by_height = list(
		RW_HEIGHT_BAND_KEY_0  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_1  = /turf/open/rimworld/dirt,
		RW_HEIGHT_BAND_KEY_2  = /turf/open/rimworld/grass/forest,
		RW_HEIGHT_BAND_KEY_3  = /turf/open/rimworld/grass/forest/light,
		RW_HEIGHT_BAND_KEY_4  = /turf/open/rimworld/dirt,
		RW_HEIGHT_BAND_KEY_5  = /turf/open/rimworld/grass/forest/light,
		RW_HEIGHT_BAND_KEY_6  = /turf/open/rimworld/grass/forest/light,
		RW_HEIGHT_BAND_KEY_7  = /turf/open/rimworld/grass/forest/tall,
		RW_HEIGHT_BAND_KEY_8  = /turf/open/rimworld/dirt,
		RW_HEIGHT_BAND_KEY_9  = /turf/open/rimworld/rock/auto,
		RW_HEIGHT_BAND_KEY_10 = /turf/open/rimworld/rock/auto,
	)

	open_turf_by_height_transition = list(
		RW_HEIGHT_BAND_KEY_0  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_1  = /turf/open/rimworld/dirt,
		RW_HEIGHT_BAND_KEY_2  = /turf/open/rimworld/dirt,
		RW_HEIGHT_BAND_KEY_3  = /turf/open/rimworld/grass/forest/light,
		RW_HEIGHT_BAND_KEY_4  = /turf/open/rimworld/dirt,
		RW_HEIGHT_BAND_KEY_5  = /turf/open/rimworld/grass/forest,
		RW_HEIGHT_BAND_KEY_6  = /turf/open/rimworld/grass/forest/light,
		RW_HEIGHT_BAND_KEY_7  = /turf/open/rimworld/grass/forest,
		RW_HEIGHT_BAND_KEY_8  = /turf/open/rimworld/dirt,
		RW_HEIGHT_BAND_KEY_9  = /turf/open/rimworld/rock/auto,
		RW_HEIGHT_BAND_KEY_10 = /turf/open/rimworld/rock/auto,
	)

	open_turf_type = /turf/open/rimworld/grass/forest
	open_turf_type_cave = /turf/open/rimworld/rock/auto

	flora_density = 60
	feature_density = 60
	fauna_density = 0

	flora_types = list(
		/obj/structure/rimworld/flora/grayscale/grass = 4,
		/obj/structure/rimworld/flora/grayscale/grass/alt = 4,
	)

	feature_types = list(
		/obj/structure/rimworld/flora/grayscale/tree/forest = 1,
	)

	cave_flora_types = list(
		/obj/structure/rimworld/flora/grayscale/bush/forest = 1,
	)

	flora_soft_radius = 4
	flora_soft_penalty = 0.5


/// Open plains — low trees, lots of grass tufts, easy travel.
/datum/biome/rimworld/grassland
	parent_type = /datum/biome/rimworld/land

	biome_key = RW_BIOME_GRASSLAND
	speed_modifier = 0.95

	open_turf_by_height = list(
		RW_HEIGHT_BAND_KEY_0  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_1  = /turf/open/rimworld/dirt,
		RW_HEIGHT_BAND_KEY_2  = /turf/open/rimworld/grass,
		RW_HEIGHT_BAND_KEY_3  = /turf/open/rimworld/grass/light,
		RW_HEIGHT_BAND_KEY_4  = /turf/open/rimworld/grass,
		RW_HEIGHT_BAND_KEY_5  = /turf/open/rimworld/grass/tall,
		RW_HEIGHT_BAND_KEY_6  = /turf/open/rimworld/grass,
		RW_HEIGHT_BAND_KEY_7  = /turf/open/rimworld/grass/light,
		RW_HEIGHT_BAND_KEY_8  = /turf/open/rimworld/rock/auto,
		RW_HEIGHT_BAND_KEY_9  = /turf/open/rimworld/rock/auto,
		RW_HEIGHT_BAND_KEY_10 = /turf/open/rimworld/rock/auto,
	)

	open_turf_by_height_transition = list(
		RW_HEIGHT_BAND_KEY_0  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_1  = /turf/open/rimworld/dirt,
		RW_HEIGHT_BAND_KEY_2  = /turf/open/rimworld/grass/light,
		RW_HEIGHT_BAND_KEY_3  = /turf/open/rimworld/grass,
		RW_HEIGHT_BAND_KEY_4  = /turf/open/rimworld/grass/tall,
		RW_HEIGHT_BAND_KEY_5  = /turf/open/rimworld/grass,
		RW_HEIGHT_BAND_KEY_6  = /turf/open/rimworld/grass/light,
		RW_HEIGHT_BAND_KEY_7  = /turf/open/rimworld/rock/auto,
		RW_HEIGHT_BAND_KEY_8  = /turf/open/rimworld/rock/auto,
		RW_HEIGHT_BAND_KEY_9  = /turf/open/rimworld/rock/auto,
		RW_HEIGHT_BAND_KEY_10 = /turf/open/rimworld/rock/auto,
	)

	open_turf_type = /turf/open/rimworld/grass
	open_turf_type_cave = /turf/open/rimworld/rock/auto

	flora_density = 38
	feature_density = 5
	fauna_density = 0

	flora_types = list(
		/obj/structure/rimworld/flora/grayscale/grass = 12,
		/obj/structure/rimworld/flora/grayscale/grass/alt = 8,
		/obj/structure/rimworld/flora/grayscale/bush = 4,
		/obj/structure/rimworld/flora/grayscale/bush/forest/light = 2,
		/obj/structure/rimworld/flora/grayscale/tree/forest = 1, // rare lone trees
	)

	cave_flora_types = list()

	flora_soft_radius = 1
	flora_soft_penalty = 0.65


/// Dry warm plains — scrub, sparse trees, yellow grass; cactus as rare accent.
/datum/biome/rimworld/savanna
	parent_type = /datum/biome/rimworld/land

	biome_key = RW_BIOME_SAVANNA
	speed_modifier = 0.85

	open_turf_by_height = list(
		RW_HEIGHT_BAND_KEY_0  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_1  = /turf/open/rimworld/sand/yellow,
		RW_HEIGHT_BAND_KEY_2  = /turf/open/rimworld/grass/savanna,
		RW_HEIGHT_BAND_KEY_3  = /turf/open/rimworld/grass/savanna/light,
		RW_HEIGHT_BAND_KEY_4  = /turf/open/rimworld/grass/savanna,
		RW_HEIGHT_BAND_KEY_5  = /turf/open/rimworld/grass/savanna/tall,
		RW_HEIGHT_BAND_KEY_6  = /turf/open/rimworld/grass/savanna,
		RW_HEIGHT_BAND_KEY_7  = /turf/open/rimworld/grass/savanna/light,
		RW_HEIGHT_BAND_KEY_8  = /turf/open/rimworld/sand/orange,
		RW_HEIGHT_BAND_KEY_9  = /turf/open/rimworld/rock/auto,
		RW_HEIGHT_BAND_KEY_10 = /turf/open/rimworld/rock/auto,
	)

	open_turf_by_height_transition = list(
		RW_HEIGHT_BAND_KEY_0  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_1  = /turf/open/rimworld/sand,
		RW_HEIGHT_BAND_KEY_2  = /turf/open/rimworld/grass/savanna/light,
		RW_HEIGHT_BAND_KEY_3  = /turf/open/rimworld/grass/savanna,
		RW_HEIGHT_BAND_KEY_4  = /turf/open/rimworld/grass/savanna/tall,
		RW_HEIGHT_BAND_KEY_5  = /turf/open/rimworld/grass/savanna,
		RW_HEIGHT_BAND_KEY_6  = /turf/open/rimworld/grass/savanna/light,
		RW_HEIGHT_BAND_KEY_7  = /turf/open/rimworld/sand/orange,
		RW_HEIGHT_BAND_KEY_8  = /turf/open/rimworld/rock/auto,
		RW_HEIGHT_BAND_KEY_9  = /turf/open/rimworld/rock/auto,
		RW_HEIGHT_BAND_KEY_10 = /turf/open/rimworld/rock/auto,
	)

	open_turf_type = /turf/open/rimworld/grass/savanna
	open_turf_type_cave = /turf/open/rimworld/rock/auto

	flora_density = 28
	feature_density = 8
	fauna_density = 0

	flora_types = list(
		/obj/structure/rimworld/flora/grayscale/bush/savanna = 10,
		/obj/structure/rimworld/flora/grayscale/grass = 5,
		/obj/structure/rimworld/flora/grayscale/tree/savanna = 4,
		/obj/structure/rimworld/flora/grayscale/cactus = 2,
	)

	// Dry caves: cactus only as a rare oddity near mouth — keep sparse
	cave_flora_types = list(
		/obj/structure/rimworld/flora/grayscale/cactus = 1,
	)

	flora_soft_radius = 2
	flora_soft_penalty = 0.5


/// Warm humid forest — dense canopy, undergrowth.
/datum/biome/rimworld/tropical_forest
	parent_type = /datum/biome/rimworld/land

	biome_key = RW_BIOME_TROPICAL_FOREST
	speed_modifier = 1.35

	open_turf_by_height = list(
		RW_HEIGHT_BAND_KEY_0  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_1  = /turf/open/rimworld/dirt,
		RW_HEIGHT_BAND_KEY_2  = /turf/open/rimworld/grass/jungle,
		RW_HEIGHT_BAND_KEY_3  = /turf/open/rimworld/grass/jungle/light,
		RW_HEIGHT_BAND_KEY_4  = /turf/open/rimworld/grass/jungle/tall,
		RW_HEIGHT_BAND_KEY_5  = /turf/open/rimworld/grass/jungle,
		RW_HEIGHT_BAND_KEY_6  = /turf/open/rimworld/grass/jungle/light,
		RW_HEIGHT_BAND_KEY_7  = /turf/open/rimworld/grass/jungle/tall,
		RW_HEIGHT_BAND_KEY_8  = /turf/open/rimworld/rock/auto,
		RW_HEIGHT_BAND_KEY_9  = /turf/open/rimworld/rock/auto,
		RW_HEIGHT_BAND_KEY_10 = /turf/open/rimworld/rock/auto,
	)

	open_turf_by_height_transition = list(
		RW_HEIGHT_BAND_KEY_0  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_1  = /turf/open/rimworld/dirt,
		RW_HEIGHT_BAND_KEY_2  = /turf/open/rimworld/grass/jungle/light,
		RW_HEIGHT_BAND_KEY_3  = /turf/open/rimworld/grass/jungle,
		RW_HEIGHT_BAND_KEY_4  = /turf/open/rimworld/grass/jungle/tall,
		RW_HEIGHT_BAND_KEY_5  = /turf/open/rimworld/grass/jungle,
		RW_HEIGHT_BAND_KEY_6  = /turf/open/rimworld/grass/jungle/light,
		RW_HEIGHT_BAND_KEY_7  = /turf/open/rimworld/grass/jungle/tall,
		RW_HEIGHT_BAND_KEY_8  = /turf/open/rimworld/rock/auto,
		RW_HEIGHT_BAND_KEY_9  = /turf/open/rimworld/rock/auto,
		RW_HEIGHT_BAND_KEY_10 = /turf/open/rimworld/rock/auto,
	)

	open_turf_type = /turf/open/rimworld/grass/jungle
	open_turf_type_cave = /turf/open/rimworld/rock/auto

	flora_density = 78
	feature_density = 7
	fauna_density = 0

	flora_types = list(
		/obj/structure/rimworld/flora/grayscale/tree/jungle = 12,
		/obj/structure/rimworld/flora/grayscale/tree/jungle/tall = 6,
		/obj/structure/rimworld/flora/grayscale/bush/jungle = 10,
		/obj/structure/rimworld/flora/grayscale/grass/jungle = 7,
		/obj/structure/rimworld/flora/grayscale/grass = 3,
	)

	cave_flora_types = list(
		/obj/structure/rimworld/flora/grayscale/bush/jungle = 1,
	)

	flora_soft_radius = 2
	flora_soft_penalty = 0.45


/// Extreme canopy — densest flora, slowest overland.
/datum/biome/rimworld/rainforest
	parent_type = /datum/biome/rimworld/land

	biome_key = RW_BIOME_RAINFOREST
	speed_modifier = 1.5

	open_turf_by_height = list(
		RW_HEIGHT_BAND_KEY_0  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_1  = /turf/open/rimworld/dirt,
		RW_HEIGHT_BAND_KEY_2  = /turf/open/rimworld/grass/jungle/light,
		RW_HEIGHT_BAND_KEY_3  = /turf/open/rimworld/grass/jungle,
		RW_HEIGHT_BAND_KEY_4  = /turf/open/rimworld/grass/jungle/tall,
		RW_HEIGHT_BAND_KEY_5  = /turf/open/rimworld/grass/jungle,
		RW_HEIGHT_BAND_KEY_6  = /turf/open/rimworld/grass/jungle/tall,
		RW_HEIGHT_BAND_KEY_7  = /turf/open/rimworld/grass/jungle,
		RW_HEIGHT_BAND_KEY_8  = /turf/open/rimworld/rock/auto,
		RW_HEIGHT_BAND_KEY_9  = /turf/open/rimworld/rock/auto,
		RW_HEIGHT_BAND_KEY_10 = /turf/open/rimworld/rock/auto,
	)

	open_turf_by_height_transition = list(
		RW_HEIGHT_BAND_KEY_0  = /turf/open/water,
		RW_HEIGHT_BAND_KEY_1  = /turf/open/rimworld/dirt,
		RW_HEIGHT_BAND_KEY_2  = /turf/open/rimworld/grass/jungle,
		RW_HEIGHT_BAND_KEY_3  = /turf/open/rimworld/grass/jungle/tall,
		RW_HEIGHT_BAND_KEY_4  = /turf/open/rimworld/grass/jungle,
		RW_HEIGHT_BAND_KEY_5  = /turf/open/rimworld/grass/jungle/light,
		RW_HEIGHT_BAND_KEY_6  = /turf/open/rimworld/grass/jungle/tall,
		RW_HEIGHT_BAND_KEY_7  = /turf/open/rimworld/rock/auto,
		RW_HEIGHT_BAND_KEY_8  = /turf/open/rimworld/rock/auto,
		RW_HEIGHT_BAND_KEY_9  = /turf/open/rimworld/rock/auto,
		RW_HEIGHT_BAND_KEY_10 = /turf/open/rimworld/rock/auto,
	)

	open_turf_type = /turf/open/rimworld/grass/jungle
	open_turf_type_cave = /turf/open/rimworld/rock/auto

	flora_density = 88
	feature_density = 8
	fauna_density = 0

	flora_types = list(
		/obj/structure/rimworld/flora/grayscale/tree/jungle/tall = 14,
		/obj/structure/rimworld/flora/grayscale/tree/jungle = 10,
		/obj/structure/rimworld/flora/grayscale/bush/jungle = 12,
		/obj/structure/rimworld/flora/grayscale/grass/jungle = 8,
		/obj/structure/rimworld/flora/grayscale/grass/alt = 3,
	)

	cave_flora_types = list(
		/obj/structure/rimworld/flora/grayscale/bush/jungle = 2,
		/obj/structure/rimworld/flora/grayscale/grass/jungle = 1,
	)

	flora_soft_radius = 1
	flora_soft_penalty = 0.55
