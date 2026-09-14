import type * as THREE from 'three';
import type { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';

import {
  CAMERA_STATE_KEY,
  DEFAULT_CAMERA_POSITION,
  DEFAULT_CAMERA_TARGET,
} from './generation/constants';

type CameraState = {
  position: {
    x: number;
    y: number;
    z: number;
  };
};

export const loadCameraState = (
  camera: THREE.PerspectiveCamera,
  controls: OrbitControls,
) => {
  const reset = () => {
    camera.position.set(
      DEFAULT_CAMERA_POSITION.x,
      DEFAULT_CAMERA_POSITION.y,
      DEFAULT_CAMERA_POSITION.z,
    );

    controls.target.set(
      DEFAULT_CAMERA_TARGET.x,
      DEFAULT_CAMERA_TARGET.y,
      DEFAULT_CAMERA_TARGET.z,
    );

    controls.update();
  };

  const raw = localStorage.getItem(CAMERA_STATE_KEY);

  if (!raw) {
    reset();
    return;
  }

  try {
    const state = JSON.parse(raw) as CameraState;

    camera.position.set(state.position.x, state.position.y, state.position.z);

    controls.target.set(
      DEFAULT_CAMERA_TARGET.x,
      DEFAULT_CAMERA_TARGET.y,
      DEFAULT_CAMERA_TARGET.z,
    );

    controls.update();
  } catch {
    localStorage.removeItem(CAMERA_STATE_KEY);
    reset();
  }
};

export const saveCameraState = (
  camera: THREE.PerspectiveCamera,
  controls: OrbitControls,
) => {
  localStorage.setItem(
    CAMERA_STATE_KEY,
    JSON.stringify({
      position: {
        x: camera.position.x,
        y: camera.position.y,
        z: camera.position.z,
      },
    } satisfies CameraState),
  );
};
