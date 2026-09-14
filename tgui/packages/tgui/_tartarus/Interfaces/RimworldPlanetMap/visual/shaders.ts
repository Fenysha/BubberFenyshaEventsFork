export const PLANET_SURFACE_VERTEX_SHADER = `
varying vec3 vLocalPosition;
varying vec3 vWorldNormal;

void main() {
  vLocalPosition = position;

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

varying vec3 vLocalPosition;
varying vec3 vWorldNormal;

const float PI = 3.14159265359;
const float TWO_PI = 6.28318530718;

float wrapX(
  float value,
  float width
) {
  return mod(
    mod(value, width) + width,
    width
  );
}

vec3 sphericalDirection(
  float longitude,
  float latitude
) {
  float cosLat = cos(latitude);

  return normalize(
    vec3(
      cosLat * cos(longitude),
      sin(latitude),
      cosLat * sin(longitude)
    )
  );
}

vec3 tileCenterDirection(
  float column,
  float row
) {
  float stagger =
    mod(row, 2.0) > 0.5
      ? 0.5
      : 0.0;

  float u =
    (column + 0.5 + stagger)
    / mapSize.x;

  u = fract(u);

  float v =
    (row + 0.5)
    / mapSize.y;

  float longitude =
    u * TWO_PI - PI;

  float latitude =
    v * PI - PI * 0.5;

  return sphericalDirection(
    longitude,
    latitude
  );
}

vec2 findNearestTile(
  vec3 surfaceDirection
) {
  float longitude =
    atan(
      surfaceDirection.z,
      surfaceDirection.x
    );

  float latitude =
    asin(
      clamp(
        surfaceDirection.y,
        -1.0,
        1.0
      )
    );

  float mapX =
    (
      longitude + PI
    ) / TWO_PI * mapSize.x;

  float mapY =
    (
      latitude + PI * 0.5
    ) / PI * mapSize.y;

  float baseRow =
    floor(mapY);

  float bestDot = -1000.0;

  float bestColumn = 0.0;
  float bestRow = 0.0;

  /*
   * Check neighbouring rows.
   */
  for (
    int rowOffset = -2;
    rowOffset <= 2;
    rowOffset++
  ) {
    float row =
      baseRow + float(rowOffset);

    if (
      row < 0.0 ||
      row >= mapSize.y
    ) {
      continue;
    }

    float stagger =
      mod(row, 2.0) > 0.5
        ? 0.5
        : 0.0;

    float baseColumn =
      floor(
        mapX - stagger
      );

    /*
     * Check neighbouring columns,
     * including longitude wrapping.
     */
    for (
      int columnOffset = -2;
      columnOffset <= 2;
      columnOffset++
    ) {
      float column =
        baseColumn +
        float(columnOffset);

      float wrappedColumn =
        wrapX(
          column,
          mapSize.x
        );

      vec3 center =
        tileCenterDirection(
          wrappedColumn,
          row
        );

      float currentDot =
        dot(
          surfaceDirection,
          center
        );

      if (
        currentDot >
        bestDot
      ) {
        bestDot =
          currentDot;

        bestColumn =
          wrappedColumn;

        bestRow =
          row;
      }
    }
  }

  return vec2(
    bestColumn,
    bestRow
  );
}

void main() {
  /*
   * Use actual spherical position,
   * not interpolated UV coordinates.
   */
  vec3 surfaceDirection =
    normalize(vLocalPosition);

  vec2 tile =
    findNearestTile(
      surfaceDirection
    );

  vec2 tileUv =
    vec2(
      (
        tile.x + 0.5
      ) / mapSize.x,

      (
        tile.y + 0.5
      ) / mapSize.y
    );

  vec3 baseColor =
    texture2D(
      planetMap,
      tileUv
    ).rgb;

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
      0.18,
      1.0,
      smoothstep(
        0.0,
        0.28,
        sunlight
      )
    );

  vec3 color =
    baseColor *
    illumination;

  float night =
    1.0 -
    smoothstep(
      0.0,
      0.25,
      sunlight
    );

  color =
    mix(
      color,
      nightColor,
      night * 0.12
    );

  gl_FragColor =
    vec4(
      color,
      1.0
    );
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
