import * as THREE from 'three';

import { PLANET_RADIUS } from '../generation/constants';

import { planetCoordinateToVector } from './coordinates';

export type PlanetSelection = {
  group: THREE.Group;
  outline: THREE.LineLoop;
  glow: THREE.LineLoop;
};

const SELECTION_OFFSET = 0.018;

/*
 * Builds a hexagonal outline around a logical tile.
 *
 * We do not draw the hex in screen space.
 * Instead each corner is created in the tangent plane
 * of the sphere and then projected back onto the sphere.
 */
const buildHexOutlineGeometry = (
  x: number,
  y: number,
  width: number,
  height: number,
  radius: number,
): THREE.BufferGeometry => {
  const center = planetCoordinateToVector(
    x,
    y,
    width,
    height,
    radius,
  ).normalize();

  /*
   * Build tangent basis.
   *
   * "east" follows longitude.
   * "north" follows latitude.
   */

  const up = new THREE.Vector3(0, 1, 0);

  const east = new THREE.Vector3().crossVectors(up, center);

  /*
   * Near the poles the cross product
   * becomes unstable.
   */
  if (east.lengthSq() < 0.000001) {
    east.set(1, 0, 0);
  }

  east.normalize();

  const north = new THREE.Vector3().crossVectors(center, east).normalize();

  /*
   * Angular dimensions of one map tile.
   *
   * The latitude step is constant.
   * Longitude must be multiplied by cos(latitude)
   * because physical longitude distance shrinks
   * towards the poles.
   */

  const latitude = Math.asin(THREE.MathUtils.clamp(center.y, -1, 1));

  const cosLatitude = Math.max(Math.cos(latitude), 0.12);

  const longitudeStep = (Math.PI * 2) / width;

  const latitudeStep = Math.PI / height;

  /*
   * Radius of the outline in tangent space.
   *
   * Slightly smaller than half a tile so neighboring
   * outlines do not visually overlap.
   */
  const horizontalRadius = longitudeStep * cosLatitude * 0.47;

  const verticalRadius = latitudeStep * 0.47;

  const positions = new Float32Array(6 * 3);

  /*
   * Pointy-top hexagon.
   *
   * Start at 30 degrees so that the
   * upper/lower vertices point outward.
   */
  for (let i = 0; i < 6; i++) {
    const angle = Math.PI / 6 + (i * Math.PI) / 3;

    const tangentX = Math.cos(angle) * horizontalRadius;

    const tangentY = Math.sin(angle) * verticalRadius;

    /*
     * Small angular displacement from
     * the sphere surface.
     */
    const point = center
      .clone()
      .add(east.clone().multiplyScalar(tangentX))
      .add(north.clone().multiplyScalar(tangentY))
      .normalize()
      .multiplyScalar(radius);

    positions[i * 3] = point.x;

    positions[i * 3 + 1] = point.y;

    positions[i * 3 + 2] = point.z;
  }

  const geometry = new THREE.BufferGeometry();

  geometry.setAttribute(
    'position',
    new THREE.Float32BufferAttribute(positions, 3),
  );

  return geometry;
};

export const createPlanetSelection = (
  width: number,
  height: number,
): PlanetSelection => {
  const group = new THREE.Group();

  group.name = 'PlanetSelection';

  /*
   * Main outline.
   */
  const outlineGeometry = buildHexOutlineGeometry(
    1,
    1,
    width,
    height,
    PLANET_RADIUS + SELECTION_OFFSET,
  );

  const outlineMaterial = new THREE.LineBasicMaterial({
    color: 0x9edcff,
    transparent: true,
    opacity: 0.95,
    depthTest: true,
    depthWrite: false,
  });

  const outline = new THREE.LineLoop(outlineGeometry, outlineMaterial);

  outline.renderOrder = 20;

  group.add(outline);

  /*
   * Very subtle outer glow.
   *
   * It is another hex, slightly larger
   * and much more transparent.
   */
  const glowGeometry = buildHexOutlineGeometry(
    1,
    1,
    width,
    height,
    PLANET_RADIUS + SELECTION_OFFSET + 0.012,
  );

  const glowMaterial = new THREE.LineBasicMaterial({
    color: 0x6bbdff,
    transparent: true,
    opacity: 0.2,
    depthTest: true,
    depthWrite: false,
  });

  const glow = new THREE.LineLoop(glowGeometry, glowMaterial);

  glow.renderOrder = 19;

  group.add(glow);

  group.visible = false;

  return {
    group,
    outline,
    glow,
  };
};

export const updatePlanetSelection = (
  selection: PlanetSelection,
  x: number,
  y: number,
  width: number,
  height: number,
) => {
  selection.outline.geometry.dispose();

  selection.outline.geometry = buildHexOutlineGeometry(
    x,
    y,
    width,
    height,
    PLANET_RADIUS + SELECTION_OFFSET,
  );

  selection.glow.geometry.dispose();

  selection.glow.geometry = buildHexOutlineGeometry(
    x,
    y,
    width,
    height,
    PLANET_RADIUS + SELECTION_OFFSET + 0.012,
  );

  selection.group.visible = true;
};
