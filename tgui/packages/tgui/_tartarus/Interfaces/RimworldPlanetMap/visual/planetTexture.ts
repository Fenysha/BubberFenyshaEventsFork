import * as THREE from 'three';

import { BIOME_COLORS } from '../generation/constants';
import type { PlanetGenerator } from '../generation/generator';
import type { PlanetMapData } from '../types';
import { getRowWidth } from './coordinates';

const stableVariation = (x: number, y: number, seed: number): number => {
  const value =
    Math.sin(x * 127.1 + y * 311.7 + seed * 0.01337) * 43758.5453123;
  const normalized = value - Math.floor(value);
  return 0.94 + normalized * 0.08;
};

export const buildPlanetTexture = (
  data: PlanetMapData,
  generator: PlanetGenerator,
): THREE.DataTexture => {
  const width = data.width;
  const height = data.height;

  const pixels = new Uint8Array(width * height * 4);

  for (let y = 0; y < height; y++) {
    const rowWidth = getRowWidth(y, height, width);

    for (let px = 0; px < width; px++) {
      const x = Math.floor((px / width) * rowWidth);
      const tile = generator.getTile(x + 1, y + 1);

      const color = new THREE.Color(BIOME_COLORS[tile.biome] ?? 0xff00ff);
      color.convertLinearToSRGB();

      const variation = stableVariation(x, y, data.terrainSeed);
      color.multiplyScalar(variation);

      const index = (y * width + px) * 4;

      pixels[index] = Math.round(THREE.MathUtils.clamp(color.r, 0, 1) * 255);
      pixels[index + 1] = Math.round(
        THREE.MathUtils.clamp(color.g, 0, 1) * 255,
      );
      pixels[index + 2] = Math.round(
        THREE.MathUtils.clamp(color.b, 0, 1) * 255,
      );
      pixels[index + 3] = 255;
    }
  }

  const texture = new THREE.DataTexture(
    pixels,
    width,
    height,
    THREE.RGBAFormat,
    THREE.UnsignedByteType,
  );

  texture.colorSpace = THREE.SRGBColorSpace;
  texture.wrapS = THREE.RepeatWrapping;
  texture.wrapT = THREE.ClampToEdgeWrapping;
  texture.magFilter = THREE.NearestFilter;
  texture.minFilter = THREE.NearestFilter;
  texture.generateMipmaps = false;
  texture.flipY = false;
  texture.needsUpdate = true;

  return texture;
};
