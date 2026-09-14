import { useEffect, useRef } from 'react';
import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';

import type {
  PlanetMapData,
  PlanetTile,
  PlanetObject,
} from './types';

/* -------------------------------------------------------------------------- */
/* Constants — must stay in sync with server                                  */
/* -------------------------------------------------------------------------- */

const CLIMATE_LOW = 0;
const CLIMATE_MEDIUM = 1;
const CLIMATE_HIGH = 2;

const ELEVATION_OCEAN = 0;
const ELEVATION_COAST = 1;
const ELEVATION_LOWLAND = 2;
const ELEVATION_HIGHLAND = 3;
const ELEVATION_MOUNTAIN = 4;
const ELEVATION_SNOW = 5;

const BIOME_COLORS: Record<string, number> = {
  ocean: 0x163d68,
  beach: 0xd1bd7b,
  tundra: 0x8697a3,
  taiga: 0x3d674b,
  temperate_forest: 0x3f7548,
  grassland: 0x78a84f,
  savanna: 0xa69a48,
  desert: 0xc9ae69,
  tropical_forest: 0x2d7946,
  rainforest: 0x17603a,
  mountains: 0x6b6862,
  snow: 0xe5e8e8,
};

const CAMERA_STATE_KEY = 'tartarus-rimworld-planet-camera';

/* -------------------------------------------------------------------------- */
/* Seed derivation — exact copy of server logic                               */
/* -------------------------------------------------------------------------- */

const deriveSeeds = (masterSeed: number) => {
  const base = Math.abs(masterSeed) % 50001;

  const terrainSeed = base;
  const heatSeed = (base + 10000) % 50001;
  const humiditySeed = (base + 20000) % 50001;

  return { terrainSeed, heatSeed, humiditySeed };
};

/* -------------------------------------------------------------------------- */
/* Noise (approximation of DBP)                                               */
/* -------------------------------------------------------------------------- */

const hash2D = (x: number, y: number, seed: number): number => {
  const value =
    Math.sin(x * 127.1 + y * 311.7 + seed * 0.01337) * 43758.5453123;
  return value - Math.floor(value);
};

const smoothNoise = (x: number, y: number, seed: number): number => {
  const x0 = Math.floor(x);
  const y0 = Math.floor(y);

  const fx = x - x0;
  const fy = y - y0;

  const sx = fx * fx * (3 - 2 * fx);
  const sy = fy * fy * (3 - 2 * fy);

  const a = hash2D(x0, y0, seed);
  const b = hash2D(x0 + 1, y0, seed);
  const c = hash2D(x0, y0 + 1, seed);
  const d = hash2D(x0 + 1, y0 + 1, seed);

  return THREE.MathUtils.lerp(
    THREE.MathUtils.lerp(a, b, sx),
    THREE.MathUtils.lerp(c, d, sx),
    sy,
  );
};

/**
 * Fractal noise remapped to approximately [-1, 1]
 * (DBP internal range is roughly in this ballpark)
 */
const fractalNoise = (
  x: number,
  y: number,
  seed: number,
): number => {
  let value = 0;
  let amplitude = 0.5;
  let frequency = 1;
  let amplitudeSum = 0;

  for (let i = 0; i < 4; i++) {
    value +=
      smoothNoise(x * frequency, y * frequency, seed + i * 137) *
      amplitude;

    amplitudeSum += amplitude;
    amplitude *= 0.5;
    frequency *= 2;
  }

  // Remap [0,1] → [-1,1]
  return (value / amplitudeSum) * 2 - 1;
};

/* -------------------------------------------------------------------------- */
/* Tile generation — mirrors server get_*_level + get_biome + get_temperature */
/* -------------------------------------------------------------------------- */

