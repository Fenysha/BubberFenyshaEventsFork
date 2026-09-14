import * as THREE from 'three';

export const planetCoordinateToVector = (
  x: number,
  y: number,
  width: number,
  height: number,
  radius: number,
): THREE.Vector3 => {
  const longitude =
    ((x - 0.5) / width) *
      Math.PI *
      2 -
    Math.PI;

  const latitude =
    ((y - 0.5) / height) *
      Math.PI -
    Math.PI / 2;

  const cosLatitude =
    Math.cos(latitude);

  return new THREE.Vector3(
    cosLatitude *
      Math.cos(longitude) *
      radius,

    Math.sin(latitude) *
      radius,

    cosLatitude *
      Math.sin(longitude) *
      radius,
  );
};

export const vectorToPlanetCoordinate = (
  point: THREE.Vector3,
  width: number,
  height: number,
): {
  x: number;
  y: number;
} => {
  const radius =
    point.length();

  const latitude =
    Math.asin(
      point.y / radius,
    );

  const longitude =
    Math.atan2(
      point.z,
      point.x,
    );

  const x = Math.max(
    1,
    Math.min(
      width,
      Math.floor(
        ((longitude + Math.PI) /
          (Math.PI * 2)) *
          width,
      ) + 1,
    ),
  );

  const y = Math.max(
    1,
    Math.min(
      height,
      Math.floor(
        ((latitude +
          Math.PI / 2) /
          Math.PI) *
          height,
      ) + 1,
    ),
  );

  return { x, y };
};
