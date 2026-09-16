/*
 * Copyright (c) 2026 Fenysha
 * All rights reserved.
 */

import type { PlanetMapData, PlanetTile } from '../types';

import {
  BIOME_BEACH,
  BIOME_COAST,
  BIOME_DESERT,
  BIOME_GRASSLAND,
  BIOME_MOUNTAINS,
  BIOME_OCEAN,
  BIOME_RAINFOREST,
  BIOME_SAVANNA,
  BIOME_SEA_ICE,
  BIOME_SNOW,
  BIOME_TAIGA,
  BIOME_TEMPERATE_FOREST,
  BIOME_TROPICAL_FOREST,
  BIOME_TUNDRA,
  CLIMATE_HIGH,
  CLIMATE_LOW,
  CLIMATE_MEDIUM,
  ELEVATION_COAST,
  ELEVATION_HIGHLAND,
  ELEVATION_LOWLAND,
  ELEVATION_MOUNTAIN,
  ELEVATION_OCEAN,
  ELEVATION_SNOW,
  PLANET_MATERIAL_GRANITE,
  PLANET_MATERIAL_JADE,
  PLANET_MATERIAL_LIMESTONE,
  PLANET_MATERIAL_MARBLE,
  PLANET_MATERIAL_NONE,
  PLANET_MATERIAL_OBSIDIAN,
  PLANET_MATERIAL_SANDSTONE,
  PLANET_MATERIAL_SLATE,
  SUBBIOME_DEEP_OCEAN,
  SUBBIOME_FOREST,
  SUBBIOME_FOREST_HILLS,
  SUBBIOME_FROZEN_OCEAN,
  SUBBIOME_HILLS,
  SUBBIOME_MARSH,
  SUBBIOME_PLAINS,
  SUBBIOME_ROCKY_HILLS,
  SUBBIOME_SHORE,
  SUBBIOME_SNOWFIELDS,
  SUBBIOME_TUNDRA_PLAINS,
} from './constants';

import {
  getLayerCell,
  getPlanetLayers,
  type PlanetLayer,
  type PlanetLayers,
  type PlanetLayersHandle,
} from './planetNoise';

export type PlanetGeneratorState = 'loading' | 'ready' | 'error';

export class PlanetGenerator {
  public readonly data: PlanetMapData;
  private readonly layersHandle: PlanetLayersHandle;

  public constructor(data: PlanetMapData) {
    this.data = data;
    this.layersHandle = getPlanetLayers(
      data.seed,
      data.generationRevision,
      data.width,
      data.height,
    );
  }

  public getState(): PlanetGeneratorState {
    if (this.layersHandle.hasError()) {
      return 'error';
    }
    if (this.layersHandle.isReady()) {
      return 'ready';
    }
    return 'loading';
  }

  public isReady(): boolean {
    return this.layersHandle.isReady();
  }

  public isLoading(): boolean {
    return this.layersHandle.isLoading();
  }

  public getError(): Error | null {
    return this.layersHandle.getError();
  }

  private getLayers(): PlanetLayers | null {
    return this.layersHandle.get();
  }

  private clamp(value: number, low: number, high: number): number {
    return Math.max(low, Math.min(high, value));
  }

  // ==========================================================================
  // Coordinates
  // ==========================================================================

  public getRowWidth(y: number): number {
    if (y < 1 || y > this.data.height) {
      return this.data.width;
    }
    const v = (y - 0.5) / this.data.height;
    const latitudeDeg = v * 180 - 90;
    const latitudeRad = (latitudeDeg * Math.PI) / 180;
    const count = Math.round(this.data.width * Math.cos(latitudeRad));
    return Math.max(6, count);
  }

  private valid(x: number, y: number): boolean {
    if (y < 1 || y > this.data.height) {
      return false;
    }
    return x >= 1 && x <= this.getRowWidth(y);
  }

  /** Sample X on the full rectangular grid (1-based). */
  private getSampleX(x: number, y: number): number {
    const rowWidth = this.getRowWidth(y);
    const normalizedX = (x - 0.5) / rowWidth;
    return this.clamp(
      Math.floor(normalizedX * this.data.width) + 1,
      1,
      this.data.width,
    );
  }