export const getPlanetTile = (
  x: number,
  y: number,
  data: PlanetMapData,
): PlanetTile => {
  const { terrainSeed, heatSeed, humiditySeed } = deriveSeeds(data.seed);

  // Normalized coordinates (0..1)
  const nx = (x - 0.5) / data.width;
  const ny = (y - 0.5) / data.height;

  // Latitude factor (0 = equator, 1 = pole) — same as server
  const latitude = Math.abs(ny * 2 - 1);

  /* ---------- Elevation (highest priority first) ---------- */
  const elevNoise = fractalNoise(
    (nx * data.width) / data.terrainScale,
    (ny * data.height) / data.terrainScale,
    terrainSeed,
  );

  let elevation: number;

  if (elevNoise >= 0.48) {
    elevation = ELEVATION_SNOW;
  } else if (elevNoise >= 0.28) {
    elevation = ELEVATION_MOUNTAIN;
  } else if (elevNoise >= 0.12) {
    elevation = ELEVATION_HIGHLAND;
  } else if (elevNoise >= -0.08) {
    elevation = ELEVATION_LOWLAND;
  } else if (elevNoise >= -0.25) {
    elevation = ELEVATION_COAST;
  } else {
    elevation = ELEVATION_OCEAN;
  }

  /* ---------- Heat ---------- */
  const heatNoise = fractalNoise(
    (nx * data.width) / data.heatScale,
    (ny * data.height) / data.heatScale,
    heatSeed,
  );

  let heat: number;
  if (heatNoise >= data.heatThresholdHigh) {
    heat = CLIMATE_HIGH;
  } else if (heatNoise >= data.heatThresholdLow) {
    heat = CLIMATE_MEDIUM;
  } else {
    heat = CLIMATE_LOW;
  }

  /* ---------- Humidity ---------- */
  const humidityNoise = fractalNoise(
    (nx * data.width) / data.humidityScale,
    (ny * data.height) / data.humidityScale,
    humiditySeed,
  );

  let humidity: number;
  if (humidityNoise >= data.humidityThresholdHigh) {
    humidity = CLIMATE_HIGH;
  } else if (humidityNoise >= data.humidityThresholdLow) {
    humidity = CLIMATE_MEDIUM;
  } else {
    humidity = CLIMATE_LOW;
  }

  /* ---------- Temperature (exact server formula) ---------- */
  const latitudeModifier = 1 - latitude;

  let heatModifier: number;
  if (heat === CLIMATE_HIGH) {
    heatModifier = 1.0;
  } else if (heat === CLIMATE_MEDIUM) {
    heatModifier = 0.6;
  } else {
    heatModifier = 0.2;
  }

  const temperature = THREE.MathUtils.clamp(
    latitudeModifier * 0.55 + heatModifier * 0.45,
    0,
    1,
  );

  /* ---------- Biome (exact server table) ---------- */
  let biome: string;

  if (elevation === ELEVATION_OCEAN) {
    biome = 'ocean';
  } else if (elevation === ELEVATION_COAST) {
    biome = 'beach';
  } else if (elevation === ELEVATION_SNOW) {
    biome = 'snow';
  } else if (elevation === ELEVATION_MOUNTAIN) {
    biome = 'mountains';
  } else if (heat === CLIMATE_LOW) {
    // Cold
    biome = humidity === CLIMATE_HIGH ? 'taiga' : 'tundra';
  } else if (heat === CLIMATE_MEDIUM) {
    // Medium heat
    if (humidity === CLIMATE_HIGH) {
      biome = 'temperate_forest';
    } else if (humidity === CLIMATE_MEDIUM) {
      biome = 'grassland';
    } else {
      biome = 'savanna';
    }
  } else {
    // Hot
    if (humidity === CLIMATE_HIGH) {
      biome = 'rainforest';
    } else if (humidity === CLIMATE_MEDIUM) {
      biome = 'tropical_forest';
    } else {
      biome = 'desert';
    }
  }

  return {
    biome,
    temperature,
    heat,
    humidity,
    elevation,
  };
};

/* -------------------------------------------------------------------------- */
/* Geometry helpers (unchanged logic)                                         */
/* -------------------------------------------------------------------------- */

const getPlanetDetail = (width: number, height: number): number => {
  const totalTiles = width * height;

  if (totalTiles >= 2_000_000) return 7;
  if (totalTiles >= 500_000)  return 6;
  if (totalTiles >= 100_000)  return 5;
  return 4;
};

