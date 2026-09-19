import * as THREE from 'three';

import { getHexGrid, type HexGrid, type Tile } from '../generation/hexGrid';
import type { PlanetMapData } from '../types';

/** The hex grid a map uses. Tiles are 1-based (x, y), exactly as DM sends them. */
export const gridFor = (data: PlanetMapData): HexGrid =>
  getHexGrid(data.gridFrequency ?? data.height - 1);

export const tileToVector = (
  grid: HexGrid,
  x: number,
  y: number,
  radius: number,
): THREE.Vector3 =>
  new THREE.Vector3(...grid.center(x, y)).multiplyScalar(radius);

/** The tile under a point on the sphere: the same nearest-centre rule the shader draws. */
export const vectorToTile = (grid: HexGrid, point: THREE.Vector3): Tile =>
  grid.fromDirection([point.x, point.y, point.z]);

/** A tile's hex (or pentagon) corners, lifted to the given radius. */
export const tileOutline = (
  grid: HexGrid,
  x: number,
  y: number,
  radius: number,
): THREE.Vector3[] =>
  grid
    .outline(x, y)
    .map((corner) => new THREE.Vector3(...corner).multiplyScalar(radius));
