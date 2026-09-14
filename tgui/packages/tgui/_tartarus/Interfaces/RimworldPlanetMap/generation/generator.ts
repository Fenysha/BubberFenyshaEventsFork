import type { PlanetMapData, PlanetTile } from '../types';

import {
  BIOME_BEACH,
  BIOME_DESERT,
  BIOME_GRASSLAND,
  BIOME_MOUNTAINS,
  BIOME_OCEAN,
  BIOME_RAINFOREST,
  BIOME_SAVANNA,
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

    /*
     * IMPORTANT:
     *
     * These seeds are authoritative.
     * Do not derive them again on the client.
     *
     * Keep worldSize equal to data.width because
     * this is exactly what the current DM side
     * passes into rustg_dbp_generate().
     */
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

  private valid(x: number, y: number): boolean {
    return x >= 1 && x <= this.data.width && y >= 1 && y <= this.data.height;
  }

  /*
   * Server coordinates are 1-based.
   * DBP coordinates are 0-based.
   */
  private dbpX(x: number): number {
    return x - 1;
  }

  private dbpY(y: number): number {
    return y - 1;
  }

  /*
   * --------------------------------------------------------------------------
   * Elevation
   * --------------------------------------------------------------------------
   */

  public getElevation(x: number, y: number): string {
    if (!this.valid(x, y)) {
      return ELEVATION_OCEAN;
    }

    const px = this.dbpX(x);
    const py = this.dbpY(y);

    /*
     * Keep the same priority as DM.
     */
    if (
      this.terrain.inRange(
        px,
        py,
        this.data.elevationSnowLow,
        this.data.elevationSnowHigh,
      )
    ) {
      return ELEVATION_SNOW;
    }

    if (
      this.terrain.inRange(
        px,
        py,
        this.data.elevationMountainLow,
        this.data.elevationMountainHigh,
      )
    ) {
      return ELEVATION_MOUNTAIN;
    }

    if (
      this.terrain.inRange(
        px,
        py,
        this.data.elevationHighlandLow,
        this.data.elevationHighlandHigh,
      )
    ) {
      return ELEVATION_HIGHLAND;
    }

    if (
      this.terrain.inRange(
        px,
        py,
        this.data.elevationLowlandLow,
        this.data.elevationLowlandHigh,
      )
    ) {
      return ELEVATION_LOWLAND;
    }

    if (
      this.terrain.inRange(
        px,
        py,
        this.data.elevationCoastLow,
        this.data.elevationCoastHigh,
      )
    ) {
      return ELEVATION_COAST;
    }

    /*
     * Values outside all ranges are ocean.
     */
    return ELEVATION_OCEAN;
  }

  /*
   * --------------------------------------------------------------------------
   * Heat
   * --------------------------------------------------------------------------
   */

  public getHeat(x: number, y: number): string {
    if (!this.valid(x, y)) {
      return CLIMATE_LOW;
    }

    const px = this.dbpX(x);
    const py = this.dbpY(y);

    if (this.heat.inRange(px, py, this.data.heatThresholdHigh, 1.1)) {
      return CLIMATE_HIGH;
    }

    if (
      this.heat.inRange(
        px,
        py,
        this.data.heatThresholdLow,
        this.data.heatThresholdHigh,
      )
    ) {
      return CLIMATE_MEDIUM;
    }

    return CLIMATE_LOW;
  }

  /*
   * --------------------------------------------------------------------------
   * Humidity
   * --------------------------------------------------------------------------
   */

  public getHumidity(x: number, y: number): string {
    if (!this.valid(x, y)) {
      return CLIMATE_LOW;
    }

    const px = this.dbpX(x);
    const py = this.dbpY(y);

    if (this.humidity.inRange(px, py, this.data.humidityThresholdHigh, 1.1)) {
      return CLIMATE_HIGH;
    }

    if (
      this.humidity.inRange(
        px,
        py,
        this.data.humidityThresholdLow,
        this.data.humidityThresholdHigh,
      )
    ) {
      return CLIMATE_MEDIUM;
    }

    return CLIMATE_LOW;
  }

  /*
   * --------------------------------------------------------------------------
   * Temperature
   * --------------------------------------------------------------------------
   *
   * Global latitude is the dominant climate factor.
   *
   * 0.0 = pole
   * 1.0 = equator
   *
   * Local heat and elevation only modify the base climate.
   */

  public getTemperature(x: number, y: number, heat?: string): number {
    if (!this.valid(x, y)) {
      return 0;
    }

    const normalizedLatitude = (y - 1) / Math.max(1, this.data.height - 1);

    /*
     * 0 = equator
     * 1 = pole
     */
    const latitudeDistance = Math.abs(normalizedLatitude - 0.5) * 2.0;

    /*
     * Strong latitudinal gradient.
     *
     * Higher exponent:
     * - hotter equator
     * - colder mid-latitudes
     * - very cold poles
     */
    const latitudeTemperature = Math.max(0, 1.0 - latitudeDistance) ** 2.4;

    const heatLevel = heat ?? this.getHeat(x, y);

    /*
     * Regional heat is deliberately weak.
     */
    let heatModifier = -0.08;

    if (heatLevel === CLIMATE_MEDIUM) {
      heatModifier = 0.06;
    } else if (heatLevel === CLIMATE_HIGH) {
      heatModifier = 0.18;
    }

    /*
     * Elevation cooling.
     *
     * Mountains and snowy terrain are colder
     * than nearby lowlands.
     */
    const elevation = this.getElevation(x, y);

    let elevationModifier = 0.0;

    switch (elevation) {
      case ELEVATION_COAST:
        elevationModifier = 0.0;
        break;

      case ELEVATION_LOWLAND:
        elevationModifier = 0.0;
        break;

      case ELEVATION_HIGHLAND:
        elevationModifier = -0.08;
        break;

      case ELEVATION_MOUNTAIN:
        elevationModifier = -0.18;
        break;

      case ELEVATION_SNOW:
        elevationModifier = -0.3;
        break;

      default:
        elevationModifier = 0.0;
        break;
    }

    /*
     * Match DM:
     *
     * 88% latitude
     * 7% regional heat
     * 5% elevation
     */
    const temperature =
      latitudeTemperature * 0.88 +
      heatModifier * 0.07 +
      elevationModifier * 0.05;

    return Math.max(0, Math.min(1, temperature));
  }

  /*
   * --------------------------------------------------------------------------
   * Biome
   * --------------------------------------------------------------------------
   */

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

    /*
     * Water.
     */
    if (e === ELEVATION_OCEAN) {
      return BIOME_OCEAN;
    }

    if (e === ELEVATION_COAST) {
      /*
       * Polar coasts become snow-covered.
       */
      if (temperature < 0.16) {
        return BIOME_SNOW;
      }

      return BIOME_BEACH;
    }

    /*
     * Permanent polar ice/snow.
     */
    if (temperature <= 0.08) {
      return BIOME_SNOW;
    }

    /*
     * Very cold elevated regions.
     */
    if (temperature <= 0.18 && e !== ELEVATION_LOWLAND) {
      return BIOME_SNOW;
    }

    /*
     * Explicit high-altitude snow.
     */
    if (e === ELEVATION_SNOW) {
      return BIOME_SNOW;
    }

    /*
     * Mountain terrain.
     */
    if (e === ELEVATION_MOUNTAIN) {
      /*
       * Cold mountain ranges become snow-covered.
       */
      if (temperature < 0.26) {
        return BIOME_SNOW;
      }

      return BIOME_MOUNTAINS;
    }

    /*
     * Cold climate.
     */
    if (temperature < 0.32) {
      if (hm === CLIMATE_HIGH) {
        return BIOME_TAIGA;
      }

      return BIOME_TUNDRA;
    }

    /*
     * Temperate climate.
     */
    if (temperature < 0.52) {
      if (hm === CLIMATE_HIGH) {
        return BIOME_TEMPERATE_FOREST;
      }

      if (hm === CLIMATE_MEDIUM) {
        return BIOME_GRASSLAND;
      }

      return BIOME_SAVANNA;
    }

    /*
     * Warm / tropical climate.
     */
    if (hm === CLIMATE_HIGH) {
      return BIOME_RAINFOREST;
    }

    if (hm === CLIMATE_MEDIUM) {
      return BIOME_TROPICAL_FOREST;
    }

    return BIOME_DESERT;
  }

  /*
   * --------------------------------------------------------------------------
   * Complete tile
   * --------------------------------------------------------------------------
   */

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
