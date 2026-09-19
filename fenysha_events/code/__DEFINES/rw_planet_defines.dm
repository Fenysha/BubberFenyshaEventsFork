/**
 * ============================================================================
 * RimWorld planetary map
 * Shared generator definitions
 * ============================================================================
 */

#define RW_PLANET_GENERATOR_VERSION 7
/// Hex grid frequency n: 10n^2 + 2 tiles, about 2050 around the equator
#define RW_PLANET_GRID_FREQUENCY 366

#define RW_PLANET_CELL_TOWN "map_town"
#define RW_PLANET_CELL_TOWN_OTHER "map_town_other"
#define RW_PLANET_CELL_TOWN_TRIBAL "map_town_tribal"
#define RW_PLANET_CELL_TOWN_PIRATE "map_town_pirate"
#define RW_PLANET_CELL_TOWN_ICON "map_poi"


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
#define RW_BIOME_RIVER "river"
#define RW_BIOME_LAKE "lake"


/**
 * ----------------------------------------------------------------------------
 * Planet object types
 * ----------------------------------------------------------------------------
 */

#define RW_OBJECT_TYPE_OBJECT "object"
#define RW_OBJECT_TYPE_SETTLEMENT "settlement"
#define RW_OBJECT_TYPE_POINT_OF_INTEREST "point_of_interest"
#define RW_OBJECT_TYPE_ROAD "road"


/**
 * ----------------------------------------------------------------------------
 * Planet materials
 * ----------------------------------------------------------------------------
 */

#define RW_MATERIAL_NONE "none"
#define RW_MATERIAL_GRANITE "granite"
#define RW_MATERIAL_LIMESTONE "limestone"
#define RW_MATERIAL_SANDSTONE "sandstone"
#define RW_MATERIAL_SLATE "slate"
#define RW_MATERIAL_MARBLE "marble"
#define RW_MATERIAL_OBSIDIAN "obsidian"
#define RW_MATERIAL_JADE "jade"

#define RW_MATERIAL_NAME_TO_TYPE list(\
	RW_MATERIAL_GRANITE = /datum/material/rimworld_material/granite, \
	RW_MATERIAL_LIMESTONE = /datum/material/rimworld_material/limestone, \
	RW_MATERIAL_SANDSTONE = /datum/material/rimworld_material/sandstone, \
	RW_MATERIAL_SLATE = /datum/material/rimworld_material/slate, \
	RW_MATERIAL_MARBLE = /datum/material/rimworld_material/marble, \
	RW_MATERIAL_OBSIDIAN = /datum/material/rimworld_material/obsidian, \
	RW_MATERIAL_JADE = /datum/material/rimworld_material/jade, \
)

/**
 * ----------------------------------------------------------------------------
 * Precipitation categories
 * ----------------------------------------------------------------------------
 */

#define RW_PRECIPITATION_LOW "low"
#define RW_PRECIPITATION_MEDIUM "medium"
#define RW_PRECIPITATION_HIGH "high"

#define RW_PRECIPITATION_CATEGORY_HIGH 0.78
#define RW_PRECIPITATION_CATEGORY_MEDIUM 0.50
#define RW_PRECIPITATION_CATEGORY_LOW 0.20


/**
 * ----------------------------------------------------------------------------
 * Planet sub-biomes
 * ----------------------------------------------------------------------------
 */

#define RW_SUBBIOME_DEEP_OCEAN "deep_ocean"
#define RW_SUBBIOME_FROZEN_OCEAN "frozen_ocean"
#define RW_SUBBIOME_SHORE "shore"
#define RW_SUBBIOME_PLAINS "plains"
#define RW_SUBBIOME_HILLS "hills"
#define RW_SUBBIOME_ROCKY_HILLS "rocky_hills"
#define RW_SUBBIOME_FOREST "forest"
#define RW_SUBBIOME_FOREST_HILLS "forest_hills"
#define RW_SUBBIOME_TUNDRA_PLAINS "tundra_plains"
#define RW_SUBBIOME_SNOWFIELDS "snowfields"
#define RW_SUBBIOME_MARSH "marsh"


