import { atom } from 'jotai';
import type { Channel } from '../../tgui-say/ChannelIterator';
import { store } from '../events/store';

/**
 * Set while a speech hotkey has the input bar standing in for tgui-say. `summoned` changes on
 * every hotkey press, `opened` only when a fresh session starts.
 */
export const saySessionAtom = atom<{
  channel: Channel;
  opened: number;
  summoned: number;
} | null>(null);
export const sayMaxLengthAtom = atom(1024);
/** Bumped by DM asking for the typed text: force-say, save, or close. */
export const sayForceAtom = atom(0);
export const saySaveAtom = atom(0);
export const sayCloseAtom = atom(0);
/** Text handed to the command bar when the say prefix is deleted. */
export const commandBarSeedAtom = atom<{ text: string; n: number } | null>(
  null,
);

export function handleSayOpen(payload: { channel: Channel }) {
  const channel = payload?.channel ?? 'Say';
  const now = Date.now();
  const session = store.get(saySessionAtom);
  // Pressing a speech hotkey again, e.g. after clicking away, returns to the message in progress
  store.set(saySessionAtom, {
    channel,
    opened: session?.opened ?? now,
    summoned: now,
  });
}

export function handleSayProps(payload: { maxLength: number }) {
  if (payload?.maxLength) {
    store.set(sayMaxLengthAtom, payload.maxLength);
  }
}

export function handleSayForce() {
  store.set(sayForceAtom, (n) => n + 1);
}

export function handleSaySave() {
  store.set(saySaveAtom, (n) => n + 1);
}

export function handleSayClose() {
  store.set(sayCloseAtom, (n) => n + 1);
}
