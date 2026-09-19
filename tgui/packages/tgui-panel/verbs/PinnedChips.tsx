import { useAtomValue } from 'jotai';
import { useMemo, useRef, useState } from 'react';
import { runVerb, searchVerbsAtom, usePinnedVerbs } from './verb-search';

/** Pinned verbs as one-click chips above the command bar. */
export function PinnedChips() {
  const { pinned, togglePin, movePin } = usePinnedVerbs();
  const verbs = useAtomValue(searchVerbsAtom);
  const [dropTarget, setDropTarget] = useState<string | null>(null);
  const dragged = useRef<string | null>(null);

  const byName = useMemo(() => new Map(verbs.map((v) => [v.name, v])), [verbs]);

  if (pinned.length === 0) {
    return null;
  }

  return (
    <div className="PinnedChips">
      {pinned.map((name) => {
        const verb = byName.get(name);
        // Until the list arrives everything would read as unavailable
        const unavailable = verbs.length > 0 && !verb;
        return (
          <span
            key={name}
            draggable
            className={[
              'PinnedChips__chip',
              unavailable && 'PinnedChips__chip--unavailable',
              dropTarget === name && 'PinnedChips__chip--drop',
            ]
              .filter(Boolean)
              .join(' ')}
            title={`${unavailable ? 'Not available right now' : verb?.desc || name} - right-click to unpin, drag to reorder`}
            onClick={() => runVerb(name)}
            onContextMenu={(e) => {
              e.preventDefault();
              togglePin(name);
            }}
            onDragStart={(e) => {
              dragged.current = name;
              e.dataTransfer.effectAllowed = 'move';
            }}
            onDragOver={(e) => {
              e.preventDefault();
              setDropTarget(name);
            }}
            onDragLeave={() => setDropTarget(null)}
            onDrop={(e) => {
              e.preventDefault();
              setDropTarget(null);
              if (dragged.current) {
                movePin(dragged.current, name);
              }
              dragged.current = null;
            }}
            onDragEnd={() => {
              dragged.current = null;
              setDropTarget(null);
            }}
          >
            {name}
          </span>
        );
      })}
    </div>
  );
}
