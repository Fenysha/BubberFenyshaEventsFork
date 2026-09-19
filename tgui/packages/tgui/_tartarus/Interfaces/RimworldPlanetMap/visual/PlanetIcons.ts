import { resolveAsset } from 'tgui/assets';
import {
  BIOME_DESERT,
  BIOME_GRASSLAND,
  BIOME_RAINFOREST,
  BIOME_SAVANNA,
  BIOME_SEA_ICE,
  BIOME_TROPICAL_FOREST,
  SUBBIOME_FOREST,
  SUBBIOME_FOREST_HILLS,
  SUBBIOME_FROZEN_OCEAN,
  SUBBIOME_HILLS,
  SUBBIOME_MARSH,
  SUBBIOME_PLAINS,
  SUBBIOME_ROCKY_HILLS,
  SUBBIOME_SNOWFIELDS,
  SUBBIOME_TUNDRA_PLAINS,
} from '../generation/constants';
import type { PlanetTile } from '../types';

const FRAME_COUNT = 4;

/**
 * Every decor sheet, in atlas order. A tile's frame is sheet index * FRAME_COUNT + variant, so
 * the order is part of the per-tile decor data: append new sheets, don't reorder. DM registers
 * the matching PNGs in planet_icons.dm.
 */
export const ICON_SHEETS = [
  'mountains',
  'mountains_i',
  'hills',
  'hills_big',
  'forest',
  'forest_d',
  'grass',
  'marsh',
  'tundra',
  'dunes',
  'snow',
  'ice',
] as const;

export const ICON_FRAME_COUNT = FRAME_COUNT;

/** Atlas frame for a resolved icon, or -1 for none. */
export const iconFrame = (icon: ResolvedIcon | null): number => {
  if (!icon) {
    return -1;
  }
  const sheet = ICON_SHEETS.indexOf(icon.sheet as (typeof ICON_SHEETS)[number]);
  return sheet < 0 ? -1 : sheet * FRAME_COUNT + icon.variant;
};

export type ResolvedIcon = {
  sheet: string;
  variant: number;
};

export type LoadedIconSheet = {
  image: HTMLImageElement;
  frameSize: number;
  frameCount: number;
};

const hashUnit = (x: number, y: number, seed: number, salt: number): number => {
  const value =
    Math.sin(x * 127.1 + y * 311.7 + seed * 0.01337 + salt * 57.31) *
    43758.5453123;
  return value - Math.floor(value);
};

const pickVariant = (
  x: number,
  y: number,
  seed: number,
  salt: number,
): number => Math.floor(hashUnit(x, y, seed, salt) * FRAME_COUNT) % FRAME_COUNT;

export const resolveTileIcon = (
  tile: PlanetTile,
  x: number,
  y: number,
  seed: number,
): ResolvedIcon | null => {
  const { subBiome, biome, precipitation = 0, rainfall = 0 } = tile;

  switch (subBiome) {
    case SUBBIOME_ROCKY_HILLS: {
      const impassable = hashUnit(x, y, seed, 71) < 0.18;
      return {
        sheet: impassable ? 'mountains_i' : 'mountains',
        variant: pickVariant(x, y, seed, 131),
      };
    }

    case SUBBIOME_HILLS: {
      const big = hashUnit(x, y, seed, 53) < 0.35;
      return {
        sheet: big ? 'hills_big' : 'hills',
        variant: pickVariant(x, y, seed, 149),
      };
    }

    case SUBBIOME_FOREST:
    case SUBBIOME_FOREST_HILLS: {
      const isTropical =
        biome === BIOME_RAINFOREST || biome === BIOME_TROPICAL_FOREST;
      const isVeryWet = precipitation >= 0.55 || rainfall >= 0.4;

      if (precipitation < 0.2 && hashUnit(x, y, seed, 88) > 0.5) {
        return null;
      }

      const dense = isTropical || isVeryWet;
      return {
        sheet: dense ? 'forest_d' : 'forest',
        variant: pickVariant(x, y, seed, 197),
      };
    }

    case SUBBIOME_PLAINS: {
      if (precipitation > 0.6 && hashUnit(x, y, seed, 31) < 0.25) {
        return {
          sheet: 'forest',
          variant: pickVariant(x, y, seed, 197),
        };
      }
      if (biome === BIOME_DESERT) {
        return hashUnit(x, y, seed, 211) < 0.7
          ? { sheet: 'dunes', variant: pickVariant(x, y, seed, 223) }
          : null;
      }
      if (biome === BIOME_GRASSLAND || biome === BIOME_SAVANNA) {
        return hashUnit(x, y, seed, 227) < 0.55
          ? { sheet: 'grass', variant: pickVariant(x, y, seed, 229) }
          : null;
      }
      return null;
    }

    case SUBBIOME_MARSH:
      return { sheet: 'marsh', variant: pickVariant(x, y, seed, 233) };

    case SUBBIOME_TUNDRA_PLAINS:
      return hashUnit(x, y, seed, 239) < 0.6
        ? { sheet: 'tundra', variant: pickVariant(x, y, seed, 241) }
        : null;

    case SUBBIOME_SNOWFIELDS:
      if (biome === BIOME_SEA_ICE) {
        return { sheet: 'ice', variant: pickVariant(x, y, seed, 251) };
      }
      return hashUnit(x, y, seed, 257) < 0.6
        ? { sheet: 'snow', variant: pickVariant(x, y, seed, 263) }
        : null;

    case SUBBIOME_FROZEN_OCEAN:
      return hashUnit(x, y, seed, 269) < 0.5
        ? { sheet: 'ice', variant: pickVariant(x, y, seed, 271) }
        : null;

    default:
      return null;
  }
};

const iconSheetCache = new Map<string, Promise<LoadedIconSheet | null>>();

export const loadIconSheet = (
  name: string,
): Promise<LoadedIconSheet | null> => {
  const cached = iconSheetCache.get(name);
  if (cached) {
    return cached;
  }

  const promise = new Promise<LoadedIconSheet | null>((resolve) => {
    const timer: NodeJS.Timeout | null = setTimeout(() => {
      console.warn(`[planetIcons] Timeout loading asset "${name}".`);
      resolve(null);
    }, 2500);

    let src: string | null = null;
    try {
      src = resolveAsset(`rimworld_planet_icon_${name}.png`);
    } catch (error) {
      console.warn(`[planetIcons] resolveAsset("${name}") failed:`, error);
    }

    if (!src) {
      if (timer) clearTimeout(timer);
      resolve(null);
      return;
    }

    const image = new Image();
    image.crossOrigin = 'anonymous';
    image.decoding = 'async';
    image.onload = () => {
      if (timer) clearTimeout(timer);
      const frameSize = image.naturalHeight || 64;
      const frameCount = Math.floor(image.naturalWidth / frameSize) || 4;
      resolve({ image, frameSize, frameCount });
    };
    image.onerror = () => {
      if (timer) clearTimeout(timer);
      console.warn(
        `[planetIcons] Failed to load icon sheet "${name}" (${src}).`,
      );
      resolve(null);
    };
    image.src = src;
  });

  iconSheetCache.set(name, promise);
  return promise;
};
