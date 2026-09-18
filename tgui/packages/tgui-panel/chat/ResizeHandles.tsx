import type { ChatCorner } from '../settings/constants';
import { saveChatRatio } from './chat-ratio';

const pixelRatio = window.devicePixelRatio ?? 1;
const MIN_WIDTH = 200;
const MIN_HEIGHT = 100;

type Point = [number, number];
type WinsetGeometry = { pos?: string; size?: string };

let winsetTarget = 'browseroutput';
let pendingWinset: WinsetGeometry = {};
// Map size captured at drag start. Null for the popup, which is its own window.
let dragBounds: Point | null = null;
let winsetRaf: number | undefined;

// winset round-trips to BYOND, so coalesce a drag's worth of updates into one per frame
function flushWinset() {
  winsetRaf = undefined;
  if (pendingWinset.pos || pendingWinset.size) {
    Byond.winset(winsetTarget, pendingWinset);
    pendingWinset = {};
  }
}

/**
 * Keeps the rect entirely on the map. A move slides the whole rect back in; a resize clips
 * the dragged edge, so the opposite edge stays where it was.
 */
export function clampToMap(
  x: number,
  y: number,
  w: number,
  h: number,
  mapW: number,
  mapH: number,
  move: boolean,
): [number, number, number, number] {
  const clampAxis = (start: number, len: number, max: number) => {
    if (move) {
      const clampedLen = Math.min(len, max);
      return [
        Math.min(Math.max(start, 0), max - clampedLen),
        clampedLen,
      ] as const;
    }
    const lo = Math.max(start, 0);
    const hi = Math.min(start + len, max);
    return [lo, Math.max(hi - lo, 0)] as const;
  };
  const [cx, cw] = clampAxis(x, w, mapW);
  const [cy, ch] = clampAxis(y, h, mapH);
  return [cx, cy, cw, ch];
}

/** Both halves every time, so the input bar can always be derived from the pending rect. */
function applyGeometry(pos: string, size: string, move = false) {
  if (dragBounds) {
    const [x, y] = pos.split(',').map(Number);
    const [w, h] = size.split('x').map(Number);
    const [cx, cy, cw, ch] = clampToMap(
      x,
      y,
      w,
      h,
      dragBounds[0],
      dragBounds[1],
      move,
    );
    pos = `${cx},${cy}`;
    size = `${cw}x${ch}`;
  }
  pendingWinset.pos = pos;
  pendingWinset.size = size;
  scheduleWinset();
}

function scheduleWinset() {
  if (winsetRaf === undefined) {
    winsetRaf = requestAnimationFrame(flushWinset);
  }
}

function sendBounds() {
  Byond.winget(winsetTarget, ['pos', 'size']).then((props) => {
    Byond.sendMessage('panel/bounds', {
      x: props.pos.x,
      y: props.pos.y,
      w: props.size.x,
      h: props.size.y,
    });
  });
}

function updateAnchors() {
  if (winsetTarget !== 'browseroutput') {
    return;
  }
  Promise.all([
    Byond.winget('browseroutput', ['pos', 'size']),
    Byond.winget('mapwindow', ['size']),
  ]).then(([browser, map]) => {
    const mapW = map.size.x;
    const mapH = map.size.y;
    if (!mapW || !mapH) {
      return;
    }
    Byond.winset('browseroutput', {
      anchor1: `${((browser.pos.x / mapW) * 100).toFixed(2)},${((browser.pos.y / mapH) * 100).toFixed(2)}`,
      anchor2: `${(((browser.pos.x + browser.size.x) / mapW) * 100).toFixed(2)},${(((browser.pos.y + browser.size.y) / mapH) * 100).toFixed(2)}`,
    });
  });
}

function endDragBatch() {
  if (winsetRaf !== undefined) {
    cancelAnimationFrame(winsetRaf);
    winsetRaf = undefined;
  }
  flushWinset();
  updateAnchors();
  saveChatRatio();
  sendBounds();
}

/**
 * Drags via pointer capture rather than document listeners. The chat sits over the map, which
 * is a separate BYOND control - once the pointer leaves the webview the page stops receiving
 * events, so a document-level pointerup never arrives and the drag sticks to the cursor.
 * Capture keeps the events coming until release.
 *
 * Listeners are attached synchronously too: winget is a round-trip to BYOND, and a quick click
 * could finish before a listener registered inside its callback ever existed.
 */