  private readLayer(
    layer: PlanetLayer | undefined,
    x: number,
    y: number,
  ): number {
    if (!layer || !this.valid(x, y)) {
      return 0;
    }
    const sampleX = this.getSampleX(x, y);
    return getLayerCell(layer, sampleX, y);
  }

  // ==========================================================================
  // Elevation (0..5)
  // ==========================================================================

  public getElevation(x: number, y: number): string {
    if (!this.valid(x, y)) {
      return ELEVATION_OCEAN;
    }

    const layers = this.getLayers();
    if (!layers) {
      return ELEVATION_OCEAN;
    }

    const value = this.readLayer(layers.elevation, x, y);
    switch (value) {
      case 1:
        return ELEVATION_COAST;
      case 2:
        return ELEVATION_LOWLAND;
      case 3:
        return ELEVATION_HIGHLAND;
      case 4:
        return ELEVATION_MOUNTAIN;
      case 5:
        return ELEVATION_SNOW;
      default:
        return ELEVATION_OCEAN;
    }
  }

  // ==========================================================================
  // Climate (0..2)
  // ==========================================================================

  public getHeat(x: number, y: number): string {
    if (!this.valid(x, y)) {
      return CLIMATE_LOW;
    }

    const layers = this.getLayers();
    if (!layers) {
      return CLIMATE_LOW;
    }

    const value = this.readLayer(layers.heat, x, y);
    switch (value) {
      case 1:
        return CLIMATE_MEDIUM;
      case 2:
        return CLIMATE_HIGH;
      default:
        return CLIMATE_LOW;
    }
  }

  public getHumidity(x: number, y: number): string {
    if (!this.valid(x, y)) {
      return CLIMATE_LOW;
    }

    const layers = this.getLayers();
    if (!layers) {
      return CLIMATE_LOW;
    }

    const value = this.readLayer(layers.humidity, x, y);
    switch (value) {
      case 1:
        return CLIMATE_MEDIUM;
      case 2:
        return CLIMATE_HIGH;
      default:
        return CLIMATE_LOW;
    }
  }

  // ==========================================================================
  // Latitude
  // ==========================================================================

  private getLatitudeOffset(
    x: number,
    y: number,
    heat?: string,
    humidity?: string,
    elevation?: string,
  ): number {
    const h = heat ?? this.getHeat(x, y);
    const hm = humidity ?? this.getHumidity(x, y);
    const e = elevation ?? this.getElevation(x, y);

    const baseLat = (y - 1) / Math.max(1, this.data.height - 1);
    const polarFade = Math.sin(baseLat * Math.PI);

    let climateOffset = 0;
    if (h === CLIMATE_HIGH) climateOffset += 0.08;
    else if (h === CLIMATE_LOW) climateOffset -= 0.08;

    if (hm === CLIMATE_HIGH) climateOffset -= 0.04;
    else if (hm === CLIMATE_LOW) climateOffset += 0.04;

    if (e === ELEVATION_MOUNTAIN || e === ELEVATION_HIGHLAND)
      climateOffset -= 0.07;
    else if (e === ELEVATION_SNOW) climateOffset -= 0.12;

    const s = (this.data.seed ?? 0) % 10000;
    const angle1 = (x * 0.35 + y * 0.15 + s) % 360;
    const angle2 = (x * 0.85 - y * 0.45 + s * 1.3) % 360;
    const angle3 = (x * 1.7 + y * 1.1 + s * 2.1) % 360;
    const toRad = Math.PI / 180;

    const wave =
      (Math.sin(angle1 * toRad) * 0.06 +
        Math.cos(angle2 * toRad) * 0.04 +
        Math.sin(angle3 * toRad) * 0.02) *
      polarFade;

    return climateOffset + wave;
  }

  public getLatitude(x: number, y: number): number {
    if (!this.valid(x, y)) {
      return 0;
    }
    const normalized = (y - 0.5) / this.data.height;
    return normalized * 180 - 90;
  }

  // ==========================================================================
  // Materials (geology 0..6)
  // ==========================================================================

