import { useEffect, useRef } from 'react';
import type { RhythmType } from './types';

type Props = {
  rate: number;
  rhythm: RhythmType | string;
  strength?: number;
  alert?: string | null;
  noise?: number;
  flatline?: number;
  criticality?: number;
  cardiacOutput?: number;
  paused?: boolean;
  compact?: boolean;
  canSeeFull?: boolean;
};

const BG_COLOR = '#0a0e0a';

const PX_PER_SECOND = 100;
const GRID_MINOR = 20;
const GRID_MAJOR = GRID_MINOR * 5;
const ERASE_GAP = 22;
const LOOKAHEAD = 0.35;

const TAU = Math.PI * 2;

const clamp = (v: number, lo: number, hi: number) =>
  Math.max(lo, Math.min(hi, v));

const rhythmLabel = (rhythm: string) => {
  switch (rhythm) {
    case 'normal':
      return 'SINUS RHYTHM';
    case 'bradycardia':
      return 'BRADYCARDIA';
    case 'tachycardia':
      return 'TACHYCARDIA';
    case 'ventricular_tachycardia':
      return 'VENTRICULAR TACHYCARDIA';
    case 'ventricular_fibrillation':
    case 'fibrillation':
      return 'VENTRICULAR FIBRILLATION';
    case 'asystole':
      return 'ASYSTOLE';
    case 'arrhythmia':
      return 'ARRHYTHMIA';
    case 'pvc':
      return 'PVC';
    default:
      return String(rhythm).toUpperCase();
  }
};

/** Interpolate ECG color from green → amber → red by criticality 0..1 */
function traceColors(criticality: number) {
  const c = clamp(criticality, 0, 1);
  // green (51,255,102) → amber (255,200,40) → red (255,60,60)
  let r: number;
  let g: number;
  let b: number;
  if (c < 0.5) {
    const t = c / 0.5;
    r = Math.round(51 + (255 - 51) * t);
    g = Math.round(255 + (200 - 255) * t);
    b = Math.round(102 + (40 - 102) * t);
  } else {
    const t = (c - 0.5) / 0.5;
    r = 255;
    g = Math.round(200 + (60 - 200) * t);
    b = Math.round(40 + (60 - 40) * t);
  }
  const gr = Math.max(20, r - 40);
  const gg = Math.max(40, g - 80);
  const gb = Math.max(20, b - 40);
  return {
    trace: `rgb(${r},${g},${b})`,
    glow: `rgba(${r},${g},${b},0.45)`,
    grid: `rgba(${gr},${gg},${gb},0.22)`,
    gridMajor: `rgba(${gr},${gg},${gb},0.45)`,
  };
}

type BeatKind = 'sinus' | 'pvc' | 'af' | 'vt';

type Beat = {
  t0: number;
  kind: BeatKind;
  amp: number;
  rr: number;
  pAmp: number;
  tAmp: number;
};

type VfState = {
  p1: number;
  p2: number;
  f1: number;
  f2: number;
  env: number;
  target: number;
};

type Sim = {
  t: number;
  nextBeat: number;
  beats: Beat[];
  rhythm: string;
  nextKind: BeatKind;
  pvcIn: number;
  vf: VfState;
};

const newSim = (rhythm: string): Sim => ({
  t: 0,
  nextBeat: 0.3,
  beats: [],
  rhythm,
  nextKind: 'sinus',
  pvcIn: 3,
  vf: { p1: 0, p2: 1.7, f1: 5, f2: 8, env: 0.7, target: 0.7 },
});

const gauss = (x: number, mu: number, sigma: number) => {
  const d = (x - mu) / sigma;
  return Math.exp(-0.5 * d * d);
};

