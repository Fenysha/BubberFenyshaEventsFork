/**
 * Basically, hacks from goonchat which try to keep the map focused at all
 * times, except for when some meaningful action happens o
 *
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { focusMap } from 'tgui/focus';
import { canStealFocus, globalEvents } from 'tgui-core/events';
import { vecLength, vecSubtract } from 'tgui-core/vector';

// Empyrically determined number for the smallest possible
// text you can select with the mouse.
const MIN_SELECTION_DISTANCE = 10;

function deferredFocusMap(): void {
  setTimeout(focusMap);
}

export function setupPanelFocusHacks(): void {
  let focusStolen = false;
  let clickStartPos: number[] | null = null;

  window.addEventListener('focusin', (e) => {
    focusStolen = canStealFocus(e.target as HTMLElement);
  });

  window.addEventListener('mousedown', (e) => {
    clickStartPos = [e.screenX, e.screenY];
  });

  window.addEventListener('mouseup', (e) => {
    let dragged = false;
    if (clickStartPos) {
      const clickEndPos = [e.screenX, e.screenY];
      const dist = vecLength(vecSubtract(clickEndPos, clickStartPos));
      dragged = dist >= MIN_SELECTION_DISTANCE;
      if (dragged) {
        focusStolen = true;
      }
      if (document.activeElement?.className.includes('Button')) {
        focusStolen = true;
      }
    }
    // FENYSHA EDIT ADDITION BEGIN - TRANSPARENT_CHAT - over the map only the input bar keeps
    // focus, so reading the chat never takes the keyboard off the game. A drag keeps it, or
    // the selection could not be copied.
    const target = e.target as HTMLElement | null;
    if (document.body.classList.contains('onmap') && !dragged) {
      focusStolen = !!target?.closest?.('.Panel__inputBar');
    }
    // FENYSHA EDIT ADDITION END
    if (!focusStolen) {
      deferredFocusMap();
      return;
    }
    // FENYSHA EDIT ADDITION - TRANSPARENT_CHAT - keeping focus means BYOND never sees the key
    // ups for anything held, which strands movement keys down
    if (document.body.classList.contains('onmap')) {
      Byond.command('Reset-Held-Keys');
    }
  });

  globalEvents.on('keydown', (key) => {
    if (key.isModifierKey()) {
      return;
    }
    deferredFocusMap();
  });
}