function startDrag(
  e: React.PointerEvent,
  onMove: (dx: number, dy: number, startPos: Point, startSize: Point) => void,
) {
  e.preventDefault();
  const target = e.currentTarget as HTMLElement;
  const { pointerId } = e;
  const startMouseX = e.screenX * pixelRatio;
  const startMouseY = e.screenY * pixelRatio;

  let startPos: Point | null = null;
  let startSize: Point | null = null;
  let latest: PointerEvent | null = null;
  let finished = false;

  try {
    target.setPointerCapture(pointerId);
  } catch {
    // Capture is best-effort; the listeners below still work without it
  }

  const apply = (ev: PointerEvent) => {
    if (!startPos || !startSize) {
      return;
    }
    onMove(
      ev.screenX * pixelRatio - startMouseX,
      ev.screenY * pixelRatio - startMouseY,
      startPos,
      startSize,
    );
  };

  const handleMove = (ev: PointerEvent) => {
    if (ev.pointerId !== pointerId) {
      return;
    }
    ev.preventDefault();
    latest = ev;
    apply(ev);
  };

  const finish = (ev: PointerEvent) => {
    if (finished || ev.pointerId !== pointerId) {
      return;
    }
    finished = true;
    if (latest) {
      apply(latest);
    }
    target.removeEventListener('pointermove', handleMove);
    target.removeEventListener('pointerup', finish);
    target.removeEventListener('pointercancel', finish);
    target.removeEventListener('lostpointercapture', finish);
    try {
      target.releasePointerCapture(pointerId);
    } catch {
      // Already released
    }
    endDragBatch();
  };

  target.addEventListener('pointermove', handleMove);
  target.addEventListener('pointerup', finish);
  target.addEventListener('pointercancel', finish);
  // Fires if the browser takes capture away, e.g. the window loses focus mid-drag
  target.addEventListener('lostpointercapture', finish);

  dragBounds = null;
  const onMap = winsetTarget === 'browseroutput';
  Promise.all([
    Byond.winget(winsetTarget, ['pos', 'size']),
    onMap ? Byond.winget('mapwindow', ['size']) : Promise.resolve(null),
  ]).then(([props, map]) => {
    if (finished) {
      return;
    }
    if (map?.size.x && map?.size.y) {
      dragBounds = [map.size.x, map.size.y];
    }
    startPos = [props.pos.x, props.pos.y];
    startSize = [props.size.x, props.size.y];
    if (latest) {
      apply(latest);
    }
  });
}

function resizeLeft(dx: number, startPos: Point, startSize: Point) {
  const newW = Math.max(startSize[0] - dx, MIN_WIDTH);
  return {
    pos: `${startPos[0] + (startSize[0] - newW)},${startPos[1]}`,
    size: `${newW}x${startSize[1]}`,
  };
}

function resizeRight(dx: number, startPos: Point, startSize: Point) {
  return { size: `${Math.max(startSize[0] + dx, MIN_WIDTH)}x${startSize[1]}` };
}

function resizeTop(dy: number, startPos: Point, startSize: Point) {
  const newH = Math.max(startSize[1] - dy, MIN_HEIGHT);
  return {
    pos: `${startPos[0]},${startPos[1] + (startSize[1] - newH)}`,
    size: `${startSize[0]}x${newH}`,
  };
}

function resizeBottom(dy: number, startPos: Point, startSize: Point) {
  return { size: `${startSize[0]}x${Math.max(startSize[1] + dy, MIN_HEIGHT)}` };
}

type EdgeResizer = (
  delta: number,
  startPos: Point,
  startSize: Point,
) => WinsetGeometry & { size: string };

function makeEdgeHandler(resize: EdgeResizer, axis: 'x' | 'y') {
  return (e: React.PointerEvent) =>
    startDrag(e, (dx, dy, startPos, startSize) => {
      const result = resize(axis === 'x' ? dx : dy, startPos, startSize);
      applyGeometry(result.pos ?? `${startPos[0]},${startPos[1]}`, result.size);
    });
}

