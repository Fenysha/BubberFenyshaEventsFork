import * as THREE from 'three';

import { BIOME_COLORS } from '../generation/constants';
import type { PlanetGenerator } from '../generation/generator';
import type { PlanetMapData } from '../types';
import { gridFor } from './coordinates';
import { iconFrame, resolveTileIcon } from './PlanetIcons';

const stableVariation = (x: number, y: number, seed: number): number => {
  const value =
    Math.sin(x * 127.1 + y * 311.7 + seed * 0.01337) * 43758.5453123;
  const normalized = value - Math.floor(value);
  return 0.94 + normalized * 0.08;
};

export type PlanetTextures = {
  /** Biome colour, one texel per tile: texel (x - 1, y - 1) is tile (x, y) */
  color: THREE.DataTexture;
  /** Same layout. R: decor atlas frame + 1 (0 for none). G: river mask. B, A: free. */
  decor: THREE.DataTexture;
};

const tileTexture = (
  pixels: Uint8Array,
  width: number,
  height: number,
  srgb: boolean,
): THREE.DataTexture => {
  const texture = new THREE.DataTexture(
    pixels,
    width,
    height,
    THREE.RGBAFormat,
    THREE.UnsignedByteType,
  );
  if (srgb) {
    texture.colorSpace = THREE.SRGBColorSpace;
  }
  texture.wrapS = THREE.ClampToEdgeWrapping;
  texture.wrapT = THREE.ClampToEdgeWrapping;
  texture.magFilter = THREE.NearestFilter;
  texture.minFilter = THREE.NearestFilter;
  texture.generateMipmaps = false;
  texture.flipY = false;
  texture.needsUpdate = true;
  return texture;
};

/**
 * Evaluates every tile once and bakes both per-tile textures. The surface shader finds the
 * tile under each fragment and reads its texels directly.
 */
export const buildPlanetTextures = (
  data: PlanetMapData,
  generator: PlanetGenerator,
): PlanetTextures => {
  const grid = gridFor(data);
  const width = grid.width;
  const height = grid.height;
  const color = new Uint8Array(width * height * 4);
  const decor = new Uint8Array(width * height * 4);
  const tint = new THREE.Color();

  for (let y = 1; y <= height; y++) {
    for (let x = 1; x <= width; x++) {
      if (!grid.isValid(x, y)) {
        continue;
      }
      const tile = generator.getTile(x, y);
      tint.set(BIOME_COLORS[tile.biome] ?? 0xff00ff);
      tint.convertLinearToSRGB();
      tint.multiplyScalar(stableVariation(x, y, data.terrainSeed));

      const index = ((y - 1) * width + (x - 1)) * 4;
      color[index] = Math.round(THREE.MathUtils.clamp(tint.r, 0, 1) * 255);
      color[index + 1] = Math.round(THREE.MathUtils.clamp(tint.g, 0, 1) * 255);
      color[index + 2] = Math.round(THREE.MathUtils.clamp(tint.b, 0, 1) * 255);
      color[index + 3] = 255;

      decor[index] =
        iconFrame(resolveTileIcon(tile, x, y, data.terrainSeed ?? 0)) + 1;
      decor[index + 1] = generator.getRiverMask(x, y);
    }
  }

  return {
    color: tileTexture(color, width, height, true),
    decor: tileTexture(decor, width, height, false),
  };
};