type CameraState = {
  position: { x: number; y: number; z: number };
  target: { x: number; y: number; z: number };
};

const saveCameraState = (
  camera: THREE.PerspectiveCamera,
  controls: OrbitControls,
) => {
  const state: CameraState = {
    position: {
      x: camera.position.x,
      y: camera.position.y,
      z: camera.position.z,
    },
    target: {
      x: controls.target.x,
      y: controls.target.y,
      z: controls.target.z,
    },
  };
  localStorage.setItem(CAMERA_STATE_KEY, JSON.stringify(state));
};

const loadCameraState = (
  camera: THREE.PerspectiveCamera,
  controls: OrbitControls,
) => {
  const raw = localStorage.getItem(CAMERA_STATE_KEY);

  if (!raw) {
    camera.position.set(0, 0, 4.7);
    controls.target.set(0, 0, 0);
    return;
  }

  try {
    const state = JSON.parse(raw) as CameraState;
    camera.position.set(state.position.x, state.position.y, state.position.z);
    controls.target.set(state.target.x, state.target.y, state.target.z);
    controls.update();
  } catch {
    localStorage.removeItem(CAMERA_STATE_KEY);
    camera.position.set(0, 0, 4.7);
    controls.target.set(0, 0, 0);
  }
};

const planetCoordinateToVector = (
  x: number,
  y: number,
  width: number,
  height: number,
  radius: number,
): THREE.Vector3 => {
  const longitude = (x / width) * Math.PI * 2 - Math.PI;
  const latitude = (y / height) * Math.PI - Math.PI / 2;

  return new THREE.Vector3(
    Math.cos(latitude) * Math.cos(longitude) * radius,
    Math.sin(latitude) * radius,
    Math.cos(latitude) * Math.sin(longitude) * radius,
  );
};

