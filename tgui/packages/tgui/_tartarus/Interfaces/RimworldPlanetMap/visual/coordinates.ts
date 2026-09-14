import * as THREE from 'three';

const wrapX = (x: number, width: number): number => {
  let result = x % width;

  if (result < 0) {
    result += width;
  }

  return result;
};

export const getRowWidth = (
  y: number,
  height: number,
  maxWidth: number,
): number => {
  const v = (y + 0.5) / height;
  const latitude = v * Math.PI - Math.PI * 0.5;
  const count = Math.round(maxWidth * Math.cos(latitude));
  return Math.max(6, count);
};

export const planetCoordinateToVector = (
  x: number,
  y: number,
  maxWidth: number,
  height: number,
  radius: number,
): THREE.Vector3 => {
  const rowWidth = getRowWidth(y, height, maxWidth);
  const v = (y + 0.5) / height;
  const latitude = v * Math.PI - Math.PI * 0.5;

  const stagger = Math.floor(y) % 2 !== 0 ? 0.5 : 0.0;
  const u =
    ((((x % rowWidth) + rowWidth) % rowWidth) + 0.5 + stagger) / rowWidth;
  const longitude = u * Math.PI * 2 - Math.PI;

  const cosLat = Math.cos(latitude);

  return new THREE.Vector3(
    radius * cosLat * Math.cos(longitude),
    radius * Math.sin(latitude),
    radius * cosLat * Math.sin(longitude),
  );
};

export const vectorToPlanetCoordinate = (
  point: THREE.Vector3,
  maxWidth: number,
  height: number,
): { x: number; y: number } => {
  const normalized = point.clone().normalize();
  const sinLat = THREE.MathUtils.clamp(normalized.y, -0.9999, 0.9999);
  const latitude = Math.asin(sinLat);
  const longitude = Math.atan2(normalized.z, normalized.x);

  const v = (latitude + Math.PI * 0.5) / Math.PI;
  const y = THREE.MathUtils.clamp(Math.floor(v * height), 0, height - 1);

  const rowWidth = getRowWidth(y, height, maxWidth);
  const u = (longitude + Math.PI) / (Math.PI * 2);
  const stagger = y % 2 !== 0 ? 0.5 : 0.0;

  let x = Math.floor(u * rowWidth - stagger);
  x = ((x % rowWidth) + rowWidth) % rowWidth;

  return { x, y };
};
