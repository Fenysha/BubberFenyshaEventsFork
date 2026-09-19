/*
 * Geodesic hex grid: the dual of a subdivided icosahedron. Every tile is a hexagon except the
 * 12 on the icosahedron's corners, which are pentagons.
 *
 * The icosahedron is cut into 10 diamonds (5 around each pole), each an n x n patch of the
 * triangular lattice. Tiles keep BYOND-style 1-based (x, y) addresses: diamond d, lattice
 * (i, j) lives at x = d * n + i + 1, y = j. The two poles sit alone in an extra row at
 * y = n + 1, north at x = 1 and south at x = 2. That makes every layer a plain
 * (10n) x (n + 1) grid.
 *
 * DM (planet.dm) and Rust (tp_planet.rs) implement this same scheme; keep all three in step.
 */

export type Vec3 = [number, number, number];
export type Tile = { x: number; y: number };

const LAT = Math.atan(0.5);
const DEG = Math.PI / 180;

const fromLatLon = (lat: number, lon: number): Vec3 => [
  Math.cos(lat) * Math.cos(lon),
  Math.sin(lat),
  Math.cos(lat) * Math.sin(lon),
];

const NORTH: Vec3 = [0, 1, 0];
const SOUTH: Vec3 = [0, -1, 0];
const UPPER: Vec3[] = [0, 1, 2, 3, 4].map((k) => fromLatLon(LAT, 72 * k * DEG));
const LOWER: Vec3[] = [0, 1, 2, 3, 4].map((k) =>
  fromLatLon(-LAT, (72 * k + 36) * DEG),
);

/** Diamond corners A, B, C, D: triangles (A, B, D) and (C, D, B) share the B-D diagonal. */
const DIAMONDS: [Vec3, Vec3, Vec3, Vec3][] = [
  ...[0, 1, 2, 3, 4].map(
    (k) =>
      [NORTH, UPPER[k], LOWER[k], UPPER[(k + 1) % 5]] as [
        Vec3,
        Vec3,
        Vec3,
        Vec3,
      ],
  ),
  ...[0, 1, 2, 3, 4].map(
    (k) =>
      [UPPER[(k + 1) % 5], LOWER[k], SOUTH, LOWER[(k + 1) % 5]] as [
        Vec3,
        Vec3,
        Vec3,
        Vec3,
      ],
  ),
];

const add = (a: Vec3, b: Vec3): Vec3 => [a[0] + b[0], a[1] + b[1], a[2] + b[2]];
const sub = (a: Vec3, b: Vec3): Vec3 => [a[0] - b[0], a[1] - b[1], a[2] - b[2]];
const scale = (a: Vec3, s: number): Vec3 => [a[0] * s, a[1] * s, a[2] * s];
const dot = (a: Vec3, b: Vec3) => a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
const cross = (a: Vec3, b: Vec3): Vec3 => [
  a[1] * b[2] - a[2] * b[1],
  a[2] * b[0] - a[0] * b[2],
  a[0] * b[1] - a[1] * b[0],
];
export const normalize = (a: Vec3): Vec3 => {
  const length = Math.hypot(a[0], a[1], a[2]) || 1;
  return [a[0] / length, a[1] / length, a[2] / length];
};

type Face = {
  diamond: number;
  upper: boolean;
  normal: Vec3;
  origin: Vec3;
  e1: Vec3;
  e2: Vec3;
};

/** The 20 faces. Lower: p = A + u(B-A) + v(D-A). Upper: p = C + u(D-C) + v(B-C). */
const FACES: Face[] = DIAMONDS.flatMap(([a, b, c, d], diamond) => {
  const lower = { origin: a, e1: sub(b, a), e2: sub(d, a) };
  const upper = { origin: c, e1: sub(d, c), e2: sub(b, c) };
  return [
    {
      diamond,
      upper: false,
      ...lower,
      normal: normalize(cross(lower.e1, lower.e2)),
    },
    {
      diamond,
      upper: true,
      ...upper,
      normal: normalize(cross(upper.e1, upper.e2)),
    },
  ].map((face) =>
    // Winding varies; point every normal outward
    dot(face.normal, face.origin) < 0
      ? { ...face, normal: scale(face.normal, -1) }
      : face,
  );
});

/**
 * The six lattice steps to a tile's neighbours in its own diamond's frame. River masks use
 * these indices as bits; rust-g (NEIGHBOUR_OFFSETS), DM and the shader share the order.
 */
export const NEIGHBOUR_OFFSETS: [number, number][] = [
  [1, 0],
  [-1, 0],
  [0, 1],
  [0, -1],
  [1, -1],
  [-1, 1],
];

export class HexGrid {
  public readonly n: number;
  public readonly width: number;
  public readonly height: number;
  public readonly tileCount: number;
  /** Mean angular distance between neighbouring tile centres, in radians */
  public readonly spacing: number;

