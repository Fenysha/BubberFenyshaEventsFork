import { useEffect, useMemo, useRef } from 'react';
import type { RhythmType } from './types';

type Props = {
  rate: number;
  rhythm: RhythmType | string;
  strength?: number;
  alert?: string | null;
  noise?: number;
  flatline?: number;
  /** 0 = healthy green, 1 = critical red */
  criticality?: number;
  cardiacOutput?: number;
  paused?: boolean;
  compact?: boolean;
};

const BG_COLOR = '#0a0e0a';

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
  const c = Math.max(0, Math.min(1, criticality));
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
  const trace = `rgb(${r},${g},${b})`;
  const glow = `rgba(${r},${g},${b},0.45)`;
  const grid = `rgba(${Math.max(20, r - 40)},${Math.max(40, g - 80)},${Math.max(20, b - 40)},0.35)`;
  return { trace, glow, grid };
}

function generateCycle(
  rhythm: string,
  samples: number,
  strength: number,
): Float32Array {
  const out = new Float32Array(samples);
  const s = Math.max(0.12, Math.min(strength, 1.5));
  const set = (i: number, v: number) => {
    if (i >= 0 && i < samples) out[i] = v;
  };
  const spike = (center: number, width: number, amplitude: number) => {
    const half = width / 2;
    for (
      let i = Math.floor(center - half);
      i <= Math.ceil(center + half);
      i++
    ) {
      const t = (i - center) / half;
      if (t >= -1 && t <= 1) {
        set(i, (out[i] || 0) + amplitude * (1 - Math.abs(t)));
      }
    }
  };

  if (rhythm === 'asystole') {
    return out;
  }

  // Chaotic VF / fibrillation — irregular low-amplitude quiver
  if (rhythm === 'ventricular_fibrillation' || rhythm === 'fibrillation') {
    let phase = Math.random() * Math.PI * 2;
    for (let i = 0; i < samples; i++) {
      phase += 0.55 + Math.random() * 0.9;
      out[i] = Math.sin(phase) * (0.18 + Math.random() * 0.32) * s;
      out[i] += Math.sin(phase * 2.7) * (0.06 + Math.random() * 0.1) * s;
      out[i] += (Math.random() - 0.5) * 0.12 * s;
    }
    return out;
  }

  // Wide bizarre QRS — ventricular tachycardia
  if (rhythm === 'ventricular_tachycardia') {
    const peak = samples * 0.32;
    spike(peak, samples * 0.38, -0.95 * s);
    spike(peak + samples * 0.1, samples * 0.22, 1.15 * s);
    spike(peak + samples * 0.22, samples * 0.28, -0.55 * s);
    return out;
  }

  // Normal / tachy / brady sinus morphology
  spike(samples * 0.14, samples * 0.09, 0.14 * s); // P
  spike(samples * 0.27, samples * 0.035, -0.1 * s); // Q
  spike(samples * 0.32, samples * 0.07, 1.05 * s); // R
  spike(samples * 0.38, samples * 0.055, -0.28 * s); // S
  spike(samples * 0.58, samples * 0.15, 0.26 * s); // T

  if (rhythm === 'pvc') {
    spike(samples * 0.74, samples * 0.2, -0.7 * s);
    spike(samples * 0.8, samples * 0.12, 0.9 * s);
  }

  if (rhythm === 'arrhythmia') {
    const shift = Math.floor((Math.random() - 0.5) * samples * 0.1);
    if (shift !== 0) {
      const tmp = Float32Array.from(out);
      for (let i = 0; i < samples; i++) {
        const src = (i - shift + samples) % samples;
        out[i] = tmp[src];
      }
    }
  }

  return out;
}

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
  } = props;

  const canvasRef = useRef<HTMLCanvasElement>(null);
  const rafRef = useRef<number>(0);
  const phaseRef = useRef(0);
  const bufferRef = useRef<Float32Array | null>(null);
  const samplesPerBeat = 120;

  const colors = useMemo(() => traceColors(criticality), [criticality]);

  const cycle = useMemo(
    () => generateCycle(String(rhythm), samplesPerBeat, strength),
    [rhythm, strength],
  );

  useEffect(() => {
    bufferRef.current = cycle;
  }, [cycle]);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    let running = true;
    const resize = () => {
      const dpr = window.devicePixelRatio || 1;
      const rect = canvas.getBoundingClientRect();
      canvas.width = Math.max(1, Math.floor(rect.width * dpr));
      canvas.height = Math.max(1, Math.floor(rect.height * dpr));
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    };

    resize();
    const ro = new ResizeObserver(resize);
    ro.observe(canvas);

    // Cap display rate for VF so the scroll still reads, actual irregularity comes from noise
    const displayRate = Math.max(
      20,
      Math.min(
        rhythm === 'ventricular_fibrillation' || rhythm === 'fibrillation'
          ? 180
          : rate || 80,
        220,
      ),
    );
    const pxPerSecond = 90;
    const beatDuration = 60 / displayRate;
    let lastTime = performance.now();

    const draw = (now: number) => {
      if (!running) return;
      rafRef.current = requestAnimationFrame(draw);
      if (paused) {
        lastTime = now;
        return;
      }

      const dt = Math.min(0.05, (now - lastTime) / 1000);
      lastTime = now;
      const rect = canvas.getBoundingClientRect();
      const w = rect.width;
      const h = rect.height;
      if (w < 2 || h < 2) return;

      phaseRef.current += dt;
      ctx.fillStyle = BG_COLOR;
      ctx.fillRect(0, 0, w, h);

      ctx.strokeStyle = colors.grid;
      ctx.lineWidth = 1;
      ctx.beginPath();
      for (let x = 0; x < w; x += 16) {
        ctx.moveTo(x + 0.5, 0);
        ctx.lineTo(x + 0.5, h);
      }
      for (let y = 0; y < h; y += 12) {
        ctx.moveTo(0, y + 0.5);
        ctx.lineTo(w, y + 0.5);
      }
      ctx.stroke();

      const buf = bufferRef.current;
      if (!buf) return;

      const midY = h * 0.5;
      const amp = h * 0.32 * (1 - flatline * 0.85);
      ctx.lineWidth = 2;
      ctx.strokeStyle = colors.trace;
      ctx.shadowColor = colors.glow;
      ctx.shadowBlur = 4;
      ctx.beginPath();

      let started = false;
      for (let x = 0; x < w; x++) {
        const t = phaseRef.current - (w - x) / pxPerSecond;
        const beatTime = ((t % beatDuration) + beatDuration) % beatDuration;
        const samplePos = (beatTime / beatDuration) * buf.length;
        const i0 = Math.floor(samplePos) % buf.length;
        const i1 = (i0 + 1) % buf.length;
        const frac = samplePos - Math.floor(samplePos);
        let yVal = buf[i0] * (1 - frac) + buf[i1] * frac;
        yVal *= 1 - flatline;
        if (noise > 0) yVal += (Math.random() - 0.5) * noise * 0.55;

        const y = midY - yVal * amp;
        if (!started) {
          ctx.moveTo(x, y);
          started = true;
        } else {
          ctx.lineTo(x, y);
        }
      }
      ctx.stroke();
      ctx.shadowBlur = 0;

      ctx.fillStyle = colors.trace;
      ctx.beginPath();
      ctx.arc(w - 1, midY, 2.5, 0, Math.PI * 2);
      ctx.fill();
    };

    rafRef.current = requestAnimationFrame(draw);
    return () => {
      running = false;
      cancelAnimationFrame(rafRef.current);
      ro.disconnect();
    };
  }, [rate, rhythm, strength, noise, flatline, paused, colors]);

  const pulseText =
    rhythm === 'asystole' || flatline
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
      <div className="HealthPanel__cardiogram-label">{rhythmLabel(String(rhythm))}</div>
    </div>
  );
};
