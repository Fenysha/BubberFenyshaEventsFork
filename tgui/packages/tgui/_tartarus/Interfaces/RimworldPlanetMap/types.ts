export type PlanetObject = {
  id: string;
  type: string;
  name: string;
  x: number;
  y: number;
  icon?: string | null;
  data?: Record<string, unknown>;
};

export type PlanetTile = {
  biome: string;
  temperature: number;
  heat: number;
  humidity: number;
  elevation: number;
};

export type PlanetMapData = {
  name: string;

  seed: number;

  width: number;
  height: number;

  terrainScale: number;
  heatScale: number;
  humidityScale: number;

  noiseScale: number;

  heatThresholdLow: number;
  heatThresholdHigh: number;

  humidityThresholdLow: number;
  humidityThresholdHigh: number;

  objects: PlanetObject[];

  generatorVersion: number;
};