/**
 * ----------------------------------------------------------------------------
 * Planet object names
 * ----------------------------------------------------------------------------
 */

#define RW_OBJECT_NAME_SETTLEMENT "Settlement"
#define RW_OBJECT_NAME_POINT_OF_INTEREST "Point of Interest"
#define RW_OBJECT_NAME_ROAD "Road"


/**
 * ----------------------------------------------------------------------------
 * Point of interest defaults
 * ----------------------------------------------------------------------------
 */

#define RW_POI_TYPE_UNKNOWN "unknown"


/**
 * ============================================================================
 * Generator configuration
 * ============================================================================
 *
 * Values are feature sizes in map cells.
 *
 * Larger scale = larger geographic structures.
 * Smaller scale = more fragmented structures.
 *
 * Planet size:
 *   2048 x 1024
 *
 * These values are intentionally large because the generator operates on a
 * spherical surface and uses multiple FBM octaves.
 * ============================================================================
 */

#define RW_TERRAIN_NOISE_SCALE 180

#define RW_ELEVATION_STAMP_SIZE 520
#define RW_HEAT_STAMP_SIZE 300
#define RW_HUMIDITY_STAMP_SIZE 340

#define RW_RELIEF_NOISE_SCALE 32
#define RW_RELIEF_SHIFT_STEP 0.035

#define RW_RIVER_NOISE_SCALE 22
#define RW_RIVER_THRESHOLD 0.018

#define RW_LAKE_NOISE_SCALE 60
#define RW_LAKE_THRESHOLD 0.44

#define RW_WARP_HARMONIC_OCTAVES 3
#define RW_WARP_STRENGTH 0.12


/**
 * ============================================================================
 * Terran planet
 * ============================================================================
 *
 * Target:
 *
 *   - several very large continents
 *   - large oceans separating continents
 *   - relatively small coastlines
 *   - broad lowland regions
 *   - meaningful highlands
 *   - mountain ranges instead of uniformly distributed mountains
 *   - snow primarily at high elevation / polar regions
 *
 * Elevation domain:
 *   [-0.5, 0.5]
 *
 * The ocean occupies roughly the lower 40% of the normalized elevation range.
 * This gives the continental noise enough room to form large connected
 * landmasses while retaining substantial oceans.
 * ============================================================================
 */


/**
 * ----------------------------------------------------------------------------
 * Climate
 * ----------------------------------------------------------------------------
 */

#define RW_TERRAN_HEAT_LOW -0.18
#define RW_TERRAN_HEAT_HIGH 0.20

#define RW_TERRAN_HUMIDITY_LOW -0.18
#define RW_TERRAN_HUMIDITY_HIGH 0.20


/**
 * ----------------------------------------------------------------------------
 * Elevation
 * ----------------------------------------------------------------------------
 */

#define RW_TERRAN_OCEAN_LOW -0.50
#define RW_TERRAN_OCEAN_HIGH -0.10

#define RW_TERRAN_COAST_LOW -0.10
#define RW_TERRAN_COAST_HIGH -0.025

#define RW_TERRAN_LOWLAND_LOW -0.025
#define RW_TERRAN_LOWLAND_HIGH 0.12

#define RW_TERRAN_HIGHLAND_LOW 0.12
#define RW_TERRAN_HIGHLAND_HIGH 0.25

#define RW_TERRAN_MOUNTAIN_LOW 0.25
#define RW_TERRAN_MOUNTAIN_HIGH 0.39

#define RW_TERRAN_SNOW_LOW 0.39
#define RW_TERRAN_SNOW_HIGH 0.50


/**
 * ============================================================================
 * Ice planet
 * ============================================================================
 *
 * Target:
 *
 *   - large frozen continents
 *   - large frozen oceans
 *   - extensive snowfields
 *   - fewer warm lowlands
 *   - strong polar character
 * ============================================================================
 */