function beatWave(tau: number, b: Beat): number {
  if (tau < -0.4 || tau > 0.9) return 0;

  switch (b.kind) {
    case 'sinus': {
      // QT
      const k = clamp(Math.sqrt(b.rr / 0.8), 0.65, 1.3);
      const pOff = -Math.min(0.16, b.rr * 0.22);
      const v =
        b.pAmp * gauss(tau, pOff, 0.026) + // P
        -0.1 * gauss(tau, -0.028, 0.01) + // Q
        1.0 * gauss(tau, 0, 0.011) + // R
        -0.2 * gauss(tau, 0.028, 0.012) + // S
        b.tAmp * gauss(tau, 0.2 * k, 0.05 * k); // T
      return v * b.amp;
    }
    case 'pvc': {
      const v =
        0.95 * gauss(tau, 0, 0.042) -
        0.35 * gauss(tau, 0.07, 0.04) -
        0.45 * gauss(tau, 0.27, 0.07);
      return v * b.amp;
    }
    case 'af': {
      const v =
        -0.08 * gauss(tau, -0.028, 0.01) +
        1.0 * gauss(tau, 0, 0.011) +
        -0.2 * gauss(tau, 0.028, 0.012) +
        0.12 * gauss(tau, 0.2, 0.05);
      return v * b.amp;
    }
    case 'vt': {
      const v = 1.0 * gauss(tau, 0, 0.06) - 0.85 * gauss(tau, 0.115, 0.07);
      return v * b.amp;
    }
  }
}

function effectiveRate(rhythm: string, rate: number): number {
  const r = rate > 0 ? rate : 70;
  if (rhythm === 'ventricular_tachycardia') return clamp(r < 140 ? 180 : r, 140, 260);
  return clamp(r, 20, 300);
}

function scheduleBeats(sim: Sim, rhythm: string, rate: number, s: number) {
  while (sim.nextBeat <= sim.t + LOOKAHEAD) {
    const t0 = sim.nextBeat;
    const baseRR = 60 / effectiveRate(rhythm, rate);
    let kind: BeatKind = 'sinus';
    let interval = baseRR;
    let amp = s;

    switch (rhythm) {
      case 'arrhythmia':
        kind = 'af';
        amp = s * (0.78 + Math.random() * 0.32);
        interval = baseRR * (0.55 + Math.random() * 0.95);
        break;

      case 'ventricular_tachycardia':
        kind = 'vt';
        amp = s * 0.9;
        interval = baseRR * (1 + (Math.random() - 0.5) * 0.03);
        break;

      case 'pvc':
        if (sim.nextKind === 'pvc') {
          kind = 'pvc';
          amp = s * 1.15;
          interval = baseRR * 1.4;
          sim.nextKind = 'sinus';
          sim.pvcIn = 3 + Math.floor(Math.random() * 4);
        } else {
          amp = s * (0.97 + Math.random() * 0.06);
          sim.pvcIn -= 1;
          if (sim.pvcIn <= 0) {
            interval = baseRR * 0.6;
            sim.nextKind = 'pvc';
          }
        }
        break;

      default: {
        const hrv =
          1 +
          0.03 * Math.sin(TAU * 0.25 * t0) +
          (Math.random() - 0.5) * 0.03;
        interval = baseRR * hrv;
        amp = s * (0.97 + Math.random() * 0.06);
      }
    }

    const tachyFactor = clamp(baseRR / 0.8, 0.4, 1);
    sim.beats.push({
      t0,
      kind,
      amp,
      rr: baseRR,
      pAmp: 0.12 * (0.6 + 0.4 * tachyFactor),
      tAmp: 0.3 * tachyFactor,
    });
    sim.nextBeat = t0 + interval;
  }


  while (sim.beats.length && sim.t - sim.beats[0].t0 > 1) sim.beats.shift();
}


function vfSample(vf: VfState, dt: number, s: number): number {
  vf.f1 = clamp(vf.f1 + (Math.random() - 0.5) * 0.35, 3.5, 7.5);
  vf.f2 = clamp(vf.f2 + (Math.random() - 0.5) * 0.5, 6, 11);
  vf.p1 += TAU * vf.f1 * dt;
  vf.p2 += TAU * vf.f2 * dt;
  vf.target = clamp(vf.target + (Math.random() - 0.5) * 0.12, 0.3, 1);
  vf.env += (vf.target - vf.env) * 0.02;
  return (
    vf.env *
    0.6 *
    s *
    (0.65 * Math.sin(vf.p1) + 0.35 * Math.sin(vf.p2) + 0.12 * Math.sin(vf.p1 * 2.3))
  );
}

