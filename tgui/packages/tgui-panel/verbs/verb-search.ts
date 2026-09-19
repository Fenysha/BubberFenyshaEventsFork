import { atom } from 'jotai';
import { store } from '../events/store';
import { returnFocusToMap } from '../say/claim-focus';
import { useSettings } from '../settings/use-settings';

export type SearchVerb = {
  name: string;
  category: string;
  desc: string;
};

export const searchVerbsAtom = atom<SearchVerb[]>([]);
export const verbStatusAtom = atom<string[]>([]);
export const verbSearchOpenAtom = atom(false);

export function handleVerbSearchVerbs(payload: { verbs: SearchVerb[] }) {
  store.set(searchVerbsAtom, payload.verbs || []);
}

export function handleVerbSearchStatus(payload: { lines: string[] }) {
  store.set(verbStatusAtom, payload.lines || []);
}

export function handleVerbSearchOpen() {
  store.set(verbSearchOpenAtom, true);
}

/** Runs a verb the way the statpanel does, then hands focus back to the map. */
export function runVerb(name: string) {
  Byond.command(name.replace(/\s/g, '-'));
  returnFocusToMap();
}

export function usePinnedVerbs() {
  const { settings, updateSettings } = useSettings();
  const pinned = settings.pinnedVerbs;

  function togglePin(name: string) {
    updateSettings({
      pinnedVerbs: pinned.includes(name)
        ? pinned.filter((n) => n !== name)
        : [...pinned, name],
    });
  }

  /** Moves `name` into `target`'s place. */
  function movePin(name: string, target: string) {
    const from = pinned.indexOf(name);
    const to = pinned.indexOf(target);
    if (from < 0 || to < 0 || from === to) {
      return;
    }
    const next = [...pinned];
    next.splice(from, 1);
    next.splice(to, 0, name);
    updateSettings({ pinnedVerbs: next });
  }

  return { pinned, togglePin, movePin };
}
