import * as THREE from 'three';

import type {
  PlanetGeometry,
  PlanetMapData,
} from '../types';

import { PlanetGenerator } from '../generation/generator';

import {
  BIOME_COLORS,
  PLANET_RADIUS,
} from '../generation/constants';

import {
  planetCoordinateToVector,
} from './coordinates';

const getPlanetDetail = (
  width: number,
  height: number,
): number => {
  const total =
    width * height;

  if (total >= 2_000_000) {
    return 7;
  }

  if (total >= 500_000) {
    return 6;
  }

  if (total >= 100_000) {
    return 5;
  }

  return 4;
};

const stableVariation = (
  x: number,
  y: number,
  seed: number,
): number => {
  const value =
    Math.sin(
      x * 127.1 +
      y * 311.7 +
      seed * 0.01337,
    ) *
    43758.5453123;

  const fract =
    value -
    Math.floor(value);

  return (
    0.94 +
    fract * 0.08
  );
};

export const buildHexPlanet = (
  data: PlanetMapData,
  generator: PlanetGenerator,
): PlanetGeometry => {
  const detail =
    getPlanetDetail(
      data.width,
      data.height,
    );

  const base =
    new THREE.IcosahedronGeometry(
      PLANET_RADIUS,
      detail,
    );

  const position =
    base.attributes.position;

  const vertices: THREE.Vector3[] = [];
  const vertexMap =
    new Map<string, number>();

  const indices: number[] = [];

  const getVertex = (
    x: number,
    y: number,
    z: number,
  ): number => {
    const key =
      `${x.toFixed(6)}:` +
      `${y.toFixed(6)}:` +
      `${z.toFixed(6)}`;

    const existing =
      vertexMap.get(key);

    if (
      existing !== undefined
    ) {
      return existing;
    }

    const index =
      vertices.length;

    vertices.push(
      new THREE.Vector3(
        x,
        y,
        z,
      )
        .normalize()
        .multiplyScalar(
          PLANET_RADIUS,
        ),
    );

    vertexMap.set(
      key,
      index,
    );

    return index;
  };

  for (
    let i = 0;
    i < position.count;
    i += 3
  ) {
    const a =
      getVertex(
        position.getX(i),
        position.getY(i),
        position.getZ(i),
      );

    const b =
      getVertex(
        position.getX(i + 1),
        position.getY(i + 1),
        position.getZ(i + 1),
      );

    const c =
      getVertex(
        position.getX(i + 2),
        position.getY(i + 2),
        position.getZ(i + 2),
      );

    indices.push(
      a,
      b,
      c,
    );
  }

  const adjacentFaces =
    Array.from(
      {
        length:
          vertices.length,
      },
      () => [] as number[],
    );

  const faceCenters:
    THREE.Vector3[] = [];

  for (
    let face = 0;
    face < indices.length;
    face += 3
  ) {
    const a =
      indices[face];

    const b =
      indices[face + 1];

    const c =
      indices[face + 2];

    const center =
      new THREE.Vector3()
        .add(vertices[a])
        .add(vertices[b])
        .add(vertices[c])
        .normalize()
        .multiplyScalar(
          PLANET_RADIUS +
            0.012,
        );

    const faceIndex =
      face / 3;

    faceCenters[
      faceIndex
    ] = center;

    adjacentFaces[a].push(
      faceIndex,
    );

    adjacentFaces[b].push(
      faceIndex,
    );

    adjacentFaces[c].push(
      faceIndex,
    );
  }

  const cellPositions: number[] = [];
  const cellColors: number[] = [];
  const boundaryPositions: number[] = [];

  for (
    let vertexIndex = 0;
    vertexIndex < vertices.length;
    vertexIndex++
  ) {
    const center =
      vertices[vertexIndex];

    const faces =
      adjacentFaces[
        vertexIndex
      ];

    const normal =
      center.clone().normalize();

    const reference =
      Math.abs(normal.y) < 0.9
        ? new THREE.Vector3(
            0,
            1,
            0,
          )
        : new THREE.Vector3(
            1,
            0,
            0,
          );

    const tangent =
      new THREE.Vector3()
        .crossVectors(
          reference,
          normal,
        )
        .normalize();

    const bitangent =
      new THREE.Vector3()
        .crossVectors(
          normal,
          tangent,
        )
        .normalize();

    const orderedFaces =
      [...faces].sort(
        (a, b) => {
          const va =
            faceCenters[a]
              .clone()
              .sub(center);

          const vb =
            faceCenters[b]
              .clone()
              .sub(center);

          return (
            Math.atan2(
              va.dot(bitangent),
              va.dot(tangent),
            ) -
            Math.atan2(
              vb.dot(bitangent),
              vb.dot(tangent),
            )
          );
        },
      );

    const lat =
      Math.asin(
        center.y /
          PLANET_RADIUS,
      );

    const lon =
      Math.atan2(
        center.z,
        center.x,
      );

    const px =
      ((lon + Math.PI) /
        (Math.PI * 2)) *
      data.width;

    const py =
      ((lat +
        Math.PI / 2) /
        Math.PI) *
      data.height;

    const tile =
      generator.getTile(
        Math.max(
          1,
          Math.min(
            data.width,
            Math.floor(px) + 1,
          ),
        ),
        Math.max(
          1,
          Math.min(
            data.height,
            Math.floor(py) + 1,
          ),
        ),
      );

    const color =
      new THREE.Color(
        BIOME_COLORS[
          tile.biome
        ] ?? 0xffffff,
      );

    color.multiplyScalar(
      stableVariation(
        vertexIndex,
        17,
        data.seed,
      ),
    );

    for (
      let i = 0;
      i < orderedFaces.length;
      i++
    ) {
      const current =
        faceCenters[
          orderedFaces[i]
        ];

      const next =
        faceCenters[
          orderedFaces[
            (i + 1) %
              orderedFaces.length
          ]
        ];

      cellPositions.push(
        center.x,
        center.y,
        center.z,

        current.x,
        current.y,
        current.z,

        next.x,
        next.y,
        next.z,
      );

      for (
        let j = 0;
        j < 3;
        j++
      ) {
        cellColors.push(
          color.r,
          color.g,
          color.b,
        );
      }

      boundaryPositions.push(
        current.x,
        current.y,
        current.z,

        next.x,
        next.y,
        next.z,
      );
    }
  }

  base.dispose();

  const surfaceGeometry =
    new THREE.BufferGeometry();

  surfaceGeometry.setAttribute(
    'position',
    new THREE.Float32BufferAttribute(
      cellPositions,
      3,
    ),
  );

  surfaceGeometry.setAttribute(
    'color',
    new THREE.Float32BufferAttribute(
      cellColors,
      3,
    ),
  );

  const boundaryGeometry =
    new THREE.BufferGeometry();

  boundaryGeometry.setAttribute(
    'position',
    new THREE.Float32BufferAttribute(
      boundaryPositions,
      3,
    ),
  );

  return {
    surfaceGeometry,
    boundaryGeometry,
  };
};
