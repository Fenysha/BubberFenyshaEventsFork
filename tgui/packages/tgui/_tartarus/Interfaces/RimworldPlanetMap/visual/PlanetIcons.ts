import { resolveAsset } from 'tgui/assets';

const FRAME_COUNT = 4;

/**
 * Every decor sheet, in atlas order. A tile's frame is sheet index * FRAME_COUNT + variant, and
 * rust-utils' tp_planet_surface.rs bakes those frames with the same order: append new sheets
 * there and here, don't reorder. DM registers the matching PNGs in planet_icons.dm.
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

export type LoadedIconSheet = {
  image: HTMLImageElement;
  frameSize: number;
  frameCount: number;
};

const iconSheetCache = new Map<string, Promise<LoadedIconSheet | null>>();

const ICON_LOAD_TIMEOUT_MS = 8000;

export const loadIconSheet = (
  name: string,
): Promise<LoadedIconSheet | null> => {
  const cached = iconSheetCache.get(name);
  if (cached) {
    return cached;
  }

  const promise = new Promise<LoadedIconSheet | null>((resolve) => {
    let settled = false;
    const finish = (result: LoadedIconSheet | null, isFailure: boolean) => {
      if (settled) {
        return;
      }
      settled = true;
      if (isFailure) {
        // Don't leave a failed attempt cached — let the next caller retry from scratch.
        iconSheetCache.delete(name);
      }
      resolve(result);
    };

    const timer: NodeJS.Timeout = setTimeout(() => {
      console.warn(`[planetIcons] Timeout loading asset "${name}".`);
      finish(null, true);
    }, ICON_LOAD_TIMEOUT_MS);

    let src: string | null = null;
    try {
      src = resolveAsset(`rimworld_planet_icon_${name}.png`);
    } catch (error) {
      console.warn(`[planetIcons] resolveAsset("${name}") failed:`, error);
    }

    if (!src) {
      clearTimeout(timer);
      finish(null, true);
      return;
    }

    const image = new Image();
    image.crossOrigin = 'anonymous';
    image.decoding = 'async';
    image.onload = () => {
      clearTimeout(timer);
      const frameSize = image.naturalHeight || 64;
      const frameCount = Math.floor(image.naturalWidth / frameSize) || 4;
      finish({ image, frameSize, frameCount }, false);
    };
    image.onerror = () => {
      clearTimeout(timer);
      console.warn(
        `[planetIcons] Failed to load icon sheet "${name}" (${src}).`,
      );
      finish(null, true);
    };
    image.src = src;
  });

  iconSheetCache.set(name, promise);
  return promise;
};
