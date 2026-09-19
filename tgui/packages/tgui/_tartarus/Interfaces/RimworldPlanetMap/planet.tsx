/*
 * Copyright (c) 2026 Fenysha
 * All rights reserved.
 */

import { useEffect, useRef, useState } from 'react';
import { resolveAsset } from 'tgui/assets';
import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';

import { loadCameraState, saveCameraState } from './camera';
import { PLANET_RADIUS } from './generation/constants';
import { PlanetGenerator } from './generation/generator';
import { HEX_SHADER_DATA, type HexGrid } from './generation/hexGrid';
import type { PlanetMapData, PlanetObject, PlanetTile } from './types';
import { getPlanetMapIdentity } from './types';
import {
  PLANET_ATMOSPHERE_COLOR,
  PLANET_BACKGROUND,
  PLANET_FILL_COLOR,
  PLANET_NIGHT_COLOR,
  PLANET_SUN_COLOR,
  PLANET_SUN_DIRECTION,
} from './visual/constants';
import {
  gridFor,
  tileOutline,
  tileToVector,
  vectorToTile,
} from './visual/coordinates';
import {
  ATLAS_COLUMNS,
  ATLAS_FRAME_SIZE,
  ATLAS_ROWS,
  getDecorAtlas,
} from './visual/decorAtlas';
import { buildPlanetGeometry, type LodLevel } from './visual/geometry';
import {
  buildPlanetTextures,
  type PlanetTextures,
} from './visual/planetTexture';

import {
  ATMOSPHERE_FRAGMENT_SHADER,
  ATMOSPHERE_VERTEX_SHADER,
  CLOUD_FRAGMENT_SHADER,
  CLOUD_VERTEX_SHADER,
  NIGHT_FRAGMENT_SHADER,
  NIGHT_VERTEX_SHADER,
  PLANET_SURFACE_FRAGMENT_SHADER,
  PLANET_SURFACE_VERTEX_SHADER,
} from './visual/shaders';

/** A cell picked by a click, with 1-based coordinates as DM uses them. */
export type CellInteraction = {
  x: number;
  y: number;
  tile: PlanetTile;
  object?: PlanetObject;
  shift: boolean;
  ctrl: boolean;
  alt: boolean;
};

type PlanetProps = {
  data: PlanetMapData;
  selectedX?: number;
  selectedY?: number;
  showAtmosphere?: boolean;
  showClouds?: boolean;
  onTileClick?: (x: number, y: number, tile: PlanetTile) => void;
  onObjectClick?: (object: PlanetObject) => void;
  onTileDoubleClick?: (cell: CellInteraction) => void;
  onTileRightClick?: (cell: CellInteraction) => void;
};

type PlanetRuntime = {
  objectGroup: THREE.Group;
  selection: THREE.Group;
  generator: PlanetGenerator;
  surface: THREE.Mesh;
  planetGroup: THREE.Group;
  planetTexture: THREE.CanvasTexture | THREE.DataTexture;
  surfaceMaterial: THREE.ShaderMaterial;
  atmosphereMesh: THREE.Mesh;
  cloudsMesh: THREE.Mesh;
  currentLod: LodLevel;
};

const LOD_DISTANCES = {
  near: 3.6,
  medium: 5.2,
} as const;

const getPlanetLod = (distance: number): LodLevel =>
  distance < LOD_DISTANCES.near
    ? 'near'
    : distance < LOD_DISTANCES.medium
      ? 'medium'
      : 'far';

const textureCache = new Map<string, PlanetTextures>();
const MAX_TEXTURE_CACHE_SIZE = 8;

const createPlaceholderTexture = (): THREE.DataTexture => {
  const pixels = new Uint8Array([60, 90, 120, 255]);
  const texture = new THREE.DataTexture(
    pixels,
    1,
    1,
    THREE.RGBAFormat,
    THREE.UnsignedByteType,
  );
  texture.needsUpdate = true;
  return texture;
};

const placeholderTexture = createPlaceholderTexture();

/** No decor anywhere, until the real per-tile data is built */
const emptyDecorTexture = new THREE.DataTexture(
  new Uint8Array(4),
  1,
  1,
  THREE.RGBAFormat,
  THREE.UnsignedByteType,
);
emptyDecorTexture.needsUpdate = true;

/** Decor icons fade in once a cell is this many pixels across on screen */
const DECOR_FADE_START_PX = 5;
const DECOR_FADE_FULL_PX = 12;

/** River half-width in tile spacings, and never less than this many pixels across */
const RIVER_HALF_WIDTH = 0.14;
const RIVER_MIN_PX = 1.5;

