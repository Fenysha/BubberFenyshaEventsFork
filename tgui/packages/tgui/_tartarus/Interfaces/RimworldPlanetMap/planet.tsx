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
  planetCoordinateToVector,
  vectorToPlanetCoordinate,
} from './visual/coordinates';

import { buildPlanetGeometry, type LodLevel } from './visual/geometry';
import { buildPlanetTexture } from './visual/planetTexture';

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

type PlanetProps = {
  data: PlanetMapData;
  selectedX?: number;
  selectedY?: number;
  showAtmosphere?: boolean;
  showClouds?: boolean;
  onTileClick?: (x: number, y: number, tile: PlanetTile) => void;
  onObjectClick?: (object: PlanetObject) => void;
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

const textureCache = new Map<string, THREE.CanvasTexture>();
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

const HEIGHT_SELECTION_OUTLINE = PLANET_RADIUS + 0.003;
const HEIGHT_SELECTION_GLOW = PLANET_RADIUS + 0.005;
const HEIGHT_OBJECT_MARKER = PLANET_RADIUS + 0.004;

const buildHexOutlineGeometry = (
  x: number,
  y: number,
  maxWidth: number,
  height: number,
  radius: number,
) => {
  const center = planetCoordinateToVector(
    x,
    y,
    maxWidth,
    height,
    radius,
  ).normalize();

  const up =
    Math.abs(center.y) > 0.99
      ? new THREE.Vector3(0, 0, 1)
      : new THREE.Vector3(0, 1, 0);

  const east = new THREE.Vector3().crossVectors(up, center).normalize();
  const north = new THREE.Vector3().crossVectors(center, east).normalize();

  const latitude = Math.asin(THREE.MathUtils.clamp(center.y, -0.999, 0.999));
  const cosLatitude = Math.max(Math.cos(latitude), 0.15);

  const hexSizeX = ((Math.PI * 2) / maxWidth) * cosLatitude * 0.5;
  const hexSizeY = (Math.PI / height) * 0.5;

  const positions = new Float32Array(18);

  for (let i = 0; i < 6; i++) {
    const angle = Math.PI / 6 + (i * Math.PI) / 3;

    const dx = Math.cos(angle) * hexSizeX;
    const dy = Math.sin(angle) * hexSizeY;

    const point = center
      .clone()
      .addScaledVector(east, dx)
      .addScaledVector(north, dy)
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

const createSelection = (width: number, height: number) => {
  const group = new THREE.Group();
  group.visible = false;

  const glow = new THREE.LineLoop(
    buildHexOutlineGeometry(1, 1, width, height, HEIGHT_SELECTION_GLOW),
    new THREE.LineBasicMaterial({
      color: 0x6bbdff,
      transparent: true,
      opacity: 0.1,
      depthWrite: false,
    }),
  );

  const outline = new THREE.LineLoop(
    buildHexOutlineGeometry(1, 1, width, height, HEIGHT_SELECTION_OUTLINE),
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
  x: number,
  y: number,
  width: number,
  height: number,
) => {
  const glow = group.children[0] as THREE.LineLoop;
  const outline = group.children[1] as THREE.LineLoop;

  glow.geometry.dispose();
  glow.geometry = buildHexOutlineGeometry(
    x,
    y,
    width,
    height,
    HEIGHT_SELECTION_GLOW,
  );

  outline.geometry.dispose();
  outline.geometry = buildHexOutlineGeometry(
    x,
    y,
    width,
    height,
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
  });

  callbacksRef.current = {
    onTileClick,
    onObjectClick,
  };

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      const key = e.key.toLowerCase();
      if (['w', 'a', 's', 'd'].includes(key)) {
        keysPressed.current[key] = true;
      }
    };

    const handleKeyUp = (e: KeyboardEvent) => {
      const key = e.key.toLowerCase();
      if (['w', 'a', 's', 'd'].includes(key)) {
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

    const cachedTexture = textureCache.get(mapIdentity);
    const initialTexture = cachedTexture ?? placeholderTexture;

    const surfaceMaterial = new THREE.ShaderMaterial({
      uniforms: {
        planetMap: { value: initialTexture },
        mapSize: { value: new THREE.Vector2(data.width, data.height) },
        sunDirection: { value: PLANET_SUN_DIRECTION.clone().normalize() },
        nightColor: { value: PLANET_NIGHT_COLOR.clone() },
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

    if (cachedTexture) {
      setIsLoading(false);
    } else {
      setIsLoading(true);

      const buildTextureWhenReady = () => {
        if (generator.isReady()) {
          try {
            const texture = buildPlanetTexture(data, generator);

            if (textureCache.size >= MAX_TEXTURE_CACHE_SIZE) {
              const firstKey = textureCache.keys().next().value;
              if (firstKey) {
                textureCache.get(firstKey)?.dispose();
                textureCache.delete(firstKey);
              }
            }
            textureCache.set(mapIdentity, texture);

            if (surfaceMaterial.uniforms.planetMap) {
              surfaceMaterial.uniforms.planetMap.value = texture;
              surfaceMaterial.needsUpdate = true;
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

    const selection = createSelection(data.width, data.height);
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

    const handleClick = (event: MouseEvent) => {
      if (pointerDragged) {
        pointerDragged = false;
        return;
      }

      const rect = renderer.domElement.getBoundingClientRect();
      mouse.x = ((event.clientX - rect.left) / rect.width) * 2 - 1;
      mouse.y = -(((event.clientY - rect.top) / rect.height) * 2 - 1);

      raycaster.setFromCamera(mouse, camera);

      const objectHits = raycaster.intersectObjects(objectGroup.children, true);

      if (objectHits.length > 0) {
        const hit = objectHits[0].object.userData.object as
          | PlanetObject
          | undefined;

        if (hit) {
          callbacksRef.current.onObjectClick?.(hit);

          const tile = generator.getTile(hit.x, hit.y);
          callbacksRef.current.onTileClick?.(hit.x, hit.y, tile);
        }
        return;
      }

      const surfaceHits = raycaster.intersectObject(surface, false);

      if (surfaceHits.length === 0) {
        return;
      }

      const point = surfaceHits[0].point.clone();
      planetGroup.worldToLocal(point);

      const { x, y } = vectorToPlanetCoordinate(point, data.width, data.height);
      const tile = generator.getTile(x, y);

      callbacksRef.current.onTileClick?.(x, y, tile);
    };

    renderer.domElement.addEventListener('pointerdown', handlePointerDown);
    renderer.domElement.addEventListener('pointermove', handlePointerMove);
    renderer.domElement.addEventListener('click', handleClick);

    let frame = 0;
    const clock = new THREE.Clock();
    let lastLod: LodLevel = currentLod;

    const animate = () => {
      frame = requestAnimationFrame(animate);

      const delta = clock.getDelta();
      const time = clock.getElapsedTime();

      const distance = controls.getDistance();

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

      // WASD Camera Control
      const wasdSpeed = THREE.MathUtils.lerp(0.012, 0.038, nearProgress);
      const keys = keysPressed.current;

      if (keys.w || keys.s || keys.a || keys.d) {
        const forward = new THREE.Vector3();
        camera.getWorldDirection(forward);
        forward.y = 0;
        forward.normalize();

        // Правильный правый вектор: forward × up
        const right = new THREE.Vector3()
          .crossVectors(forward, new THREE.Vector3(0, 1, 0))
          .normalize();

        const moveVector = new THREE.Vector3();
        if (keys.w) moveVector.add(forward);
        if (keys.s) moveVector.sub(forward);
        if (keys.a) moveVector.sub(right);
        if (keys.d) moveVector.add(right);

        if (moveVector.lengthSq() > 0) {
          moveVector.normalize().multiplyScalar(wasdSpeed);
          const camLen = camera.position.length();
          camera.position.add(moveVector);
          camera.position.normalize().multiplyScalar(camLen);
        }
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
        planetCoordinateToVector(
          object.x,
          object.y,
          data.width,
          data.height,
          HEIGHT_OBJECT_MARKER,
        ),
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

    updateSelection(
      runtime.selection,
      selectedX,
      selectedY,
      data.width,
      data.height,
    );
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
