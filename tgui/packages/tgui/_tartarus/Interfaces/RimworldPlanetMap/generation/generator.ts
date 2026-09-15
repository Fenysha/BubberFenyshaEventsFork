/*
 * Copyright (c) 2026 Fenysha
 * SPDX-License-Identifier: MIT
 *
 * Original implementation by Fenysha.
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
} from './constants';

import { DbpSampler } from './dbp';

export class PlanetGenerator {
  public readonly data: PlanetMapData;

  private readonly terrain: DbpSampler;
  private readonly heat: DbpSampler;
  private readonly humidity: DbpSampler;

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

  public getTemperature(x: number, y: number, heat?: string): number {
    if (!this.valid(x, y)) {
      return 0;
    }

    const heatLevel = heat ?? this.getHeat(x, y);

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

    const elevation = this.getElevation(x, y);
    let elevationModifier = 0.0;

    switch (elevation) {
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

    const temperature =
      latitudeTemperature * 0.6 +
      (heatModifier + 0.15) * 0.25 +
      (elevationModifier + 0.35) * 0.15;

    return Math.max(0, Math.min(1, temperature));
  }

  public getBiome(
    x: number,
    y: number,
    elevation?: string,
    heat?: string,
    humidity?: string,
  ): string {
    const e = elevation ?? this.getElevation(x, y);
    const h = heat ?? this.getHeat(x, y);
    const hm = humidity ?? this.getHumidity(x, y);

    const temperature = this.getTemperature(x, y, h);

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
    const temperature = this.getTemperature(x, y, heat);
    const biome = this.getBiome(x, y, elevation, heat, humidity);

    return {
      biome,
      temperature,
      heat,
      humidity,
      elevation,
    };
  }
}