const objectTextureCache = new Map<string, THREE.Texture>();
const sharedTextureLoader = new THREE.TextureLoader();

const loadObjectTexture = (iconName: string): THREE.Texture | null => {
  const assetName = `rimworld_planet_icon_${iconName}.png`;
  if (objectTextureCache.has(assetName)) {
    return objectTextureCache.get(assetName)!;
  }

  try {
    const src = resolveAsset(assetName);
    if (src) {
      const texture = sharedTextureLoader.load(src);
      texture.colorSpace = THREE.SRGBColorSpace;
      objectTextureCache.set(assetName, texture);
      return texture;
    }
  } catch (error) {
    console.warn(`[Planet] Failed to resolve asset "${assetName}":`, error);
  }
  return null;
};

const geometryCache = new Map<string, THREE.BufferGeometry>();
const MAX_GEOMETRY_CACHE_SIZE = 12;

const getCachedPlanetGeometry = (
  data: PlanetMapData,
  lod: LodLevel,
): THREE.BufferGeometry => {
  const key = `${data.width}:${data.height}:${lod}`;
  let geom = geometryCache.get(key);
  if (!geom) {
    geom = buildPlanetGeometry(data, lod);

    if (geometryCache.size >= MAX_GEOMETRY_CACHE_SIZE) {
      const firstKey = geometryCache.keys().next().value;
      if (firstKey) {
        geometryCache.get(firstKey)?.dispose();
        geometryCache.delete(firstKey);
      }
    }
    geometryCache.set(key, geom);
  }
  return geom;
};

let sharedStarGeometry: THREE.BufferGeometry | null = null;

const getSharedStarGeometry = (): THREE.BufferGeometry => {
  if (!sharedStarGeometry) {
    const starCount = 1800;
    const starPositions = new Float32Array(starCount * 3);

    for (let i = 0; i < starCount; i++) {
      const radius = 40 + Math.random() * 60;
      const theta = Math.random() * Math.PI * 2;
      const phi = Math.acos(2 * Math.random() - 1);

      starPositions[i * 3] = radius * Math.sin(phi) * Math.cos(theta);
      starPositions[i * 3 + 1] = radius * Math.sin(phi) * Math.sin(theta);
      starPositions[i * 3 + 2] = radius * Math.cos(phi);
    }

    sharedStarGeometry = new THREE.BufferGeometry();
    sharedStarGeometry.setAttribute(
      'position',
      new THREE.BufferAttribute(starPositions, 3),
    );
  }
  return sharedStarGeometry;
};

const sharedMarkerGeometry = new THREE.SphereGeometry(0.018, 12, 12);
const sharedMarkerMaterials = {
  settlement: new THREE.MeshBasicMaterial({ color: 0xffc857 }),
  road: new THREE.MeshBasicMaterial({ color: 0xc4a574 }),
  default: new THREE.MeshBasicMaterial({ color: 0xf0f4ff }),
};

/** Radians per second per unit of camera height above the surface */
const WASD_ANGULAR_SPEED = 0.12;
/** How much faster WASD moves while Shift is held */
const WASD_SHIFT_MULTIPLIER = 3;

// A cell is only ~0.006 across, so any real lift reads as the outline sitting on the next hex.
// The surface mesh's faces dip inside the sphere, so a hair above it always stays visible.
const HEIGHT_SELECTION_OUTLINE = PLANET_RADIUS + 0.0003;
const HEIGHT_SELECTION_GLOW = PLANET_RADIUS + 0.0004;
const HEIGHT_OBJECT_MARKER = PLANET_RADIUS + 0.004;

/** The selected tile's real outline: a hexagon, or a pentagon at the 12 icosahedron corners. */
const buildTileOutlineGeometry = (
  grid: HexGrid,
  x: number,
  y: number,
  radius: number,
) => new THREE.BufferGeometry().setFromPoints(tileOutline(grid, x, y, radius));

const createSelection = (grid: HexGrid) => {
  const group = new THREE.Group();
  group.visible = false;

  const glow = new THREE.LineLoop(
    buildTileOutlineGeometry(grid, 1, 1, HEIGHT_SELECTION_GLOW),
    new THREE.LineBasicMaterial({
      color: 0x6bbdff,
      transparent: true,
      opacity: 0.1,
      depthWrite: false,
    }),
  );

  const outline = new THREE.LineLoop(
    buildTileOutlineGeometry(grid, 1, 1, HEIGHT_SELECTION_OUTLINE),
    new THREE.LineBasicMaterial({
      color: 0x9edcff,
      transparent: true,
      opacity: 0.92,
      depthWrite: false,
    }),
  );

  glow.renderOrder = 20;
  outline.renderOrder = 21;

  group.add(glow, outline);

  return group;
};

