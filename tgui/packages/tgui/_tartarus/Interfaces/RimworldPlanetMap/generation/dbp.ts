/*
 * Copyright (c) 2026 Fenysha
 * All rights reserved.
 */

/*
 * ============================================================================
 * DBP noise
 * ============================================================================
 *
 * Deterministic browser-side implementation of dbpnoise 0.1.2,
 * which is what rust-g uses for rustg_dbp_generate().
 *
 * References:
 *
 * - dbpnoise::gen_noise
 * - rand_seeder::Seeder
 * - rand_pcg::Pcg32
 *
 * Important:
 *
 * JavaScript does not have native uint64 arithmetic, so all RNG state is
 * represented with BigInt.
 */

const U64_MASK = 0xffffffffffffffffn;

const PCG_MULTIPLIER = 6364136223846793005n;

/*
 * ----------------------------------------------------------------------------
 * f32 helpers
 * ----------------------------------------------------------------------------
 *
 * dbpnoise performs its calculations with Rust f32.
 *
 * Math.cos/sin/tanh return JS doubles, so intermediate results are explicitly
 * rounded to float32 where the original implementation uses f32.
 */

function f32(value: number): number {
  return Math.fround(value);
}

function addF32(a: number, b: number): number {
  return f32(f32(a) + f32(b));
}

function subF32(a: number, b: number): number {
  return f32(f32(a) - f32(b));
}

function mulF32(a: number, b: number): number {
  return f32(f32(a) * f32(b));
}

function divF32(a: number, b: number): number {
  return f32(f32(a) / f32(b));
}

/*
 * ----------------------------------------------------------------------------
 * u64 helpers
 * ----------------------------------------------------------------------------
 */

function u64(value: bigint): bigint {
  return value & U64_MASK;
}

function addU64(a: bigint, b: bigint): bigint {
  return (a + b) & U64_MASK;
}

function mulU64(a: bigint, b: bigint): bigint {
  return (a * b) & U64_MASK;
}

function xorU64(a: bigint, b: bigint): bigint {
  return a ^ b;
}

function rotl64(value: bigint, amount: number): bigint {
  const shift = BigInt(amount);

  return ((value << shift) | (value >> (64n - shift))) & U64_MASK;
}

function rotr32(value: number, amount: number): number {
  const shift = amount & 31;

  const unsigned = value >>> 0;

  return ((unsigned >>> shift) | (unsigned << (32 - shift))) >>> 0;
}

/*
 * ============================================================================
 * SipHash 2-4
 * ============================================================================
 *
 * rand_seeder uses its own portable SipHash implementation.
 *
 * Seeder::from("...") hashes the Rust str bytes followed by 0xff.
 */

function sipRound(
  state: [bigint, bigint, bigint, bigint],
): [bigint, bigint, bigint, bigint] {
  let [v0, v1, v2, v3] = state;

  v0 = addU64(v0, v1);

  v1 = rotl64(v1, 13);

  v1 = xorU64(v1, v0);

  v0 = rotl64(v0, 32);

  v2 = addU64(v2, v3);

  v3 = rotl64(v3, 16);

  v3 = xorU64(v3, v2);

  v0 = addU64(v0, v3);

  v3 = rotl64(v3, 21);

  v3 = xorU64(v3, v0);

  v2 = addU64(v2, v1);

  v1 = rotl64(v1, 17);

  v1 = xorU64(v1, v2);

  v2 = rotl64(v2, 32);

  return [v0, v1, v2, v3];
}

function sipCompression(
  state: [bigint, bigint, bigint, bigint],
): [bigint, bigint, bigint, bigint] {
  state = sipRound(state);

  state = sipRound(state);

  return state;
}

/*
 * Create the SipHasher state used by:
 *
 * Seeder::from(seed)
 */