type LiveProps = {
  rate: number;
  rhythm: string;
  strength: number;
  noise: number;
  flatline: number;
  paused: boolean;
  colors: ReturnType<typeof traceColors>;
};

export const Cardiogram = (props: Props) => {
  const {
    rate,
    rhythm,
    strength = 1,
    alert,
    noise = 0,
    flatline = 0,
    criticality = 0,
    cardiacOutput = 0,
    paused = false,
    compact = false,
    canSeeFull = true,
  } = props;

  const canvasRef = useRef<HTMLCanvasElement>(null);

  const liveRef = useRef<LiveProps>({
    rate,
    rhythm: String(rhythm),
    strength,
    noise,
    flatline,
    paused,
    colors: traceColors(criticality),
  });
  liveRef.current = {
    rate,
    rhythm: String(rhythm),
    strength,
    noise,
    flatline,
    paused,
    colors: traceColors(criticality),
  };

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    let running = true;
    let raf = 0;

    let cols = 1;
    let buf = new Float32Array(1).fill(NaN);
    let head = 0;
    let headFrac = 0;
    const sim = newSim(liveRef.current.rhythm);

    const resize = () => {
      const dpr = window.devicePixelRatio || 1;
      const rect = canvas.getBoundingClientRect();
      canvas.width = Math.max(1, Math.floor(rect.width * dpr));
      canvas.height = Math.max(1, Math.floor(rect.height * dpr));
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      cols = Math.max(1, Math.floor(rect.width));
      buf = new Float32Array(cols).fill(NaN);
      head = 0;
      headFrac = 0;
    };

    resize();
    const ro = new ResizeObserver(resize);
    ro.observe(canvas);

    const stepColumn = (p: LiveProps): number => {
      const dt = 1 / PX_PER_SECOND;
      const s = clamp(p.strength, 0.12, 1.5);
      sim.t += dt;

      if (p.rhythm !== sim.rhythm) {
        sim.rhythm = p.rhythm;
        sim.beats = [];
        sim.nextBeat = sim.t + 0.3;
        sim.nextKind = 'sinus';
        sim.pvcIn = 3;
      }

      const isVf =
        p.rhythm === 'ventricular_fibrillation' || p.rhythm === 'fibrillation';
      const isAsystole = p.rhythm === 'asystole';

      let v = 0;
      if (isVf) {
        v = vfSample(sim.vf, dt, s);
      } else if (!isAsystole) {
        const rrNow = 60 / effectiveRate(p.rhythm, p.rate);
        const maxWait = rrNow * 1.6 + 0.3;
        if (sim.nextBeat - sim.t > maxWait) {
          sim.nextBeat = sim.t + maxWait * 0.6;
        }
        scheduleBeats(sim, p.rhythm, p.rate, s);
        for (const b of sim.beats) v += beatWave(sim.t - b.t0, b);

        if (p.rhythm === 'arrhythmia') {
          v += 0.035 * s * Math.sin(TAU * 6.3 * sim.t) * Math.sin(TAU * 0.9 * sim.t + 1);
          v += 0.02 * s * Math.sin(TAU * 8.1 * sim.t);
        }
      }

      v += 0.025 * Math.sin(TAU * 0.28 * sim.t);

      v *= 1 - p.flatline;
      if (p.noise > 0) v += (Math.random() - 0.5) * p.noise * 0.55;
      return v;
    };

    let last = performance.now();

    const draw = (now: number) => {
      if (!running) return;
      raf = requestAnimationFrame(draw);

      const p = liveRef.current;
      if (p.paused) {
        last = now;
        return;
      }

      const dt = Math.min(0.05, (now - last) / 1000);
      last = now;

      const rect = canvas.getBoundingClientRect();
      const w = rect.width;
      const h = rect.height;
      if (w < 2 || h < 2) return;

      headFrac += dt * PX_PER_SECOND;
      while (headFrac >= 1) {
        headFrac -= 1;
        head = (head + 1) % cols;
        buf[head] = stepColumn(p);
      }

      ctx.fillStyle = BG_COLOR;
      ctx.fillRect(0, 0, w, h);

      const { colors } = p;
      ctx.shadowBlur = 0;
      ctx.lineWidth = 1;
      for (const [step, color] of [
        [GRID_MINOR, colors.grid],
        [GRID_MAJOR, colors.gridMajor],
      ] as const) {
        ctx.strokeStyle = color;
        ctx.beginPath();
        for (let x = 0; x < w; x += step) {
          ctx.moveTo(x + 0.5, 0);
          ctx.lineTo(x + 0.5, h);
        }
        for (let y = 0; y < h; y += step) {
          ctx.moveTo(0, y + 0.5);
          ctx.lineTo(w, y + 0.5);
        }
        ctx.stroke();
      }

      const midY = h * 0.5;
      const amp = h * 0.32;
      const yOf = (i: number) => midY - buf[i] * amp;

      ctx.lineWidth = 2;
      ctx.lineJoin = 'round';
      ctx.strokeStyle = colors.trace;
      ctx.shadowColor = colors.glow;
      ctx.shadowBlur = 4;
      ctx.beginPath();

      const seg = (from: number, to: number) => {
        let pen = false;
        for (let i = from; i <= to; i++) {
          if (Number.isNaN(buf[i])) {
            pen = false;
            continue;
          }
          const y = yOf(i);
          if (!pen) {
            ctx.moveTo(i, y);
            pen = true;
          } else {
            ctx.lineTo(i, y);
          }
        }
      };

      seg(Math.max(0, head + ERASE_GAP - (cols - 1)), head);
      if (head + ERASE_GAP < cols) seg(head + ERASE_GAP, cols - 1);
      ctx.stroke();
      ctx.shadowBlur = 0;

      if (!Number.isNaN(buf[head])) {
        ctx.fillStyle = colors.trace;
        ctx.shadowColor = colors.glow;
        ctx.shadowBlur = 8;
        ctx.beginPath();
        ctx.arc(head, yOf(head), 2.5, 0, TAU);
        ctx.fill();
        ctx.shadowBlur = 0;
      }
    };

    raf = requestAnimationFrame(draw);
    return () => {
      running = false;
      cancelAnimationFrame(raf);
      ro.disconnect();
    };
  }, []);

  const pulseText = !canSeeFull
    ? '??'
    : rhythm === 'asystole' || flatline
      ? '—'
      : rhythm === 'ventricular_fibrillation' || rhythm === 'fibrillation'
        ? `${Math.round(rate)}±`
        : `${Math.round(rate)}`;

  return (
    <div
      className={`HealthPanel__cardiogram${
        compact ? ' HealthPanel__cardiogram--compact' : ''
      }`}
    >
      <canvas ref={canvasRef} className="HealthPanel__cardiogram-canvas" />

      <div className="HealthPanel__cardiogram-hud">
        <div className="HealthPanel__cardiogram-hud-row">
          <span className="HealthPanel__cardiogram-hud-label">Pulse</span>
          <span className="HealthPanel__cardiogram-hud-value">{pulseText}</span>
          <span className="HealthPanel__cardiogram-hud-unit">bpm</span>
        </div>
        <div className="HealthPanel__cardiogram-hud-row">
          <span className="HealthPanel__cardiogram-hud-label">Output</span>
          <span className="HealthPanel__cardiogram-hud-value">
            {Math.round(Math.max(0, cardiacOutput) * 100)}
          </span>
          <span className="HealthPanel__cardiogram-hud-unit">%</span>
        </div>
      </div>

      {alert && <div className="HealthPanel__cardiogram-alert">{alert}</div>}
      {canSeeFull && (
        <div className="HealthPanel__cardiogram-label">
          {rhythmLabel(String(rhythm))}
        </div>
      )}
    </div>
  );
};
