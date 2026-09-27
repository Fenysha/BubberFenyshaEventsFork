import * as THREE from 'three';
import { resolveAsset } from 'tgui/assets';

import type { PlanetMapData } from '../types';
import { gridFor } from './coordinates';

export type PlanetTextures = {
  /** Biome colour, one texel per tile: texel (x - 1, y - 1) is tile (x, y) */
  color: THREE.Texture;
  /** Same layout. R: decor atlas frame + 1 (0 for none) in the low six bits, road grade in the top two. G: river mask. B: road mask. */
  decor: THREE.Texture;
  /** Size of the two PNGs they were decoded from */
  bytes: number;
};

const setupTileTexture = <T extends THREE.Texture>(
  texture: T,
  srgb: boolean,
): T => {
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

const loadBakedTexture = async (
  name: string,
  width: number,
  height: number,
  srgb: boolean,
): Promise<{ texture: THREE.Texture; bytes: number }> => {
  const response = await fetch(resolveAsset(`rimworld_planet_${name}.png`));
  if (!response.ok) {
    throw new Error(`${name}: ${response.status} ${response.statusText}`);
  }
  const blob = await response.blob();
  // Raw bytes: the decor channels are bitmasks, not colours
  const bitmap = await createImageBitmap(blob, {
    premultiplyAlpha: 'none',
    colorSpaceConversion: 'none',
    imageOrientation: 'none',
  });
  if (bitmap.width !== width || bitmap.height !== height) {
    bitmap.close();
    throw new Error(
      `${name}: ${bitmap.width}x${bitmap.height}, expected ${width}x${height}`,
    );
  }
  return {
    texture: setupTileTexture(new THREE.Texture(bitmap), srgb),
    bytes: blob.size,
  };
};

export const formatBytes = (bytes: number): string =>
  `${(bytes / 1024 / 1024).toFixed(2)} MB`;

/** The server's baked textures (tp_planet_bake_surface), or null when it has none. */
export const loadBakedPlanetTextures = async (
  data: PlanetMapData,
): Promise<PlanetTextures | null> => {
  const grid = gridFor(data);
  const started = performance.now();
  try {
    const [color, decor] = await Promise.all([
      loadBakedTexture('surface_color', grid.width, grid.height, true),
      loadBakedTexture('surface_decor', grid.width, grid.height, false),
    ]);
    const bytes = color.bytes + decor.bytes;
    // eslint-disable-next-line no-console
    console.info(
      `[Planet] Surface textures loaded from assets in ${Math.round(performance.now() - started)} ms (colour ${formatBytes(color.bytes)} + decor ${formatBytes(decor.bytes)} = ${formatBytes(bytes)})`,
    );
    return { color: color.texture, decor: decor.texture, bytes };
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('[Planet] Could not load the baked surface:', error);
    return null;
  }
};