function createSipState(bytes: Uint8Array): [bigint, bigint, bigint, bigint] {
  let v0 = 0x736f6d6570736575n;

  let v1 = 0x646f72616e646f6dn;

  let v2 = 0x6c7967656e657261n;

  let v3 = 0x7465646279746573n;

  /*
   * Hash input.
   *
   * Rust's Hash implementation for str appends 0xff.
   */

  const input = new Uint8Array(bytes.length + 1);

  input.set(bytes, 0);

  input[input.length - 1] = 0xff;

  let tail = 0n;

  let tailLength = 0;

  /*
   * Process complete 8-byte blocks.
   */

  let offset = 0;

  while (offset + 8 <= input.length) {
    let message = 0n;

    for (let i = 0; i < 8; i++) {
      message |= BigInt(input[offset + i]) << BigInt(i * 8);
    }

    v3 = xorU64(v3, message);

    [v0, v1, v2, v3] = sipCompression([v0, v1, v2, v3]);

    v0 = xorU64(v0, message);

    offset += 8;
  }

  /*
   * Remaining bytes.
   */

  tailLength = input.length - offset;

  for (let i = 0; i < tailLength; i++) {
    tail |= BigInt(input[offset + i]) << BigInt(i * 8);
  }

  /*
   * Seeder::into_rng()
   *
   * b = ((length & 0xff) << 56) | tail
   */

  const message = ((BigInt(input.length & 0xff) << 56n) | tail) & U64_MASK;

  v3 = xorU64(v3, message);

  [v0, v1, v2, v3] = sipCompression([v0, v1, v2, v3]);

  v0 = xorU64(v0, message);

  /*
   * rand_seeder::SipHasher::into_rng()
   *
   * It performs c=2 additional rounds here,
   * giving a total of d-c=2 extra rounds.
   */

  [v0, v1, v2, v3] = sipCompression([v0, v1, v2, v3]);

  return [v0, v1, v2, v3];
}

/*
 * ============================================================================
 * SipRng
 * ============================================================================
 */

class SipRng {
  private v0: bigint;
  private v1: bigint;
  private v2: bigint;
  private v3: bigint;

  private adjustment = 0x13n;

  public constructor(state: [bigint, bigint, bigint, bigint]) {
    [this.v0, this.v1, this.v2, this.v3] = state;
  }

  public nextU64(): bigint {
    this.v2 = xorU64(this.v2, this.adjustment);

    this.adjustment = u64(this.adjustment - 0x11n);

    [this.v0, this.v1, this.v2, this.v3] = sipCompression([
      this.v0,
      this.v1,
      this.v2,
      this.v3,
    ]);

    return xorU64(xorU64(this.v0, this.v1), xorU64(this.v2, this.v3));
  }

  public fillBytes(length: number): Uint8Array {
    const result = new Uint8Array(length);

    let offset = 0;

    while (offset < length) {
      const value = this.nextU64();

      for (let i = 0; i < 8 && offset < length; i++) {
        result[offset++] = Number((value >> BigInt(i * 8)) & 0xffn);
      }
    }

    return result;
  }
}

/*
 * Create exactly the same RNG as:
 *
 * Seeder::from(seed).make_rng::<Pcg32>()
 */
function createPcg32(seed: string): Pcg32 {
  const bytes = new TextEncoder().encode(seed);

  const sipState = createSipState(bytes);

  const sip = new SipRng(sipState);

  /*
   * Pcg32::Seed = [u8; 16]
   */

  const seedBytes = sip.fillBytes(16);

  let state = 0n;

  let increment = 0n;

  for (let i = 0; i < 8; i++) {
    state |= BigInt(seedBytes[i]) << BigInt(i * 8);
  }

  for (let i = 0; i < 8; i++) {
    increment |= BigInt(seedBytes[8 + i]) << BigInt(i * 8);
  }

  /*
   * Pcg32::from_seed()
   *
   * increment must be odd.
   */

  increment = increment | 1n;

  /*
   * rand_pcg moves away from the initial state:
   *
   * state += increment
   * state = state * MULTIPLIER + increment
   */

  state = addU64(state, increment);

  state = addU64(mulU64(state, PCG_MULTIPLIER), increment);

  return new Pcg32(state, increment);
}

/*
 * ============================================================================
 * PCG32
 * ============================================================================
 */

class Pcg32 {
  private state: bigint;

  private readonly increment: bigint;

  public constructor(state: bigint, increment: bigint) {
    this.state = state;

    this.increment = increment;
  }

  public nextU32(): number {
    /*
     * PCG uses the state BEFORE stepping
     * for the output transformation.
     */

    const oldState = this.state;

    /*
     * Advance state.
     */

    this.state = addU64(mulU64(this.state, PCG_MULTIPLIER), this.increment);

    /*
     * XSH RR 64/32.
     */

    const rot = Number(oldState >> 59n);

    const xsh = Number(((oldState >> 18n) ^ oldState) >> 27n) >>> 0;

    return rotr32(xsh, rot);
  }

  public nextU64(): bigint {
    /*
     * rand_core::utils::next_u64_via_u32
     *
     * low word first, high word second.
     */

    const low = BigInt(this.nextU32());

    const high = BigInt(this.nextU32());

    return low | (high << 32n);
  }

