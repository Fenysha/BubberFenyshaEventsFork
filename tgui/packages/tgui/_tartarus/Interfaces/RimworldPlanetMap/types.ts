import type { BooleanLike } from 'tgui-core/react';
import type * as THREE from 'three';

export type PlanetViewType = 'admin' | 'caravan' | 'overview';

export const selectedPlanetTileToPlanetTile = (
  tile: SelectedPlanetTile | PlanetTile | null | undefined,
): PlanetTile | null => {
  if (!tile) {
    return null;
  }

  return {
    x: tile.x,
    y: tile.y,
    biome: tile.biome ?? 'Unknown',
    temperature: tile.temperature ?? 0,
    heat: tile.heat ?? '0',
    humidity: tile.humidity ?? '0',
    elevation: tile.elevation ?? '0',
    objects: 'objects' in tile ? tile.objects : [],
  };
};

export type PlanetMapData = {
  name: string;

  seed: number;

  /**
   * Informational only.
   *
   * PlanetGenerator does NOT use this value to make decisions.
   * All actual parameters are already expanded below.
   */
  planetType: string;

  /**
   * Explicit derived seeds.
   *
   * These come directly from the server.
   */
  terrainSeed: number;
  heatSeed: number;
  humiditySeed: number;

  width: number;
  height: number;

  terrainScale: number;
  heatScale: number;
  humidityScale: number;

  /**
   * Corresponds directly to rustg_dbp_generate(...).
   */
  noiseScale: number;

  /**
   * Elevation ranges.
   */
  elevationOceanLow: number;
  elevationOceanHigh: number;

  elevationCoastLow: number;
  elevationCoastHigh: number;

  elevationLowlandLow: number;
  elevationLowlandHigh: number;

  elevationHighlandLow: number;
  elevationHighlandHigh: number;

  elevationMountainLow: number;
  elevationMountainHigh: number;

  elevationSnowLow: number;
  elevationSnowHigh: number;

  /**
   * Climate ranges.
   */
  heatThresholdLow: number;
  heatThresholdHigh: number;

  humidityThresholdLow: number;
  humidityThresholdHigh: number;

  /**
   * Dynamic Rotation parameters.
   */
  rotationAngle?: number;
  rotationSpeed?: number;
  autoRotate?: BooleanLike;

  /**
   * Interactive objects.
   */
  objects: PlanetObject[];

  /**
   * Deterministic generator format.
   */
  generatorVersion: number;

  /**
   * Bumps whenever the server regenerates generator parameters.
   */
  generationRevision: number;

  presets?: string[];

  viewType: PlanetViewType;
  windowTitle?: string;

  canEdit: BooleanLike;
  canRegenerate: BooleanLike;
  canSelectTiles: BooleanLike;

  mapsLoaded?: BooleanLike;

  selectedTile?: SelectedPlanetTile | null;
  selectedObject?: PlanetObject | null;

  view?: PlanetViewData;

  /**
   * Sparse per-tile overlay art. Never a full-resolution grid.
   */
  tileImages?: PlanetTileImage[];

  /**
   * Optional biome -> asset path. Unused until tile art exists.
   */
  biomeImages?: Record<string, string>;
};

export type PlanetViewData = {
  caravanId?: string | null;
  originX?: number | null;
  originY?: number | null;
  destinationX?: number | null;
  destinationY?: number | null;
  canTravel?: BooleanLike;
  status?: string;
  roadStartX?: number | null;
  roadStartY?: number | null;
};

export type PlanetTile = {
  x?: number;
  y?: number;
  biome: string;
  temperature: number;
  heat: string;
  humidity: string;
  elevation: string;
  objects?: PlanetObject[];
};

export type SelectedPlanetTile = {
  x: number;
  y: number;
  objects: PlanetObject[];
  image?: string | null;
  mapsLoaded?: BooleanLike;
  elevation?: string;
  temperature?: number;
  heat?: string;
  humidity?: string;
  biome?: string;
};

export type PlanetTileImage = {
  x: number;
  y: number;
  src: string;
};

export type PlanetObject = {
  id: string;

  type: string;

  name: string;

  x: number;
  y: number;

  icon: string | null;

  data: Record<string, unknown>;

  start_x?: number;
  start_y?: number;

  end_x?: number;
  end_y?: number;
};

export type PlanetGeometry = {
  surfaceGeometry: THREE.BufferGeometry;
  boundaryGeometry: THREE.BufferGeometry;
};

export type PlanetCallbacks = {
  onTileClick?: (x: number, y: number, tile: PlanetTile) => void;

  onObjectClick?: (object: PlanetObject) => void;
};

export const getPlanetMapIdentity = (data: PlanetMapData): string =>
  [
    data.generationRevision,
    data.seed,
    data.terrainSeed,
    data.heatSeed,
    data.humiditySeed,
    data.width,
    data.height,
    data.terrainScale,
    data.heatScale,
    data.humidityScale,
    data.noiseScale,
    data.planetType,
  ].join(':');
