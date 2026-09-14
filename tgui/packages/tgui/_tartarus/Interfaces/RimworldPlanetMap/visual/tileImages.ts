import type * as THREE from 'three';

import type {
  PlanetTileImage,
} from '../types';

/**
 * Future tile-art pipeline.
 *
 * The server stores only sparse image keys (`tileImages`, `biomeImages`)
 * instead of a full planetary bitmap. When assets exist, load them here
 * and project them onto hex cells or overlay sprites.
 *
 * This file is intentionally a no-op until those assets exist.
 */

const textureCache =
  new Map<string, THREE.Texture>();


export const loadTileImage = async (
  src: string,
): Promise<THREE.Texture | null> => {
  if (!src) {
    return null;
  }

  const cached =
    textureCache.get(src);

  if (cached) {
    return cached;
  }

  /*
   * Future:
   *
   * const texture = await new THREE.TextureLoader().loadAsync(src);
   * texture.colorSpace = THREE.SRGBColorSpace;
   * textureCache.set(src, texture);
   * return texture;
   */

  return null;
};


export const applyTileImages = (
  _surface: THREE.Mesh,
  _tileImages?: PlanetTileImage[],
  _biomeImages?: Record<string, string>,
): void => {
  /*
   * Future:
   *
   * 1. Resolve biomeImages[tile.biome] as a fallback.
   * 2. Override with a matching tileImages entry for (x, y).
   * 3. Either:
   *    - tint/replace hex vertex colors from sampled textures, or
   *    - spawn billboards/decals at planetCoordinateToVector(x, y).
   */
};
