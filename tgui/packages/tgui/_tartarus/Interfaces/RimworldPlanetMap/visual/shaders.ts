export const PLANET_SURFACE_VERTEX_SHADER = `
varying vec2 vUv;
varying vec3 vWorldNormal;

void main() {
  vec3 n = normalize(position);

  float longitude = atan(n.z, n.x);
  float latitude = asin(clamp(n.y, -1.0, 1.0));

  vUv = vec2(
    (longitude + 3.14159265359) / 6.28318530718,
    (latitude + 1.57079632679) / 3.14159265359
  );

  vWorldNormal = normalize(
    mat3(modelMatrix) * normal
  );

  gl_Position =
    projectionMatrix *
    modelViewMatrix *
    vec4(position, 1.0);
}
`;

export const PLANET_SURFACE_FRAGMENT_SHADER = `
precision highp float;

uniform sampler2D planetMap;
uniform vec2 mapSize;
uniform vec3 sunDirection;
uniform vec3 nightColor;

varying vec2 vUv;

varying vec3 vWorldNormal;

float wrapX(float x, float width) {
  return mod(
    mod(x, width) + width,
    width
  );
}

void main() {
  vec2 mapPos = vUv * mapSize;

  float baseRow = floor(mapPos.y);

  float bestDistance = 1e20;
  vec2 bestCenter = vec2(0.0);

  /*
   * Search neighbouring rows/columns.
   *
   * This is the actual staggered hex Voronoi
   * selection instead of rectangular UV cells.
   */
  for (int rowOffset = -1; rowOffset <= 1; rowOffset++) {
    float row = baseRow + float(rowOffset);

    if (row < 0.0 || row >= mapSize.y) {
      continue;
    }

    float stagger = mod(row, 2.0) > 0.5
      ? 0.5
      : 0.0;

    float baseColumn =
      floor(mapPos.x - stagger);

    for (int columnOffset = -1; columnOffset <= 1; columnOffset++) {
      float column =
        baseColumn + float(columnOffset);

      float wrappedColumn =
        wrapX(column, mapSize.x);

      vec2 center = vec2(
        wrappedColumn +
          0.5 +
          stagger,

        row + 0.5
      );

      vec2 delta = mapPos - center;

      /*
       * Horizontal wrapping.
       */
      if (delta.x > mapSize.x * 0.5) {
        delta.x -= mapSize.x;
      }

      if (delta.x < -mapSize.x * 0.5) {
        delta.x += mapSize.x;
      }

      float distanceToCenter =
        dot(delta, delta);

      if (distanceToCenter < bestDistance) {
        bestDistance = distanceToCenter;
        bestCenter = center;
      }
    }
  }

  float selectedRow =
    clamp(
      floor(bestCenter.y),
      0.0,
      mapSize.y - 1.0
    );

  float selectedStagger =
    mod(selectedRow, 2.0) > 0.5
      ? 0.5
      : 0.0;

  float selectedColumn =
    wrapX(
      floor(bestCenter.x - selectedStagger),
      mapSize.x
    );

  vec2 tileUv = vec2(
    (selectedColumn + 0.5) / mapSize.x,
    (selectedRow + 0.5) / mapSize.y
  );

  vec3 baseColor =
    texture2D(
      planetMap,
      tileUv
    ).rgb;

  /*
   * Planet lighting.
   */
  vec3 normal =
    normalize(vWorldNormal);

  vec3 sun =
    normalize(sunDirection);

  float sunlight =
    max(
      dot(normal, sun),
      0.0
    );

  float illumination =
    mix(
      0.20,
      1.0,
      sunlight
    );

  vec3 color =
    baseColor * illumination;

  float night =
    1.0 -
    smoothstep(
      0.02,
      0.32,
      sunlight
    );

  color =
    mix(
      color,
      nightColor * 0.45,
      night * 0.15
    );

  gl_FragColor =
    vec4(color, 1.0);
}
`;

export const ATMOSPHERE_VERTEX_SHADER = `
varying vec3 vWorldNormal;
varying vec3 vViewDirection;

void main() {
  vec4 world = modelMatrix * vec4(position, 1.0);
  vWorldNormal = normalize(mat3(modelMatrix) * normal);
  vViewDirection = normalize(cameraPosition - world.xyz);
  gl_Position = projectionMatrix * viewMatrix * world;
}
`;