function makeCornerHandler(horizontal: EdgeResizer, vertical: EdgeResizer) {
  return (e: React.PointerEvent) =>
    startDrag(e, (dx, dy, startPos, startSize) => {
      const hResult = horizontal(dx, startPos, startSize);
      const vResult = vertical(dy, startPos, startSize);
      const newX = hResult.pos?.split(',')[0] ?? `${startPos[0]}`;
      const newY = vResult.pos?.split(',')[1] ?? `${startPos[1]}`;
      applyGeometry(
        `${newX},${newY}`,
        `${hResult.size.split('x')[0]}x${vResult.size.split('x')[1]}`,
      );
    });
}

/** Drags the detached chat window by its bar. */
export function startPopupMove(e: React.PointerEvent) {
  winsetTarget = 'tgui_panel_popup';
  startDrag(e, (dx, dy, startPos, startSize) => {
    applyGeometry(
      `${startPos[0] + dx},${startPos[1] + dy}`,
      `${startSize[0]}x${startSize[1]}`,
    );
  });
}

/** Drags the whole on-map chat around. startDrag saves the ratio and reports bounds on release. */
export function startChatMove(e: React.PointerEvent) {
  winsetTarget = 'browseroutput';
  startDrag(e, (dx, dy, startPos, startSize) => {
    applyGeometry(
      `${startPos[0] + dx},${startPos[1] + dy}`,
      `${startSize[0]}x${startSize[1]}`,
      true,
    );
  });
}

type Props = {
  corner?: ChatCorner;
  target?: string;
  allEdges?: boolean;
};

export function ResizeHandles({
  corner,
  target = 'browseroutput',
  allEdges = false,
}: Props) {
  winsetTarget = target;

  if (allEdges) {
    return (
      <>
        <div
          className="ResizeHandle ResizeHandle--left"
          onPointerDown={makeEdgeHandler(resizeLeft, 'x')}
        />
        <div
          className="ResizeHandle ResizeHandle--right"
          onPointerDown={makeEdgeHandler(resizeRight, 'x')}
        />
        <div
          className="ResizeHandle ResizeHandle--top"
          onPointerDown={makeEdgeHandler(resizeTop, 'y')}
        />
        <div
          className="ResizeHandle ResizeHandle--bottom"
          onPointerDown={makeEdgeHandler(resizeBottom, 'y')}
        />
        <div
          className="ResizeHandle ResizeHandle--top-left"
          style={{ cursor: 'nwse-resize' }}
          onPointerDown={makeCornerHandler(resizeLeft, resizeTop)}
        />
        <div
          className="ResizeHandle ResizeHandle--top-right"
          style={{ cursor: 'nesw-resize' }}
          onPointerDown={makeCornerHandler(resizeRight, resizeTop)}
        />
        <div
          className="ResizeHandle ResizeHandle--bottom-left"
          style={{ cursor: 'nesw-resize' }}
          onPointerDown={makeCornerHandler(resizeLeft, resizeBottom)}
        />
        <div
          className="ResizeHandle ResizeHandle--bottom-right"
          style={{ cursor: 'nwse-resize' }}
          onPointerDown={makeCornerHandler(resizeRight, resizeBottom)}
        />
      </>
    );
  }

  // Anchored into a corner of the map, so only the two inward edges can be dragged
  const isLeft = corner?.includes('left') ?? false;
  const isTop = corner?.includes('top') ?? true;
  const hEdge = isLeft ? 'right' : 'left';
  const vEdge = isTop ? 'bottom' : 'top';
  const diagonalCursor =
    (isTop && isLeft) || (!isTop && !isLeft) ? 'nwse-resize' : 'nesw-resize';

  return (
    <>
      <div
        className={`ResizeHandle ResizeHandle--${hEdge}`}
        onPointerDown={makeEdgeHandler(isLeft ? resizeRight : resizeLeft, 'x')}
      />
      <div
        className={`ResizeHandle ResizeHandle--${vEdge}`}
        onPointerDown={makeEdgeHandler(isTop ? resizeBottom : resizeTop, 'y')}
      />
      <div
        className={`ResizeHandle ResizeHandle--${vEdge}-${hEdge}`}
        style={{ cursor: diagonalCursor }}
        onPointerDown={makeCornerHandler(
          isLeft ? resizeRight : resizeLeft,
          isTop ? resizeBottom : resizeTop,
        )}
      />
    </>
  );
}