const buildHexPlanet = (data: PlanetMapData) => {
  const detail = getPlanetDetail(data.width, data.height);
  const base = new THREE.IcosahedronGeometry(2, detail);
  const position = base.attributes.position;

  const vertices: THREE.Vector3[] = [];
  const vertexMap = new Map<string, number>();
  const indices: number[] = [];

  const getVertex = (x: number, y: number, z: number) => {
    const key = [x.toFixed(6), y.toFixed(6), z.toFixed(6)].join(':');
    const existing = vertexMap.get(key);
    if (existing !== undefined) return existing;

    const index = vertices.length;
    vertices.push(new THREE.Vector3(x, y, z).normalize().multiplyScalar(2));
    vertexMap.set(key, index);
    return index;
  };

  for (let i = 0; i < position.count; i += 3) {
    const a = getVertex(position.getX(i), position.getY(i), position.getZ(i));
    const b = getVertex(position.getX(i + 1), position.getY(i + 1), position.getZ(i + 1));
    const c = getVertex(position.getX(i + 2), position.getY(i + 2), position.getZ(i + 2));
    indices.push(a, b, c);
  }

  const adjacentFaces = new Array<number[]>(vertices.length);
  for (let i = 0; i < vertices.length; i++) {
    adjacentFaces[i] = [];
  }

  const faceCenters: THREE.Vector3[] = [];

  for (let face = 0; face < indices.length; face += 3) {
    const a = indices[face];
    const b = indices[face + 1];
    const c = indices[face + 2];

    const center = new THREE.Vector3()
      .add(vertices[a])
      .add(vertices[b])
      .add(vertices[c])
      .normalize()
      .multiplyScalar(2.012);

    const faceIndex = face / 3;
    faceCenters[faceIndex] = center;

    adjacentFaces[a].push(faceIndex);
    adjacentFaces[b].push(faceIndex);
    adjacentFaces[c].push(faceIndex);
  }

  const cellPositions: number[] = [];
  const cellColors: number[] = [];
  const boundaryPositions: number[] = [];

  for (let vertexIndex = 0; vertexIndex < vertices.length; vertexIndex++) {
    const center = vertices[vertexIndex];
    const faces = adjacentFaces[vertexIndex];

    const normal = center.clone().normalize();
    const reference =
      Math.abs(normal.y) < 0.9
        ? new THREE.Vector3(0, 1, 0)
        : new THREE.Vector3(1, 0, 0);

    const tangent = new THREE.Vector3().crossVectors(reference, normal).normalize();
    const bitangent = new THREE.Vector3().crossVectors(normal, tangent).normalize();

    const orderedFaces = [...faces].sort((a, b) => {
      const va = faceCenters[a].clone().sub(center);
      const vb = faceCenters[b].clone().sub(center);
      return (
        Math.atan2(va.dot(bitangent), va.dot(tangent)) -
        Math.atan2(vb.dot(bitangent), vb.dot(tangent))
      );
    });

    // Sample biome at cell center
    const lat = Math.asin(center.y / 2);
    const lon = Math.atan2(center.z, center.x);

    const px = ((lon + Math.PI) / (Math.PI * 2)) * data.width;
    const py = ((lat + Math.PI / 2) / Math.PI) * data.height;

    const tile = getPlanetTile(px, py, data);

    const color = new THREE.Color(BIOME_COLORS[tile.biome] ?? 0xffffff);
    color.multiplyScalar(0.92 + hash2D(vertexIndex, 17, data.seed) * 0.08);

    for (let i = 0; i < orderedFaces.length; i++) {
      const current = faceCenters[orderedFaces[i]];
      const next = faceCenters[orderedFaces[(i + 1) % orderedFaces.length]];

      cellPositions.push(
        center.x, center.y, center.z,
        current.x, current.y, current.z,
        next.x, next.y, next.z,
      );

      for (let j = 0; j < 3; j++) {
        cellColors.push(color.r, color.g, color.b);
      }

      boundaryPositions.push(
        current.x, current.y, current.z,
        next.x, next.y, next.z,
      );
    }
  }

  base.dispose();

  const surfaceGeometry = new THREE.BufferGeometry();
  surfaceGeometry.setAttribute(
    'position',
    new THREE.Float32BufferAttribute(cellPositions, 3),
  );
  surfaceGeometry.setAttribute(
    'color',
    new THREE.Float32BufferAttribute(cellColors, 3),
  );

  const boundaryGeometry = new THREE.BufferGeometry();
  boundaryGeometry.setAttribute(
    'position',
    new THREE.Float32BufferAttribute(boundaryPositions, 3),
  );

  return { surfaceGeometry, boundaryGeometry };
};

/* -------------------------------------------------------------------------- */
/* Component                                                                  */
/* -------------------------------------------------------------------------- */

type PlanetProps = {
  data: PlanetMapData;
  onTileClick?: (x: number, y: number, tile: PlanetTile) => void;
  onObjectClick?: (object: PlanetObject) => void;
};