  public constructor(frequency: number) {
    this.n = frequency;
    this.width = 10 * frequency;
    this.height = frequency + 1;
    this.tileCount = 10 * frequency * frequency + 2;
    this.spacing = Math.sqrt((4 * Math.PI) / this.tileCount);
  }

  public isValid(x: number, y: number): boolean {
    if (y === this.height) {
      return x === 1 || x === 2;
    }
    return x >= 1 && x <= this.width && y >= 1 && y <= this.n;
  }

  /** Unnormalised point on the diamond's folded surface for lattice (i, j) in 0..n. */
  private flatPoint(diamond: number, i: number, j: number): Vec3 {
    const [a, b, c, d] = DIAMONDS[diamond];
    const n = this.n;
    if (i + j <= n) {
      return add(
        add(scale(a, 1 - (i + j) / n), scale(b, i / n)),
        scale(d, j / n),
      );
    }
    return add(
      add(scale(c, (i + j) / n - 1), scale(b, 1 - j / n)),
      scale(d, 1 - i / n),
    );
  }

  public center(x: number, y: number): Vec3 {
    if (y === this.height) {
      return x === 1 ? NORTH : SOUTH;
    }
    const diamond = Math.floor((x - 1) / this.n);
    const i = (x - 1) % this.n;
    return normalize(this.flatPoint(diamond, i, y));
  }

