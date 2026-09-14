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
 * Biome colors
 * ----------------------------------------------------------------------------
 *
 * These are purely visual and do not affect generation.
 */

export const BIOME_COLORS: Record<string, number> = {
  [BIOME_OCEAN]: 0x133854,
  [BIOME_COAST]: 0x2b729e,

  [BIOME_BEACH]: 0xe6d496,
  [BIOME_DESERT]: 0xdfb05b,
  [BIOME_SAVANNA]: 0xbe9f48,

  [BIOME_GRASSLAND]: 0x82b347,
  [BIOME_TEMPERATE_FOREST]: 0x488a48,
  [BIOME_TAIGA]: 0x2e5c42,

  [BIOME_TROPICAL_FOREST]: 0x2ca058,
  [BIOME_RAINFOREST]: 0x116e34,

  [BIOME_TUNDRA]: 0x8e9e8c,
  [BIOME_MOUNTAINS]: 0x727a85,
  [BIOME_SEA_ICE]: 0xf0f5f8,
  [BIOME_SNOW]: 0xf0f5f8,
};
