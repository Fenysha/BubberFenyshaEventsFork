/*
 * Copyright (c) 2026 Fenysha
 * All rights reserved.
 */

export const PLANET_SURFACE_VERTEX_SHADER = `
varying vec3 vLocalPosition;
varying vec3 vWorldNormal;
varying vec3 vLocalCamera;

void main() {
  vLocalPosition = position;
  // The camera in the planet's own (rotating) frame, for the fragment's ray-sphere hit
  vLocalCamera = (inverse(modelMatrix) * vec4(cameraPosition, 1.0)).xyz;

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
precision highp int;

// Geodesic hex grid, see generation/hexGrid.ts - this is its fromDirection() on the GPU
uniform sampler2D planetMap;
uniform vec2 mapSize;
uniform float gridN;
uniform float tileSpacing;
uniform vec3 diamondCorners[40];
uniform vec3 faceOrigin[20];
uniform vec3 faceE1[20];
uniform vec3 faceE2[20];
uniform vec3 faceNormal[20];
uniform float faceDiamond[20];
uniform float faceUpper[20];
uniform vec3 sunDirection;
uniform vec3 nightColor;
uniform float planetRadius;
// Decor icons: per-tile atlas frame (+1) in decorMap.r, frames packed in decorAtlas
uniform sampler2D decorMap;
uniform sampler2D decorAtlas;
uniform vec2 atlasGrid;
uniform float decorOpacity;
uniform float decorLod;
// River half-width, in tile spacings
uniform float riverWidth;

// Lattice steps to a tile's neighbours, in its own diamond's frame: river mask bit b follows
// step b (see HexGrid.neighborsWithBits, rust-g NEIGHBOUR_OFFSETS)
const vec2 NEIGHBOUR_OFFSETS[6] = vec2[6](
  vec2(1.0, 0.0), vec2(-1.0, 0.0), vec2(0.0, 1.0),
  vec2(0.0, -1.0), vec2(1.0, -1.0), vec2(-1.0, 1.0)
);

varying vec3 vLocalPosition;
varying vec3 vWorldNormal;
varying vec3 vLocalCamera;

vec3 flatPoint(int d, float i, float j) {
  float n = gridN;
  vec3 a = diamondCorners[d * 4];
  vec3 b = diamondCorners[d * 4 + 1];
  vec3 c = diamondCorners[d * 4 + 2];
  vec3 dd = diamondCorners[d * 4 + 3];
  if (i + j <= n) {
    return a * (1.0 - (i + j) / n) + b * (i / n) + dd * (j / n);
  }
  return c * ((i + j) / n - 1.0) + b * (1.0 - j / n) + dd * (1.0 - i / n);
}

// Owner of a lattice point in diamond d's frame; edges a diamond doesn't own go to its neighbour
vec2 canonicalTile(int d, int i, int j) {
  int n = int(gridN + 0.5);
  for (int guard = 0; guard < 4; guard++) {
    if (j >= 1 && i <= n - 1) {
      return vec2(float(d * n + i + 1), float(j));
    }
    bool north = d < 5;
    int k = d % 5;
    if (j == 0) {
      if (i == 0) {
        if (north) {
          return vec2(1.0, float(n + 1));
        }
        return vec2(float(k * n + 1), float(n));
      }
      if (north) {
        d = (k + 4) % 5;
        j = i;
        i = 0;
      } else {
        d = k;
        j = n;
      }
      continue;
    }
    if (north) {
      d = 5 + (k + 4) % 5;
      i = 0;
    } else {
      if (j == n) {
        return vec2(2.0, float(n + 1));
      }
      d = 5 + (k + 4) % 5;
      i = j;
      j = n;
    }
  }
  return vec2(1.0, float(n + 1));
}

// xy: the tile under dir; z: how far inside its cell (0 on an edge), for the cell border.
// center: that tile's centre direction.
vec3 findTile(vec3 dir, out vec3 center) {
  float n = gridN;
  if (dir.y > 0.999999999) {
    center = vec3(0.0, 1.0, 0.0);
    return vec3(1.0, n + 1.0, 1.0);
  }
  if (dir.y < -0.999999999) {
    center = vec3(0.0, -1.0, 0.0);
    return vec3(2.0, n + 1.0, 1.0);
  }

  int face = 0;
  float best = -2.0;
  for (int f = 0; f < 20; f++) {
    float alignment = dot(dir, faceNormal[f]);
    if (alignment > best) {
      best = alignment;
      face = f;
    }
  }

  vec3 origin = faceOrigin[face];
  vec3 e1 = faceE1[face];
  vec3 e2 = faceE2[face];
  vec3 normal = faceNormal[face];
  vec3 q = dir * (dot(origin, normal) / dot(dir, normal)) - origin;
  float a11 = dot(e1, e1);
  float a12 = dot(e1, e2);
  float a22 = dot(e2, e2);
  float b1 = dot(q, e1);
  float b2 = dot(q, e2);
  float det = a11 * a22 - a12 * a12;
  float u = (b1 * a22 - b2 * a12) / det;
  float v = (b2 * a11 - b1 * a12) / det;

  bool upper = faceUpper[face] > 0.5;
  // Upper face: u weighs D (1 - i/n) and v weighs B (1 - j/n)
  float fi = upper ? n * (1.0 - u) : n * u;
  float fj = upper ? n * (1.0 - v) : n * v;
  int d = int(faceDiamond[face] + 0.5);

  float baseI = floor(fi);
  float baseJ = floor(fj);
  float bestDot = -2.0;
  float secondDot = -2.0;
  float bestI = 0.0;
  float bestJ = 0.0;
  center = dir;
  for (int di = -1; di <= 2; di++) {
    for (int dj = -1; dj <= 2; dj++) {
      float i = baseI + float(di);
      float j = baseJ + float(dj);
      vec3 candidate = normalize(flatPoint(d, i, j));
      float alignment = dot(dir, candidate);
      bool inside = i >= 0.0 && j >= 0.0 && i <= n && j <= n;
      // Only lattice points on this diamond can own the fragment (as in the TS picker), but
      // the extrapolated ones across a seam still bound the cell for the border
      if (inside && alignment > bestDot) {
        secondDot = max(secondDot, bestDot);
        bestDot = alignment;
        bestI = i;
        bestJ = j;
        center = candidate;
      } else {
        secondDot = max(secondDot, alignment);
      }
    }
  }

  vec2 tile = canonicalTile(d, int(bestI + 0.5), int(bestJ + 0.5));
  // Dot products of neighbouring centres differ by about spacing * distance from the edge
  float inset = (bestDot - secondDot) / (tileSpacing * tileSpacing);
  return vec3(tile, inset);
}

void main() {
  // The mesh is flat triangles that sag inside the sphere, so the fragment's own direction is
  // off by up to a good fraction of a cell. Where this ray meets the true sphere is where the
  // selection outline and click picking put the tile.
  vec3 rayDirection = normalize(vLocalPosition - vLocalCamera);
  float b = dot(vLocalCamera, rayDirection);
  float c = dot(vLocalCamera, vLocalCamera) - planetRadius * planetRadius;
  float disc = b * b - c;
  vec3 surfaceDirection = disc >= 0.0
    ? normalize(vLocalCamera + rayDirection * (-b - sqrt(disc)))
    : normalize(vLocalPosition);
  vec3 tileCenter;
  vec3 found = findTile(surfaceDirection, tileCenter);

  vec2 planetUv = vec2(
    (found.x - 0.5) / mapSize.x,
    (found.y - 0.5) / mapSize.y
  );

  vec3 baseColor = texture2D(planetMap, planetUv).rgb;
  // A thin, faint line where cells meet; CELL_BORDER_DARKEN is how much it darkens at the edge
  const float CELL_BORDER_DARKEN = 0.08;
  baseColor *= mix(1.0 - CELL_BORDER_DARKEN, 1.0, smoothstep(0.0, 0.06, found.z));

  // Decor icon, drawn north-up in a square about a cell wide around the tile centre. The
  // neighbouring cells own the fragments past each edge, so it's clipped to the hex.
  float frame = floor(texture2D(decorMap, planetUv).r * 255.0 + 0.5) - 1.0;
  if (frame >= 0.0 && decorOpacity > 0.0) {
    const float DECOR_SPAN = 1.15;
    vec3 east = cross(tileCenter, vec3(0.0, 1.0, 0.0));
    east = dot(east, east) < 1e-10 ? vec3(0.0, 0.0, 1.0) : normalize(east);
    vec3 north = cross(east, tileCenter);
    vec3 offset = surfaceDirection - tileCenter;
    vec2 local =
      vec2(dot(offset, east), dot(offset, north)) / (tileSpacing * DECOR_SPAN) + 0.5;
    if (local.x >= 0.0 && local.x <= 1.0 && local.y >= 0.0 && local.y <= 1.0) {
      float column = mod(frame, atlasGrid.x);
      float row = floor(frame / atlasGrid.x);
      // Canvas row 0 is the top of the atlas, which flipY puts at v = 1
      vec2 atlasUv = vec2(
        (column + local.x) / atlasGrid.x,
        1.0 - (row + 1.0 - local.y) / atlasGrid.y
      );
      // An explicit LOD: the implicit one jumps to the blurriest level at cell edges
      vec4 icon = textureLod(decorAtlas, atlasUv, decorLod);
      baseColor = mix(baseColor, icon.rgb, icon.a * decorOpacity);
    }
  }

  // Rivers: from the tile centre to the midpoint towards each connected neighbour. The
  // neighbour draws the other half to the same midpoint, so the line runs on across the edge.
  int riverMask = int(texture2D(decorMap, planetUv).g * 255.0 + 0.5);
  if (riverMask > 0) {
    vec3 east = cross(tileCenter, vec3(0.0, 1.0, 0.0));
    east = dot(east, east) < 1e-10 ? vec3(0.0, 0.0, 1.0) : normalize(east);
    vec3 north = cross(east, tileCenter);
    vec3 fromCenter = surfaceDirection - tileCenter;
    vec2 p = vec2(dot(fromCenter, east), dot(fromCenter, north));

    int n = int(gridN + 0.5);
    int tx = int(found.x + 0.5);
    int ty = int(found.y + 0.5);
    int diamond = (tx - 1) / n;
    float i = float(tx - 1 - diamond * n);
    float distanceToRiver = 1e9;
    for (int bit = 0; bit < 6; bit++) {
      if (((riverMask >> bit) & 1) == 0) {
        continue;
      }
      vec3 neighbour;
      if (ty == n + 1) {
        // A pole's bits are its five spokes
        if (bit > 4) {
          continue;
        }
        neighbour = tx == 1
          ? normalize(flatPoint(bit, 1.0, 0.0))
          : normalize(flatPoint(5 + bit, float(n) - 1.0, float(n)));
      } else {
        vec2 step = NEIGHBOUR_OFFSETS[bit];
        neighbour = normalize(flatPoint(diamond, i + step.x, float(ty) + step.y));
      }
      vec3 toMid = normalize(tileCenter + neighbour) - tileCenter;
      vec2 m = vec2(dot(toMid, east), dot(toMid, north));
      float t = clamp(dot(p, m) / dot(m, m), 0.0, 1.0);
      distanceToRiver = min(distanceToRiver, length(p - m * t));
    }
    float halfWidth = tileSpacing * riverWidth;
    float river = 1.0 - smoothstep(halfWidth * 0.75, halfWidth, distanceToRiver);
    const vec3 RIVER_COLOR = vec3(0.07, 0.2, 0.42);
    baseColor = mix(baseColor, RIVER_COLOR, river);
  }

  vec3 normal = normalize(vWorldNormal);
  vec3 sun = normalize(sunDirection);

  float sunlight = max(dot(normal, sun), 0.0);
  float illumination = mix(0.18, 1.0, smoothstep(0.0, 0.28, sunlight));
  vec3 color = baseColor * illumination;

  float night = 1.0 - smoothstep(0.0, 0.30, sunlight);
  color = mix(color, nightColor, night * 0.12);

  gl_FragColor = vec4(color, 1.0);
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
uniform float opacityFactor;

varying vec3 vWorldNormal;
varying vec3 vViewDirection;

void main() {
  vec3 n = normalize(vWorldNormal);
  vec3 v = normalize(vViewDirection);

  float rim = pow(1.0 - abs(dot(n, v)), 2.2);
  float sun = max(dot(n, normalize(sunDirection)), 0.0);
  float intensity = rim * (0.35 + sun * 0.90);

  vec3 color = atmosphereColor * intensity * 1.5;
  float alpha = intensity * 0.88 * opacityFactor;

  gl_FragColor = vec4(color, alpha);
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
uniform float opacityFactor;

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
    noise(p * 4.5) * 0.50 +
    noise(p * 9.0) * 0.32 +
    noise(p * 18.0) * 0.18;

  // Richer cloud layer
  float cloud = smoothstep(0.46, 0.64, value);

  vec3 viewDir = normalize(cameraPosition - vPosition);
  float view = max(dot(n, viewDir), 0.0);

  float alpha = cloud * mix(0.40, 0.88, view) * opacityFactor;
  gl_FragColor = vec4(0.96, 0.98, 1.0, alpha * 0.45);
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
