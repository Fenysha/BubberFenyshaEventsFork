import { useAtomValue } from 'jotai';
import { useEffect, useState } from 'react';
import { settingsAtom } from '../settings/atoms';
import type { ChatCorner } from '../settings/constants';
import { setClientTheme } from '../settings/themes';
import { loadChatRatio, saveChatRatio } from './chat-ratio';
import { clampToMap } from './ResizeHandles';

const DEFAULT_W_RATIO = 1 / 3;
const DEFAULT_H_RATIO = 1 / 3;
// A stored ratio outlives the code that wrote it, so treat it as untrusted rather than
// letting a bad one park the chat across half the map with no obvious way back
const MIN_SIDE_RATIO = 0.12;
const MAX_SIDE_RATIO = 0.75;

function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max);
}

function isUsableRatio(value: unknown): value is number {
  return typeof value === 'number' && Number.isFinite(value);
}

// Remembered across renders so we can tell a settings change from the first placement,
// which should restore the saved ratio rather than snap back to a corner.
let lastCorner: ChatCorner | null = null;
let lastPadding: number | null = null;

function defaultPosition(
  corner: ChatCorner,
  mapW: number,
  mapH: number,
  browserW: number,
  browserH: number,
  padding: number,
): { x: number; y: number } {
  switch (corner) {
    case 'top-left':
      return { x: padding, y: padding };
    case 'bottom-left':
      return { x: padding, y: mapH - (browserH + padding) };
    case 'bottom-right':
      return { x: mapW - (browserW + padding), y: mapH - (browserH + padding) };
    default:
      return { x: mapW - (browserW + padding), y: padding };
  }
}

/** Anchors are percentages of the map, so the chat keeps its place when the window resizes. */
function setAnchors(
  browserX: number,
  browserY: number,
  browserW: number,
  browserH: number,
  mapW: number,
  mapH: number,
) {
  Byond.winset('browseroutput', {
    anchor1: `${((browserX / mapW) * 100).toFixed(2)},${((browserY / mapH) * 100).toFixed(2)}`,
    anchor2: `${(((browserX + browserW) / mapW) * 100).toFixed(2)},${(((browserY + browserH) / mapH) * 100).toFixed(2)}`,
  });
}

/**
 * Positions the chat browser for whichever layout DM put it in, and reports the resulting
 * rect back so the HUD can move its screen objects out of the way.
 */
export function useChatPlacement() {
  const [layout, setLayout] = useState<string | null>(null);
  const settings = useAtomValue(settingsAtom);
  const chatCorner = (settings.chatCorner || 'top-right') as ChatCorner;
  const chatOpacity = settings.chatOpacity ?? 0.45;
  const chatPadding = settings.chatPadding ?? 10;

  const isOnMap = layout === 'onmap';
  const isPopup = layout === 'window';

  // Drives the frameless message backdrop. BYOND exposes no working transparency for a
  // browser control, so the chat itself cannot be made see-through over the map.
  useEffect(() => {
    document.body.style.setProperty('--chat-opacity', `${chatOpacity}`);
  }, [chatOpacity]);

  // DM owns the layout. Asking beats inspecting the control's parent, which does not
  // reliably read back as the plain window name we set.
  useEffect(() => {
    Byond.subscribeTo('panel/layout', (payload: { layout: string }) => {
      setLayout(payload?.layout ?? null);
    });
    Byond.sendMessage('panel/request_layout');
  }, []);

  useEffect(() => {
    if (!layout) {
      return;
    }

    const settingChanged =
      (lastCorner !== null && lastCorner !== chatCorner) ||
      (lastPadding !== null && lastPadding !== chatPadding);
    lastCorner = chatCorner;
    lastPadding = chatPadding;

    if (layout !== 'onmap') {
      document.body.classList.remove('onmap');
      document.body.style.backgroundColor = '';
      document.documentElement.style.backgroundColor = '';
      if (layout === 'panel') {
        // Unhide the docked chat pane, which skin.dmf leaves pointing at output_legacy
        Byond.winset('output_selector.legacy_output_selector', {
          left: 'output_browser',
        });
        setClientTheme(settings.theme);
      }
      return;
    }

    const markOnMap = () => {
      document.body.classList.add('onmap');
      // The theme paints body, and html is left to whatever the webview defaults to (white),
      // so both have to be cleared for the map to show through
      document.body.style.backgroundColor = 'transparent';
      document.documentElement.style.backgroundColor = 'transparent';
    };

    const place = (x: number, y: number, w: number, h: number) => {
      Byond.sendMessage('panel/bounds', { x, y, w, h });
    };

    Byond.winget('mapwindow', ['size']).then((map) => {
      const mapW = map.size.x;
      const mapH = map.size.y;

      if (settingChanged) {
        Byond.winget('browseroutput', ['size']).then((props) => {
          const pos = defaultPosition(
            chatCorner,
            mapW,
            mapH,
            props.size.x,
            props.size.y,
            chatPadding,
          );
          // Padding can push a large chat past the far edge
          const [x, y, browserW, browserH] = clampToMap(
            pos.x,
            pos.y,
            props.size.x,
            props.size.y,
            mapW,
            mapH,
            true,
          );
          Byond.winset('browseroutput', {
            pos: `${x},${y}`,
            size: `${browserW}x${browserH}`,
          });
          setAnchors(x, y, browserW, browserH, mapW, mapH);
          saveChatRatio();
          place(x, y, browserW, browserH);
          markOnMap();
        });
        return;
      }

      loadChatRatio().then((saved) => {
        let browserW: number;
        let browserH: number;
        let browserX: number;
        let browserY: number;

        const usable =
          saved &&
          isUsableRatio(saved.w) &&
          isUsableRatio(saved.h) &&
          isUsableRatio(saved.x) &&
          isUsableRatio(saved.y);

        if (usable) {
          const wRatio = clamp(saved.w, MIN_SIDE_RATIO, MAX_SIDE_RATIO);
          const hRatio = clamp(saved.h, MIN_SIDE_RATIO, MAX_SIDE_RATIO);
          browserW = Math.round(mapW * wRatio);
          browserH = Math.round(mapH * hRatio);
          // Keep it fully on the map whatever was stored
          browserX = Math.round(mapW * clamp(saved.x, 0, 1 - wRatio));
          browserY = Math.round(mapH * clamp(saved.y, 0, 1 - hRatio));
        } else {
          browserW = Math.round(mapW * DEFAULT_W_RATIO);
          browserH = Math.round(mapH * DEFAULT_H_RATIO);
          const pos = defaultPosition(
            chatCorner,
            mapW,
            mapH,
            browserW,
            browserH,
            chatPadding,
          );
          browserX = pos.x;
          browserY = pos.y;
        }

        Byond.winset('browseroutput', {
          size: `${browserW}x${browserH}`,
          pos: `${browserX},${browserY}`,
        });
        setAnchors(browserX, browserY, browserW, browserH, mapW, mapH);
        place(browserX, browserY, browserW, browserH);
        markOnMap();
      });
    });
  }, [layout, chatCorner, chatPadding, settings.theme]);

  return { isOnMap, isPopup, chatCorner };
}
