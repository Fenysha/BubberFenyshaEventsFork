/**
 * The say/whisper/me/OOC bar normally lives in the docked pane. When the chat floats over the
 * map, DM hosts that pane in a CHILD control on the mapwindow, and this keeps it under the chat.
 */

/// Hosts the chat pane over the map. This, not browseroutput, is what we move and resize.
export const CHAT_HOST_CHILD = 'chat_host';
export const INPUT_BAR_CHILD = 'chat_input';
export const INPUT_BAR_HEIGHT = 28;
// body.onmap insets the chat's visible frame, so butt the bar against that rather than
// the control's edge, which would leave a visible gap. Keep in step with ChatOnMap.scss.
const CHAT_FRAME_INSET = 4;

// Cached so a drag can reposition the bar without a winget round-trip per frame
let mapHeight = 0;

export function setInputBarMapHeight(height: number): void {
  mapHeight = height;
}

/** Places the bar directly under the chat, clamped so it stays on the map. */
export function positionInputBar(
  x: number,
  y: number,
  w: number,
  h: number,
): void {
  let top = y + h - CHAT_FRAME_INSET;
  if (mapHeight) {
    top = Math.min(top, mapHeight - INPUT_BAR_HEIGHT);
  }
  Byond.winset(INPUT_BAR_CHILD, {
    pos: `${Math.round(x)},${Math.round(Math.max(top, 0))}`,
    size: `${Math.round(w)}x${INPUT_BAR_HEIGHT}`,
  });
}

/** Parses the "x,y" / "WxH" pair a winset was about to send, then places the bar. */
export function positionInputBarFrom(pos: string, size: string): void {
  const [x, y] = pos.split(',').map(Number);
  const [w, h] = size.split('x').map(Number);
  if ([x, y, w, h].some(Number.isNaN)) {
    return;
  }
  positionInputBar(x, y, w, h);
}
