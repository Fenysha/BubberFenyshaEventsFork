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

  width: number;
  height: number;

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

  view?: PlanetViewData;

  tileImages?: PlanetTileImage[];
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
  subBiome?: string;
  material?: string;
  latitude?: number;
  precipitation?: number;
  rainfall?: number;
  snowfall?: number;
  waterAvailability?: number;
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