  public nextUSize(bits = 64): bigint {
    if (bits <= 32) {
      return BigInt(this.nextU32());
    }

    return this.nextU64();
  }
}

/*
 * ============================================================================
 * DBP sampler
 * ============================================================================
 */

type Stamp = {
  data: number[][];
};

export type DbpSamplerOptions = {
  seed: number | string;
  accuracy: number;
  stampSize: number;
  worldSize: number;
};

export class DbpSampler {
  public readonly seed: number | string;

  public readonly accuracy: number;

  public readonly stampSize: number;

  public readonly worldSize: number;

  private readonly realStampSize: number;

  private readonly realWorldSize: number;

  private readonly stamps: Stamp[];

  private readonly stampGrid: number[][];

  public constructor(options: DbpSamplerOptions) {
    this.seed = options.seed;

    this.accuracy = options.accuracy;

    this.stampSize = options.stampSize;

    this.worldSize = options.worldSize;

    /*
     * rust:
     *
     * let real_stamp_size = stamp_size * 2;
     */

    this.realStampSize = this.stampSize * 2;

    /*
     * rust:
     *
     * (((world_size as f32 / stamp_size as f32).ceil()
     * * stamp_size as f32 + real_stamp_size as f32)
     */

    this.realWorldSize =
      Math.ceil(this.worldSize / this.stampSize) * this.stampSize +
      this.realStampSize;

    this.stamps = this.generateStamps(this.accuracy, this.realStampSize);

    this.stampGrid = this.generateStampGrid();
  }

  /*
   * --------------------------------------------------------------------------
   * Stamp generation
   * --------------------------------------------------------------------------
   */

  private generateStamps(accuracy: number, size: number): Stamp[] {
    const result: Stamp[] = [];

    const step = f32((2 * Math.PI) / accuracy);

    const fsize = f32(size);

    const denominator = mulF32(divF32(fsize, 2), Math.SQRT2);

    const scale = divF32(1, denominator);

    for (let direction = 0; direction < accuracy; direction++) {
      /*
       * Rust:
       *
       * Vec2::new(
       *   (i as f32 * step).cos(),
       *   (i as f32 * step).sin()
       * )
       */

      const angle = f32(direction * step);

      const vectorX = f32(Math.cos(angle));

      const vectorY = f32(Math.sin(angle));

      const data: number[][] = [];

      for (let x = 0; x < size; x++) {
        const row: number[] = [];

        const fx = f32(x);

        const offsetX = subF32(addF32(fx, 0.5), divF32(fsize, 2));

        for (let y = 0; y < size; y++) {
          const fy = f32(y);

          const offsetY = subF32(addF32(fy, 0.5), divF32(fsize, 2));

          const normalizedX = mulF32(offsetX, scale);

          const normalizedY = mulF32(offsetY, scale);

          const dot = addF32(
            mulF32(normalizedX, vectorX),
            mulF32(normalizedY, vectorY),
          );

          row.push(dot);
        }

        data.push(row);
      }

      result.push({
        data,
      });
    }

    return result;
  }

  /*
   * --------------------------------------------------------------------------
   * Random stamp grid
   * --------------------------------------------------------------------------
   */

  private generateStampGrid(): number[][] {
    const rng = createPcg32(String(this.seed));

    const dimensions = Math.floor(this.realWorldSize / this.stampSize);

    const grid: number[][] = [];

    for (let x = 0; x < dimensions; x++) {
      const row: number[] = [];

      for (let y = 0; y < dimensions; y++) {
        /*
         * Rust:
         *
         * rng.gen::<usize>() % stamps.len()
         *
         * rust-g currently runs on 64-bit platforms,
         * therefore usize corresponds to u64 here.
         */

        const randomValue = rng.nextUSize(64);

        row.push(Number(randomValue % BigInt(this.stamps.length)));
      }

      grid.push(row);
    }

    return grid;
  }

  /*
   * --------------------------------------------------------------------------
   * Smoothstep
   * --------------------------------------------------------------------------
   *
   * Not the classic Perlin smoothstep.
   *
   * dbpnoise uses:
   *
   * ((8*x - 3).tanh() + 1) / 2
   */

  private smoothstep(value: number): number {
    const input = subF32(mulF32(8, value), 3);

    return f32((Math.tanh(input) + 1) / 2);
  }

  /*
   * --------------------------------------------------------------------------
   * Raw DBP value
   * --------------------------------------------------------------------------
   *
   * This reproduces the value before the lower/upper comparison.
   *
   * Coordinates here are the coordinates used by dbpnoise's generated
   * Vec<Vec<f32>>:
   *
   *   x = outer vector
   *   y = inner vector
   */

