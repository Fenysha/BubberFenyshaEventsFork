import { useAtom, useAtomValue } from 'jotai';
import {
  type KeyboardEvent,
  type ReactNode,
  useEffect,
  useMemo,
  useRef,
  useState,
} from 'react';
import { claimFocus, returnFocusToMap } from '../say/claim-focus';
import {
  runVerb,
  type SearchVerb,
  searchVerbsAtom,
  usePinnedVerbs,
  verbSearchOpenAtom,
  verbStatusAtom,
} from './verb-search';

const ALL = 'All';
const STATUS_REFRESH_MS = 2000;

type Group = { title: string; verbs: SearchVerb[] };

function score(verb: SearchVerb, query: string): number {
  if (!query) {
    return 1;
  }
  const name = verb.name.toLowerCase();
  if (name.startsWith(query)) {
    return 3;
  }
  if (name.includes(query)) {
    return 2;
  }
  if (verb.desc?.toLowerCase().includes(query)) {
    return 1;
  }
  return 0;
}

function highlight(text: string, query: string): ReactNode {
  const index = query ? text.toLowerCase().indexOf(query) : -1;
  if (index < 0) {
    return text;
  }
  return (
    <>
      {text.slice(0, index)}
      <mark>{text.slice(index, index + query.length)}</mark>
      {text.slice(index + query.length)}
    </>
  );
}

function buildGroups(
  verbs: SearchVerb[],
  pinned: string[],
  query: string,
  category: string,
): Group[] {
  const groups: Group[] = [];
  const pinnedSet = new Set(pinned);
  const showPinned = !query && category === ALL && pinned.length > 0;

  if (showPinned) {
    const byName = new Map(verbs.map((v) => [v.name, v]));
    groups.push({
      title: 'Pinned',
      // A pin outlives the verb, e.g. after changing mobs, so keep it listed to unpin
      verbs: pinned.map(
        (name) =>
          byName.get(name) ?? {
            name,
            category: '',
            desc: 'Not available right now',
          },
      ),
    });
  }

  const byCategory = new Map<string, SearchVerb[]>();
  for (const verb of verbs) {
    if (category !== ALL && verb.category !== category) {
      continue;
    }
    if (showPinned && pinnedSet.has(verb.name)) {
      continue;
    }
    if (score(verb, query) === 0) {
      continue;
    }
    const list = byCategory.get(verb.category) ?? [];
    list.push(verb);
    byCategory.set(verb.category, list);
  }

  const rank = (v: SearchVerb) =>
    score(v, query) + (pinnedSet.has(v.name) ? 0.5 : 0);
  for (const title of [...byCategory.keys()].sort()) {
    const list = byCategory.get(title)!;
    list.sort((a, b) => rank(b) - rank(a) || a.name.localeCompare(b.name));
    groups.push({ title, verbs: list });
  }
  return groups;
}

