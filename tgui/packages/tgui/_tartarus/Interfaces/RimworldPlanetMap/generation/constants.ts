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
  [BIOME_OCEAN]: 0x1b4d73,
  [BIOME_BEACH]: 0xd7c27d,

  [BIOME_TUNDRA]: 0x9ca89b,
  [BIOME_TAIGA]: 0x4f6b55,

  [BIOME_TEMPERATE_FOREST]: 0x4f7f4f,
  [BIOME_GRASSLAND]: 0x91a85c,
  [BIOME_SAVANNA]: 0xb39a52,

  [BIOME_DESERT]: 0xc9a45c,

  [BIOME_TROPICAL_FOREST]: 0x3f8a4f,
  [BIOME_RAINFOREST]: 0x1f6b3a,

  [BIOME_MOUNTAINS]: 0x6e6e6e,
  [BIOME_SNOW]: 0xe8edf0,
};
