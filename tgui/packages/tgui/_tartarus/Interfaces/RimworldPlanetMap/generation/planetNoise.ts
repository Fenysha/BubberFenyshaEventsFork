/*
 * Copyright (c) 2026 Fenysha
 * All rights reserved.
 */

import { resolveAsset } from 'tgui/assets';

export interface PlanetLayer {
  name: string;
  width: number;
  height: number;
  bitsPerCell: number;
  payload: Uint8Array;
}

export interface PlanetLayers {
  elevation: PlanetLayer;
  heat: PlanetLayer;
  humidity: PlanetLayer;
  precipitation: PlanetLayer;
  geology: PlanetLayer;
}

type CacheEntry = {
  data: PlanetLayers | null;
  loading: boolean;
  error: Error | null;
};

const layerCache = new Map<string, CacheEntry>();

const LAYER_NAMES = [
  'elevation',
  'heat',
  'humidity',
  'precipitation',
  'geology',
] as const;

type LayerName = (typeof LAYER_NAMES)[number];

function getCacheKey(
  seed: number,
  generationRevision: number,
  width: number,
  height: number,
): string {
  return `${seed}:${generationRevision}:${width}x${height}`;
}

function parseTpl1(buffer: ArrayBuffer, expectedName: string): PlanetLayer {
  const view = new DataView(buffer);
  const bytes = new Uint8Array(buffer);

  if (bytes.length < 20) {
    throw new Error(
      `Layer ${expectedName}: file too small (${bytes.length} bytes)`,
    );
  }

  const magic = String.fromCharCode(bytes[0], bytes[1], bytes[2], bytes[3]);
  if (magic !== 'TPL1') {
    // Часто сюда попадает HTML/текст 404 или JSON ошибка
    const preview = new TextDecoder()
      .decode(bytes.subarray(0, Math.min(80, bytes.length)))
      .replace(/\s+/g, ' ');
    throw new Error(
      `Layer ${expectedName}: invalid magic "${magic}". Preview: ${preview}`,
    );
  }

  const version = bytes[4];
  if (version !== 1) {
    throw new Error(`Layer ${expectedName}: unsupported version ${version}`);
  }

  const bitsPerCell = bytes[6];
  if (bitsPerCell < 1 || bitsPerCell > 8) {
    throw new Error(`Layer ${expectedName}: bad bitsPerCell ${bitsPerCell}`);
  }

  const width = view.getUint32(12, true);
  const height = view.getUint32(16, true);

  if (width === 0 || height === 0) {
    throw new Error(`Layer ${expectedName}: invalid dimensions ${width}x${height}`);
  }

  const payload = bytes.subarray(20);
  const expectedBits = width * height * bitsPerCell;
  const expectedBytes = Math.ceil(expectedBits / 8);

  if (payload.length < expectedBytes) {
    throw new Error(
      `Layer ${expectedName}: payload too short ` +
        `(${payload.length} < ${expectedBytes})`,
    );
  }

  return {
    name: expectedName,
    width,
    height,
    bitsPerCell,
    payload,
  };
}

export function extractPackedValue(layer: PlanetLayer, index: number): number {
  const { bitsPerCell, payload } = layer;
  const bitOffset = index * bitsPerCell;
  let value = 0;

  for (let bit = 0; bit < bitsPerCell; bit++) {
    const absoluteBit = bitOffset + bit;
    const byteIndex = absoluteBit >>> 3;
    const bitIndex = absoluteBit & 7;

    if (byteIndex >= payload.length) {
      return 0;
    }

    if ((payload[byteIndex] & (1 << bitIndex)) !== 0) {
      value |= 1 << bit;
    }
  }

  return value;
}

export function getLayerCell(layer: PlanetLayer, x: number, y: number): number {
  if (x < 1 || y < 1 || x > layer.width || y > layer.height) {
    return 0;
  }
  const index = (y - 1) * layer.width + (x - 1);
  return extractPackedValue(layer, index);
}

async function loadLayer(name: LayerName): Promise<PlanetLayer> {
  const assetName = `rimworld_planet_${name}.bin`;
  const url = resolveAsset(assetName);

  if (!url) {
    throw new Error(`resolveAsset returned empty for ${assetName}`);
  }

  // eslint-disable-next-line no-console
  console.info(`[PlanetLayers] loading ${assetName} -> ${url}`);

  const response = await fetch(url, {
    cache: 'no-store', // важнее свежесть, чем force-cache на этапе отладки
  });

  if (!response.ok) {
    throw new Error(
      `Failed to load ${assetName}: ${response.status} ${response.statusText} (${url})`,
    );
  }

  const buffer = await response.arrayBuffer();

  // eslint-disable-next-line no-console
  console.info(`[PlanetLayers] ${assetName} loaded, ${buffer.byteLength} bytes`);

  return parseTpl1(buffer, name);
}

function startLayersLoad(
  cacheKey: string,
  width: number,
  height: number,
): void {
  const entry = layerCache.get(cacheKey);
  if (!entry || entry.loading || entry.data) {
    return;
  }

  entry.loading = true;
  entry.error = null;

  Promise.all(LAYER_NAMES.map((name) => loadLayer(name)))
    .then((layers) => {
      const byName = Object.fromEntries(
        layers.map((layer) => [layer.name, layer]),
      ) as Record<LayerName, PlanetLayer>;

      for (const name of LAYER_NAMES) {
        const layer = byName[name];
        if (layer.width !== width || layer.height !== height) {
          throw new Error(
            `Layer ${name} size mismatch: ` +
              `expected ${width}x${height}, got ${layer.width}x${layer.height}`,
          );
        }
      }

      // Sanity: elevation should not be all zeros on a real map
      let nonZero = 0;
      const elev = byName.elevation;
      const sampleCount = Math.min(1000, elev.width * elev.height);
      for (let i = 0; i < sampleCount; i++) {
        if (extractPackedValue(elev, i) !== 0) {
          nonZero++;
        }
      }

      // eslint-disable-next-line no-console
      console.info(
        `[PlanetLayers] ready. elevation non-zero samples: ${nonZero}/${sampleCount}`,
      );

      entry.data = {
        elevation: byName.elevation,
        heat: byName.heat,
        humidity: byName.humidity,
        precipitation: byName.precipitation,
        geology: byName.geology,
      };
      entry.loading = false;
    })
    .catch((error) => {
      // eslint-disable-next-line no-console
      console.error('[PlanetLayers] load failed:', error);
      entry.error = error instanceof Error ? error : new Error(String(error));
      entry.loading = false;
    });
}

export interface PlanetLayersHandle {
  isReady(): boolean;
  isLoading(): boolean;
  hasError(): boolean;
  get(): PlanetLayers | null;
  getError(): Error | null;
}

export function getPlanetLayers(
  seed: number,
  generationRevision: number,
  width: number,
  height: number,
): PlanetLayersHandle {
  const cacheKey = getCacheKey(seed, generationRevision, width, height);

  let entry = layerCache.get(cacheKey);
  if (!entry) {
    entry = { data: null, loading: false, error: null };
    layerCache.set(cacheKey, entry);
  }

  startLayersLoad(cacheKey, width, height);

  return {
    isReady: () => entry!.data !== null,
    isLoading: () => entry!.loading,
    hasError: () => entry!.error !== null,
    get: () => entry!.data,
    getError: () => entry!.error,
  };
}

export function clearPlanetLayersCache(): void {
  layerCache.clear();
}
