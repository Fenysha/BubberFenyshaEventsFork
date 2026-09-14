import * as THREE from 'three';
import { PLANET_RADIUS } from '../generation/constants';
import type { PlanetMapData } from '../types';

export type LodLevel = 'far' | 'medium' | 'near';

const LOD_SUBDIVISIONS: Record<LodLevel, number> = {
  far: 12,
  medium: 24,
  near: 48,
};

export const buildPlanetGeometry = (
  _data: PlanetMapData,
  lod: LodLevel,
): THREE.BufferGeometry => {
  const detail = LOD_SUBDIVISIONS[lod];
  return new THREE.IcosahedronGeometry(PLANET_RADIUS, detail);
};