#define RW_ICE_HEAT_LOW -0.28
#define RW_ICE_HEAT_HIGH 0.08

#define RW_ICE_HUMIDITY_LOW -0.20
#define RW_ICE_HUMIDITY_HIGH 0.18

#define RW_ICE_OCEAN_LOW -0.50
#define RW_ICE_OCEAN_HIGH -0.13

#define RW_ICE_COAST_LOW -0.13
#define RW_ICE_COAST_HIGH -0.055

#define RW_ICE_LOWLAND_LOW -0.055
#define RW_ICE_LOWLAND_HIGH 0.08

#define RW_ICE_HIGHLAND_LOW 0.08
#define RW_ICE_HIGHLAND_HIGH 0.19

#define RW_ICE_MOUNTAIN_LOW 0.19
#define RW_ICE_MOUNTAIN_HIGH 0.32

#define RW_ICE_SNOW_LOW 0.32
#define RW_ICE_SNOW_HIGH 0.50


/**
 * ============================================================================
 * Desert planet
 * ============================================================================
 *
 * Target:
 *
 *   - large continental masses
 *   - relatively dry interiors
 *   - broad desert regions
 *   - substantial mountain systems
 *   - limited permanent snow
 * ============================================================================
 */

#define RW_DESERT_HEAT_LOW -0.05
#define RW_DESERT_HEAT_HIGH 0.30

#define RW_DESERT_HUMIDITY_LOW -0.30
#define RW_DESERT_HUMIDITY_HIGH 0.08

#define RW_DESERT_OCEAN_LOW -0.50
#define RW_DESERT_OCEAN_HIGH -0.12

#define RW_DESERT_COAST_LOW -0.12
#define RW_DESERT_COAST_HIGH -0.045

#define RW_DESERT_LOWLAND_LOW -0.045
#define RW_DESERT_LOWLAND_HIGH 0.12

#define RW_DESERT_HIGHLAND_LOW 0.12
#define RW_DESERT_HIGHLAND_HIGH 0.25

#define RW_DESERT_MOUNTAIN_LOW 0.25
#define RW_DESERT_MOUNTAIN_HIGH 0.40

#define RW_DESERT_SNOW_LOW 0.40
#define RW_DESERT_SNOW_HIGH 0.50


/**
 * ============================================================================
 * Ocean planet
 * ============================================================================
 *
 * Target:
 *
 *   - one or several large continental regions
 *   - enormous oceans
 *   - relatively small land percentage
 *   - broad shallow coastal regions
 * ============================================================================
 */

#define RW_OCEAN_HEAT_LOW -0.18
#define RW_OCEAN_HEAT_HIGH 0.22

#define RW_OCEAN_HUMIDITY_LOW -0.10
#define RW_OCEAN_HUMIDITY_HIGH 0.28

#define RW_OCEAN_OCEAN_LOW -0.50
#define RW_OCEAN_OCEAN_HIGH 0.02

#define RW_OCEAN_COAST_LOW 0.02
#define RW_OCEAN_COAST_HIGH 0.09

#define RW_OCEAN_LOWLAND_LOW 0.09
#define RW_OCEAN_LOWLAND_HIGH 0.20

#define RW_OCEAN_HIGHLAND_LOW 0.20
#define RW_OCEAN_HIGHLAND_HIGH 0.30

#define RW_OCEAN_MOUNTAIN_LOW 0.30
#define RW_OCEAN_MOUNTAIN_HIGH 0.40

#define RW_OCEAN_SNOW_LOW 0.40
#define RW_OCEAN_SNOW_HIGH 0.50


/**
 * ----------------------------------------------------------------------------
 * Utility
 * ----------------------------------------------------------------------------
 */

/// 2D Euclidean distance.
/proc/get_dist_2d(x1, y1, x2, y2)
	return sqrt(((x2 - x1) ** 2) + ((y2 - y1) ** 2))
