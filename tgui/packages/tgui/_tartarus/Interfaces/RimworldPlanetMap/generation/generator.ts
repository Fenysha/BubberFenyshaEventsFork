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
  PLANET_MATERIAL_LIMESTONE,
  PLANET_MATERIAL_MARBLE,
  PLANET_MATERIAL_OBSIDIAN,
  PLANET_MATERIAL_SANDSTONE,
  PLANET_MATERIAL_SLATE,
  PLANET_MATERIAL_JADE,
  PLANET_MATERIAL_NONE,
  SUBBIOME_DEEP_OCEAN,
  SUBBIOME_SHORE,
  SUBBIOME_HILLS,
  SUBBIOME_ROCKY_HILLS,
  SUBBIOME_MARSH,
  SUBBIOME_PLAINS,
  SUBBIOME_FOREST,
  SUBBIOME_FOREST_HILLS,
  SUBBIOME_TUNDRA_PLAINS,
  SUBBIOME_SNOWFIELDS,
  SUBBIOME_FROZEN_OCEAN,
} from './constants';

import { DbpSampler } from './dbp';

export class PlanetGenerator {
  public readonly data: PlanetMapData;

  private readonly terrain: DbpSampler;
  private readonly heat: DbpSampler;
  private readonly humidity: DbpSampler;
  private readonly geology: DbpSampler;
  private readonly precipitation: DbpSampler;

  public constructor(data: PlanetMapData) {
    this.data = data;

    this.terrain = new DbpSampler({
      seed: data.terrainSeed,
      accuracy: data.noiseScale,
      stampSize: data.terrainScale,
      worldSize: data.width,
    });

    this.heat = new DbpSampler({
      seed: data.heatSeed,
      accuracy: data.noiseScale,
      stampSize: data.heatScale,
      worldSize: data.width,
    });

    this.humidity = new DbpSampler({
      seed: data.humiditySeed,
      accuracy: data.noiseScale,
      stampSize: data.humidityScale,
      worldSize: data.width,
    });

    this.geology = new DbpSampler({
      seed: data.geologySeed,
      accuracy: data.noiseScale,
      stampSize: data.geologyScale,
      worldSize: data.width,
    });

    this.precipitation = new DbpSampler({
      seed: data.precipitationSeed,
      accuracy: data.noiseScale,
      stampSize: data.precipitationScale,
      worldSize: data.width,
    });
  }

  public getRowWidth(y: number): number {
    if (y < 1 || y > this.data.height) {
      return this.data.width;
    }

    const v = (y - 0.5) / this.data.height;
    const latitudeRad = ((v * 180 - 90) * Math.PI) / 180;
    const count = Math.round(this.data.width * Math.cos(latitudeRad));

    return Math.max(6, count);
  }

  private valid(x: number, y: number): boolean {
    if (y < 1 || y > this.data.height) {
      return false;
    }
    return x >= 1 && x <= this.getRowWidth(y);
  }

  private sampleContinuousNoise(
    sampler: DbpSampler,
    x: number,
    y: number,
  ): number {
    const baseLat = (y - 1) / Math.max(1, this.data.height - 1);
    const polarFade = Math.sin(baseLat * Math.PI);

    const s = (this.data.seed ?? 0) % 5000;
    const angleDeg = (x * 0.85 + y * 0.35 + s) % 360;
    // Смещение y плавно уменьшается к полюсам
    const warpY = Math.max(
      1,
      Math.min(
        this.data.height,
        Math.round(y + Math.sin((angleDeg * Math.PI) / 180) * 15 * polarFade),
      ),
    );

    const rowWidth = this.getRowWidth(warpY);
    const normX = (x - 0.5) / rowWidth;
    const noiseX = normX * this.data.width;
    const noiseY = warpY - 0.5;

    const x0 = Math.floor(noiseX);
    const y0 = Math.floor(noiseY);
    const x1 = (x0 + 1) % this.data.width;
    const y1 = Math.min(this.data.height - 1, Math.max(0, y0 + 1));

    const fx = noiseX - x0;
    const fy = noiseY - y0;

    const v00 = sampler.sample(x0, y0);
    const v10 = sampler.sample(x1, y0);
    const v01 = sampler.sample(x0, y1);
    const v11 = sampler.sample(x1, y1);

    const top = v00 + fx * (v10 - v00);
    const bottom = v01 + fx * (v11 - v01);

    return top + fy * (bottom - top);
  }

