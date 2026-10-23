// Board rules for Insight Synthesis, kept apart from rendering

export const SIZE = 4;
export const SLIDE_MS = 110;

export const TIERS = [
  { name: 'Doubt', glyph: '✗' },
  { name: 'Note', glyph: '✎' },
  { name: 'Observation', glyph: '◉' },
  { name: 'Data set', glyph: '▤' },
  { name: 'Hypothesis', glyph: '?' },
  { name: 'Theory', glyph: '∴' },
  { name: 'Insight', glyph: '✦' },
  { name: 'Breakthrough', glyph: '★' },
];

/** Insight paid for fusing into each tier */
export const AWARD = [0, 0, 4, 8, 16, 32, 64, 200];
export const BREAKTHROUGH = 7;

export type Dir = 'up' | 'down' | 'left' | 'right';

export type Tile = {
  id: number;
  tier: number;
  r: number;
  c: number;
  /** Bumped on every fusion so the pop animation replays */
  pop: number;
  /** Merged away, dissolved or cashed in; drawn until its animation ends */
  gone?: 'merged' | 'dissolved' | 'cashed';
  merged?: boolean;
};

export type GameEvent =
  | { type: 'fuse'; tile: Tile; gain: number }
  | { type: 'breakthrough'; tile: Tile; gain: number }
  | { type: 'wasted'; cost: number; run: number }
  | { type: 'doubt'; tile: Tile }
  | { type: 'resolved'; tile: Tile };

export type SlideResult = { moved: boolean; fused: Tile[]; dead: Tile[] };

export class SynthesisBoard {
  tiles: Tile[] = [];
  grid: (Tile | null)[][];
  clarity = 100;
  wastedRun = 0;
  score = 0;
  merges = 0;
  wasted = 0;
  doubts = 0;
  bestTier = 1;
  private nextId = 1;

  constructor(headStart: number) {
    this.grid = Array.from({ length: SIZE }, () => Array(SIZE).fill(null));
    this.spawn(1);
    this.spawn(1);
    for (let i = 0; i < headStart; i++) {
      this.spawn(2);
    }
  }

  /** Clarity scales every payout, between 0.4 and 1 */
  get payoutMult() {
    return Math.round((0.4 + (0.6 * this.clarity) / 100) * 20) / 20;
  }

  get stats() {
    return {
      merges: this.merges,
      best_tier: this.bestTier,
      wasted: this.wasted,
    };
  }

  private empties() {
    const out: [number, number][] = [];
    for (let r = 0; r < SIZE; r++) {
      for (let c = 0; c < SIZE; c++) {
        if (!this.grid[r][c]) {
          out.push([r, c]);
        }
      }
    }
    return out;
  }

  /** Places a tile on a random free cell; with no tier given, low clarity may make it a Doubt */
  spawn(tier?: number): Tile | null {
    const free = this.empties();
    if (!free.length) {
      return null;
    }
    const [r, c] = free[Math.floor(Math.random() * free.length)];
    let picked = tier;
    if (picked === undefined) {
      const doubtChance =
        this.clarity < 40 ? (1 - this.clarity / 40) * 0.8 + 0.1 : 0;
      picked = Math.random() < doubtChance ? 0 : Math.random() < 0.85 ? 1 : 2;
    }
    const tile: Tile = { id: this.nextId++, tier: picked, r, c, pop: 0 };
    this.grid[r][c] = tile;
    this.tiles.push(tile);
    if (picked === 0) {
      this.doubts++;
    }
    return tile;
  }

  private line(dir: Dir, i: number): [number, number][] {
    const out: [number, number][] = [];
    for (let k = 0; k < SIZE; k++) {
      if (dir === 'left') out.push([i, k]);
      else if (dir === 'right') out.push([i, SIZE - 1 - k]);
      else if (dir === 'up') out.push([k, i]);
      else out.push([SIZE - 1 - k, i]);
    }
    return out;
  }

