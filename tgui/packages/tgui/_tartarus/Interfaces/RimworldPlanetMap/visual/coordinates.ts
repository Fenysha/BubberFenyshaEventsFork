import * as THREE from 'three';

import { PLANET_RADIUS } from '../generation/constants';

const wrapX = (x: number, width: number): number => {
  let result = x % width;

  if (result < 0) {
    result += width;
  }

  return result;
};

/*
 * Logical hex tile -> sphere.
 *
 * X:
 *   longitude / column
 *
 * Y:
 *   latitude / row
 *
 * Odd rows are shifted by half
 * a logical column.
 */

export const planetCoordinateToVector = (
  x: number,
  y: number,
  width: number,
  height: number,
  radius: number = PLANET_RADIUS,
): THREE.Vector3 => {
  const column = wrapX(x - 1, width);

  const row = THREE.MathUtils.clamp(y - 1, 0, height - 1);

  const rowOffset = row % 2 === 1 ? 0.5 : 0.0;

  /*
   * IMPORTANT:
   *
   * The stagger applies to the logical
   * tile position, not texture sampling.
   */

  const u = (column + 0.5 + rowOffset) / width;

  const v = (row + 0.5) / height;

  const longitude = u * Math.PI * 2 - Math.PI;

  const latitude = v * Math.PI - Math.PI / 2;

  const cosLatitude = Math.cos(latitude);

  return new THREE.Vector3(
    Math.cos(longitude) * cosLatitude * radius,

    Math.sin(latitude) * radius,

    Math.sin(longitude) * cosLatitude * radius,
  );
};

/*
 * Sphere -> logical tile.
 */

export const vectorToPlanetCoordinate = (
  vector: THREE.Vector3,
  width: number,
  height: number,
): {
  x: number;
  y: number;
} => {
  const normal = vector.clone().normalize();

  const latitude = Math.asin(THREE.MathUtils.clamp(normal.y, -1, 1));

  const longitude = Math.atan2(normal.z, normal.x);

  /*
   * [-PI, PI] -> [0, 1]
   */

  let u = (longitude + Math.PI) / (Math.PI * 2);

  u = ((u % 1) + 1) % 1;

  /*
   * Latitude -> row.
   */

  const continuousRow = ((latitude + Math.PI / 2) / Math.PI) * height - 0.5;

  const row = Math.round(continuousRow);

  const clampedRow = THREE.MathUtils.clamp(row, 0, height - 1);

  /*
   * Reverse stagger.
   */

  const rowOffset = clampedRow % 2 === 1 ? 0.5 : 0.0;

  const continuousColumn = u * width - 0.5 - rowOffset;

  const column = Math.round(continuousColumn);

  return {
    x: wrapX(column, width) + 1,

    y: clampedRow + 1,
  };
};
