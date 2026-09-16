/*
 * ----------------------------------------------------------------------------
 * Planet geometry
 * ----------------------------------------------------------------------------
 */

export const PLANET_RADIUS = 2;

/*
 * ----------------------------------------------------------------------------
 * Camera
 * ----------------------------------------------------------------------------
 */

export const CAMERA_STATE_KEY = 'rimworld-planet-camera';

export const DEFAULT_CAMERA_POSITION = {
  x: 0,
  y: 0,
  z: PLANET_RADIUS * 2.4,
};

export const DEFAULT_CAMERA_TARGET = {
  x: 0,
  y: 0,
  z: 0,
};

/*
 * ----------------------------------------------------------------------------
 * Climate
 * ----------------------------------------------------------------------------
 */

export const CLIMATE_LOW = '0';
export const CLIMATE_MEDIUM = '1';
export const CLIMATE_HIGH = '2';

/*
 * ----------------------------------------------------------------------------
 * Elevation
 * ----------------------------------------------------------------------------
 */

export const ELEVATION_OCEAN = '0';
export const ELEVATION_COAST = '1';
export const ELEVATION_LOWLAND = '2';
export const ELEVATION_HIGHLAND = '3';
export const ELEVATION_MOUNTAIN = '4';
export const ELEVATION_SNOW = '5';

/*
 * ----------------------------------------------------------------------------
 * Biomes
 * ----------------------------------------------------------------------------
 */

export const BIOME_OCEAN = 'ocean';
export const BIOME_BEACH = 'beach';
export const BIOME_COAST = 'coasts';
export const BIOME_SEA_ICE = 'sea_ice';

export const BIOME_LAKE = 'lake';
export const BIOME_RIVER = 'river';

export const BIOME_TUNDRA = 'tundra';
export const BIOME_TAIGA = 'taiga';

export const BIOME_TEMPERATE_FOREST = 'temperate_forest';

export const BIOME_GRASSLAND = 'grassland';

export const BIOME_SAVANNA = 'savanna';

export const BIOME_DESERT = 'desert';

export const BIOME_TROPICAL_FOREST = 'tropical_forest';

export const BIOME_RAINFOREST = 'rainforest';

export const BIOME_MOUNTAINS = 'mountains';

export const BIOME_SNOW = 'snow';

/*
 * ----------------------------------------------------------------------------
 * Planet materials
 * ----------------------------------------------------------------------------
 */

export const PLANET_MATERIAL_NONE = 'none';
export const PLANET_MATERIAL_GRANITE = 'granite';
export const PLANET_MATERIAL_LIMESTONE = 'limestone';
export const PLANET_MATERIAL_SANDSTONE = 'sandstone';
export const PLANET_MATERIAL_SLATE = 'slate';
export const PLANET_MATERIAL_MARBLE = 'marble';
export const PLANET_MATERIAL_OBSIDIAN = 'obsidian';
export const PLANET_MATERIAL_JADE = 'jade';

/*
 * ----------------------------------------------------------------------------
 * Sub-biomes
 * ----------------------------------------------------------------------------
 */

export const SUBBIOME_DEEP_OCEAN = 'deep_ocean';
export const SUBBIOME_FROZEN_OCEAN = 'frozen_ocean';
export const SUBBIOME_SHORE = 'shore';
export const SUBBIOME_PLAINS = 'plains';
export const SUBBIOME_HILLS = 'hills';
export const SUBBIOME_ROCKY_HILLS = 'rocky_hills';
export const SUBBIOME_FOREST = 'forest';
export const SUBBIOME_FOREST_HILLS = 'forest_hills';
export const SUBBIOME_TUNDRA_PLAINS = 'tundra_plains';
export const SUBBIOME_SNOWFIELDS = 'snowfields';
export const SUBBIOME_MARSH = 'marsh';

/*
 * ----------------------------------------------------------------------------
 * Biome colors
 * ----------------------------------------------------------------------------
 *
 * These are purely visual and do not affect generation.
 */
export const BIOME_COLORS: Record<string, number> = {
  [BIOME_OCEAN]: 0x2b526b,
  [BIOME_COAST]: 0x5f8795,
  [BIOME_LAKE]: 0x4f7f91,
  [BIOME_RIVER]: 0x6b9bb0,

  [BIOME_BEACH]: 0xd8c58f,

  [BIOME_DESERT]: 0xd6bd7a,
  [BIOME_SAVANNA]: 0xb0aa68,
  [BIOME_GRASSLAND]: 0x8da85b,

  [BIOME_TEMPERATE_FOREST]: 0x5d8248,
  [BIOME_TAIGA]: 0x4f6947,
  [BIOME_TROPICAL_FOREST]: 0x4d8749,
  [BIOME_RAINFOREST]: 0x39733f,

  [BIOME_TUNDRA]: 0x8f9789,
  [BIOME_MOUNTAINS]: 0x77786f,

  [BIOME_SEA_ICE]: 0xbfcbd0,
  [BIOME_SNOW]: 0xe4e5df,
};