  private isNoiseInRange(
    sampler: DbpSampler,
    x: number,
    y: number,
    low: number,
    high: number,
  ): boolean {
    const val = this.sampleContinuousNoise(sampler, x, y);
    return val >= low && val < high;
  }

  public getElevation(x: number, y: number): string {
    if (!this.valid(x, y)) {
      return ELEVATION_OCEAN;
    }

    if (
      this.isNoiseInRange(
        this.terrain,
        x,
        y,
        this.data.elevationSnowLow,
        this.data.elevationSnowHigh,
      )
    ) {
      return ELEVATION_SNOW;
    }

    if (
      this.isNoiseInRange(
        this.terrain,
        x,
        y,
        this.data.elevationMountainLow,
        this.data.elevationMountainHigh,
      )
    ) {
      return ELEVATION_MOUNTAIN;
    }

    if (
      this.isNoiseInRange(
        this.terrain,
        x,
        y,
        this.data.elevationHighlandLow,
        this.data.elevationHighlandHigh,
      )
    ) {
      return ELEVATION_HIGHLAND;
    }

    if (
      this.isNoiseInRange(
        this.terrain,
        x,
        y,
        this.data.elevationLowlandLow,
        this.data.elevationLowlandHigh,
      )
    ) {
      return ELEVATION_LOWLAND;
    }

    if (
      this.isNoiseInRange(
        this.terrain,
        x,
        y,
        this.data.elevationCoastLow,
        this.data.elevationCoastHigh,
      )
    ) {
      return ELEVATION_COAST;
    }

    return ELEVATION_OCEAN;
  }

  public getHeat(x: number, y: number): string {
    if (!this.valid(x, y)) {
      return CLIMATE_LOW;
    }

    if (
      this.isNoiseInRange(this.heat, x, y, this.data.heatThresholdHigh, 1.1)
    ) {
      return CLIMATE_HIGH;
    }

    if (
      this.isNoiseInRange(
        this.heat,
        x,
        y,
        this.data.heatThresholdLow,
        this.data.heatThresholdHigh,
      )
    ) {
      return CLIMATE_MEDIUM;
    }

    return CLIMATE_LOW;
  }

  public getHumidity(x: number, y: number): string {
    if (!this.valid(x, y)) {
      return CLIMATE_LOW;
    }

    if (
      this.isNoiseInRange(
        this.humidity,
        x,
        y,
        this.data.humidityThresholdHigh,
        1.1,
      )
    ) {
      return CLIMATE_HIGH;
    }

    if (
      this.isNoiseInRange(
        this.humidity,
        x,
        y,
        this.data.humidityThresholdLow,
        this.data.humidityThresholdHigh,
      )
    ) {
      return CLIMATE_MEDIUM;
    }

    return CLIMATE_LOW;
  }

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
    // Затухание волн у полюсов (0 на полюсах, 1 на экваторе)
    const polarFade = Math.sin(baseLat * Math.PI);

    let climateOffset = 0.0;
    if (h === CLIMATE_HIGH) {
      climateOffset += 0.08;
    } else if (h === CLIMATE_LOW) {
      climateOffset -= 0.08;
    }

    if (hm === CLIMATE_HIGH) {
      climateOffset -= 0.04;
    } else if (hm === CLIMATE_LOW) {
      climateOffset += 0.04;
    }

    if (e === ELEVATION_MOUNTAIN || e === ELEVATION_HIGHLAND) {
      climateOffset -= 0.07;
    } else if (e === ELEVATION_SNOW) {
      climateOffset -= 0.12;
    }

    const s = (this.data.seed ?? 0) % 10000;
    const angle1Deg = (x * 0.35 + y * 0.15 + s) % 360;
    const angle2Deg = (x * 0.85 - y * 0.45 + s * 1.3) % 360;
    const angle3Deg = (x * 1.7 + y * 1.1 + s * 2.1) % 360;

