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
/** True once every sheet made it into the currently-cached atlas. */
let atlasComplete = false;

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

  let allLoaded = true;
  sheets.forEach((sheet, sheetIndex) => {
    if (!sheet || !context) {
      allLoaded = false;
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

  atlasComplete = allLoaded;
  if (!allLoaded) {
    atlas = null;
  }
  return texture;
};

/** True once every decor sheet has successfully made it into the cached atlas. */
export const isDecorAtlasComplete = (): boolean => atlasComplete;
