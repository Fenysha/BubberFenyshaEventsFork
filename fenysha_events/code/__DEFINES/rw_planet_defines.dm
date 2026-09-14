/**
 * ============================================================================
 * RimWorld planetary map
 * Shared generator definitions
 * ============================================================================
 */

/**
 * ----------------------------------------------------------------------------
 * Generator version
 * ----------------------------------------------------------------------------
 *
 * Increment this whenever deterministic generation changes.
 */
#define RW_PLANET_GENERATOR_VERSION 4


/**
 * ----------------------------------------------------------------------------
 * Planet presets
 * ----------------------------------------------------------------------------
 */

#define RW_PLANET_PRESET_TERRAN "terran"
#define RW_PLANET_PRESET_ICE "ice"
#define RW_PLANET_PRESET_DESERT "desert"
#define RW_PLANET_PRESET_OCEAN "ocean"


/**
 * ----------------------------------------------------------------------------
 * Climate levels
 * ----------------------------------------------------------------------------
 */

#define RW_CLIMATE_LOW "0"
#define RW_CLIMATE_MEDIUM "1"
#define RW_CLIMATE_HIGH "2"


/**
 * ----------------------------------------------------------------------------
 * Elevation levels
 * ----------------------------------------------------------------------------
 */

#define RW_ELEVATION_OCEAN "0"
#define RW_ELEVATION_COAST "1"
#define RW_ELEVATION_LOWLAND "2"
#define RW_ELEVATION_HIGHLAND "3"
#define RW_ELEVATION_MOUNTAIN "4"
#define RW_ELEVATION_SNOW "5"


/**
 * ----------------------------------------------------------------------------
 * Biomes
 * ----------------------------------------------------------------------------
 */

#define RW_BIOME_OCEAN "ocean"
#define RW_BIOME_BEACH "beach"
#define RW_BIOME_COAST "coasts"
#define RW_BIOME_SEA_ICE "sea_ice"
#define RW_BIOME_TUNDRA "tundra"
#define RW_BIOME_TAIGA "taiga"
#define RW_BIOME_TEMPERATE_FOREST "temperate_forest"
#define RW_BIOME_GRASSLAND "grassland"
#define RW_BIOME_SAVANNA "savanna"
#define RW_BIOME_DESERT "desert"
#define RW_BIOME_TROPICAL_FOREST "tropical_forest"
#define RW_BIOME_RAINFOREST "rainforest"
#define RW_BIOME_MOUNTAINS "mountains"
#define RW_BIOME_SNOW "snow"


/**
 * ----------------------------------------------------------------------------
 * DBP configuration
 * ----------------------------------------------------------------------------
 */

/*
 * Keep noise relatively smooth.
 */
#define RW_TERRAIN_NOISE_SCALE 60

#define RW_ELEVATION_STAMP_SIZE 340
#define RW_HEAT_STAMP_SIZE 150
#define RW_HUMIDITY_STAMP_SIZE 140


/**
 * ----------------------------------------------------------------------------
 * Terran planet parameters
 * ----------------------------------------------------------------------------
 */

#define RW_TERRAN_HEAT_LOW -0.20
#define RW_TERRAN_HEAT_HIGH 0.25

#define RW_TERRAN_HUMIDITY_LOW -0.18
#define RW_TERRAN_HUMIDITY_HIGH 0.25

#define RW_TERRAN_OCEAN_LOW -1.0
#define RW_TERRAN_OCEAN_HIGH -0.02

#define RW_TERRAN_COAST_LOW -0.02
#define RW_TERRAN_COAST_HIGH 0.06

#define RW_TERRAN_LOWLAND_LOW 0.06
#define RW_TERRAN_LOWLAND_HIGH 0.40

#define RW_TERRAN_HIGHLAND_LOW 0.40
#define RW_TERRAN_HIGHLAND_HIGH 0.62

#define RW_TERRAN_MOUNTAIN_LOW 0.62
#define RW_TERRAN_MOUNTAIN_HIGH 0.78

#define RW_TERRAN_SNOW_LOW 0.78
#define RW_TERRAN_SNOW_HIGH 1.10