  /**
   * The owner of a lattice point given in some diamond's frame, i and j in 0..n. Points on
   * the edges a diamond does not own are handed to the neighbour that does.
   */
  private canonical(diamond: number, i: number, j: number): Tile {
    const n = this.n;
    let d = diamond;
    for (let guard = 0; guard < 4; guard++) {
      if (j >= 1 && i <= n - 1) {
        return { x: d * n + i + 1, y: j };
      }
      const north = d < 5;
      const k = d % 5;
      if (j === 0) {
        if (i === 0) {
          if (north) {
            return { x: 1, y: this.height };
          }
          // Upper-ring corner: owned as north diamond k's D corner
          return { x: k * n + 1, y: n };
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
      // i === n
      if (north) {
        d = 5 + ((k + 4) % 5);
        i = 0;
      } else {
        if (j === n) {
          return { x: 2, y: this.height };
        }
        d = 5 + ((k + 4) % 5);
        i = j;
        j = n;
      }
    }
    throw new Error(`HexGrid: could not canonicalise ${diamond}:${i},${j}`);
  }

  /** The tile whose centre is nearest the given direction. */
  public fromDirection(direction: Vec3): Tile {
    const dir = normalize(direction);
    if (dir[1] > 1 - 1e-12) {
      return { x: 1, y: this.height };
    }
    if (dir[1] < -1 + 1e-12) {
      return { x: 2, y: this.height };
    }

    let face = FACES[0];
    let best = -Infinity;
    for (const candidate of FACES) {
      const alignment = dot(dir, candidate.normal);
      if (alignment > best) {
        best = alignment;
        face = candidate;
      }
    }

    // Where the ray meets the face's plane, in the face's (u, v) coordinates
    const hit = scale(
      dir,
      dot(face.origin, face.normal) / dot(dir, face.normal),
    );
    const q = sub(hit, face.origin);
    const a11 = dot(face.e1, face.e1);
    const a12 = dot(face.e1, face.e2);
    const a22 = dot(face.e2, face.e2);
    const b1 = dot(q, face.e1);
    const b2 = dot(q, face.e2);
    const det = a11 * a22 - a12 * a12;
    const u = (b1 * a22 - b2 * a12) / det;
    const v = (b2 * a11 - b1 * a12) / det;

    const n = this.n;
    // Upper face: u weighs D (1 - i/n) and v weighs B (1 - j/n)
    const fi = face.upper ? n * (1 - u) : n * u;
    const fj = face.upper ? n * (1 - v) : n * v;

    let bestDot = -Infinity;
    let bestI = 0;
    let bestJ = 0;
    const baseI = Math.floor(fi);
    const baseJ = Math.floor(fj);
    for (let di = -1; di <= 2; di++) {
      for (let dj = -1; dj <= 2; dj++) {
        const i = baseI + di;
        const j = baseJ + dj;
        if (i < 0 || j < 0 || i > n || j > n) {
          continue;
        }
        const alignment = dot(
          dir,
          normalize(this.flatPoint(face.diamond, i, j)),
        );
        if (alignment > bestDot) {
          bestDot = alignment;
          bestI = i;
          bestJ = j;
        }
      }
    }
    return this.canonical(face.diamond, bestI, bestJ);
  }

  /** Adjacent tiles: 6, or 5 around the 12 pentagons. */
  public neighbors(x: number, y: number): Tile[] {
    return this.neighborsWithBits(x, y).map(({ tile }) => tile);
  }

  /**
   * Adjacent tiles with their bit: the index in NEIGHBOUR_OFFSETS of this tile's own diamond,
   * or the spoke 0..4 at a pole. River masks use it, matching rust-g and DM.
   */
  public neighborsWithBits(
    x: number,
    y: number,
  ): { tile: Tile; bit: number }[] {
    const n = this.n;
    const found: { tile: Tile; bit: number }[] = [];
    // The first bit wins for a tile reached twice, as in rust-g and DM
    const push = (tile: Tile, bit: number) => {
      const self = tile.x === x && tile.y === y;
      if (
        !self &&
        !found.some((f) => f.tile.x === tile.x && f.tile.y === tile.y)
      ) {
        found.push({ tile, bit });
      }
    };

    if (y === this.height) {
      for (let k = 0; k < 5; k++) {
        push(
          x === 1 ? this.canonical(k, 1, 0) : this.canonical(5 + k, n - 1, n),
          k,
        );
      }
      return found;
    }

    const diamond = Math.floor((x - 1) / n);
    const i = (x - 1) % n;
    NEIGHBOUR_OFFSETS.forEach(([di, dj], bit) => {
      const ni = i + di;
      const nj = y + dj;
      if (ni >= 0 && nj >= 0 && ni <= n && nj <= n) {
        push(this.canonical(diamond, ni, nj), bit);
        return;
      }
      // Off this diamond: step the same distance along the surface and look it up
      const here = this.center(x, y);
      const step = sub(
        normalize(this.flatPoint(diamond, i + di * 0.5, y + dj * 0.5)),
        normalize(this.flatPoint(diamond, i, y)),
      );
      const stepped = this.fromDirection(add(here, scale(step, 2)));
      // At a pentagon one step points into the gap where a sixth cell would be, and the
      // lookup there lands on a cell that isn't adjacent. Adjacent cells share an edge, so
      // the point halfway between their centres belongs to one of the two.
      const midway = this.fromDirection(
        add(here, this.center(stepped.x, stepped.y)),
      );
      const onEdge =
        (midway.x === x && midway.y === y) ||
        (midway.x === stepped.x && midway.y === stepped.y);
      if (onEdge) {
        push(stepped, bit);
      }
    });
    return found;
  }

  /** Latitude and longitude of a tile centre, in degrees. */
  public latLon(x: number, y: number): { lat: number; lon: number } {
    const [cx, cy, cz] = this.center(x, y);
    return {
      lat: Math.asin(Math.max(-1, Math.min(1, cy))) / DEG,
      lon: Math.atan2(cz, cx) / DEG,
    };
  }

  /**
   * Corners of a tile's cell on the unit sphere, in order around it. Each corner is where the
   * tile meets two consecutive neighbours: the point equally far from all three centres (their
   * spherical circumcentre), which is exactly where the shader's nearest-centre cells meet.
   */
  public outline(x: number, y: number): Vec3[] {
    const c = this.center(x, y);
    const east0 = cross(c, [0, 1, 0]);
    const east =
      dot(east0, east0) < 1e-12 ? ([0, 0, 1] as Vec3) : normalize(east0);
    const north = cross(east, c);
    const around = this.neighbors(x, y)
      .map((tile) => {
        const p = this.center(tile.x, tile.y);
        const offset = sub(p, c);
        return { p, angle: Math.atan2(dot(offset, east), dot(offset, north)) };
      })
      .sort((a, b) => a.angle - b.angle);
    return around.map((current, index) => {
      const next = around[(index + 1) % around.length].p;
      const corner = normalize(cross(sub(current.p, c), sub(next, c)));
      return dot(corner, c) < 0 ? scale(corner, -1) : corner;
    });
  }

  /** Great-circle distance between two tiles, in tile steps. */
  public distance(a: Tile, b: Tile): number {
    const c = dot(this.center(a.x, a.y), this.center(b.x, b.y));
    return Math.acos(Math.max(-1, Math.min(1, c))) / this.spacing;
  }
}

const grids = new Map<number, HexGrid>();

/** One shared grid per frequency; building neighbours and outlines is cheap once it exists. */
export const getHexGrid = (frequency: number): HexGrid => {
  let grid = grids.get(frequency);
  if (!grid) {
    grid = new HexGrid(frequency);
    grids.set(frequency, grid);
  }
  return grid;
};

/** Diamond corners and face frames, flattened for the surface shader's uniforms. */
export const HEX_SHADER_DATA = {
  diamondCorners: DIAMONDS.flat(),
  faceOrigin: FACES.map((face) => face.origin),
  faceE1: FACES.map((face) => face.e1),
  faceE2: FACES.map((face) => face.e2),
  faceNormal: FACES.map((face) => face.normal),
  faceDiamond: FACES.map((face) => face.diamond),
  faceUpper: FACES.map((face) => (face.upper ? 1 : 0)),
};