/** Search every verb the player has, run one, or pin it above the chat. */
export function VerbSearch() {
  const [open, setOpen] = useAtom(verbSearchOpenAtom);
  const verbs = useAtomValue(searchVerbsAtom);
  const status = useAtomValue(verbStatusAtom);
  const { pinned, togglePin } = usePinnedVerbs();
  const [query, setQuery] = useState('');
  const [category, setCategory] = useState(ALL);
  const [selected, setSelected] = useState(0);
  const inputRef = useRef<HTMLInputElement>(null);
  const listRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    Byond.sendMessage('verbsearch/request');
  }, []);

  useEffect(() => {
    const onKeyDown = (e: globalThis.KeyboardEvent) => {
      if (e.ctrlKey && e.key.toLowerCase() === 'k') {
        e.preventDefault();
        setOpen((o) => !o);
      }
    };
    document.addEventListener('keydown', onKeyDown);
    return () => document.removeEventListener('keydown', onKeyDown);
  }, []);

  useEffect(() => {
    if (!open) {
      return;
    }
    setQuery('');
    setCategory(ALL);
    setSelected(0);
    Byond.sendMessage('verbsearch/request_status');
    const timer = setInterval(
      () => Byond.sendMessage('verbsearch/request_status'),
      STATUS_REFRESH_MS,
    );
    const release = claimFocus(() => inputRef.current);
    return () => {
      clearInterval(timer);
      release();
    };
  }, [open]);

  const categories = useMemo(
    () => [ALL, ...[...new Set(verbs.map((v) => v.category))].sort()],
    [verbs],
  );
  const term = query.trim().toLowerCase();
  const groups = useMemo(
    () => buildGroups(verbs, pinned, term, category),
    [verbs, pinned, term, category],
  );
  const flat = useMemo(() => groups.flatMap((g) => g.verbs), [groups]);
  const current = Math.min(selected, Math.max(flat.length - 1, 0));

  useEffect(() => {
    listRef.current
      ?.querySelector('.VerbSearch__row--selected')
      ?.scrollIntoView({ block: 'nearest' });
  }, [current, open]);

  if (!open) {
    return null;
  }

  const close = () => {
    setOpen(false);
    returnFocusToMap();
  };

  const run = (verb: SearchVerb | undefined) => {
    if (!verb) {
      return;
    }
    setOpen(false);
    runVerb(verb.name);
  };

  const cycleCategory = (step: number) => {
    const index = categories.indexOf(category);
    setCategory(
      categories[(index + step + categories.length) % categories.length],
    );
    setSelected(0);
  };

  const handleKeyDown = (e: KeyboardEvent<HTMLInputElement>) => {
    switch (e.key) {
      case 'ArrowDown':
        e.preventDefault();
        setSelected(Math.min(current + 1, flat.length - 1));
        break;
      case 'ArrowUp':
        e.preventDefault();
        setSelected(Math.max(current - 1, 0));
        break;
      case 'Enter':
        e.preventDefault();
        if (e.shiftKey) {
          if (flat[current]) {
            togglePin(flat[current].name);
          }
        } else {
          run(flat[current]);
        }
        break;
      case 'Tab':
        e.preventDefault();
        cycleCategory(e.shiftKey ? -1 : 1);
        break;
      case 'Escape':
        e.preventDefault();
        close();
        break;
      default:
        return;
    }
    e.stopPropagation();
  };

  let index = 0;
  return (
    <div className="VerbSearch">
      <div className="VerbSearch__search">
        <input
          ref={inputRef}
          className="VerbSearch__input"
          placeholder="Search verbs..."
          value={query}
          onChange={(e) => {
            setQuery(e.target.value);
            setSelected(0);
          }}
          onKeyDown={handleKeyDown}
        />
        <span className="VerbSearch__close" onClick={close}>
          Esc
        </span>
      </div>
      {status.length > 0 && (
        <div className="VerbSearch__status">
          {status.map((line) => {
            const split = line.indexOf(': ');
            return split < 0 ? (
              <span key={line} className="VerbSearch__stat">
                {line}
              </span>
            ) : (
              <span key={line} className="VerbSearch__stat">
                <span className="VerbSearch__stat-label">
                  {line.slice(0, split)}
                </span>
                {line.slice(split + 2)}
              </span>
            );
          })}
        </div>
      )}
      <div className="VerbSearch__categories">
        {categories.map((c) => (
          <span
            key={c}
            className={`VerbSearch__category${c === category ? ' VerbSearch__category--selected' : ''}`}
            onClick={() => {
              setCategory(c);
              setSelected(0);
              inputRef.current?.focus();
            }}
          >
            {c}
          </span>
        ))}
      </div>
      <div className="VerbSearch__results" ref={listRef}>
        {flat.length === 0 && (
          <div className="VerbSearch__empty">
            {verbs.length ? `No verbs match "${query}"` : 'Loading verbs...'}
          </div>
        )}
        {groups.map((group) => (
          <div key={group.title}>
            <div className="VerbSearch__group">{group.title}</div>
            {group.verbs.map((verb) => {
              const i = index++;
              const isPinned = pinned.includes(verb.name);
              return (
                <div
                  key={`${group.title}-${verb.name}`}
                  className={`VerbSearch__row${i === current ? ' VerbSearch__row--selected' : ''}`}
                  onMouseEnter={() => setSelected(i)}
                  onClick={() => run(verb)}
                >
                  <span className="VerbSearch__name">
                    {highlight(verb.name, term)}
                  </span>
                  <span className="VerbSearch__desc">
                    {highlight(verb.desc || '', term)}
                  </span>
                  <span
                    className={`VerbSearch__pin${isPinned ? ' VerbSearch__pin--on' : ''}`}
                    title={isPinned ? 'Unpin' : 'Pin above the chat'}
                    onClick={(e) => {
                      e.stopPropagation();
                      togglePin(verb.name);
                      inputRef.current?.focus();
                    }}
                  >
                    {isPinned ? '★' : '☆'}
                  </span>
                </div>
              );
            })}
          </div>
        ))}
      </div>
      <div className="VerbSearch__footer">
        <span>
          <kbd>&uarr;</kbd>
          <kbd>&darr;</kbd> select
        </span>
        <span>
          <kbd>Enter</kbd> run
        </span>
        <span>
          <kbd>Shift+Enter</kbd> pin
        </span>
        <span>
          <kbd>Tab</kbd> category
        </span>
      </div>
    </div>
  );
}
