import * as THREE from 'three';

import { ICON_FRAME_COUNT, ICON_SHEETS, loadIconSheet } from './PlanetIcons';

/** Every decor frame is drawn into a square of this many pixels. */
export const ATLAS_FRAME_SIZE = 128;
export const ATLAS_COLUMNS = 8;
export const ATLAS_ROWS = Math.ceil(
  (ICON_SHEETS.length * ICON_FRAME_COUNT) / ATLAS_COLUMNS,
);
/** Transparent margin inside each frame, so mip levels don't bleed between frames */
const FRAME_PADDING = 4;

let atlas: Promise<THREE.CanvasTexture> | null = null;

/**
 * All decor sheets packed into one texture, frame f at column f % ATLAS_COLUMNS, row
 * f / ATLAS_COLUMNS (row 0 at the top). Built once and shared; a sheet that fails to load
 * just leaves its frames empty.
 */
export const getDecorAtlas = (): Promise<THREE.CanvasTexture> => {
  if (!atlas) {
    atlas = buildAtlas();
  }
  return atlas;
};

const buildAtlas = async (): Promise<THREE.CanvasTexture> => {
  const canvas = document.createElement('canvas');
  canvas.width = ATLAS_COLUMNS * ATLAS_FRAME_SIZE;
  canvas.height = ATLAS_ROWS * ATLAS_FRAME_SIZE;
  const context = canvas.getContext('2d');

  const sheets = await Promise.all(
    ICON_SHEETS.map((name) => loadIconSheet(name)),
  );
  sheets.forEach((sheet, sheetIndex) => {
    if (!sheet || !context) {
      return;
    }
    for (let variant = 0; variant < ICON_FRAME_COUNT; variant++) {
      const frame = sheetIndex * ICON_FRAME_COUNT + variant;
      const column = frame % ATLAS_COLUMNS;
      const row = Math.floor(frame / ATLAS_COLUMNS);
      context.drawImage(
        sheet.image,
        (variant % sheet.frameCount) * sheet.frameSize,
        0,
        sheet.frameSize,
        sheet.frameSize,
        column * ATLAS_FRAME_SIZE + FRAME_PADDING,
        row * ATLAS_FRAME_SIZE + FRAME_PADDING,
        ATLAS_FRAME_SIZE - FRAME_PADDING * 2,
        ATLAS_FRAME_SIZE - FRAME_PADDING * 2,
      );
    }
  });

  const texture = new THREE.CanvasTexture(canvas);
  texture.colorSpace = THREE.SRGBColorSpace;
  texture.wrapS = THREE.ClampToEdgeWrapping;
  texture.wrapT = THREE.ClampToEdgeWrapping;
  texture.minFilter = THREE.LinearMipmapLinearFilter;
  texture.magFilter = THREE.LinearFilter;
  texture.generateMipmaps = true;
  texture.needsUpdate = true;
  return texture;
};