    const toRad = Math.PI / 180;
    // Гасим волны на полюсах через polarFade
    const wave =
      (Math.sin(angle1Deg * toRad) * 0.06 +
        Math.cos(angle2Deg * toRad) * 0.04 +
        Math.sin(angle3Deg * toRad) * 0.02) *
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

  private getMaterialFromNoise(value: number, elevation: string): string {
    // Ocean cells do not expose a surface rock type.
    if (elevation === ELEVATION_OCEAN) {
      return PLANET_MATERIAL_NONE;
    }

    const geology = value;

    if (geology < 0.20) {
      return PLANET_MATERIAL_GRANITE;
    }
    if (geology < 0.40) {
      return PLANET_MATERIAL_LIMESTONE;
    }
    if (geology < 0.60) {
      return PLANET_MATERIAL_SANDSTONE;
    }
    if (geology < 0.78) {
      return PLANET_MATERIAL_SLATE;
    }
    if (geology < 0.94) {
      return PLANET_MATERIAL_MARBLE;
    }
    if (geology < 0.995) {
      return PLANET_MATERIAL_OBSIDIAN;
    }

    return PLANET_MATERIAL_JADE;
  }

  public getMaterial(x: number, y: number, elevation?: string): string {
    if (!this.valid(x, y)) {
      return PLANET_MATERIAL_NONE;
    }

    const e = elevation ?? this.getElevation(x, y);
    const geology = this.sampleContinuousNoise(this.geology, x, y);

    return this.getMaterialFromNoise(geology, e);
  }

