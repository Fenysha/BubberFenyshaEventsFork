import * as THREE from 'three';
import { OrbitControls } from
  'three/examples/jsm/controls/OrbitControls.js';

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

  target: {
    x: number;
    y: number;
    z: number;
  };
};

export const loadCameraState = (
  camera: THREE.PerspectiveCamera,
  controls: OrbitControls,
) => {
  const raw =
    localStorage.getItem(
      CAMERA_STATE_KEY,
    );

  if (!raw) {
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

    return;
  }

  try {
    const state =
      JSON.parse(raw) as CameraState;

    camera.position.set(
      state.position.x,
      state.position.y,
      state.position.z,
    );

    controls.target.set(
      state.target.x,
      state.target.y,
      state.target.z,
    );

    controls.update();
  } catch {
    localStorage.removeItem(
      CAMERA_STATE_KEY,
    );

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
  }
};

export const saveCameraState = (
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

  localStorage.setItem(
    CAMERA_STATE_KEY,
    JSON.stringify(state),
  );
};
