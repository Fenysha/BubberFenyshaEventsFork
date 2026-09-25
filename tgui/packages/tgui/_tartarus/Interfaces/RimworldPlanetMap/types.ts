import type { BooleanLike } from 'tgui-core/react';
import type * as THREE from 'three';

export type PlanetViewType = 'admin' | 'caravan' | 'overview' | 'settlement';

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
    subBiome: tile.subBiome ?? 'plains',
    material: tile.material ?? 'none',
    latitude: tile.latitude ?? 0,
    temperature: tile.temperature ?? 0,
    heat: tile.heat ?? '0',
    humidity: tile.humidity ?? '0',
    precipitation: tile.precipitation ?? 0,
    rainfall: tile.rainfall ?? 0,
    snowfall: tile.snowfall ?? 0,
    waterAvailability: tile.waterAvailability ?? 0,
    elevation: tile.elevation ?? '0',
    river: Boolean(tile.river),
    objects: 'objects' in tile ? tile.objects : [],
  };
};

export type PlanetMapData = {
  name: string;
  seed: number;
  planetType: string;

  terrainSeed: number;
  heatSeed: number;
  humiditySeed: number;
  geologySeed: number;
  precipitationSeed: number;

  /** Layer grid size: 10n x (n + 1) for hex grid frequency n */
  width: number;
  height: number;
  /** Hex grid frequency n, see generation/hexGrid.ts */
  gridFrequency?: number;

  terrainScale: number;
  heatScale: number;
  humidityScale: number;
  geologyScale: number;
  precipitationScale: number;

  noiseScale: number;

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

  heatThresholdLow: number;
  heatThresholdHigh: number;
  humidityThresholdLow: number;
  humidityThresholdHigh: number;

  canControlTime?: boolean;
  calendar?: Record<string, unknown>;
  timeOfDay?: number;
  currentYear?: number;
  dayOfYear?: number;
  quadrum?: string;
  quadrumName?: string;
  dayOfQuadrum?: number;
  seasonNorth?: string;
  seasonSouth?: string;
  timeScale?: number;
  daysPerYear?: number;
  daysPerQuadrum?: number;
  quadrumNames?: string[];
  seasons?: string[];
  startingYear?: number;

  rotationAngle?: number;
  rotationSpeed?: number;
  autoRotate?: BooleanLike;

  objects: PlanetObject[];

  generatorVersion: number;
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

  view?: PlanetMapViewData;

  tileImages?: PlanetTileImage[];
  biomeImages?: Record<string, string>;
};

export interface PlanetCellData {
  id: string;
  x: number;
  y: number;

  elevation: number;
  heat: number;
  humidity: number;
  material: number;
  latitude: number;
  temperature: number;
  precipitation: number;
  rainfall: number;
  snowfall: number;
  waterAvailability: number;

  biome: string;
  subBiome: string;

  objects: PlanetObject[];

  image?: string | null;
  mapsLoaded: boolean;

  isGenerated: boolean;
  isGenerating: boolean;

  subLevelId?: string | null;

  weatherType: string;
  weatherIntensity: number;

  localWidth: number;
  localHeight: number;
}

export interface PlanetMapViewData {
  roadStartX?: number | null;
  roadStartY?: number | null;
  cell?: PlanetCellData | null;

  mode?: 'start' | 'observer';

  startX?: number | null;
  startY?: number | null;
  joinSettlementId?: string | null;

  canCreate?: BooleanLike;
  canJoin?: BooleanLike;

  playerSettlements?: PlayerSettlementInfo[];

  loadedCells?: LoadedCellInfo[];
}

export interface PlayerSettlementInfo {
  id: string;
  name: string;
  x: number;
  y: number;
  population: number;
  faction: string;
}

export interface LoadedCellInfo {
  x: number;
  y: number;
  id?: string;
  name?: string;
}

export type PlanetTile = {
  x?: number;
  y?: number;

  biome: string;
  subBiome: string;
  material: string;

  latitude: number;
  temperature: number;
  heat: string;
  humidity: string;

  precipitation: number;
  rainfall: number;
  snowfall: number;
  waterAvailability: number;

  season?: string;
  isDaylight?: boolean;
  sunIntensity?: number;

  elevation: string;
  /** A river runs through this tile */
  river?: boolean;
  objects?: PlanetObject[];
};

export type SelectedPlanetTile = {
  x: number;
  y: number;
  objects: PlanetObject[];
  image?: string | null;
  mapsLoaded?: BooleanLike;

  season?: string;
  isDaylight?: boolean;
  sunIntensity?: number;

  elevation?: string;
  temperature?: number;
  heat?: string;
  humidity?: string;
  biome?: string;
  subBiome?: string;
  material?: string;
  latitude?: number;
  precipitation?: number;
  rainfall?: number;
  snowfall?: number;
  waterAvailability?: number;
  river?: BooleanLike;
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
    data.geologySeed,
    data.precipitationSeed,
    data.width,
    data.height,
    data.terrainScale,
    data.heatScale,
    data.humidityScale,
    data.geologyScale,
    data.precipitationScale,
    data.noiseScale,
    data.planetType,
  ].join(':');
