import type { BooleanLike } from 'tgui-core/react';
import type * as THREE from 'three';

export type PlanetViewType = 'admin' | 'caravan' | 'overview' | 'settlement';

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
  dayLengthMinutes?: number;
  daysPerYear?: number;
  daysPerQuadrum?: number;
  quadrumNames?: string[];
  seasons?: string[];
  startingYear?: number;

  rotationAngle?: number;
  rotationSpeed?: number;
  autoRotate?: BooleanLike;

  /** Non-player settlements + roads; from ui_static_data */
  staticObjects?: PlanetObject[];

  /** Dynamic only (player settlements, POIs, …) from ui_data */
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

  tileImages?: PlanetTileImage[];
  biomeImages?: Record<string, string>;

  /** Current avatar tile on the hex map (1-based), if any */
  playerX?: number | null;
  playerY?: number | null;
  /** Base64 PNG of the avatar appearance (no data: prefix) */
  playerIcon?: string | null;
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
  color?: string | null;
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
