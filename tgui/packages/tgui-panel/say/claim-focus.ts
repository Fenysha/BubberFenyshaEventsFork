const CLAIM_WINDOW_MS = 1000;
const CLAIM_INTERVAL_MS = 50;

/**
 * Focuses an input in the chat and keeps it focused for a moment. When a hotkey on the map
 * opens it, BYOND hands focus back to the map while that key is still going down/up, so a
 * single focus call made straight away is lost. Returns a cancel function.
 */
export function claimFocus(getInput: () => HTMLElement | null): () => void {
  const started = Date.now();
  let timer: ReturnType<typeof setTimeout> | undefined;

  const attempt = () => {
    const input = getInput();
    if (!input) {
      return;
    }
    if (!document.hasFocus() || document.activeElement !== input) {
      Byond.winset('browseroutput', { focus: true });
      window.focus();
      input.focus();
    }
    if (Date.now() - started < CLAIM_WINDOW_MS) {
      timer = setTimeout(attempt, CLAIM_INTERVAL_MS);
    }
  };

  attempt();
  return () => clearTimeout(timer);
}

/**
 * Hands focus back to the map. Keys released while the chat had focus never reach the map, so
 * the server still thinks they're held - a stuck Ctrl from Ctrl+K turns every later T into
 * Ctrl+T. The Escape macro clears them the same way.
 */
export function returnFocusToMap() {
  Byond.command('Reset-Held-Keys');
  Byond.winset('map', { focus: true });
}