  public getMaterial(x: number, y: number, elevation?: string): string {
    if (!this.valid(x, y)) {
      return PLANET_MATERIAL_NONE;
    }

    const e = elevation ?? this.getElevation(x, y);
    if (e === ELEVATION_OCEAN) {
      return PLANET_MATERIAL_NONE;
    }

    const layers = this.getLayers();
    if (!layers) {
      return PLANET_MATERIAL_GRANITE;
    }

    const geo = this.readLayer(layers.geology, x, y);
    switch (geo) {
      case 0:
      case 1:
        return PLANET_MATERIAL_GRANITE;
      case 2:
        return PLANET_MATERIAL_LIMESTONE;
      case 3:
        return PLANET_MATERIAL_SANDSTONE;
      case 4:
        return PLANET_MATERIAL_SLATE;
      case 5:
        return PLANET_MATERIAL_MARBLE;
      case 6:
        return PLANET_MATERIAL_OBSIDIAN;
      default:
        return PLANET_MATERIAL_GRANITE;
    }
  }

  private getMaterialTemperatureModifier(material: string): number {
    switch (material) {
      case PLANET_MATERIAL_GRANITE:
        return -0.005;
      case PLANET_MATERIAL_LIMESTONE:
        return 0;
      case PLANET_MATERIAL_SANDSTONE:
        return 0.012;
      case PLANET_MATERIAL_SLATE:
        return -0.008;
      case PLANET_MATERIAL_MARBLE:
        return 0.008;
      case PLANET_MATERIAL_OBSIDIAN:
        return 0.018;
      case PLANET_MATERIAL_JADE:
        return 0.004;
      default:
        return 0;
    }
  }

  // ==========================================================================
  // Temperature
  // ==========================================================================

  public getTemperature(
    x: number,
    y: number,
    heat?: string,
    elevation?: string,
    material?: string,
  ): number {
    if (!this.valid(x, y)) {
      return 0;
    }

    const heatLevel = heat ?? this.getHeat(x, y);
    const e = elevation ?? this.getElevation(x, y);
    const m = material ?? this.getMaterial(x, y, e);

    const latitudeOffset = this.getLatitudeOffset(x, y, heatLevel);
    const baseLat = (y - 1) / Math.max(1, this.data.height - 1);
    const normalizedLatitude = this.clamp(baseLat + latitudeOffset, 0, 1);
    const latitudeDistance = Math.abs(normalizedLatitude - 0.5) * 2;
    const latitudeTemperature = Math.max(0, 1 - latitudeDistance) ** 1.8;

    let heatModifier = -0.15;
    if (heatLevel === CLIMATE_MEDIUM) heatModifier = 0.05;
    else if (heatLevel === CLIMATE_HIGH) heatModifier = 0.22;

    let elevationModifier = 0;
    switch (e) {
      case ELEVATION_HIGHLAND:
        elevationModifier = -0.1;
        break;
      case ELEVATION_MOUNTAIN:
        elevationModifier = -0.22;
        break;
      case ELEVATION_SNOW:
        elevationModifier = -0.35;
        break;
    }

    const materialModifier = this.getMaterialTemperatureModifier(m);

    const temperature =
      latitudeTemperature * 0.6 +
      (heatModifier + 0.15) * 0.25 +
      (elevationModifier + 0.35) * 0.15 +
      materialModifier;

    return this.clamp(temperature, 0, 1);
  }

  // ==========================================================================
  // Precipitation (layer 0..2)
  // ==========================================================================

  private getPrecipitationNoiseCategory(x: number, y: number): number {
    const layers = this.getLayers();
    if (!layers) {
      return 0;
    }
    return this.readLayer(layers.precipitation, x, y);
  }

  private getPrecipitationBase(category: number): number {
    switch (category) {
      case 2:
        return 0.78;
      case 1:
        return 0.5;
      default:
        return 0.2;
    }
  }

