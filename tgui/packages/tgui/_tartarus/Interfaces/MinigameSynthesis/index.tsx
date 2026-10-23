import { type RefObject, useEffect, useRef, useState } from 'react';
import { useBackend } from 'tgui/backend';
import {
  AnimatedNumber,
  Box,
  Button,
  KeyListener,
  LabeledList,
  ProgressBar,
  Section,
  Stack,
} from 'tgui-core/components';
import type { KeyEvent } from 'tgui-core/events';
import { acquireHotKey, releaseHotKey } from 'tgui-core/hotkeys';
import {
  KEY_A,
  KEY_D,
  KEY_DOWN,
  KEY_ESCAPE,
  KEY_LEFT,
  KEY_RIGHT,
  KEY_S,
  KEY_UP,
  KEY_W,
} from 'tgui-core/keycodes';
import { classes } from 'tgui-core/react';
import {
  MinigameBriefing,
  type MinigameData,
  MinigameHeader,
  MinigameResults,
  MinigameWindow,
} from '../../layouts/MinigameWindow';
import { arpeggio, burst, floatText, orbs, shake, tone } from './fx';
import {
  AWARD,
  type Dir,
  type GameEvent,
  SIZE,
  SLIDE_MS,
  SynthesisBoard,
  TIERS,
} from './game';

type GameData = { head_start: number };
type Stats = { merges: number; best_tier: number; wasted: number };
type Data = MinigameData<GameData, Stats>;
type Live = { score: number; stats: Stats };

const KEY_DIRS: Record<number, Dir> = {
  [KEY_UP]: 'up',
  [KEY_W]: 'up',
  [KEY_DOWN]: 'down',
  [KEY_S]: 'down',
  [KEY_LEFT]: 'left',
  [KEY_A]: 'left',
  [KEY_RIGHT]: 'right',
  [KEY_D]: 'right',
};

const CONTROLS = (
  <>
    <Box inline className="MinigameChip">
      Arrows / WASD
    </Box>
    slide, or swipe ·{' '}
    <Box inline className="MinigameChip">
      Esc
    </Box>
    abandon
  </>
);

const BREAKTHROUGH_NAMES = [
  'Glitterworld protein folding',
  'Room-temperature superconductor',
  'Stable micro-wormhole',
  'Archotech signal grammar',
  'Neural lace bandwidth limit',
  'Boomalope gland chemistry',
  'Luciferium half-life',
  'Persona core lattice',
  'Mechanite self-repair loop',
  'Zero-point thermal sink',
];

function grade(score: number) {
  if (score >= 600) return 'S';
  if (score >= 350) return 'A';
  if (score >= 180) return 'B';
  if (score >= 80) return 'C';
  return 'D';
}