export const ATMOSPHERE_FRAGMENT_SHADER = `
uniform vec3 atmosphereColor;
uniform vec3 sunDirection;

varying vec3 vWorldNormal;
varying vec3 vViewDirection;

void main() {
  vec3 n = normalize(vWorldNormal);
  vec3 v = normalize(vViewDirection);

  float rim = pow(1.0 - abs(dot(n, v)), 3.0);
  float sun = max(dot(n, normalize(sunDirection)), 0.0);
  float intensity = rim * (0.20 + sun * 0.80);

  gl_FragColor = vec4(
    atmosphereColor * intensity * 1.25,
    intensity * 0.72
  );
}
`;

export const NIGHT_VERTEX_SHADER = `
varying vec3 vWorldNormal;

void main() {
  vWorldNormal = normalize(mat3(modelMatrix) * normal);
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
`;

export const NIGHT_FRAGMENT_SHADER = `
uniform vec3 sunDirection;
uniform vec3 nightColor;

varying vec3 vWorldNormal;

void main() {
  float sun = max(
    dot(normalize(vWorldNormal), normalize(sunDirection)),
    0.0
  );

  float night = 1.0 - smoothstep(0.0, 0.30, sun);
  gl_FragColor = vec4(nightColor, night * 0.30);
}
`;

export const CLOUD_VERTEX_SHADER = `
varying vec3 vNormal;
varying vec3 vPosition;

void main() {
  vNormal = normalize(normalMatrix * normal);
  vPosition = position;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
`;

export const CLOUD_FRAGMENT_SHADER = `
uniform float time;

varying vec3 vNormal;
varying vec3 vPosition;

float hash(vec3 p) {
  p = fract(p * vec3(443.8975, 397.2973, 491.1871));
  p += dot(p, p.yxz + 19.19);
  return fract((p.x + p.y) * p.z);
}

float noise(vec3 p) {
  vec3 i = floor(p);
  vec3 f = fract(p);
  f = f * f * (3.0 - 2.0 * f);

  float n000 = hash(i);
  float n100 = hash(i + vec3(1.0, 0.0, 0.0));
  float n010 = hash(i + vec3(0.0, 1.0, 0.0));
  float n110 = hash(i + vec3(1.0, 1.0, 0.0));
  float n001 = hash(i + vec3(0.0, 0.0, 1.0));
  float n101 = hash(i + vec3(1.0, 0.0, 1.0));
  float n011 = hash(i + vec3(0.0, 1.0, 1.0));
  float n111 = hash(i + vec3(1.0, 1.0, 1.0));

  return mix(
    mix(mix(n000, n100, f.x), mix(n010, n110, f.x), f.y),
    mix(mix(n001, n101, f.x), mix(n011, n111, f.x), f.y),
    f.z
  );
}

void main() {
  vec3 n = normalize(vNormal);
  vec3 p = normalize(vPosition);

  float a = time * 0.006;
  float c = cos(a);
  float s = sin(a);

  p = vec3(
    p.x * c - p.z * s,
    p.y,
    p.x * s + p.z * c
  );

  float value =
    noise(p * 5.0) * 0.55 +
    noise(p * 10.0) * 0.30 +
    noise(p * 20.0) * 0.15;

  float cloud = smoothstep(0.52, 0.68, value);

  vec3 viewDir = normalize(cameraPosition - vPosition);
  float view = max(dot(n, viewDir), 0.0);

  float alpha = cloud * mix(0.30, 0.75, view);
  gl_FragColor = vec4(0.95, 0.98, 1.0, alpha * 0.22);
}
`;

export const STAR_VERTEX_SHADER = `
uniform float size;

void main() {
  gl_PointSize = size;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
`;

export const STAR_FRAGMENT_SHADER = `
void main() {
  vec2 p = gl_PointCoord - 0.5;
  float alpha = smoothstep(0.5, 0.0, length(p));
  gl_FragColor = vec4(1.0, 1.0, 1.0, alpha);
}
`;
