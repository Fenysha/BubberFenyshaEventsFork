/*
 * ----------------------------------------------------------------------------
 * Planet geometry
 * ----------------------------------------------------------------------------
 */

export const PLANET_RADIUS = 2;

/*
 * ----------------------------------------------------------------------------
 * Camera
 * ----------------------------------------------------------------------------
 */

export const CAMERA_STATE_KEY = 'rimworld-planet-camera';

export const DEFAULT_CAMERA_POSITION = {
  x: 0,
  y: 0,
  z: PLANET_RADIUS * 2.4,
};

export const DEFAULT_CAMERA_TARGET = {
  x: 0,
  y: 0,
  z: 0,
};