  /** Moves tiles to their new cells. Fusions only take effect in settle(), after the slide animates. */
  slide(dir: Dir): SlideResult {
    const fused: Tile[] = [];
    const dead: Tile[] = [];
    let moved = false;
    for (const tile of this.tiles) {
      tile.merged = false;
    }
    for (let i = 0; i < SIZE; i++) {
      const cells = this.line(dir, i);
      const row = cells
        .map(([r, c]) => this.grid[r][c])
        .filter((t): t is Tile => !!t);
      for (const [r, c] of cells) {
        this.grid[r][c] = null;
      }
      let write = 0;
      let last: Tile | null = null;
      for (const tile of row) {
        if (
          last &&
          !last.merged &&
          last.tier === tile.tier &&
          tile.tier > 0 &&
          tile.tier < BREAKTHROUGH
        ) {
          last.merged = true;
          tile.r = last.r;
          tile.c = last.c;
          tile.gone = 'merged';
          dead.push(tile);
          fused.push(last);
          moved = true;
        } else {
          const [r, c] = cells[write++];
          if (tile.r !== r || tile.c !== c) {
            moved = true;
          }
          tile.r = r;
          tile.c = c;
          this.grid[r][c] = tile;
          last = tile;
        }
      }
    }
    return { moved, fused, dead };
  }

  /** Applies fusions and clarity after a slide, spawns the next note and reports what happened */
  settle(result: SlideResult): GameEvent[] {
    const events: GameEvent[] = [];
    this.tiles = this.tiles.filter((t) => !result.dead.includes(t));
    if (result.fused.length) {
      this.wastedRun = 0;
      this.merges += result.fused.length;
      this.setClarity(this.clarity + 5 * result.fused.length);
      for (const tile of result.fused) {
        tile.tier++;
        tile.pop++;
        this.bestTier = Math.max(this.bestTier, tile.tier);
        const gain = Math.round(AWARD[tile.tier] * this.payoutMult);
        this.score += gain;
        if (tile.tier === BREAKTHROUGH) {
          // Cashes in straight away and frees its cell
          this.grid[tile.r][tile.c] = null;
          tile.gone = 'cashed';
          events.push({ type: 'breakthrough', tile, gain });
        } else {
          events.push({ type: 'fuse', tile, gain });
        }
        for (const [dr, dc] of [
          [0, 1],
          [0, -1],
          [1, 0],
          [-1, 0],
        ]) {
          const doubt = this.grid[tile.r + dr]?.[tile.c + dc];
          if (doubt && doubt.tier === 0 && !doubt.gone) {
            this.grid[doubt.r][doubt.c] = null;
            doubt.gone = 'dissolved';
            this.setClarity(this.clarity + 4);
            events.push({ type: 'resolved', tile: doubt });
          }
        }
      }
    } else {
      this.wastedRun++;
      this.wasted++;
      const cost = Math.min(36, 12 * this.wastedRun);
      this.setClarity(this.clarity - cost);
      events.push({ type: 'wasted', cost, run: this.wastedRun });
    }
    const spawned = this.spawn();
    if (spawned?.tier === 0) {
      events.push({ type: 'doubt', tile: spawned });
    }
    return events;
  }

  /** Drops tiles whose exit animation has finished */
  purge() {
    this.tiles = this.tiles.filter((t) => !t.gone);
  }

  setClarity(value: number) {
    this.clarity = Math.max(0, Math.min(100, value));
  }

  canMove() {
    for (let r = 0; r < SIZE; r++) {
      for (let c = 0; c < SIZE; c++) {
        const tile = this.grid[r][c];
        if (!tile) {
          return true;
        }
        if (tile.tier === 0) {
          continue;
        }
        const right = this.grid[r][c + 1];
        const down = this.grid[r + 1]?.[c];
        if (right && right.tier === tile.tier) {
          return true;
        }
        if (down && down.tier === tile.tier) {
          return true;
        }
      }
    }
    return false;
  }
}
