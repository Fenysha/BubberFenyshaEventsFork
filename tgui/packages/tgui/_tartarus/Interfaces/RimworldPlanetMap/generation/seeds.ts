/*
 * ============================================================================
 * Seed derivation
 * ============================================================================
 *
 * This intentionally mirrors the DM implementation.
 *
 * The server sends derived seeds in PlanetMapData, so production rendering
 * does not depend on this function.
 */

const SEED_MODULUS = 2147483647;
const SEED_MULTIPLIER = 1103515245;
const SEED_INCREMENT = 12345;

/**
 * JS Number safely represents integers only up to 2^53 - 1.
 *
 * seed * multiplier is safely below that boundary:
 *
 * ~2e9 * ~1.1e9 ~= 2.2e18
 *
 * which is NOT safe.
 *
 * Therefore BigInt is deliberately used here.
 */
function nextSeed(seed: number): number {
  const value =
    (BigInt(Math.trunc(seed)) * BigInt(SEED_MULTIPLIER) +
      BigInt(SEED_INCREMENT)) %
    BigInt(SEED_MODULUS);

  return Number(value);
}

export function deriveSeeds(seed: number) {
  const terrainSeed = nextSeed(seed);

  const heatSeed = nextSeed(terrainSeed);

  const humiditySeed = nextSeed(heatSeed);

  return {
    terrainSeed,
    heatSeed,
    humiditySeed,
  };
}