  private getMaterialTemperatureModifier(material: string): number {
    switch (material) {
      case PLANET_MATERIAL_GRANITE:
        return -0.005;
      case PLANET_MATERIAL_LIMESTONE:
        return 0.000;
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
    const normalizedLatitude = Math.max(
      0,
      Math.min(1, baseLat + latitudeOffset),
    );

    const latitudeDistance = Math.abs(normalizedLatitude - 0.5) * 2.0;
    const latitudeTemperature = Math.max(0, 1.0 - latitudeDistance) ** 1.8;

    let heatModifier = -0.15;
    if (heatLevel === CLIMATE_MEDIUM) {
      heatModifier = 0.05;
    } else if (heatLevel === CLIMATE_HIGH) {
      heatModifier = 0.22;
    }

    let elevationModifier = 0.0;
    switch (e) {
      case ELEVATION_HIGHLAND:
        elevationModifier = -0.10;
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
      latitudeTemperature * 0.60 +
      (heatModifier + 0.15) * 0.25 +
      (elevationModifier + 0.35) * 0.15 +
      materialModifier;

    return Math.max(0, Math.min(1, temperature));
  }

  private getPrecipitationNoiseCategory(
    x: number,
    y: number,
  ): number {
    const value = this.sampleContinuousNoise(this.precipitation, x, y);

    if (value < 0.33) {
      return 0;
    }
    if (value < 0.66) {
      return 1;
    }
    return 2;
  }

  private getPrecipitationBase(category: number): number {
    switch (category) {
      case 2:
        return 0.78;
      case 1:
        return 0.50;
      default:
        return 0.20;
    }
  }

  private getPrecipitationCategoryServerCompatible(
    category: number,
    humidity: string,
  ): number {
    let value = this.getPrecipitationBase(category);

    if (humidity === CLIMATE_HIGH) {
      value += 0.06;
    } else if (humidity === CLIMATE_LOW) {
      value -= 0.05;
    }

    return value;
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

    let precipitation = this.getPrecipitationCategoryServerCompatible(
      this.getPrecipitationNoiseCategory(x, y),
      hm,
    );

    const latitude = Math.abs(this.getLatitude(x, y)) / 90;

    // Moist equatorial belt, drier polar air.
    precipitation += (1 - latitude) * 0.08 - latitude * 0.05;

    // Warm air can carry more moisture; very cold cells get a modest penalty.
    precipitation += (t - 0.5) * 0.10;

    // Elevated terrain provides a mild orographic boost.
    if (e === ELEVATION_HIGHLAND) {
      precipitation += 0.025;
    } else if (e === ELEVATION_MOUNTAIN) {
      precipitation += 0.055;
    }

    return Math.max(0, Math.min(1, precipitation));
  }

  public getRainfall(
    x: number,
    y: number,
    temperature?: number,
    precipitation?: number,
  ): number {
    const t = temperature ?? this.getTemperature(x, y);
    const p = precipitation ?? this.getPrecipitation(x, y, t);

    // Transition between rain and snow around the freezing band.
    const rainFactor = Math.max(0, Math.min(1, (t - 0.20) / 0.18));
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
    if (e === ELEVATION_LOWLAND) {
      value += 0.08;
    } else if (e === ELEVATION_HIGHLAND) {
      value += 0.03;
    } else if (e === ELEVATION_MOUNTAIN) {
      value -= 0.04;
    }

    return Math.max(0, Math.min(1, value));
  }

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
      if (b === BIOME_SEA_ICE) {
        return SUBBIOME_FROZEN_OCEAN;
      }
      return SUBBIOME_DEEP_OCEAN;
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
    const e = elevation ?? this.getElevation(x, y);
    const h = heat ?? this.getHeat(x, y);
    const hm = humidity ?? this.getHumidity(x, y);
    const m = material ?? this.getMaterial(x, y, e);

    const temperature = this.getTemperature(x, y, h, e, m);

    const latitudeOffset = this.getLatitudeOffset(x, y, h, hm, e);
    const baseLat = (y - 1) / Math.max(1, this.data.height - 1);
    const normalizedLatitude = Math.max(
      0,
      Math.min(1, baseLat + latitudeOffset),
    );

    const polarDistance = Math.abs((normalizedLatitude - 0.5) * 2.0);

    if (polarDistance >= 0.82) {
      if (e === ELEVATION_OCEAN || e === ELEVATION_COAST) {
        return BIOME_SEA_ICE;
      }

      return BIOME_SNOW;
    }

    if (polarDistance >= 0.7) {
      const polarStrength = Math.max(
        0,
        Math.min(1, (polarDistance - 0.7) / 0.12),
      );

      const polarTemperature = temperature * (1.0 - polarStrength);

      if (e === ELEVATION_OCEAN || e === ELEVATION_COAST) {
        if (polarTemperature <= 0.24) {
          return BIOME_SEA_ICE;
        }
      } else {
        if (polarTemperature <= 0.22 || e === ELEVATION_SNOW) {
          return BIOME_SNOW;
        }
      }
    }

    if (e === ELEVATION_OCEAN) {
      if (temperature <= 0.14) {
        return BIOME_SEA_ICE;
      }

      return BIOME_OCEAN;
    }

    if (e === ELEVATION_COAST) {
      if (temperature <= 0.1) {
        return BIOME_SEA_ICE;
      }

      if (temperature >= 0.45 && hm === CLIMATE_LOW) {
        return BIOME_BEACH;
      }

      return BIOME_COAST;
    }

    if (temperature <= 0.1 || e === ELEVATION_SNOW) {
      return BIOME_SNOW;
    }

    if (temperature <= 0.2 && e === ELEVATION_MOUNTAIN) {
      return BIOME_SNOW;
    }

    if (e === ELEVATION_MOUNTAIN) {
      return BIOME_MOUNTAINS;
    }

    if (temperature < 0.3) {
      if (hm === CLIMATE_HIGH) {
        return BIOME_TAIGA;
      }

      return BIOME_TUNDRA;
    }

    if (temperature < 0.55) {
      if (hm === CLIMATE_HIGH) {
        return BIOME_TEMPERATE_FOREST;
      }

      if (hm === CLIMATE_MEDIUM) {
        return BIOME_GRASSLAND;
      }

      return BIOME_SAVANNA;
    }

    if (hm === CLIMATE_HIGH) {
      return BIOME_RAINFOREST;
    }

    if (hm === CLIMATE_MEDIUM) {
      return BIOME_TROPICAL_FOREST;
    }

    return BIOME_DESERT;
  }

  public getTile(x: number, y: number): PlanetTile {
    const elevation = this.getElevation(x, y);
    const heat = this.getHeat(x, y);
    const humidity = this.getHumidity(x, y);
    const material = this.getMaterial(x, y, elevation);
    const temperature = this.getTemperature(
      x,
      y,
      heat,
      elevation,
      material,
    );
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
