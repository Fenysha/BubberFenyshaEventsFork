import * as THREE from 'three';
import { PLANET_RADIUS } from '../generation/constants';
import type { PlanetMapData } from '../types';

export type LodLevel = 'far' | 'medium' | 'near';

type LodDetail = {
  widthSegments: number;
  heightSegments: number;
};

const LOD_DETAIL: Record<LodLevel, LodDetail> = {
  far: {
    widthSegments: 32,
    heightSegments: 16,
  },

  medium: {
    widthSegments: 96,
    heightSegments: 48,
  },

  near: {
    widthSegments: 192,
    heightSegments: 96,
  },
};

export const buildPlanetGeometry = (
  _data: PlanetMapData,
  lod: LodLevel,
): THREE.SphereGeometry => {
  const detail = LOD_DETAIL[lod];

  return new THREE.SphereGeometry(
    PLANET_RADIUS,
    detail.widthSegments,
    detail.heightSegments,
  );
};