/**
 * ----------------------------------------------------------------------------
 * Ice planet
 * ----------------------------------------------------------------------------
 *
 * Target:
 * - very large frozen regions
 * - substantial snow coverage
 * - some exposed ocean / liquid regions
 * - mountains more common than on Terran
 */

#define RW_ICE_HEAT_LOW 0.02
#define RW_ICE_HEAT_HIGH 0.52

#define RW_ICE_HUMIDITY_LOW -0.24
#define RW_ICE_HUMIDITY_HIGH 0.24

#define RW_ICE_OCEAN_LOW -1.0
#define RW_ICE_OCEAN_HIGH -0.26

#define RW_ICE_COAST_LOW -0.26
#define RW_ICE_COAST_HIGH -0.16

#define RW_ICE_LOWLAND_LOW -0.16
#define RW_ICE_LOWLAND_HIGH 0.10

#define RW_ICE_HIGHLAND_LOW 0.10
#define RW_ICE_HIGHLAND_HIGH 0.27

#define RW_ICE_MOUNTAIN_LOW 0.27
#define RW_ICE_MOUNTAIN_HIGH 0.46

#define RW_ICE_SNOW_LOW 0.46
#define RW_ICE_SNOW_HIGH 1.10


/**
 * ----------------------------------------------------------------------------
 * Desert planet
 * ----------------------------------------------------------------------------
 *
 * Target:
 * - low humidity
 * - large dry continents
 * - relatively little water
 * - occasional mountain chains
 */

#define RW_DESERT_HEAT_LOW -0.40
#define RW_DESERT_HEAT_HIGH 0.12

#define RW_DESERT_HUMIDITY_LOW 0.02
#define RW_DESERT_HUMIDITY_HIGH 0.58

#define RW_DESERT_OCEAN_LOW -1.0
#define RW_DESERT_OCEAN_HIGH -0.50

#define RW_DESERT_COAST_LOW -0.50
#define RW_DESERT_COAST_HIGH -0.40

#define RW_DESERT_LOWLAND_LOW -0.40
#define RW_DESERT_LOWLAND_HIGH 0.20

#define RW_DESERT_HIGHLAND_LOW 0.20
#define RW_DESERT_HIGHLAND_HIGH 0.36

#define RW_DESERT_MOUNTAIN_LOW 0.36
#define RW_DESERT_MOUNTAIN_HIGH 0.56

#define RW_DESERT_SNOW_LOW 0.56
#define RW_DESERT_SNOW_HIGH 1.10


/**
 * ----------------------------------------------------------------------------
 * Ocean planet
 * ----------------------------------------------------------------------------
 *
 * Target:
 * - dominant ocean
 * - many relatively small continents
 * - shallow coastal areas
 * - visible mountain interiors
 * - still enough land to avoid "almost entirely ocean"
 */

#define RW_OCEAN_HEAT_LOW -0.18
#define RW_OCEAN_HEAT_HIGH 0.30

#define RW_OCEAN_HUMIDITY_LOW -0.50
#define RW_OCEAN_HUMIDITY_HIGH 0.08

#define RW_OCEAN_OCEAN_LOW -1.0
#define RW_OCEAN_OCEAN_HIGH 0.14

#define RW_OCEAN_COAST_LOW 0.14
#define RW_OCEAN_COAST_HIGH 0.22

#define RW_OCEAN_LOWLAND_LOW 0.22
#define RW_OCEAN_LOWLAND_HIGH 0.34

#define RW_OCEAN_HIGHLAND_LOW 0.34
#define RW_OCEAN_HIGHLAND_HIGH 0.46

#define RW_OCEAN_MOUNTAIN_LOW 0.46
#define RW_OCEAN_MOUNTAIN_HIGH 0.60

#define RW_OCEAN_SNOW_LOW 0.60
#define RW_OCEAN_SNOW_HIGH 1.10


/**
 * ----------------------------------------------------------------------------
 * Utility
 * ----------------------------------------------------------------------------
 */

/// 2D Euclidean distance.
/proc/get_dist_2d(x1, y1, x2, y2)
	return sqrt(((x2 - x1) ** 2) + ((y2 - y1) ** 2))
