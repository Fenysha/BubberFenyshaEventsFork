import type { BodypartZone } from './types';

export type BodyDollZone = BodypartZone;

export type BodyDollOffset = {
  x: number;
  y: number;
  width: number;
  height: number;
};

/**
 * Where status markers (bleed / disabled) sit relative to the part box,
 * as fractions of the scaled part size (0..1). Tuned so the dots sit on
 * the visible limb silhouette rather than the empty corner of the DMI box.
 */
export type BodyDollIndicatorOffset = {
  /** 0 = left edge, 0.5 = center, 1 = right edge */
  x: number;
  /** 0 = top edge, 0.5 = center, 1 = bottom edge */
  y: number;
};

type OffsetMap = Partial<Record<BodyDollZone, Partial<BodyDollOffset>>>;

/**
 * Base positions for the human health doll.
 *
 * Race-specific offsets below are additive, so a new race only needs to
 * describe the parts that differ from the default silhouette.
 */
export const BODY_DOLL_BASE_OFFSETS: Record<BodyDollZone, BodyDollOffset> = {
  head: { x: 67, y: 39, width: 96, height: 96 },
  chest: { x: 67, y: 107, width: 96, height: 96 },
  l_arm: { x: 102, y: 110, width: 96, height: 96 },
  r_arm: { x: 32, y: 110, width: 96, height: 96 },
  l_leg: { x: 70, y: 171, width: 96, height: 96 },
  r_leg: { x: 64, y: 171, width: 96, height: 96 },
};

/**
 * Per-zone placement for the red bleed / disabled markers.
 * Anchored on the visible mass of each limb, not the top-right of the
 * oversized DMI bounding box.
 */
export const BODY_DOLL_INDICATOR_OFFSETS: Record<
  BodyDollZone,
  BodyDollIndicatorOffset
> = {
  head: { x: 0.52, y: 0.38 },
  chest: { x: 0.52, y: 0.42 },
  // Left arm (viewer's right on the doll) — marker sits mid-upper arm
  l_arm: { x: 0.62, y: 0.38 },
  // Right arm (viewer's left)
  r_arm: { x: 0.38, y: 0.38 },
  l_leg: { x: 0.55, y: 0.42 },
  r_leg: { x: 0.45, y: 0.42 },
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

export const getBodyDollIndicatorOffset = (
  zone: BodyDollZone,
): BodyDollIndicatorOffset => {
  return BODY_DOLL_INDICATOR_OFFSETS[zone] ?? { x: 0.5, y: 0.4 };
};