  public getPrecipitation(
    x: number,
    y: number,
    temperature?: number,
    humidity?: string,
    elevation?: string,
  ): number {
    if (!this.valid(x, y)) {
      return 0;
    }

    const t = temperature ?? this.getTemperature(x, y);
    const hm = humidity ?? this.getHumidity(x, y);
    const e = elevation ?? this.getElevation(x, y);

    let precipitation = this.getPrecipitationBase(
      this.getPrecipitationNoiseCategory(x, y),
    );

    if (hm === CLIMATE_HIGH) precipitation += 0.06;
    else if (hm === CLIMATE_LOW) precipitation -= 0.05;

    const latitude = Math.abs(this.getLatitude(x, y)) / 90;
    precipitation += (1 - latitude) * 0.08 - latitude * 0.05;
    precipitation += (t - 0.5) * 0.1;

    if (e === ELEVATION_HIGHLAND) precipitation += 0.025;
    else if (e === ELEVATION_MOUNTAIN) precipitation += 0.055;

    return this.clamp(precipitation, 0, 1);
  }

  public getRainfall(
    x: number,
    y: number,
    temperature?: number,
    precipitation?: number,
  ): number {
    const t = temperature ?? this.getTemperature(x, y);
    const p = precipitation ?? this.getPrecipitation(x, y, t);
    const rainFactor = this.clamp((t - 0.2) / 0.18, 0, 1);
    return p * rainFactor;
  }

  public getSnowfall(
    x: number,
    y: number,
    temperature?: number,
    precipitation?: number,
  ): number {
    const t = temperature ?? this.getTemperature(x, y);
    const p = precipitation ?? this.getPrecipitation(x, y, t);
    return Math.max(0, p - this.getRainfall(x, y, t, p));
  }

  public getWaterAvailability(
    x: number,
    y: number,
    precipitation?: number,
    elevation?: string,
  ): number {
    const p = precipitation ?? this.getPrecipitation(x, y);
    const e = elevation ?? this.getElevation(x, y);

    let value = p * 0.78;
    if (e === ELEVATION_LOWLAND) value += 0.08;
    else if (e === ELEVATION_HIGHLAND) value += 0.03;
    else if (e === ELEVATION_MOUNTAIN) value -= 0.04;

    return this.clamp(value, 0, 1);
  }

  // ==========================================================================
  // Sub-biome / Biome (same logic as before)
  // ==========================================================================

  public getSubBiome(
    x: number,
    y: number,
    biome?: string,
    elevation?: string,
    precipitation?: number,
    temperature?: number,
  ): string {
    if (!this.valid(x, y)) {
      return SUBBIOME_PLAINS;
    }

    const e = elevation ?? this.getElevation(x, y);
    const b = biome ?? this.getBiome(x, y);
    const p = precipitation ?? this.getPrecipitation(x, y, temperature);
    const t = temperature ?? this.getTemperature(x, y);

    if (e === ELEVATION_OCEAN) {
      return b === BIOME_SEA_ICE ? SUBBIOME_FROZEN_OCEAN : SUBBIOME_DEEP_OCEAN;
    }
    if (b === BIOME_SEA_ICE || b === BIOME_SNOW) {
      return SUBBIOME_SNOWFIELDS;
    }
    if (e === ELEVATION_COAST || b === BIOME_BEACH || b === BIOME_COAST) {
      return SUBBIOME_SHORE;
    }
    if (e === ELEVATION_MOUNTAIN || b === BIOME_MOUNTAINS) {
      return SUBBIOME_ROCKY_HILLS;
    }
    if (e === ELEVATION_HIGHLAND) {
      if (
        b === BIOME_TEMPERATE_FOREST ||
        b === BIOME_TROPICAL_FOREST ||
        b === BIOME_RAINFOREST ||
        b === BIOME_TAIGA
      ) {
        return SUBBIOME_FOREST_HILLS;
      }
      return SUBBIOME_HILLS;
    }
    if (e === ELEVATION_LOWLAND && p >= 0.72 && t > 0.24) {
      return SUBBIOME_MARSH;
    }
    if (
      b === BIOME_TEMPERATE_FOREST ||
      b === BIOME_TROPICAL_FOREST ||
      b === BIOME_RAINFOREST ||
      b === BIOME_TAIGA
    ) {
      return SUBBIOME_FOREST;
    }
    if (b === BIOME_TUNDRA) {
      return SUBBIOME_TUNDRA_PLAINS;
    }
    return SUBBIOME_PLAINS;
  }