export const Planet = ({
  data,
  onTileClick,
  onObjectClick,
}: PlanetProps) => {
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const container = containerRef.current;
    if (!container) return;

    const scene = new THREE.Scene();
    scene.background = new THREE.Color(0x03060c);

    const camera = new THREE.PerspectiveCamera(
      40,
      container.clientWidth / container.clientHeight,
      0.1,
      100,
    );

    const renderer = new THREE.WebGLRenderer({
      antialias: true,
      alpha: true,
    });
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    renderer.setSize(container.clientWidth, container.clientHeight);
    renderer.outputColorSpace = THREE.SRGBColorSpace;
    container.appendChild(renderer.domElement);

    const controls = new OrbitControls(camera, renderer.domElement);
    controls.enablePan = false;
    controls.enableDamping = true;
    controls.minDistance = 2.2;
    controls.maxDistance = 8;

    loadCameraState(camera, controls);

    scene.add(new THREE.AmbientLight(0xffffff, 0.4));

    const sun = new THREE.DirectionalLight(0xffffff, 2);
    sun.position.set(4, 3, 5);
    scene.add(sun);

    const planet = new THREE.Group();
    scene.add(planet);

    const { surfaceGeometry, boundaryGeometry } = buildHexPlanet(data);

    const surfaceMaterial = new THREE.MeshStandardMaterial({
      vertexColors: true,
      flatShading: true,
      roughness: 1,
      metalness: 0,
    });

    const surface = new THREE.Mesh(surfaceGeometry, surfaceMaterial);
    planet.add(surface);

    const boundaryMaterial = new THREE.LineBasicMaterial({
      color: 0xb5d5df,
      transparent: true,
      opacity: 0.18,
    });

    const boundaries = new THREE.LineSegments(boundaryGeometry, boundaryMaterial);
    boundaries.scale.setScalar(1.002);
    planet.add(boundaries);

    // Atmosphere
    const atmosphereGeometry = new THREE.SphereGeometry(2.065, 64, 64);
    const atmosphereMaterial = new THREE.MeshBasicMaterial({
      color: 0x4f8dff,
      transparent: true,
      opacity: 0.09,
      side: THREE.BackSide,
    });
    planet.add(new THREE.Mesh(atmosphereGeometry, atmosphereMaterial));

    // Objects
    const objectGroup = new THREE.Group();
    planet.add(objectGroup);

    for (const object of data.objects) {
      const marker = new THREE.Mesh(
        new THREE.SphereGeometry(0.035, 12, 12),
        new THREE.MeshBasicMaterial({
          color: object.type === 'settlement' ? 0xffc857 : 0xffffff,
        }),
      );

      marker.position.copy(
        planetCoordinateToVector(
          object.x,
          object.y,
          data.width,
          data.height,
          2.04,
        ),
      );
      marker.userData.object = object;
      objectGroup.add(marker);
    }

    const raycaster = new THREE.Raycaster();
    const mouse = new THREE.Vector2();

    const handleClick = (event: MouseEvent) => {
      const rect = renderer.domElement.getBoundingClientRect();

      mouse.x = ((event.clientX - rect.left) / rect.width) * 2 - 1;
      mouse.y = -((event.clientY - rect.top) / rect.height) * 2 + 1;

      raycaster.setFromCamera(mouse, camera);

      const objectHits = raycaster.intersectObjects(objectGroup.children, true);
      if (objectHits.length) {
        const object = objectHits[0].object.userData.object as PlanetObject;
        onObjectClick?.(object);
        return;
      }

      const hits = raycaster.intersectObject(surface);
      if (!hits.length) return;

      const point = hits[0].point.clone();
      planet.worldToLocal(point);

      const radius = point.length();
      const latitude = Math.asin(point.y / radius);
      const longitude = Math.atan2(point.z, point.x);

      const x = THREE.MathUtils.clamp(
        Math.round(((longitude + Math.PI) / (Math.PI * 2)) * data.width),
        1,
        data.width,
      );

      const y = THREE.MathUtils.clamp(
        Math.round(((latitude + Math.PI / 2) / Math.PI) * data.height),
        1,
        data.height,
      );

      onTileClick?.(x, y, getPlanetTile(x, y, data));
    };

    renderer.domElement.addEventListener('click', handleClick);

    let frame = 0;
    const animate = () => {
      frame = requestAnimationFrame(animate);
      controls.update();
      renderer.render(scene, camera);
    };
    animate();

    const resize = () => {
      const width = container.clientWidth;
      const height = container.clientHeight;
      camera.aspect = width / height;
      camera.updateProjectionMatrix();
      renderer.setSize(width, height);
    };
    window.addEventListener('resize', resize);

    const saveView = () => saveCameraState(camera, controls);
    controls.addEventListener('change', saveView);

    return () => {
      saveCameraState(camera, controls);
      cancelAnimationFrame(frame);
      window.removeEventListener('resize', resize);
      renderer.domElement.removeEventListener('click', handleClick);
      controls.removeEventListener('change', saveView);
      controls.dispose();
      surfaceGeometry.dispose();
      surfaceMaterial.dispose();
      boundaryGeometry.dispose();
      boundaryMaterial.dispose();
      atmosphereGeometry.dispose();
      atmosphereMaterial.dispose();
      renderer.dispose();
      renderer.domElement.remove();
    };
  }, [data, onTileClick, onObjectClick]);

  return (
    <div
      ref={containerRef}
      style={{ width: '100%', height: '100%', overflow: 'hidden' }}
    />
  );
};
