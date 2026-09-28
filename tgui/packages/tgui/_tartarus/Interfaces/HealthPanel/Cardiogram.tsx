import { useEffect, useMemo, useRef } from 'react';
import type { RhythmType } from './types';

type Props = {
  rate: number;
  rhythm: RhythmType | string;
  strength?: number;
  alert?: string | null;
  noise?: number;
  flatline?: number;
  paused?: boolean;
};

const GRID_COLOR = 'rgba(30, 80, 30, 0.35)';
const TRACE_COLOR = '#33ff66';
const TRACE_GLOW = 'rgba(51, 255, 102, 0.4)';
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
    case 'asystole':
      return 'ASYSTOLE';
    case 'fibrillation':
      return 'FIBRILLATION';
    case 'arrhythmia':
      return 'ARRHYTHMIA';
    case 'pvc':
      return 'PVC';
    default:
      return rhythm.toUpperCase();
  }
};

function generateCycle(
  rhythm: string,
  samples: number,
  strength: number,
): Float32Array {
  const out = new Float32Array(samples);
  const s = Math.max(0.15, Math.min(strength, 1.5));
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
      if (t >= -1 && t <= 1)
        set(i, (out[i] || 0) + amplitude * (1 - Math.abs(t)));
    }
  };

  if (rhythm === 'asystole') {
    return out;
  }

  if (rhythm === 'fibrillation') {
    let phase = Math.random() * Math.PI * 2;
    for (let i = 0; i < samples; i++) {
      phase += 0.4 + Math.random() * 0.6;
      out[i] = Math.sin(phase) * (0.15 + Math.random() * 0.25) * s;
      out[i] += Math.sin(phase * 2.3) * 0.08 * s;
    }
    return out;
  }

  if (rhythm === 'ventricular_tachycardia') {
    const peak = samples * 0.35;
    spike(peak, samples * 0.35, -0.9 * s);
    spike(peak + samples * 0.08, samples * 0.2, 1.1 * s);
    spike(peak + samples * 0.18, samples * 0.25, -0.5 * s);
    return out;
  }

  spike(samples * 0.15, samples * 0.1, 0.15 * s);
  spike(samples * 0.28, samples * 0.04, -0.12 * s);
  spike(samples * 0.32, samples * 0.08, 1.0 * s);
  spike(samples * 0.38, samples * 0.06, -0.25 * s);
  spike(samples * 0.58, samples * 0.16, 0.28 * s);

  if (rhythm === 'pvc') {
    spike(samples * 0.75, samples * 0.2, -0.7 * s);
    spike(samples * 0.8, samples * 0.12, 0.9 * s);
  }

  if (rhythm === 'arrhythmia') {
    const shift = Math.floor((Math.random() - 0.5) * samples * 0.08);
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
    paused = false,
  } = props;

  const canvasRef = useRef<HTMLCanvasElement>(null);
  const rafRef = useRef<number>(0);
  const phaseRef = useRef(0);
  const bufferRef = useRef<Float32Array | null>(null);
  const samplesPerBeat = 120;

  const cycle = useMemo(
    () => generateCycle(rhythm, samplesPerBeat, strength),
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

    const bpm = Math.max(20, Math.min(rate || 80, 220));
    const pxPerSecond = 90;
    const beatDuration = 60 / bpm;
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

      ctx.strokeStyle = GRID_COLOR;
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
      ctx.strokeStyle = TRACE_COLOR;
      ctx.shadowColor = TRACE_GLOW;
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
        if (noise > 0) yVal += (Math.random() - 0.5) * noise * 0.4;

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

      ctx.fillStyle = TRACE_COLOR;
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
  }, [rate, rhythm, strength, noise, flatline, paused]);

  return (
    <div className="HealthPanel__cardiogram">
      <canvas ref={canvasRef} className="HealthPanel__cardiogram-canvas" />
      {alert && <div className="HealthPanel__cardiogram-alert">{alert}</div>}
      <div className="HealthPanel__cardiogram-label">{rhythmLabel(rhythm)}</div>
    </div>
  );
};
