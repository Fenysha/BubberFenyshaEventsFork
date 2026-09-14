export const ATMOSPHERE_VERTEX_SHADER = `
varying vec3 vWorldNormal;
varying vec3 vViewDirection;

void main() {
  vec4 worldPosition =
    modelMatrix * vec4(position, 1.0);

  vWorldNormal =
    normalize(
      mat3(modelMatrix) * normal
    );

  vViewDirection =
    normalize(
      cameraPosition -
      worldPosition.xyz
    );

  gl_Position =
    projectionMatrix *
    viewMatrix *
    worldPosition;
}
`;

export const ATMOSPHERE_FRAGMENT_SHADER = `
uniform vec3 atmosphereColor;
uniform vec3 sunDirection;

varying vec3 vWorldNormal;
varying vec3 vViewDirection;

void main() {
  float viewDot =
    max(
      dot(
        vWorldNormal,
        vViewDirection
      ),
      0.0
    );

  float rim =
    pow(
      1.0 - viewDot,
      3.2
    );

  float sunDot =
    max(
      dot(
        vWorldNormal,
        normalize(sunDirection)
      ),
      0.0
    );

  float day =
    pow(
      sunDot,
      0.35
    );

  float intensity =
    rim *
    (0.18 + day * 0.82);

  vec3 color =
    atmosphereColor *
    intensity *
    1.35;

  gl_FragColor =
    vec4(
      color,
      intensity * 0.8
    );
}
`;

export const NIGHT_VERTEX_SHADER = `
varying vec3 vNormal;

void main() {
  vNormal =
    normalize(
      normalMatrix * normal
    );

  gl_Position =
    projectionMatrix *
    modelViewMatrix *
    vec4(position, 1.0);
}
`;

export const NIGHT_FRAGMENT_SHADER = `
uniform vec3 sunDirection;
uniform vec3 nightColor;

varying vec3 vNormal;

void main() {
  float light =
    max(
      dot(
        normalize(vNormal),
        normalize(sunDirection)
      ),
      0.0
    );

  float night =
    smoothstep(
      0.22,
      0.0,
      light
    );

  gl_FragColor =
    vec4(
      nightColor,
      night * 0.38
    );
}
`;

export const CLOUD_VERTEX_SHADER = `
varying vec3 vNormal;
varying vec3 vPosition;

void main() {
  vNormal =
    normalize(
      normalMatrix * normal
    );

  vPosition =
    normalize(position);

  gl_Position =
    projectionMatrix *
    modelViewMatrix *
    vec4(position, 1.0);
}
`;

export const CLOUD_FRAGMENT_SHADER = `
uniform float time;

varying vec3 vNormal;
varying vec3 vPosition;

float hash(vec3 p) {
  p =
    fract(
      p * 0.3183099 +
      0.1
    );

  p *= 17.0;

  return fract(
    p.x *
    p.y *
    p.z *
    (
      p.x +
      p.y +
      p.z
    )
  );
}

float noise(vec3 p) {
  vec3 i =
    floor(p);

  vec3 f =
    fract(p);

  f =
    f * f *
    (3.0 - 2.0 * f);

  float n000 =
    hash(i);

  float n100 =
    hash(
      i +
      vec3(1.0, 0.0, 0.0)
    );

  float n010 =
    hash(
      i +
      vec3(0.0, 1.0, 0.0)
    );

  float n110 =
    hash(
      i +
      vec3(1.0, 1.0, 0.0)
    );

  float n001 =
    hash(
      i +
      vec3(0.0, 0.0, 1.0)
    );

  float n101 =
    hash(
      i +
      vec3(1.0, 0.0, 1.0)
    );

  float n011 =
    hash(
      i +
      vec3(0.0, 1.0, 1.0)
    );

  float n111 =
    hash(
      i +
      vec3(1.0, 1.0, 1.0)
    );

  return mix(
    mix(
      mix(
        n000,
        n100,
        f.x
      ),
      mix(
        n010,
        n110,
        f.x
      ),
      f.y
    ),
    mix(
      mix(
        n001,
        n101,
        f.x
      ),
      mix(
        n011,
        n111,
        f.x
      ),
      f.y
    ),
    f.z
  );
}

void main() {
  vec3 p =
    vPosition;

  p.xz +=
    time * 0.006;

  float n =
    noise(p * 5.0) *
      0.55 +
    noise(p * 10.0) *
      0.30 +
    noise(p * 20.0) *
      0.15;

  float cloud =
    smoothstep(
      0.52,
      0.68,
      n
    );

  float edge =
    pow(
      1.0 -
      abs(vNormal.z),
      1.7
    );

  float alpha =
    cloud *
    mix(
      0.75,
      0.35,
      edge
    );

  gl_FragColor =
    vec4(
      0.95,
      0.98,
      1.0,
      alpha * 0.32
    );
}
`;

export const STAR_VERTEX_SHADER = `
void main() {
  gl_PointSize =
    size;

  gl_Position =
    projectionMatrix *
    modelViewMatrix *
    vec4(
      position,
      1.0
    );
}
`;

export const STAR_FRAGMENT_SHADER = `
void main() {
  vec2 p =
    gl_PointCoord -
    vec2(0.5);

  float d =
    length(p);

  float alpha =
    smoothstep(
      0.5,
      0.0,
      d
    );

  gl_FragColor =
    vec4(
      1.0,
      1.0,
      1.0,
      alpha
    );
}
`;
