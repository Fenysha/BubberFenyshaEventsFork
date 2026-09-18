import { storage } from 'common/storage';

// Bumped to throw away rects saved while the control's geometry was still wrong - they park
// the chat across a big slice of the map on load with no obvious way to recover
const STORAGE_KEY = 'chat-placement-ratio-v2';

export type ChatRatio = {
  x: number;
  y: number;
  w: number;
  h: number;
};

export async function loadChatRatio(): Promise<ChatRatio | null> {
  try {
    return await storage.get(STORAGE_KEY);
  } catch {
    return null;
  }
}

/** Stores the chat's placement as a fraction of the map, so it survives resolution changes. */
export function saveChatRatio(): void {
  Promise.all([
    Byond.winget('browseroutput', ['pos', 'size']),
    Byond.winget('mapwindow', ['size']),
  ]).then(([browser, map]) => {
    const mapW = map.size.x;
    const mapH = map.size.y;
    if (!mapW || !mapH) {
      return;
    }
    storage.set(STORAGE_KEY, {
      x: browser.pos.x / mapW,
      y: browser.pos.y / mapH,
      w: browser.size.x / mapW,
      h: browser.size.y / mapH,
    } satisfies ChatRatio);
  });
}