const updateSelection = (
  group: THREE.Group,
  grid: HexGrid,
  x: number,
  y: number,
) => {
  if (!grid.isValid(x, y)) {
    group.visible = false;
    return;
  }
  const glow = group.children[0] as THREE.LineLoop;
  const outline = group.children[1] as THREE.LineLoop;

  glow.geometry.dispose();
  glow.geometry = buildTileOutlineGeometry(grid, x, y, HEIGHT_SELECTION_GLOW);

  outline.geometry.dispose();
  outline.geometry = buildTileOutlineGeometry(
    grid,
    x,
    y,
    HEIGHT_SELECTION_OUTLINE,
  );

  group.visible = true;
};

export const Planet = ({
  data,
  selectedX,
  selectedY,
  showAtmosphere = true,
  showClouds = true,
  onTileClick,
  onObjectClick,
  onTileDoubleClick,
  onTileRightClick,
}: PlanetProps) => {
  const containerRef = useRef<HTMLDivElement>(null);
  const runtimeRef = useRef<PlanetRuntime | null>(null);

  const dataRef = useRef(data);
  dataRef.current = data;

  const keysPressed = useRef<{ [key: string]: boolean }>({});

  const mapIdentity = getPlanetMapIdentity(data);

  const [isLoading, setIsLoading] = useState(
    () => !textureCache.has(mapIdentity),
  );

  const callbacksRef = useRef({
    onTileClick,
    onObjectClick,
    onTileDoubleClick,
    onTileRightClick,
  });

  callbacksRef.current = {
    onTileClick,
    onObjectClick,
    onTileDoubleClick,
    onTileRightClick,
  };

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      const key = e.key.toLowerCase();
      if (['w', 'a', 's', 'd', 'shift'].includes(key)) {
        keysPressed.current[key] = true;
      }
    };

    const handleKeyUp = (e: KeyboardEvent) => {
      const key = e.key.toLowerCase();
      if (['w', 'a', 's', 'd', 'shift'].includes(key)) {
        keysPressed.current[key] = false;
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    window.addEventListener('keyup', handleKeyUp);

    return () => {
      window.removeEventListener('keydown', handleKeyDown);
      window.removeEventListener('keyup', handleKeyUp);
    };
  }, []);

  useEffect(() => {
    let isMounted = true;
    const container = containerRef.current;
    if (!container) {
      return;
    }

    const generator = new PlanetGenerator(data);
    const grid = gridFor(data);

    const scene = new THREE.Scene();
    scene.background = PLANET_BACKGROUND.clone();
    scene.fog = null;

    const camera = new THREE.PerspectiveCamera(
      38,
      container.clientWidth / container.clientHeight,
      0.1,
      200,
    );

    const renderer = new THREE.WebGLRenderer({
      antialias: true,
      alpha: true,
      powerPreference: 'high-performance',
    });

    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    renderer.setSize(container.clientWidth, container.clientHeight);
    renderer.outputColorSpace = THREE.SRGBColorSpace;
    renderer.toneMapping = THREE.ACESFilmicToneMapping;
    renderer.toneMappingExposure = 1.15;

    container.appendChild(renderer.domElement);

    const controls = new OrbitControls(camera, renderer.domElement);
    controls.enablePan = false;
    controls.enableDamping = true;
    controls.dampingFactor = 0.06;
    controls.minDistance = PLANET_RADIUS * 1.08;
    controls.maxDistance = 13;
    controls.rotateSpeed = 0.55;

    loadCameraState(camera, controls);
    controls.target.set(0, 0, 0);
    controls.update();

    scene.add(new THREE.AmbientLight(0x6b8cae, 0.22));

    const sun = new THREE.DirectionalLight(PLANET_SUN_COLOR, 2.8);
    sun.position.copy(PLANET_SUN_DIRECTION);
    scene.add(sun);

    const fill = new THREE.DirectionalLight(PLANET_FILL_COLOR, 0.22);
    fill.position.set(-4, -1, -3);
    scene.add(fill);

    // Visual Sun Setup
    const sunGroup = new THREE.Group();
    const sunDistance = 55;
    const sunPos = PLANET_SUN_DIRECTION.clone()
      .normalize()
      .multiplyScalar(sunDistance);

    const sunCoreMesh = new THREE.Mesh(
      new THREE.SphereGeometry(3.2, 32, 32),
      new THREE.MeshBasicMaterial({ color: 0xffffff }),
    );
    sunCoreMesh.position.copy(sunPos);
    sunGroup.add(sunCoreMesh);

    const sunInnerGlowMesh = new THREE.Mesh(
      new THREE.SphereGeometry(5.0, 32, 32),
      new THREE.MeshBasicMaterial({
        color: 0xffea9f,
        transparent: true,
        opacity: 0.65,
        side: THREE.BackSide,
        blending: THREE.AdditiveBlending,
      }),
    );
    sunInnerGlowMesh.position.copy(sunPos);
    sunGroup.add(sunInnerGlowMesh);

    const sunOuterGlowMesh = new THREE.Mesh(
      new THREE.SphereGeometry(8.5, 32, 32),
      new THREE.MeshBasicMaterial({
        color: 0xff7700,
        transparent: true,
        opacity: 0.25,
        side: THREE.BackSide,
        blending: THREE.AdditiveBlending,
      }),
    );
    sunOuterGlowMesh.position.copy(sunPos);
    sunGroup.add(sunOuterGlowMesh);

    scene.add(sunGroup);

    const stars = new THREE.Points(
      getSharedStarGeometry(),
      new THREE.PointsMaterial({
        color: 0xffffff,
        size: 0.15,
        sizeAttenuation: true,
        transparent: true,
        opacity: 0.85,
        depthWrite: false,
      }),
    );
    scene.add(stars);

    const planetGroup = new THREE.Group();
    scene.add(planetGroup);

    if (data.rotationAngle != null) {
      planetGroup.rotation.y = (data.rotationAngle * Math.PI) / 180;
    }

    const cachedTextures = textureCache.get(mapIdentity);
    const initialTexture = cachedTextures?.color ?? placeholderTexture;

    const surfaceMaterial = new THREE.ShaderMaterial({
      uniforms: {
        planetMap: { value: initialTexture },
        mapSize: { value: new THREE.Vector2(grid.width, grid.height) },
        gridN: { value: grid.n },
        planetRadius: { value: PLANET_RADIUS },
        tileSpacing: { value: grid.spacing },
        diamondCorners: {
          value: HEX_SHADER_DATA.diamondCorners.map(
            (v) => new THREE.Vector3(...v),
          ),
        },
        faceOrigin: {
          value: HEX_SHADER_DATA.faceOrigin.map((v) => new THREE.Vector3(...v)),
        },
        faceE1: {
          value: HEX_SHADER_DATA.faceE1.map((v) => new THREE.Vector3(...v)),
        },
        faceE2: {
          value: HEX_SHADER_DATA.faceE2.map((v) => new THREE.Vector3(...v)),
        },
        faceNormal: {
          value: HEX_SHADER_DATA.faceNormal.map((v) => new THREE.Vector3(...v)),
        },
        faceDiamond: { value: HEX_SHADER_DATA.faceDiamond },
        faceUpper: { value: HEX_SHADER_DATA.faceUpper },
        sunDirection: { value: PLANET_SUN_DIRECTION.clone().normalize() },
        nightColor: { value: PLANET_NIGHT_COLOR.clone() },
        decorMap: { value: cachedTextures?.decor ?? emptyDecorTexture },
        decorAtlas: { value: emptyDecorTexture as THREE.Texture },
        atlasGrid: { value: new THREE.Vector2(ATLAS_COLUMNS, ATLAS_ROWS) },
        decorOpacity: { value: 0 },
        decorLod: { value: 0 },
        riverWidth: { value: RIVER_HALF_WIDTH },
      },
      vertexShader: PLANET_SURFACE_VERTEX_SHADER,
      fragmentShader: PLANET_SURFACE_FRAGMENT_SHADER,
      side: THREE.DoubleSide,
      transparent: false,
      depthWrite: true,
    });

    let currentLod: LodLevel = getPlanetLod(controls.getDistance());

    const surface = new THREE.Mesh(
      getCachedPlanetGeometry(data, currentLod),
      surfaceMaterial,
    );
    surface.name = 'PlanetSurface';
    planetGroup.add(surface);

    let animFrameId: number | null = null;

    getDecorAtlas()
      .then((atlas) => {
        if (isMounted && surfaceMaterial.uniforms.decorAtlas) {
          surfaceMaterial.uniforms.decorAtlas.value = atlas;
        }
      })
      .catch((error) => console.warn('[Planet] Decor atlas failed:', error));

    if (cachedTextures) {
      setIsLoading(false);
    } else {
      setIsLoading(true);

      const buildTextureWhenReady = () => {
        if (generator.isReady()) {
          try {
            const textures = buildPlanetTextures(data, generator);

            if (textureCache.size >= MAX_TEXTURE_CACHE_SIZE) {
              const firstKey = textureCache.keys().next().value;
              if (firstKey) {
                const evicted = textureCache.get(firstKey);
                evicted?.color.dispose();
                evicted?.decor.dispose();
                textureCache.delete(firstKey);
              }
            }
            textureCache.set(mapIdentity, textures);

            if (surfaceMaterial.uniforms.planetMap) {
              surfaceMaterial.uniforms.planetMap.value = textures.color;
            }
            if (surfaceMaterial.uniforms.decorMap) {
              surfaceMaterial.uniforms.decorMap.value = textures.decor;
            }
          } catch (error) {
            console.error('[Planet] Texture generation error:', error);
          } finally {
            if (isMounted) {
              setIsLoading(false);
            }
            animFrameId = null;
          }
        } else if (generator.getState() === 'error') {
          console.error(
            '[Planet] Planet generator error:',
            generator.getError(),
          );
          if (isMounted) {
            setIsLoading(false);
          }
          animFrameId = null;
        } else {
          animFrameId = requestAnimationFrame(buildTextureWhenReady);
        }
      };
      animFrameId = requestAnimationFrame(buildTextureWhenReady);
    }

    const atmosphereMaterial = new THREE.ShaderMaterial({
      uniforms: {
        atmosphereColor: { value: PLANET_ATMOSPHERE_COLOR.clone() },
        sunDirection: { value: PLANET_SUN_DIRECTION.clone().normalize() },
        opacityFactor: { value: 1.0 },
      },
      vertexShader: ATMOSPHERE_VERTEX_SHADER,
      fragmentShader: ATMOSPHERE_FRAGMENT_SHADER,
      side: THREE.BackSide,
      blending: THREE.AdditiveBlending,
      transparent: true,
      depthWrite: false,
    });

    const atmosphere = new THREE.Mesh(
      new THREE.SphereGeometry(PLANET_RADIUS * 1.08, 96, 96),
      atmosphereMaterial,
    );
    planetGroup.add(atmosphere);

    const night = new THREE.Mesh(
      new THREE.SphereGeometry(PLANET_RADIUS * 1.002, 96, 96),
      new THREE.ShaderMaterial({
        uniforms: {
          sunDirection: { value: PLANET_SUN_DIRECTION.clone().normalize() },
          nightColor: { value: PLANET_NIGHT_COLOR.clone() },
        },
        vertexShader: NIGHT_VERTEX_SHADER,
        fragmentShader: NIGHT_FRAGMENT_SHADER,
        transparent: true,
        depthWrite: false,
        blending: THREE.AdditiveBlending,
      }),
    );
    planetGroup.add(night);

    const cloudMaterial = new THREE.ShaderMaterial({
      uniforms: {
        time: { value: 0 },
        opacityFactor: { value: 1.0 },
      },
      vertexShader: CLOUD_VERTEX_SHADER,
      fragmentShader: CLOUD_FRAGMENT_SHADER,
      transparent: true,
      depthWrite: false,
    });

    const clouds = new THREE.Mesh(
      new THREE.SphereGeometry(PLANET_RADIUS * 1.028, 96, 96),
      cloudMaterial,
    );
    planetGroup.add(clouds);

    const objectGroup = new THREE.Group();
    objectGroup.name = 'PlanetObjects';
    planetGroup.add(objectGroup);

    const selection = createSelection(grid);
    planetGroup.add(selection);

    runtimeRef.current = {
      objectGroup,
      selection,
      generator,
      surface,
      planetGroup,
      planetTexture: initialTexture,
      surfaceMaterial,
      atmosphereMesh: atmosphere,
      cloudsMesh: clouds,
      currentLod,
    };

    const switchLod = (newLod: LodLevel) => {
      if (newLod === currentLod) {
        return;
      }

      surface.geometry = getCachedPlanetGeometry(data, newLod);
      currentLod = newLod;

      if (runtimeRef.current) {
        runtimeRef.current.currentLod = newLod;
      }
    };

    const raycaster = new THREE.Raycaster();
    const mouse = new THREE.Vector2();

    let pointerDownX = 0;
    let pointerDownY = 0;
    let pointerDragged = false;

    const handlePointerDown = (event: PointerEvent) => {
      pointerDownX = event.clientX;
      pointerDownY = event.clientY;
      pointerDragged = false;
    };

    const handlePointerMove = (event: PointerEvent) => {
      if (
        Math.abs(event.clientX - pointerDownX) > 5 ||
        Math.abs(event.clientY - pointerDownY) > 5
      ) {
        pointerDragged = true;
      }
    };

    /** The object or surface cell under the cursor, 1-based. */
    const pickAt = (event: MouseEvent): CellInteraction | null => {
      const rect = renderer.domElement.getBoundingClientRect();
      mouse.x = ((event.clientX - rect.left) / rect.width) * 2 - 1;
      mouse.y = -(((event.clientY - rect.top) / rect.height) * 2 - 1);
      raycaster.setFromCamera(mouse, camera);

      const modifiers = {
        shift: event.shiftKey,
        ctrl: event.ctrlKey,
        alt: event.altKey,
      };

      const objectHits = raycaster.intersectObjects(objectGroup.children, true);
      if (objectHits.length > 0) {
        const object = objectHits[0].object.userData.object as
          | PlanetObject
          | undefined;
        if (object) {
          return {
            x: object.x,
            y: object.y,
            tile: generator.getTile(object.x, object.y),
            object,
            ...modifiers,
          };
        }
      }

      const surfaceHits = raycaster.intersectObject(surface, false);
      if (surfaceHits.length === 0) {
        return null;
      }
      const point = surfaceHits[0].point.clone();
      planetGroup.worldToLocal(point);

      const { x, y } = vectorToTile(grid, point);
      return { x, y, tile: generator.getTile(x, y), ...modifiers };
    };

    const handleClick = (event: MouseEvent) => {
      if (pointerDragged) {
        pointerDragged = false;
        return;
      }
      const cell = pickAt(event);
      if (!cell) {
        return;
      }
      if (cell.object) {
        callbacksRef.current.onObjectClick?.(cell.object);
      }
      callbacksRef.current.onTileClick?.(cell.x, cell.y, cell.tile);
    };

    const handleDoubleClick = (event: MouseEvent) => {
      if (pointerDragged) {
        return;
      }
      const cell = pickAt(event);
      if (cell) {
        callbacksRef.current.onTileDoubleClick?.(cell);
      }
    };

    const handleContextMenu = (event: MouseEvent) => {
      event.preventDefault();
      if (pointerDragged) {
        return;
      }
      const cell = pickAt(event);
      if (cell) {
        callbacksRef.current.onTileRightClick?.(cell);
      }
    };

    renderer.domElement.addEventListener('pointerdown', handlePointerDown);
    renderer.domElement.addEventListener('pointermove', handlePointerMove);
    renderer.domElement.addEventListener('click', handleClick);
    renderer.domElement.addEventListener('dblclick', handleDoubleClick);
    renderer.domElement.addEventListener('contextmenu', handleContextMenu);

    let frame = 0;
    const clock = new THREE.Clock();
    let lastLod: LodLevel = currentLod;

    const animate = () => {
      frame = requestAnimationFrame(animate);

      const delta = clock.getDelta();
      const time = clock.getElapsedTime();

      const distance = controls.getDistance();

      // How many pixels a cell spans at the point nearest the camera: fade icons in once
      // they're big enough to read, and pick the atlas mip that matches their size
      const cellWorld = grid.spacing * PLANET_RADIUS;
      const pixelsPerUnit =
        renderer.domElement.height /
        (2 *
          Math.tan(THREE.MathUtils.degToRad(camera.fov) / 2) *
          Math.max(distance - PLANET_RADIUS, 1e-4));
      const cellPixels = cellWorld * pixelsPerUnit;
      if (surfaceMaterial.uniforms.decorOpacity) {
        surfaceMaterial.uniforms.decorOpacity.value =
          THREE.MathUtils.smoothstep(
            cellPixels,
            DECOR_FADE_START_PX,
            DECOR_FADE_FULL_PX,
          );
      }
      if (surfaceMaterial.uniforms.riverWidth) {
        surfaceMaterial.uniforms.riverWidth.value = Math.max(
          RIVER_HALF_WIDTH,
          RIVER_MIN_PX / 2 / Math.max(cellPixels, 1e-3),
        );
      }
      if (surfaceMaterial.uniforms.decorLod) {
        surfaceMaterial.uniforms.decorLod.value = Math.max(
          0,
          Math.log2(ATLAS_FRAME_SIZE / Math.max(cellPixels, 1)),
        );
      }

      // Proximity factors
      const nearDistanceMin = PLANET_RADIUS * 1.1;
      const nearDistanceMax = PLANET_RADIUS * 1.45;
      const nearProgress = THREE.MathUtils.clamp(
        (distance - nearDistanceMin) / (nearDistanceMax - nearDistanceMin),
        0.0,
        1.0,
      );

      // Camera slowdown
      controls.rotateSpeed = THREE.MathUtils.lerp(0.12, 0.55, nearProgress);

      // Atmospheric fade-out on close distance
      const fadeOpacity = THREE.MathUtils.clamp(
        (distance - PLANET_RADIUS * 1.05) / (PLANET_RADIUS * 0.45),
        0.0,
        1.0,
      );

      if (atmosphereMaterial.uniforms.opacityFactor) {
        atmosphereMaterial.uniforms.opacityFactor.value = fadeOpacity;
      }
      if (cloudMaterial.uniforms.opacityFactor) {
        cloudMaterial.uniforms.opacityFactor.value = fadeOpacity;
      }

      if (cloudMaterial?.uniforms?.time) {
        cloudMaterial.uniforms.time.value = time;
      }
      clouds.rotation.y = time * 0.012;

      // WASD orbits in latitude/longitude. The rate scales with height above the surface, so
      // the ground scrolls past at the same on-screen speed at any zoom.
      const keys = keysPressed.current;
      const vertical = (keys.w ? 1 : 0) - (keys.s ? 1 : 0);
      const horizontal = (keys.d ? 1 : 0) - (keys.a ? 1 : 0);

      if (vertical || horizontal) {
        const altitude = Math.max(distance - PLANET_RADIUS, 0.02);
        const boost = keys.shift ? WASD_SHIFT_MULTIPLIER : 1;
        const step =
          WASD_ANGULAR_SPEED * boost * altitude * Math.min(delta, 0.1);
        const orbit = new THREE.Spherical().setFromVector3(
          camera.position.clone().sub(controls.target),
        );

        orbit.phi -= vertical * step;
        // A degree of longitude is shorter away from the equator; divide it back out so
        // sideways matches up/down
        orbit.theta +=
          (horizontal * step) / Math.max(Math.sin(orbit.phi), 0.15);
        orbit.phi = THREE.MathUtils.clamp(orbit.phi, 0.05, Math.PI - 0.05);

        camera.position.setFromSpherical(orbit).add(controls.target);
      }
      // Planet rotation & close-proximity camera attachment
      const currentData = dataRef.current;
      if (currentData.autoRotate !== false) {
        const speed = currentData.rotationSpeed ?? 1.0;
        const rotDelta = delta * 0.08 * speed;
        planetGroup.rotation.y += rotDelta;

        // Sync camera position with planetary rotation when close to terrain
        if (nearProgress < 0.85) {
          const bindRatio = 1.0 - nearProgress / 0.85;
          camera.position.applyAxisAngle(
            new THREE.Vector3(0, 1, 0),
            rotDelta * bindRatio,
          );
        }
      }

      sunInnerGlowMesh.scale.setScalar(1 + Math.sin(time * 1.5) * 0.025);
      sunOuterGlowMesh.scale.setScalar(1 + Math.cos(time * 1.2) * 0.035);

      const nextLod = getPlanetLod(distance);
      if (nextLod !== lastLod) {
        switchLod(nextLod);
        lastLod = nextLod;
      }

      if (runtimeRef.current?.objectGroup) {
        const tileWidthInUnits = (Math.PI * 2 * PLANET_RADIUS) / data.width;
        const minSpriteScale = tileWidthInUnits * 0.45;
        const maxSpriteScale = 0.22;

        const zoomProgress = THREE.MathUtils.clamp(
          (distance - 2.2) / (10.0 - 2.2),
          0.0,
          1.0,
        );

        const spriteScale = THREE.MathUtils.lerp(
          minSpriteScale,
          maxSpriteScale,
          zoomProgress,
        );
        const markerScale = THREE.MathUtils.lerp(0.5, 2.0, zoomProgress);

        runtimeRef.current.objectGroup.children.forEach((child) => {
          child.visible = true;

          if (child instanceof THREE.Sprite) {
            child.scale.set(spriteScale, spriteScale, 1);
            if (child.material) {
              child.material.opacity = 1.0;
            }
          } else if (child instanceof THREE.Mesh) {
            child.scale.setScalar(markerScale);
          }
        });
      }

      controls.target.set(0, 0, 0);
      controls.update();

      try {
        renderer.render(scene, camera);
      } catch (error) {
        console.error('[Planet] Render error:', error);
      }
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
      isMounted = false;
      saveCameraState(camera, controls);

      if (animFrameId !== null) {
        cancelAnimationFrame(animFrameId);
      }

      runtimeRef.current = null;
      cancelAnimationFrame(frame);

      window.removeEventListener('resize', resize);
      renderer.domElement.removeEventListener('pointerdown', handlePointerDown);
      renderer.domElement.removeEventListener('pointermove', handlePointerMove);
      renderer.domElement.removeEventListener('click', handleClick);
      renderer.domElement.removeEventListener('dblclick', handleDoubleClick);
      renderer.domElement.removeEventListener('contextmenu', handleContextMenu);
      controls.removeEventListener('change', saveView);

      controls.dispose();

      surfaceMaterial.dispose();

      atmosphere.geometry.dispose();
      atmosphereMaterial.dispose();

      night.geometry.dispose();
      (night.material as THREE.Material).dispose();

      clouds.geometry.dispose();
      cloudMaterial.dispose();

      sunCoreMesh.geometry.dispose();
      (sunCoreMesh.material as THREE.Material).dispose();
      sunInnerGlowMesh.geometry.dispose();
      (sunInnerGlowMesh.material as THREE.Material).dispose();
      sunOuterGlowMesh.geometry.dispose();
      (sunOuterGlowMesh.material as THREE.Material).dispose();

      selection.traverse((child) => {
        if (child instanceof THREE.LineLoop) {
          child.geometry.dispose();
          (child.material as THREE.Material).dispose();
        }
      });

      (stars.material as THREE.Material).dispose();

      renderer.dispose();
      renderer.domElement.remove();
    };
  }, [mapIdentity]);

  // Handle visibility toggles for atmosphere and clouds
  useEffect(() => {
    const runtime = runtimeRef.current;
    if (!runtime) {
      return;
    }

    if (runtime.atmosphereMesh) {
      runtime.atmosphereMesh.visible = showAtmosphere;
    }
    if (runtime.cloudsMesh) {
      runtime.cloudsMesh.visible = showClouds;
    }
  }, [showAtmosphere, showClouds]);

  useEffect(() => {
    const runtime = runtimeRef.current;
    if (!runtime) {
      return;
    }

    const { objectGroup } = runtime;

    while (objectGroup.children.length > 0) {
      const child = objectGroup.children[0];
      objectGroup.remove(child);
    }

    for (const object of data.objects ?? []) {
      let objectMesh: THREE.Object3D;

      if (object.icon) {
        const texture = loadObjectTexture(object.icon);
        if (texture) {
          const spriteMaterial = new THREE.SpriteMaterial({
            map: texture,
            transparent: true,
            opacity: 1.0,
            depthTest: true,
            depthWrite: false,
          });
          const sprite = new THREE.Sprite(spriteMaterial);
          sprite.renderOrder = 10;
          objectMesh = sprite;
        } else {
          const material = sharedMarkerMaterials.default;
          objectMesh = new THREE.Mesh(sharedMarkerGeometry, material);
        }
      } else {
        const material =
          object.type === 'settlement'
            ? sharedMarkerMaterials.settlement
            : object.type === 'road'
              ? sharedMarkerMaterials.road
              : sharedMarkerMaterials.default;

        objectMesh = new THREE.Mesh(sharedMarkerGeometry, material);
      }

      objectMesh.position.copy(
        tileToVector(gridFor(data), object.x, object.y, HEIGHT_OBJECT_MARKER),
      );

      objectMesh.userData.object = object;
      objectGroup.add(objectMesh);
    }
  }, [mapIdentity, data.objects, data.width, data.height]);

  useEffect(() => {
    const runtime = runtimeRef.current;
    if (!runtime) {
      return;
    }

    if (selectedX == null || selectedY == null) {
      runtime.selection.visible = false;
      return;
    }

    updateSelection(runtime.selection, gridFor(data), selectedX, selectedY);
  }, [mapIdentity, selectedX, selectedY, data.width, data.height]);

  return (
    <div
      ref={containerRef}
      style={{
        width: '100%',
        height: '100%',
        overflow: 'hidden',
        position: 'relative',
      }}
    >
      <style>
        {`
          @keyframes planetLoadSpin {
            from { transform: rotate(0deg); }
            to { transform: rotate(360deg); }
          }
        `}
      </style>

      {isLoading && (
        <div
          className="rimworld-planet-map__loading"
          style={{
            position: 'absolute',
            top: '16px',
            left: '16px',
            display: 'flex',
            alignItems: 'center',
            gap: '10px',
            padding: '8px 14px 8px 10px',
            backgroundColor: 'rgba(10, 14, 22, 0.85)',
            border: '1px solid rgba(255, 255, 255, 0.15)',
            borderRadius: '6px',
            color: '#c8d6ee',
            fontSize: '12px',
            pointerEvents: 'none',
            zIndex: 5,
            backdropFilter: 'blur(4px)',
            boxShadow: '0 4px 16px rgba(0, 0, 0, 0.4)',
          }}
        >
          <div
            style={{
              width: '14px',
              height: '14px',
              flexShrink: 0,
              borderRadius: '50%',
              border: '2px solid rgba(138, 180, 248, 0.25)',
              borderTopColor: '#8ab4f8',
              animation: 'planetLoadSpin 0.8s linear infinite',
            }}
          />
          <span>Generating terrain&hellip;</span>
        </div>
      )}
    </div>
  );
};
