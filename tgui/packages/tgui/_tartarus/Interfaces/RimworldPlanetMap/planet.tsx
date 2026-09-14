import { useEffect, useRef } from 'react';
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

import { loadTileImage } from './visual/tileImages';

type PlanetProps = {
  data: PlanetMapData;
  selectedX?: number;
  selectedY?: number;
  onTileClick?: (x: number, y: number, tile: PlanetTile) => void;
  onObjectClick?: (object: PlanetObject) => void;
};

type PlanetRuntime = {
  objectGroup: THREE.Group;
  selection: THREE.Group;
  generator: PlanetGenerator;
  surface: THREE.Mesh;
  planetGroup: THREE.Group;
  planetTexture: THREE.DataTexture;
  surfaceMaterial: THREE.ShaderMaterial;
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

const buildHexOutlineGeometry = (
  x: number,
  y: number,
  width: number,
  height: number,
  radius: number,
) => {
  const center = planetCoordinateToVector(
    x,
    y,
    width,
    height,
    radius,
  ).normalize();

  const up = new THREE.Vector3(0, 1, 0);
  const east = new THREE.Vector3().crossVectors(up, center);

  if (east.lengthSq() < 0.000001) {
    east.set(1, 0, 0);
  }

  east.normalize();

  const north = new THREE.Vector3().crossVectors(center, east).normalize();

  const latitude = Math.asin(THREE.MathUtils.clamp(center.y, -1, 1));

  const cosLatitude = Math.max(Math.cos(latitude), 0.12);

  const rx = ((Math.PI * 2) / width) * cosLatitude * 0.48;

  const ry = (Math.PI / height) * 0.48;

  const positions = new Float32Array(18);

  for (let i = 0; i < 6; i++) {
    const angle = Math.PI / 6 + (i * Math.PI) / 3;

    const point = center
      .clone()
      .addScaledVector(east, Math.cos(angle) * rx)
      .addScaledVector(north, Math.sin(angle) * ry)
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
    buildHexOutlineGeometry(1, 1, width, height, PLANET_RADIUS + 0.022),
    new THREE.LineBasicMaterial({
      color: 0x6bbdff,
      transparent: true,
      opacity: 0.1,
      depthWrite: false,
    }),
  );

  const outline = new THREE.LineLoop(
    buildHexOutlineGeometry(1, 1, width, height, PLANET_RADIUS + 0.013),
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
    PLANET_RADIUS + 0.022,
  );

  outline.geometry.dispose();
  outline.geometry = buildHexOutlineGeometry(
    x,
    y,
    width,
    height,
    PLANET_RADIUS + 0.013,
  );

  group.visible = true;
};

export const Planet = ({
  data,
  selectedX,
  selectedY,
  onTileClick,
  onObjectClick,
}: PlanetProps) => {
  const containerRef = useRef<HTMLDivElement>(null);

  const runtimeRef = useRef<PlanetRuntime | null>(null);

  const callbacksRef = useRef({
    onTileClick,
    onObjectClick,
  });

  callbacksRef.current = {
    onTileClick,
    onObjectClick,
  };

  const mapIdentity = getPlanetMapIdentity(data);

  useEffect(() => {
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
    controls.minDistance = PLANET_RADIUS * 1.015;
    controls.maxDistance = 9;
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

    const starGeometry = new THREE.BufferGeometry();

    starGeometry.setAttribute(
      'position',
      new THREE.BufferAttribute(starPositions, 3),
    );

    const stars = new THREE.Points(
      starGeometry,
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

    const planetTexture = buildPlanetTexture(data, generator);

    const surfaceMaterial = new THREE.ShaderMaterial({
      uniforms: {
        planetMap: {
          value: planetTexture,
        },

        mapSize: {
          value: new THREE.Vector2(data.width, data.height),
        },

        sunDirection: {
          value: PLANET_SUN_DIRECTION.clone().normalize(),
        },

        nightColor: {
          value: PLANET_NIGHT_COLOR.clone(),
        },
      },

      vertexShader: PLANET_SURFACE_VERTEX_SHADER,

      fragmentShader: PLANET_SURFACE_FRAGMENT_SHADER,

      side: THREE.DoubleSide,
      transparent: false,
      depthWrite: true,
    });

    let currentLod: LodLevel = 'medium';

    const surface = new THREE.Mesh(
      buildPlanetGeometry(data, currentLod),
      surfaceMaterial,
    );

    surface.name = 'PlanetSurface';

    planetGroup.add(surface);

    const atmosphere = new THREE.Mesh(
      new THREE.SphereGeometry(PLANET_RADIUS * 1.075, 96, 96),
      new THREE.ShaderMaterial({
        uniforms: {
          atmosphereColor: {
            value: PLANET_ATMOSPHERE_COLOR.clone(),
          },

          sunDirection: {
            value: PLANET_SUN_DIRECTION.clone().normalize(),
          },
        },

        vertexShader: ATMOSPHERE_VERTEX_SHADER,

        fragmentShader: ATMOSPHERE_FRAGMENT_SHADER,

        side: THREE.BackSide,
        blending: THREE.AdditiveBlending,
        transparent: true,
        depthWrite: false,
      }),
    );

    planetGroup.add(atmosphere);

    const night = new THREE.Mesh(
      new THREE.SphereGeometry(PLANET_RADIUS * 1.002, 96, 96),
      new THREE.ShaderMaterial({
        uniforms: {
          sunDirection: {
            value: PLANET_SUN_DIRECTION.clone().normalize(),
          },

          nightColor: {
            value: PLANET_NIGHT_COLOR.clone(),
          },
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
        time: {
          value: 0,
        },
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
      planetTexture,
      surfaceMaterial,
      currentLod,
    };

    const switchLod = (newLod: LodLevel) => {
      if (newLod === currentLod) {
        return;
      }

      const newGeometry = buildPlanetGeometry(data, newLod);

      surface.geometry.dispose();
      surface.geometry = newGeometry;

      currentLod = newLod;

      if (runtimeRef.current) {
        runtimeRef.current.currentLod = newLod;
      }
    };

    const zoomToSelection = () => {
      const direction = camera.position
        .clone()
        .sub(controls.target)
        .normalize();

      const start = camera.position.clone();

      const end = direction.multiplyScalar(PLANET_RADIUS * 1.045);

      const started = performance.now();

      const duration = 380;

      const animateZoom = (now: number) => {
        const t = THREE.MathUtils.clamp((now - started) / duration, 0, 1);

        const eased = t * t * (3 - 2 * t);

        camera.position.lerpVectors(start, end, eased);

        controls.target.set(0, 0, 0);

        controls.update();

        if (t < 1) {
          requestAnimationFrame(animateZoom);
        }
      };

      requestAnimationFrame(animateZoom);
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

      zoomToSelection();
    };

    renderer.domElement.addEventListener('pointerdown', handlePointerDown);

    renderer.domElement.addEventListener('pointermove', handlePointerMove);

    renderer.domElement.addEventListener('click', handleClick);

    let frame = 0;

    const clock = new THREE.Clock();

    let lastLod: LodLevel = currentLod;

    const animate = () => {
      frame = requestAnimationFrame(animate);

      const time = clock.getElapsedTime();

      cloudMaterial.uniforms.time.value = time;

      clouds.rotation.y = time * 0.012;

      const distance = controls.getDistance();

      const nextLod = getPlanetLod(distance);

      if (nextLod !== lastLod) {
        switchLod(nextLod);

        lastLod = nextLod;
      }

      controls.target.set(0, 0, 0);

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

      runtimeRef.current = null;

      cancelAnimationFrame(frame);

      window.removeEventListener('resize', resize);

      renderer.domElement.removeEventListener('pointerdown', handlePointerDown);

      renderer.domElement.removeEventListener('pointermove', handlePointerMove);

      renderer.domElement.removeEventListener('click', handleClick);

      controls.removeEventListener('change', saveView);

      controls.dispose();

      surface.geometry.dispose();
      surfaceMaterial.dispose();
      planetTexture.dispose();

      atmosphere.geometry.dispose();
      (atmosphere.material as THREE.Material).dispose();

      night.geometry.dispose();
      (night.material as THREE.Material).dispose();

      clouds.geometry.dispose();
      cloudMaterial.dispose();

      selection.traverse((child) => {
        if (child instanceof THREE.LineLoop) {
          child.geometry.dispose();
          (child.material as THREE.Material).dispose();
        }
      });

      starGeometry.dispose();
      (stars.material as THREE.Material).dispose();

      renderer.dispose();
      renderer.domElement.remove();
    };
  }, [mapIdentity]);

  useEffect(() => {
    const runtime = runtimeRef.current;

    if (!runtime) {
      return;
    }

    const { objectGroup } = runtime;

    while (objectGroup.children.length > 0) {
      const child = objectGroup.children[0];

      objectGroup.remove(child);

      if (child instanceof THREE.Mesh) {
        child.geometry.dispose();

        if (Array.isArray(child.material)) {
          child.material.forEach((material) => {
            material.dispose();
          });
        } else {
          child.material.dispose();
        }
      }
    }

    for (const object of data.objects ?? []) {
      const marker = new THREE.Mesh(
        new THREE.SphereGeometry(0.032, 12, 12),
        new THREE.MeshBasicMaterial({
          color:
            object.type === 'settlement'
              ? 0xffc857
              : object.type === 'road'
                ? 0xc4a574
                : 0xf0f4ff,
        }),
      );

      marker.position.copy(
        planetCoordinateToVector(
          object.x,
          object.y,
          data.width,
          data.height,
          PLANET_RADIUS + 0.04,
        ),
      );

      marker.userData.object = object;

      objectGroup.add(marker);

      if (object.icon) {
        void loadTileImage(object.icon);
      }
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
      }}
    />
  );
};
