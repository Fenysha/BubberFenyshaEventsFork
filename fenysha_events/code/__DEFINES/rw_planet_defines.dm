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
 * The whole generator surface is 5 simple sliders, each on a uniform -5..5
 * scale. Rust (tp_planet.rs, see derive_generation_params()) turns these into
 * every noise scale, elevation band and climate threshold the old, much more
 * granular system used to expose to DM; none of that lives here anymore.
 *
 *   mountains   -5 flat plains        .. 5 extreme mountain ranges
 *   ocean       -5 arid / mostly land .. 5 water world
 *   humidity    -5 arid               .. 5 humid/rainy
 *   temperature -5 frozen             .. 5 scorching
 *   population  -5 empty              .. 5 densely settled (settlements only,
 *                                        the terrain generator ignores it)
 * ============================================================================
 */

#define RW_SLIDER_MIN -5
#define RW_SLIDER_MAX 5
#define RW_SLIDER_DEFAULT 0

/**
 * ----------------------------------------------------------------------------
 * Preset slider values
 * ----------------------------------------------------------------------------
 */

#define RW_TERRAN_SLIDER_MOUNTAINS 2
#define RW_TERRAN_SLIDER_OCEAN 2
#define RW_TERRAN_SLIDER_HUMIDITY 1
#define RW_TERRAN_SLIDER_TEMPERATURE 1
#define RW_TERRAN_SLIDER_POPULATION 3

#define RW_ICE_SLIDER_MOUNTAINS 1
#define RW_ICE_SLIDER_OCEAN 0
#define RW_ICE_SLIDER_HUMIDITY -1
#define RW_ICE_SLIDER_TEMPERATURE -5
#define RW_ICE_SLIDER_POPULATION -2

#define RW_DESERT_SLIDER_MOUNTAINS 2
#define RW_DESERT_SLIDER_OCEAN -3
#define RW_DESERT_SLIDER_HUMIDITY -4
#define RW_DESERT_SLIDER_TEMPERATURE 3
#define RW_DESERT_SLIDER_POPULATION -1

#define RW_OCEAN_SLIDER_MOUNTAINS -1
#define RW_OCEAN_SLIDER_OCEAN 4
#define RW_OCEAN_SLIDER_HUMIDITY 2
#define RW_OCEAN_SLIDER_TEMPERATURE 1
#define RW_OCEAN_SLIDER_POPULATION 0


/**
 * ----------------------------------------------------------------------------
 * Utility
 * ----------------------------------------------------------------------------
 */

/// 2D Euclidean distance.
/proc/get_dist_2d(x1, y1, x2, y2)
	return sqrt(((x2 - x1) ** 2) + ((y2 - y1) ** 2))