function formatTime(seconds: number) {
  const s = Math.ceil(seconds);
  return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, '0')}`;
}

export function MinigameSynthesis() {
  const { act, data } = useBackend<Data>();
  const { phase, progress, time_limit, result } = data;
  const barRef = useRef<HTMLDivElement>(null);
  const [live, setLive] = useState<Live>({
    score: 0,
    stats: { merges: 0, best_tier: 1, wasted: 0 },
  });
  const [timeLeft, setTimeLeft] = useState(time_limit);
  const [endedBy, setEndedBy] = useState('');
  const pending = progress ? live.score * progress.per_point : 0;

  const dismiss = () => {
    if (phase === 'playing') {
      act('abandon', live);
    } else if (phase === 'results') {
      act('close');
    } else {
      act('abandon');
    }
  };

  const timer = phase === 'playing' && time_limit > 0 && (
    <Box width="10em">
      <ProgressBar
        value={timeLeft / time_limit}
        ranges={{
          bad: [-Infinity, 0.2],
          average: [0.2, 0.5],
        }}
      >
        {formatTime(timeLeft)}
      </ProgressBar>
    </Box>
  );

  const stats = result?.stats;

  return (
    <MinigameWindow>
      <KeyListener
        onKeyDown={(key: KeyEvent) => {
          if (key.code === KEY_ESCAPE) {
            dismiss();
          }
        }}
      />
      <MinigameHeader
        timer={timer}
        pending={phase === 'playing' ? pending : 0}
        barRef={barRef}
        onClose={dismiss}
      />
      {phase === 'briefing' && <MinigameBriefing controls={CONTROLS} />}
      {phase === 'playing' && (
        <SynthesisPlay
          barRef={barRef}
          onLive={setLive}
          onTime={setTimeLeft}
          onEnd={setEndedBy}
        />
      )}
      {phase === 'results' && result && stats && (
        <MinigameResults grade={grade(result.score)}>
          <LabeledList.Item label="Insight">
            <b>{result.score}</b>
          </LabeledList.Item>
          <LabeledList.Item label="Syntheses">{stats.merges}</LabeledList.Item>
          <LabeledList.Item label="Deepest tier">
            {TIERS[stats.best_tier].glyph} {TIERS[stats.best_tier].name}
          </LabeledList.Item>
          <LabeledList.Item label="Wasted moves">
            {stats.wasted}
          </LabeledList.Item>
          <LabeledList.Item label="Ended by">
            {endedBy || 'filed early'}
          </LabeledList.Item>
        </MinigameResults>
      )}
    </MinigameWindow>
  );
}

type PlayProps = {
  barRef: RefObject<HTMLDivElement | null>;
  onLive: (live: Live) => void;
  onTime: (seconds: number) => void;
  onEnd: (why: string) => void;
};

function SynthesisPlay(props: PlayProps) {
  const { barRef, onLive, onTime, onEnd } = props;
  const { act, data } = useBackend<Data>();
  const { progress, time_limit } = data;
  const boardRef = useRef<SynthesisBoard | null>(null);
  if (!boardRef.current) {
    boardRef.current = new SynthesisBoard(data.game.head_start);
  }
  const board = boardRef.current;
  const [, setTick] = useState(0);
  const redraw = () => setTick((t) => t + 1);
  const busy = useRef(false);
  const ended = useRef(false);
  const boardEl = useRef<HTMLDivElement>(null);
  const clarityEl = useRef<HTMLDivElement>(null);
  const swipe = useRef<{ x: number; y: number } | null>(null);

  const finish = (why: string) => {
    if (ended.current) {
      return;
    }
    ended.current = true;
    onEnd(why);
    arpeggio([392, 494, 587], 90, 0.04);
    act('finish', { score: board.score, stats: board.stats });
  };

  useEffect(() => {
    if (!time_limit) {
      return;
    }
    const started = Date.now();
    let lastWhole = Math.ceil(time_limit);
    const interval = setInterval(() => {
      const left = Math.max(0, time_limit - (Date.now() - started) / 1000);
      onTime(left);
      const whole = Math.ceil(left);
      if (whole !== lastWhole && whole <= 10 && whole > 0) {
        tone(880, 0.05, 'square', 0.02);
      }
      lastWhole = whole;
      if (left <= 0) {
        finish('time ran out');
      }
    }, 250);
    return () => clearInterval(interval);
  }, []);

  // WASD would otherwise reach the game and walk the pawn
  useEffect(() => {
    const keys = [KEY_W, KEY_A, KEY_S, KEY_D];
    keys.forEach(acquireHotKey);
    return () => keys.forEach(releaseHotKey);
  }, []);

  const tileEl = (id: number) =>
    boardEl.current?.querySelector(`[data-tile="${id}"]`) ?? null;

  const play = (events: GameEvent[]) => {
    const fraction = progress
      ? (progress.value + board.score * progress.per_point) /
        Math.max(1, progress.max)
      : 1;
    events.forEach((event, k) => {
      switch (event.type) {
        case 'fuse': {
          const el = tileEl(event.tile.id);
          const tier = event.tile.tier;
          setTimeout(
            () => tone(262 * 2 ** ((tier * 2) / 12), 0.13, 'triangle', 0.05),
            k * 50,
          );
          floatText(
            `+${event.gain}`,
            el,
            '#f3f3f0',
            15 + Math.min(10, event.gain / 8),
          );
          orbs(
            el,
            barRef.current,
            fraction,
            Math.min(10, 2 + Math.round(event.gain / 12)),
            (i) => tone(700 + i * 40, 0.04, 'sine', 0.02),
          );
          if (tier >= 5) {
            burst(
              el,
              tier === 6 ? 'hsl(40,90%,55%)' : 'hsl(260,80%,75%)',
              10,
              50,
            );
          }
          break;
        }
        case 'breakthrough': {
          const el = tileEl(event.tile.id);
          const name =
            BREAKTHROUGH_NAMES[
              Math.floor(Math.random() * BREAKTHROUGH_NAMES.length)
            ];
          arpeggio([523, 659, 784, 1047], 80, 0.045);
          burst(el, 'hsl(40,100%,70%)', 36, 140);
          burst(el, '#fff', 14, 70);
          shake(boardEl.current);
          floatText(`+${event.gain}  ${name}`, el, 'hsl(40,100%,80%)', 18);
          orbs(el, barRef.current, fraction, 12);
          break;
        }
        case 'wasted':
          shake(clarityEl.current);
          floatText(
            `-${event.cost} clarity`,
            clarityEl.current,
            'hsl(0,72.5%,62%)',
            13,
          );
          tone(200 - Math.min(event.run, 5) * 20, 0.12, 'sawtooth', 0.025, 0.7);
          break;
        case 'doubt':
          floatText('Doubt', tileEl(event.tile.id), 'hsl(0,70%,65%)', 13);
          tone(155, 0.2, 'sawtooth', 0.03, 0.7);
          break;
        case 'resolved':
          floatText('Doubt resolved', tileEl(event.tile.id), '#f3f3f0', 12);
          burst(tileEl(event.tile.id), 'hsl(0,70%,70%)', 10, 40);
          tone(660, 0.1, 'sine', 0.04);
          break;
      }
    });
  };

  const move = (dir: Dir) => {
    if (busy.current || ended.current) {
      return;
    }
    const slid = board.slide(dir);
    if (!slid.moved) {
      tone(130, 0.07, 'square', 0.018, 0.8);
      shake(boardEl.current);
      return;
    }
    busy.current = true;
    redraw();
    setTimeout(() => {
      const events = board.settle(slid);
      redraw();
      requestAnimationFrame(() => play(events));
      onLive({ score: board.score, stats: board.stats });
      busy.current = false;
      setTimeout(() => {
        board.purge();
        redraw();
      }, 500);
      if (!board.canMove()) {
        setTimeout(() => finish('notebook full'), 400);
      }
    }, SLIDE_MS);
  };

  const clarity = board.clarity;
  return (
    <>
      <KeyListener
        onKeyDown={(key: KeyEvent) => {
          const dir = KEY_DIRS[key.code];
          if (dir && !key.repeat && !key.hasModifierKeys()) {
            move(dir);
          }
        }}
      />
      <Stack>
        <Stack.Item grow>
          <Section title="Lab notebook" fill>
            <div className="Synthesis__game">
              <div
                ref={boardEl}
                className="Synthesis__board"
                onPointerDown={(e) => {
                  swipe.current = { x: e.clientX, y: e.clientY };
                }}
                onPointerUp={(e) => {
                  const start = swipe.current;
                  swipe.current = null;
                  if (!start) {
                    return;
                  }
                  const dx = e.clientX - start.x;
                  const dy = e.clientY - start.y;
                  if (Math.max(Math.abs(dx), Math.abs(dy)) < 24) {
                    return;
                  }
                  move(
                    Math.abs(dx) > Math.abs(dy)
                      ? dx > 0
                        ? 'right'
                        : 'left'
                      : dy > 0
                        ? 'down'
                        : 'up',
                  );
                }}
              >
                <div className="Synthesis__cells">
                  {Array.from({ length: SIZE * SIZE }, (_, i) => (
                    <div
                      key={i}
                      className="Synthesis__slot"
                      style={{
                        transform: `translate(${(i % SIZE) * 100}%,${Math.floor(i / SIZE) * 100}%)`,
                      }}
                    />
                  ))}
                </div>
                <div className="Synthesis__tiles">
                  {board.tiles.map((tile) => (
                    <div
                      key={tile.id}
                      data-tile={tile.id}
                      className={classes([
                        'Synthesis__tile',
                        tile.gone === 'merged' && 'Synthesis__tile--under',
                      ])}
                      style={{
                        transform: `translate(${tile.c * 100}%,${tile.r * 100}%)`,
                      }}
                    >
                      <div
                        key={tile.pop}
                        className={classes([
                          'Synthesis__tileInner',
                          `Synthesis--t${tile.tier}`,
                          tile.pop > 0 && 'Synthesis__tileInner--pop',
                          tile.gone === 'dissolved' &&
                            'Synthesis__tileInner--gone',
                          tile.gone === 'cashed' &&
                            'Synthesis__tileInner--cash',
                        ])}
                      >
                        <span className="Synthesis__glyph">
                          {TIERS[tile.tier].glyph}
                        </span>
                        <span className="Synthesis__name">
                          {TIERS[tile.tier].name}
                        </span>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
              <div className="Synthesis__clarity" ref={clarityEl}>
                <Stack mb={0.25}>
                  <Stack.Item grow className="MinigameLabel">
                    Clarity
                  </Stack.Item>
                  <Stack.Item>{Math.round(clarity)}%</Stack.Item>
                </Stack>
                <ProgressBar
                  value={clarity / 100}
                  color={
                    clarity >= 60
                      ? undefined
                      : clarity >= 30
                        ? 'average'
                        : 'bad'
                  }
                >
                  payouts ×{board.payoutMult.toFixed(2)}
                </ProgressBar>
              </div>
            </div>
          </Section>
        </Stack.Item>
        <Stack.Item basis="20em">
          <Section title="Session">
            <Box fontSize="2em" bold>
              <AnimatedNumber value={board.score} />
            </Box>
            <Box className="MinigameLabel" mb={1}>
              insight
              {progress &&
                ` · ≈ ${(board.score * progress.per_point).toFixed(1)} research`}
            </Box>
            <LabeledList>
              <LabeledList.Item label="Syntheses">
                {board.merges}
              </LabeledList.Item>
              <LabeledList.Item label="Wasted moves">
                <Box inline color={board.wasted ? 'bad' : undefined}>
                  {board.wasted}
                </Box>
              </LabeledList.Item>
              <LabeledList.Item label="Doubts">{board.doubts}</LabeledList.Item>
              <LabeledList.Item label="Deepest tier">
                {TIERS[board.bestTier].glyph} {TIERS[board.bestTier].name}
              </LabeledList.Item>
            </LabeledList>
          </Section>
          <Section title="Tiers">
            {TIERS.slice(1).map((tier, i) => (
              <Stack key={tier.name} align="center" mb={0.25}>
                <Stack.Item grow>
                  <span
                    className={classes([
                      'Synthesis__legendSwatch',
                      `Synthesis--t${i + 1}`,
                    ])}
                  >
                    {tier.glyph}
                  </span>
                  {tier.name}
                </Stack.Item>
                <Stack.Item className="MinigameHint">
                  {AWARD[i + 1] ? `+${AWARD[i + 1]}` : ''}
                </Stack.Item>
              </Stack>
            ))}
          </Section>
        </Stack.Item>
      </Stack>
      <Stack align="center">
        <Stack.Item grow className="MinigameHint">
          {CONTROLS}
        </Stack.Item>
        <Stack.Item>
          <Button onClick={() => finish('filed early')}>Finish early</Button>
        </Stack.Item>
      </Stack>
    </>
  );
}