  public getBiome(
    x: number,
    y: number,
    elevation?: string,
    heat?: string,
    humidity?: string,
    material?: string,
  ): string {
    if (!this.valid(x, y)) {
      return BIOME_OCEAN;
    }

    const e = elevation ?? this.getElevation(x, y);
    const h = heat ?? this.getHeat(x, y);
    const hm = humidity ?? this.getHumidity(x, y);
    const m = material ?? this.getMaterial(x, y, e);
    const temperature = this.getTemperature(x, y, h, e, m);
    const latitudeOffset = this.getLatitudeOffset(x, y, h, hm, e);
    const baseLat = (y - 1) / Math.max(1, this.data.height - 1);
    const normalizedLatitude = this.clamp(baseLat + latitudeOffset, 0, 1);
    const polarDistance = Math.abs((normalizedLatitude - 0.5) * 2);

    if (polarDistance >= 0.82) {
      return e === ELEVATION_OCEAN || e === ELEVATION_COAST
        ? BIOME_SEA_ICE
        : BIOME_SNOW;
    }

    if (polarDistance >= 0.7) {
      const polarStrength = this.clamp((polarDistance - 0.7) / 0.12, 0, 1);
      const polarTemperature = temperature * (1 - polarStrength);

      if (e === ELEVATION_OCEAN || e === ELEVATION_COAST) {
        if (polarTemperature <= 0.24) return BIOME_SEA_ICE;
      } else if (polarTemperature <= 0.22 || e === ELEVATION_SNOW) {
        return BIOME_SNOW;
      }
    }

    if (e === ELEVATION_OCEAN) {
      return temperature <= 0.14 ? BIOME_SEA_ICE : BIOME_OCEAN;
    }

    if (e === ELEVATION_COAST) {
      if (temperature <= 0.1) return BIOME_SEA_ICE;
      if (temperature >= 0.45 && hm === CLIMATE_LOW) return BIOME_BEACH;
      return BIOME_COAST;
    }

    if (temperature <= 0.1 || e === ELEVATION_SNOW) return BIOME_SNOW;
    if (temperature <= 0.2 && e === ELEVATION_MOUNTAIN) return BIOME_SNOW;
    if (e === ELEVATION_MOUNTAIN) return BIOME_MOUNTAINS;

    if (temperature < 0.3) {
      return hm === CLIMATE_HIGH ? BIOME_TAIGA : BIOME_TUNDRA;
    }

    if (temperature < 0.55) {
      if (hm === CLIMATE_HIGH) return BIOME_TEMPERATE_FOREST;
      if (hm === CLIMATE_MEDIUM) return BIOME_GRASSLAND;
      return BIOME_SAVANNA;
    }

    if (hm === CLIMATE_HIGH) return BIOME_RAINFOREST;
    if (hm === CLIMATE_MEDIUM) return BIOME_TROPICAL_FOREST;
    return BIOME_DESERT;
  }

  // ==========================================================================
  // Tile
  // ==========================================================================

  public getTile(x: number, y: number): PlanetTile {
    const elevation = this.getElevation(x, y);
    const heat = this.getHeat(x, y);
    const humidity = this.getHumidity(x, y);
    const material = this.getMaterial(x, y, elevation);
    const temperature = this.getTemperature(x, y, heat, elevation, material);
    const precipitation = this.getPrecipitation(
      x,
      y,
      temperature,
      humidity,
      elevation,
    );
    const rainfall = this.getRainfall(x, y, temperature, precipitation);
    const snowfall = this.getSnowfall(x, y, temperature, precipitation);
    const waterAvailability = this.getWaterAvailability(
      x,
      y,
      precipitation,
      elevation,
    );
    const biome = this.getBiome(x, y, elevation, heat, humidity, material);
    const subBiome = this.getSubBiome(
      x,
      y,
      biome,
      elevation,
      precipitation,
      temperature,
    );

    return {
      x,
      y,
      biome,
      subBiome,
      material,
      latitude: this.getLatitude(x, y),
      temperature,
      heat,
      humidity,
      precipitation,
      rainfall,
      snowfall,
      waterAvailability,
      elevation,
    };
  }
}
