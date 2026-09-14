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
  PLANET_BORDER_COLOR,
  PLANET_FILL_COLOR,
  PLANET_NIGHT_COLOR,
  PLANET_SUN_COLOR,
  PLANET_SUN_DIRECTION,
} from './visual/constants';

import {
  planetCoordinateToVector,
  vectorToPlanetCoordinate,
} from './visual/coordinates';
import { buildHexPlanet } from './visual/geometry';

import {
  ATMOSPHERE_FRAGMENT_SHADER,
  ATMOSPHERE_VERTEX_SHADER,
  CLOUD_FRAGMENT_SHADER,
  CLOUD_VERTEX_SHADER,
  NIGHT_FRAGMENT_SHADER,
  NIGHT_VERTEX_SHADER,
} from './visual/shaders';

import { applyTileImages, loadTileImage } from './visual/tileImages';

type PlanetProps = {
  data: PlanetMapData;

  selectedX?: number;
  selectedY?: number;

  onTileClick?: (x: number, y: number, tile: PlanetTile) => void;

  onObjectClick?: (object: PlanetObject) => void;
};

type PlanetRuntime = {
  objectGroup: THREE.Group;
  selectedMarker: THREE.Mesh;
  generator: PlanetGenerator;
  surface: THREE.Mesh;
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

    /* ---------------------------------------------------------------------- */
    /* Generator                                                               */
    /* ---------------------------------------------------------------------- */

    const generator = new PlanetGenerator(data);

    /* ---------------------------------------------------------------------- */
    /* Scene                                                                   */
    /* ---------------------------------------------------------------------- */

    const scene = new THREE.Scene();

    scene.background = PLANET_BACKGROUND.clone();

    scene.fog = new THREE.FogExp2(PLANET_BACKGROUND, 0.012);

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

    /* ---------------------------------------------------------------------- */
    /* Controls                                                                */
    /* ---------------------------------------------------------------------- */

    const controls = new OrbitControls(camera, renderer.domElement);

    controls.enablePan = false;
    controls.enableDamping = true;

    controls.dampingFactor = 0.06;

    controls.minDistance = 2.6;
    controls.maxDistance = 9;

    controls.rotateSpeed = 0.55;

    loadCameraState(camera, controls);

    /* ---------------------------------------------------------------------- */
    /* Lighting                                                                */
    /* ---------------------------------------------------------------------- */

    const ambient = new THREE.AmbientLight(0x6b8cae, 0.22);

    scene.add(ambient);

    const sun = new THREE.DirectionalLight(PLANET_SUN_COLOR, 2.8);

    sun.position.copy(PLANET_SUN_DIRECTION);

    scene.add(sun);

    const fill = new THREE.DirectionalLight(PLANET_FILL_COLOR, 0.22);

    fill.position.set(-4, -1, -3);

    scene.add(fill);

    /* ---------------------------------------------------------------------- */
    /* Stars                                                                   */
    /* ---------------------------------------------------------------------- */

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

    const starMaterial = new THREE.PointsMaterial({
      color: 0xffffff,
      size: 0.15,
      sizeAttenuation: true,
      transparent: true,
      opacity: 0.85,
      depthWrite: false,
    });

    const stars = new THREE.Points(starGeometry, starMaterial);

    scene.add(stars);

    /* ---------------------------------------------------------------------- */
    /* Planet root                                                             */
    /* ---------------------------------------------------------------------- */

    const planetGroup = new THREE.Group();

    scene.add(planetGroup);

    /* ---------------------------------------------------------------------- */
    /* Surface                                                                  */
    /* ---------------------------------------------------------------------- */

    const { surfaceGeometry, boundaryGeometry } = buildHexPlanet(
      data,
      generator,
    );

    const surfaceMaterial = new THREE.MeshStandardMaterial({
      vertexColors: true,
      flatShading: true,
      roughness: 0.92,
      metalness: 0.05,
    });

    const surface = new THREE.Mesh(surfaceGeometry, surfaceMaterial);

    planetGroup.add(surface);

    /* ---------------------------------------------------------------------- */
    /* Borders                                                                  */
    /* ---------------------------------------------------------------------- */

    const boundaryMaterial = new THREE.LineBasicMaterial({
      color: PLANET_BORDER_COLOR,
      transparent: true,
      opacity: 0.13,
    });

    const boundaries = new THREE.LineSegments(
      boundaryGeometry,
      boundaryMaterial,
    );

    boundaries.scale.setScalar(1.0015);

    planetGroup.add(boundaries);

    /* ---------------------------------------------------------------------- */
    /* Atmosphere                                                               */
    /* ---------------------------------------------------------------------- */

    const atmosphereGeometry = new THREE.SphereGeometry(
      PLANET_RADIUS * 1.075,
      96,
      96,
    );

    const atmosphereMaterial = new THREE.ShaderMaterial({
      uniforms: {
        atmosphereColor: {
          value: PLANET_ATMOSPHERE_COLOR.clone(),
        },

        sunDirection: {
          value: PLANET_SUN_DIRECTION.clone(),
        },
      },

      vertexShader: ATMOSPHERE_VERTEX_SHADER,

      fragmentShader: ATMOSPHERE_FRAGMENT_SHADER,

      side: THREE.BackSide,

      blending: THREE.AdditiveBlending,

      transparent: true,

      depthWrite: false,
    });

    const atmosphere = new THREE.Mesh(atmosphereGeometry, atmosphereMaterial);

    planetGroup.add(atmosphere);

    /* ---------------------------------------------------------------------- */
    /* Night hemisphere                                                        */
    /* ---------------------------------------------------------------------- */

    const nightGeometry = new THREE.SphereGeometry(
      PLANET_RADIUS * 1.002,
      96,
      96,
    );

    const nightMaterial = new THREE.ShaderMaterial({
      uniforms: {
        sunDirection: {
          value: PLANET_SUN_DIRECTION.clone(),
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
    });

    const night = new THREE.Mesh(nightGeometry, nightMaterial);

    planetGroup.add(night);

    /* ---------------------------------------------------------------------- */
    /* Cloud layer                                                             */
    /* ---------------------------------------------------------------------- */

    const cloudGeometry = new THREE.SphereGeometry(
      PLANET_RADIUS * 1.028,
      96,
      96,
    );

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

    const clouds = new THREE.Mesh(cloudGeometry, cloudMaterial);

    planetGroup.add(clouds);

    /* ---------------------------------------------------------------------- */
    /* Interactive objects                                                     */
    /* ---------------------------------------------------------------------- */

    const objectGroup = new THREE.Group();

    planetGroup.add(objectGroup);

    const selectedGeometry = new THREE.SphereGeometry(0.045, 14, 14);

    const selectedMaterial = new THREE.MeshBasicMaterial({
      color: 0x7ecbff,
    });

    const selectedMarker = new THREE.Mesh(selectedGeometry, selectedMaterial);

    selectedMarker.visible = false;

    planetGroup.add(selectedMarker);

    runtimeRef.current = {
      objectGroup,
      selectedMarker,
      generator,
      surface,
    };

    applyTileImages(surface, data.tileImages, data.biomeImages);

    /* ---------------------------------------------------------------------- */
    /* Interaction                                                             */
    /* ---------------------------------------------------------------------- */

    const raycaster = new THREE.Raycaster();

    const mouse = new THREE.Vector2();

    const handleClick = (event: MouseEvent) => {
      const rect = renderer.domElement.getBoundingClientRect();

      mouse.x = ((event.clientX - rect.left) / rect.width) * 2 - 1;

      mouse.y = -((event.clientY - rect.top) / rect.height) * 2 + 1;

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

      const surfaceHits = raycaster.intersectObject(surface);

      if (surfaceHits.length === 0) {
        return;
      }

      const point = surfaceHits[0].point.clone();

      planetGroup.worldToLocal(point);

      const { x, y } = vectorToPlanetCoordinate(point, data.width, data.height);

      callbacksRef.current.onTileClick?.(x, y, generator.getTile(x, y));
    };

    renderer.domElement.addEventListener('click', handleClick);

    /* ---------------------------------------------------------------------- */
    /* Animation                                                               */
    /* ---------------------------------------------------------------------- */

    let frame = 0;

    const clock = new THREE.Clock();

    const animate = () => {
      frame = requestAnimationFrame(animate);

      const time = clock.getElapsedTime();

      cloudMaterial.uniforms.time.value = time;

      /*
       * Clouds rotate independently
       * from the planet.
       */
      clouds.rotation.y = time * 0.012;

      controls.update();

      renderer.render(scene, camera);
    };

    animate();

    /* ---------------------------------------------------------------------- */
    /* Resize                                                                  */
    /* ---------------------------------------------------------------------- */

    const resize = () => {
      const width = container.clientWidth;

      const height = container.clientHeight;

      camera.aspect = width / height;

      camera.updateProjectionMatrix();

      renderer.setSize(width, height);
    };

    window.addEventListener('resize', resize);

    /* ---------------------------------------------------------------------- */
    /* Camera saving                                                           */
    /* ---------------------------------------------------------------------- */

    const saveView = () => {
      saveCameraState(camera, controls);
    };

    controls.addEventListener('change', saveView);

    /* ---------------------------------------------------------------------- */
    /* Cleanup                                                                 */
    /* ---------------------------------------------------------------------- */

    return () => {
      saveCameraState(camera, controls);

      runtimeRef.current = null;

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

      nightGeometry.dispose();
      nightMaterial.dispose();

      cloudGeometry.dispose();
      cloudMaterial.dispose();

      starGeometry.dispose();
      starMaterial.dispose();

      selectedGeometry.dispose();
      selectedMaterial.dispose();

      renderer.dispose();

      renderer.domElement.remove();
    };
  }, [mapIdentity]);

  useEffect(() => {
    const runtime = runtimeRef.current;

    if (!runtime) {
      return;
    }

    const { objectGroup, surface } = runtime;

    while (objectGroup.children.length > 0) {
      const child = objectGroup.children[0];

      objectGroup.remove(child);

      if (child instanceof THREE.Mesh) {
        child.geometry.dispose();

        if (Array.isArray(child.material)) {
          for (const material of child.material) {
            material.dispose();
          }
        } else {
          child.material.dispose();
        }
      }
    }

    for (const object of data.objects ?? []) {
      const geometry = new THREE.SphereGeometry(0.032, 12, 12);

      const material = new THREE.MeshBasicMaterial({
        color:
          object.type === 'settlement'
            ? 0xffc857
            : object.type === 'road'
              ? 0xc4a574
              : 0xf0f4ff,
      });

      const marker = new THREE.Mesh(geometry, material);

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

    applyTileImages(surface, data.tileImages, data.biomeImages);
  }, [
    mapIdentity,
    data.objects,
    data.tileImages,
    data.biomeImages,
    data.width,
    data.height,
  ]);

  useEffect(() => {
    const runtime = runtimeRef.current;

    if (!runtime) {
      return;
    }

    const { selectedMarker } = runtime;

    if (selectedX == null || selectedY == null) {
      selectedMarker.visible = false;
      return;
    }

    selectedMarker.visible = true;

    selectedMarker.position.copy(
      planetCoordinateToVector(
        selectedX,
        selectedY,
        data.width,
        data.height,
        PLANET_RADIUS + 0.055,
      ),
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
