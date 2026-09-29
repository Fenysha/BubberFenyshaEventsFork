export type BodyDollZone =
  | 'head'
  | 'chest'
  | 'l_arm'
  | 'r_arm'
  | 'l_leg'
  | 'r_leg';

export type BodyDollOffset = {
  x: number;
  y: number;
  width: number;
  height: number;
};

type OffsetMap = Partial<Record<BodyDollZone, Partial<BodyDollOffset>>>;

/**
 * Base positions for the human health doll.
 *
 * Race-specific offsets below are additive, so a new race only needs to
 * describe the parts that differ from the default silhouette.
 */
export const BODY_DOLL_BASE_OFFSETS: Record<BodyDollZone, BodyDollOffset> = {
  head: { x: 78, y: 39, width: 64, height: 64 },
  l_arm: { x: 105, y: 114, width: 64, height: 64 },
  chest: { x: 78, y: 74, width: 64, height: 64 },
  r_arm: { x: 51, y: 114, width: 64, height: 64 },
  l_leg: { x: 97, y: 191, width: 64, height: 64 },
  r_leg: { x: 60, y: 191, width: 64, height: 64 },
};

/**
 * Future race/gender-specific corrections.
 *
 * Keep this separate from the component so sprite alignment can be tuned
 * without touching the health doll implementation.
 */
export const BODY_DOLL_RACE_OFFSETS: Record<
  string,
  Partial<Record<'m' | 'f' | string, OffsetMap>>
> = {
  human: {
    m: {},
    f: {},
  },

  // Example:
  // digitigrade: {
  //   m: {
  //     l_leg: { x: -2, y: 6, height: 120 },
  //     r_leg: { x: 2, y: 6, height: 120 },
  //   },
  // },

  default: {},
};

const mergeOffset = (
  base: BodyDollOffset,
  override?: Partial<BodyDollOffset>,
): BodyDollOffset => ({
  ...base,
  ...override,
});

export const getBodyDollOffset = (
  spriteId: string | undefined,
  gender: string | undefined,
  zone: BodyDollZone,
): BodyDollOffset => {
  const raceOffsets =
    BODY_DOLL_RACE_OFFSETS[spriteId || ''] ?? BODY_DOLL_RACE_OFFSETS.default;
  const genderOffsets = raceOffsets[gender || ''] ?? raceOffsets.m ?? {};
  return mergeOffset(BODY_DOLL_BASE_OFFSETS[zone], genderOffsets[zone]);
};
