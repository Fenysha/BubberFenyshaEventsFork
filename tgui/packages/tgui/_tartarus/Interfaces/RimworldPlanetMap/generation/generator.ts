import type {
  PlanetMapData,
  PlanetTile,
} from '../types';

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


  public constructor(
    data: PlanetMapData,
  ) {

    this.data = data;

    /*
     * IMPORTANT:
     *
     * We use the explicitly transmitted server seeds.
     *
     * We do NOT derive them again here.
     */

    this.terrain =
      new DbpSampler({
        seed: data.terrainSeed,
        accuracy: data.noiseScale,
        stampSize: data.terrainScale,
        worldSize: data.width,
      });

    this.heat =
      new DbpSampler({
        seed: data.heatSeed,
        accuracy: data.noiseScale,
        stampSize: data.heatScale,
        worldSize: data.width,
      });

    this.humidity =
      new DbpSampler({
        seed: data.humiditySeed,
        accuracy: data.noiseScale,
        stampSize: data.humidityScale,
        worldSize: data.width,
      });
  }


  private valid(
    x: number,
    y: number,
  ): boolean {

    return (
      x >= 1 &&
      x <= this.data.width &&
      y >= 1 &&
      y <= this.data.height
    );
  }


  /*
   * rustg_dbp_generate returns a grid whose first cell corresponds
   * to logical coordinate 0,0.
   *
   * Server planetary coordinates start at 1,1.
   */

  private dbpX(
    x: number,
  ): number {

    return x - 1;
  }


  private dbpY(
    y: number,
  ): number {

    return y - 1;
  }


  /*
   * --------------------------------------------------------------------------
   * Elevation
   * --------------------------------------------------------------------------
   */

  public getElevation(
    x: number,
    y: number,
  ): string {

    if(!this.valid(x, y)) {
      return ELEVATION_OCEAN;
    }

    const px = this.dbpX(x);
    const py = this.dbpY(y);

    if(
      this.terrain.inRange(
        px,
        py,
        this.data.elevationSnowLow,
        this.data.elevationSnowHigh,
      )
    ) {
      return ELEVATION_SNOW;
    }

    if(
      this.terrain.inRange(
        px,
        py,
        this.data.elevationMountainLow,
        this.data.elevationMountainHigh,
      )
    ) {
      return ELEVATION_MOUNTAIN;
    }

    if(
      this.terrain.inRange(
        px,
        py,
        this.data.elevationHighlandLow,
        this.data.elevationHighlandHigh,
      )
    ) {
      return ELEVATION_HIGHLAND;
    }

    if(
      this.terrain.inRange(
        px,
        py,
        this.data.elevationLowlandLow,
        this.data.elevationLowlandHigh,
      )
    ) {
      return ELEVATION_LOWLAND;
    }

    if(
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
     * The DBP intervals cover the expected value range.
     *
     * Anything outside them is treated as ocean,
     * exactly like the server fallback.
     */

    return ELEVATION_OCEAN;
  }


  /*
   * --------------------------------------------------------------------------
   * Heat
   * --------------------------------------------------------------------------
   */

  public getHeat(
    x: number,
    y: number,
  ): string {

    if(!this.valid(x, y)) {
      return CLIMATE_LOW;
    }

    const px = this.dbpX(x);
    const py = this.dbpY(y);

    if(
      this.heat.inRange(
        px,
        py,
        this.data.heatThresholdHigh,
        1.1,
      )
    ) {
      return CLIMATE_HIGH;
    }

    if(
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

  public getHumidity(
    x: number,
    y: number,
  ): string {

    if(!this.valid(x, y)) {
      return CLIMATE_LOW;
    }

    const px = this.dbpX(x);
    const py = this.dbpY(y);

    if(
      this.humidity.inRange(
        px,
        py,
        this.data.humidityThresholdHigh,
        1.1,
      )
    ) {
      return CLIMATE_HIGH;
    }

    if(
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
   */

  public getTemperature(
    x: number,
    y: number,
    heat?: string,
  ): number {

    if(!this.valid(x, y)) {
      return 0;
    }

    const latitude =
      Math.abs(
        (
          (y - 1) /
          Math.max(
            1,
            this.data.height - 1,
          )
        ) * 2 -
        1,
      );

    /*
     * 0 = equator
     * 1 = pole
     */

    const latitudeModifier =
      1 - latitude;

    const heatLevel =
      heat ?? this.getHeat(x, y);

    let heatModifier = 0.2;

    if(
      heatLevel ===
      CLIMATE_HIGH
    ) {

      heatModifier = 1.0;

    } else if(
      heatLevel ===
      CLIMATE_MEDIUM
    ) {

      heatModifier = 0.6;
    }

    return Math.max(
      0,
      Math.min(
        1,
        latitudeModifier * 0.55 +
        heatModifier * 0.45,
      ),
    );
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

    const e =
      elevation ??
      this.getElevation(x, y);

    const h =
      heat ??
      this.getHeat(x, y);

    const hm =
      humidity ??
      this.getHumidity(x, y);

    /*
     * Water.
     */

    if(e === ELEVATION_OCEAN) {
      return BIOME_OCEAN;
    }

    if(e === ELEVATION_COAST) {
      return BIOME_BEACH;
    }

    /*
     * Extreme terrain.
     */

    if(e === ELEVATION_SNOW) {
      return BIOME_SNOW;
    }

    if(e === ELEVATION_MOUNTAIN) {
      return BIOME_MOUNTAINS;
    }

    /*
     * Cold.
     */

    if(h === CLIMATE_LOW) {

      if(hm === CLIMATE_HIGH) {
        return BIOME_TAIGA;
      }

      return BIOME_TUNDRA;
    }

    /*
     * Moderate.
     */

    if(h === CLIMATE_MEDIUM) {

      if(hm === CLIMATE_HIGH) {
        return BIOME_TEMPERATE_FOREST;
      }

      if(hm === CLIMATE_MEDIUM) {
        return BIOME_GRASSLAND;
      }

      return BIOME_SAVANNA;
    }

    /*
     * Hot.
     */

    if(hm === CLIMATE_HIGH) {
      return BIOME_RAINFOREST;
    }

    if(hm === CLIMATE_MEDIUM) {
      return BIOME_TROPICAL_FOREST;
    }

    return BIOME_DESERT;
  }


  /*
   * --------------------------------------------------------------------------
   * Complete tile
   * --------------------------------------------------------------------------
   */

  public getTile(
    x: number,
    y: number,
  ): PlanetTile {

    const elevation =
      this.getElevation(
        x,
        y,
      );

    const heat =
      this.getHeat(
        x,
        y,
      );

    const humidity =
      this.getHumidity(
        x,
        y,
      );

    const temperature =
      this.getTemperature(
        x,
        y,
        heat,
      );

    const biome =
      this.getBiome(
        x,
        y,
        elevation,
        heat,
        humidity,
      );

    return {
      biome,
      temperature,
      heat,
      humidity,
      elevation,
    };
  }
}
