// FENYSHA ADDITION - TRANSPARENT_CHAT - shrinks the chat control to what is on screen, so the
// map takes clicks everywhere else

type PlacedRect = {
  x: number;
  y: number;
  w: number;
  h: number;
  mapW: number;
  mapH: number;
};

const CONTENT_SLACK = 8;
const SHRINK_DELAY = 250;

let placed: PlacedRect | null = null;
let appliedHeight: number | null = null;
let shrinkTimer: ReturnType<typeof setTimeout> | null = null;
let pendingShrink: number | null = null;

export function setAnchors(
  browserX: number,
  browserY: number,
  browserW: number,
  browserH: number,
  mapW: number,
  mapH: number,
): void {
  Byond.winset('browseroutput', {
    anchor1: `${((browserX / mapW) * 100).toFixed(2)},${((browserY / mapH) * 100).toFixed(2)}`,
    anchor2: `${(((browserX + browserW) / mapW) * 100).toFixed(2)},${(((browserY + browserH) / mapH) * 100).toFixed(2)}`,
  });
}

export function setPlacedRect(rect: PlacedRect): void {
  placed = rect;
  appliedHeight = rect.h;
}

/** Re-reads the control after the player has dragged or resized it. */
export function syncPlacedRect(): void {
  Promise.all([
    Byond.winget('browseroutput', ['pos', 'size']),
    Byond.winget('mapwindow', ['size']),
  ]).then(([browser, map]) => {
    if (!browser?.size?.x || !map?.size?.x) {
      return;
    }
    setPlacedRect({
      x: browser.pos.x,
      y: browser.pos.y,
      w: browser.size.x,
      h: browser.size.y,
      mapW: map.size.x,
      mapH: map.size.y,
    });
  });
}

function measureContentHeight(): number {
  const bar = document.querySelector<HTMLElement>('.Panel__inputBar');
  if (!bar) {
    return 0;
  }
  const pane = document.getElementById('chat-pane');
  const scrolled = pane ? pane.scrollTop : 0;
  let bottom = bar.getBoundingClientRect().bottom;
  const lit = document.querySelectorAll<HTMLElement>(
    '.ChatMessage--recent, .ChatMessage--fading, .CommandBar__suggestions',
  );
  for (const message of lit) {
    const rect = message.getBoundingClientRect();
    if (rect.height > 0) {
      bottom = Math.max(bottom, rect.bottom + scrolled);
    }
  }
  return Math.ceil((bottom + CONTENT_SLACK) * (window.devicePixelRatio || 1));
}

function resize(height: number): void {
  if (!placed || height === appliedHeight) {
    return;
  }
  const { x, y, w, mapW, mapH } = placed;
  appliedHeight = height;
  Byond.winset('browseroutput', { size: `${w}x${height}` });
  setAnchors(x, y, w, height, mapW, mapH);
}

export function applyCollapse(collapsed: boolean): void {
  if (!placed) {
    return;
  }
  const pane = document.getElementById('chat-pane');
  if (collapsed && pane) {
    pane.scrollTop = 0;
  }
  const height = collapsed
    ? Math.min(Math.max(measureContentHeight(), 1), placed.h)
    : placed.h;

  if (appliedHeight === null || height >= appliedHeight) {
    if (shrinkTimer) {
      clearTimeout(shrinkTimer);
      shrinkTimer = null;
      pendingShrink = null;
    }
    resize(height);
    return;
  }
  if (shrinkTimer && pendingShrink === height) {
    return;
  }
  if (shrinkTimer) {
    clearTimeout(shrinkTimer);
  }
  pendingShrink = height;
  shrinkTimer = setTimeout(() => {
    shrinkTimer = null;
    const target = pendingShrink;
    pendingShrink = null;
    if (target !== null) {
      resize(target);
    }
  }, SHRINK_DELAY);
}
