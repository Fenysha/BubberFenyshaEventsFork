// Floaters, sparks and orbs drawn over the page, plus a small synth for feedback tones

type Point = { x: number; y: number };

function centre(el: Element): Point {
  const rect = el.getBoundingClientRect();
  return { x: rect.left + rect.width / 2, y: rect.top + rect.height / 2 };
}

function spawn(className: string): HTMLDivElement {
  const el = document.createElement('div');
  el.className = className;
  document.body.appendChild(el);
  return el;
}

export function floatText(
  text: string,
  from: Element | null,
  color = '#f3f3f0',
  size = 16,
) {
  if (!from) {
    return;
  }
  const p = centre(from);
  const el = spawn('MinigameFx-floater');
  el.textContent = text;
  el.style.color = color;
  el.style.fontSize = `${size}px`;
  el.style.left = `${p.x}px`;
  el.style.top = `${p.y}px`;
  el.animate(
    [
      { transform: 'translate(-50%,-50%) scale(.6)', opacity: 0 },
      { transform: 'translate(-50%,-90%) scale(1.1)', opacity: 1, offset: 0.2 },
      { transform: 'translate(-50%,-240%)', opacity: 0 },
    ],
    { duration: 1000, easing: 'ease-out' },
  ).onfinish = () => el.remove();
}

export function burst(
  from: Element | null,
  color: string,
  count = 12,
  spread = 50,
) {
  if (!from) {
    return;
  }
  const p = centre(from);
  for (let i = 0; i < count; i++) {
    const el = spawn('MinigameFx-spark');
    el.style.background = color;
    el.style.boxShadow = `0 0 6px ${color}`;
    const angle = Math.random() * Math.PI * 2;
    const dist = spread * (0.4 + Math.random() * 0.8);
    el.animate(
      [
        { transform: `translate(${p.x}px,${p.y}px)`, opacity: 1 },
        {
          transform: `translate(${p.x + Math.cos(angle) * dist}px,${p.y + Math.sin(angle) * dist}px) scale(.2)`,
          opacity: 0,
        },
      ],
      {
        duration: 450 + Math.random() * 300,
        easing: 'cubic-bezier(.1,.8,.3,1)',
      },
    ).onfinish = () => el.remove();
  }
}

/** Orbs that curve from a tile into the progress bar, landing at `fraction` of its width */
export function orbs(
  from: Element | null,
  bar: Element | null,
  fraction: number,
  count: number,
  onLand?: (index: number) => void,
) {
  if (!from || !bar) {
    return;
  }
  const start = centre(from);
  const rect = bar.getBoundingClientRect();
  const end = {
    x: rect.left + rect.width * Math.min(1, Math.max(0, fraction)),
    y: rect.top + rect.height / 2,
  };
  for (let i = 0; i < count; i++) {
    const el = spawn('MinigameFx-orb');
    const ctrl = {
      x: start.x + (Math.random() - 0.5) * 160,
      y: start.y + (Math.random() - 0.5) * 120,
    };
    const frames: Keyframe[] = [];
    for (let k = 0; k <= 12; k++) {
      const t = k / 12;
      const u = 1 - t;
      const x = u * u * start.x + 2 * u * t * ctrl.x + t * t * end.x;
      const y = u * u * start.y + 2 * u * t * ctrl.y + t * t * end.y;
      frames.push({
        transform: `translate(${x}px,${y}px) scale(${1.3 - t * 0.7})`,
      });
    }
    el.animate(frames, {
      duration: 600 + Math.random() * 200,
      delay: i * 35,
      easing: 'cubic-bezier(.45,0,.9,.6)',
    }).onfinish = () => {
      el.remove();
      onLand?.(i);
    };
  }
}

export function shake(el: Element | null) {
  if (!el) {
    return;
  }
  el.classList.remove('MinigameShake');
  void (el as HTMLElement).offsetWidth;
  el.classList.add('MinigameShake');
}

let audio: AudioContext | null = null;

export function tone(
  freq: number,
  duration = 0.08,
  type: OscillatorType = 'triangle',
  volume = 0.05,
  slide = 0,
) {
  try {
    audio = audio || new AudioContext();
    const t = audio.currentTime;
    const osc = audio.createOscillator();
    const gain = audio.createGain();
    osc.type = type;
    osc.frequency.setValueAtTime(freq, t);
    if (slide) {
      osc.frequency.exponentialRampToValueAtTime(freq * slide, t + duration);
    }
    gain.gain.setValueAtTime(0.0001, t);
    gain.gain.exponentialRampToValueAtTime(volume, t + 0.008);
    gain.gain.exponentialRampToValueAtTime(0.0001, t + duration);
    osc.connect(gain);
    gain.connect(audio.destination);
    osc.start(t);
    osc.stop(t + duration + 0.03);
  } catch {
    // No audio device; play silently
  }
}

/** Notes played one after another */
export function arpeggio(freqs: number[], stepMs: number, volume: number) {
  freqs.forEach((freq, i) => {
    setTimeout(() => tone(freq, 0.3, 'triangle', volume), i * stepMs);
  });
}