  private sampleRaw(x: number, y: number): number {
    /*
     * ==========================================================
     * IMPORTANT — matches dbpnoise::gen_noise() exactly
     * ==========================================================
     *
     * The reference implementation NEVER samples starting at
     * raw coordinate 0. Its generation loop runs from
     * `real_stamp_size` to `real_world_size`, and afterwards
     * cut_noise_to_dimensions() truncates the result down to
     * `world_size` FROM THE FRONT.
     *
     * That means logical world coordinate 0 corresponds to the
     * internal dbpnoise coordinate `real_stamp_size`, not 0.
     *
     * Without this offset, xdiv/ydiv are almost always sitting
     * right at the ragged edge of the stamp grid (0 or 1), which
     * is exactly why a defensive clamp used to be "needed" here -
     * it was papering over reading the noise field at its own
     * boundary everywhere, instead of its smooth interior.
     */

    const sx = x + this.realStampSize;

    const sy = y + this.realStampSize;

    const xdiv = Math.floor(sx / this.stampSize);

    const ydiv = Math.floor(sy / this.stampSize);

    const maxGrid = this.stampGrid.length - 1;

    /*
     * Mirrors gen_noise()'s own bounds check
     * (xdiv < 1 || xdiv > stamp_vec.len()).
     */
    if (xdiv < 1 || xdiv > maxGrid || ydiv < 1 || ydiv > maxGrid) {
      return 0;
    }

    const stampX1 = this.stampGrid[xdiv][ydiv];

    const stampX2 = this.stampGrid[xdiv - 1][ydiv];

    const stampX3 = this.stampGrid[xdiv][ydiv - 1];

    const stampX4 = this.stampGrid[xdiv - 1][ydiv - 1];

    const localX = sx - xdiv * this.stampSize;

    const localY = sy - ydiv * this.stampSize;

    /*
     * IMPORTANT:
     *
     * x2/x3/x4 come from the PREVIOUS grid cell along the
     * relevant axis, so relative to THEIR stamp's own center
     * our sample point is `localX/localY + stampSize`, not
     * `localX`/`localY` unshifted. Reusing the unshifted local
     * coordinates for all four corners (as this used to) reads
     * the same corner of every stamp and produces hard seams
     * every stampSize tiles — exactly the "torn apart" look.
     */

    const x1 = this.stamps[stampX1].data[localX][localY];

    const x2 = this.stamps[stampX2].data[localX + this.stampSize][localY];

    const x3 = this.stamps[stampX3].data[localX][localY + this.stampSize];

    const x4 =
      this.stamps[stampX4].data[localX + this.stampSize][
        localY + this.stampSize
      ];

    const unitX = this.smoothstep(divF32(localX, this.stampSize));

    const unitY = this.smoothstep(divF32(localY, this.stampSize));

    const left = addF32(x4, mulF32(subF32(x3, x4), unitX));

    const right = addF32(x2, mulF32(subF32(x1, x2), unitX));

    return addF32(left, mulF32(subF32(right, left), unitY));
  }

  /*
   * --------------------------------------------------------------------------
   * Range test
   * --------------------------------------------------------------------------
   *
   * IMPORTANT:
   *
   * rustg_dbp_generate serializes the dbpnoise Vec<Vec<bool>> in the
   * same order consumed by CaveGenerator:
   *
   *   worldSize * (y - 1) + x
   *
   * Therefore a logical DBP coordinate (x, y) maps to the generated
   * matrix as:
   *
   *   raw outer coordinate = y
   *   raw inner coordinate = x
   *
   * PlanetGenerator already converts its 1-based coordinates to 0-based
   * coordinates before calling us.
   */

  public inRange(x: number, y: number, lower: number, upper: number): boolean {
    if (x < 0 || y < 0 || x >= this.worldSize || y >= this.worldSize) {
      return false;
    }

    /*
     * Match:
     *
     * map[worldSize * y + x]
     *
     *
     * where dbpnoise's outer index represents the serialized row.
     */

    const value = this.sampleRaw(y, x);

    /*
     * Rust:
     *
     * result >= lower_range &&
     * result < upper_range
     */

    return value >= lower && value < upper;
  }

  /*
   * Optional raw sample method.
   *
   * This is useful for debugging and visual validation.
   */

  public sample(x: number, y: number): number {
    if (x < 0 || y < 0 || x >= this.worldSize || y >= this.worldSize) {
      return 0;
    }

    return this.sampleRaw(y, x);
  }
}
