import { useAtomValue, useSetAtom } from 'jotai';
import {
  type ChangeEvent,
  type KeyboardEvent,
  type SyntheticEvent,
  useEffect,
  useRef,
  useState,
} from 'react';
import { debounce, throttle } from 'tgui-core/timer';
import { type Channel, ChannelIterator } from '../../tgui-say/ChannelIterator';
import { ChatHistory } from '../../tgui-say/ChatHistory';
import { RADIO_PREFIXES } from '../../tgui-say/constants';
import { getPrefix } from '../../tgui-say/helpers';
import {
  commandBarSeedAtom,
  sayCloseAtom,
  sayForceAtom,
  sayMaxLengthAtom,
  saySaveAtom,
  saySessionAtom,
} from './atoms';
import { claimFocus, returnFocusToMap } from './claim-focus';

type RadioPrefix = keyof typeof RADIO_PREFIXES;

const SECONDS = 1000;

// tgui-say's timings, sent through the chat panel's say relay instead of its own window
const messages = {
  thinking: debounce(
    (visible: boolean) => Byond.sendMessage('say/thinking', { visible }),
    0.4 * SECONDS,
  ),
  force: debounce(
    (entry: string, channel: Channel) =>
      Byond.sendMessage('say/force', { entry, channel }),
    1 * SECONDS,
    true,
  ),
  save: throttle(
    (entry: string, channel: Channel) =>
      Byond.sendMessage('say/save', { entry, channel }),
    1 * SECONDS,
  ),
  typing: throttle(() => Byond.sendMessage('say/typing'), 4 * SECONDS),
};

// Outlives each session, as the modal's does
const history = new ChatHistory();

const CHANNEL_LABELS: Partial<Record<Channel, string>> = {
  Whis: 'Whisper',
  Admin: 'Asay',
};

function labelFor(channel: Channel, prefix: RadioPrefix | null): string {
  if (prefix) {
    return RADIO_PREFIXES[prefix];
  }
  return CHANNEL_LABELS[channel] ?? channel;
}

/** Runs `callback` when `signal` changes, but not for the value it mounted with. */
function useSignal(signal: number, callback: () => void) {
  const initial = useRef(signal);
  useEffect(() => {
    if (signal !== initial.current) {
      callback();
    }
  }, [signal]);
}

/** The speech hotkeys' input while the chat floats over the map. */
export function SayBar() {
  const session = useAtomValue(saySessionAtom);
  if (!session) {
    return null;
  }
  return (
    <SayInput
      key={session.opened}
      channel={session.channel}
      summoned={session.summoned}
    />
  );
}

function SayInput(props: { channel: Channel; summoned: number }) {
  const setSession = useSetAtom(saySessionAtom);
  const setSeed = useSetAtom(commandBarSeedAtom);
  const maxLength = useAtomValue(sayMaxLengthAtom);
  const iterator = useRef(new ChannelIterator());
  const inputRef = useRef<HTMLInputElement>(null);
  const [channel, setChannel] = useState<Channel>(props.channel);
  const [prefix, setPrefix] = useState<RadioPrefix | null>(null);
  const [value, setValue] = useState('');
  const [historyIndex, setHistoryIndex] = useState<number | null>(null);

  // DM's force/save/close arrive outside React's event flow, so they read from here
  const current = useRef({ value, prefix });
  current.current = { value, prefix };

  const label = labelFor(channel, prefix);
  const head = `${label} "`;

  useEffect(() => {
    if (iterator.current.current() !== props.channel) {
      setPrefix(null);
    }
    iterator.current.set(props.channel);
    setChannel(iterator.current.current());
    Byond.sendMessage('say/open', { channel: iterator.current.current() });
    const release = claimFocus(() => inputRef.current);
    const input = inputRef.current;
    input?.setSelectionRange(input.value.length, input.value.length);
    return release;
  }, [props.summoned]);

  function end() {
    history.reset();
    setSession(null);
  }

  function close() {
    inputRef.current?.blur();
    returnFocusToMap();
    Byond.sendMessage('say/close');
    end();
  }

  /** Deleting into the channel label drops back to the command bar, as its Say mode does. */
  function exitToCommand(text: string) {
    Byond.sendMessage('say/close');
    end();
    setSeed({ text, n: Date.now() });
  }

  function send() {
    const entry = iterator.current.isSay() ? (prefix ?? '') + value : value;
    if (value.length && value.length < maxLength) {
      history.add(value);
      Byond.sendMessage('say/entry', {
        channel: iterator.current.current(),
        entry,
      });
    }
    close();
  }

  function nextChannel() {
    iterator.current.next();
    setChannel(iterator.current.current());
    setPrefix(null);
    messages.thinking(iterator.current.isVisible());
  }

  function browseHistory(older: boolean) {
    if (older) {
      if (history.isAtLatest() && value) {
        history.saveTemp(value);
      }
      const message = history.getOlderMessage();
      if (message) {
        setHistoryIndex(history.getIndex());
        setValue(message);
      }
      return;
    }
    const message = history.getNewerMessage() || history.getTemp() || '';
    setHistoryIndex(history.isAtLatest() ? null : history.getIndex());
    setValue(message);
  }

  useSignal(useAtomValue(sayForceAtom), () => {
    const { value: text, prefix: radio } = current.current;
    if (!text || !iterator.current.isVisible()) {
      return;
    }
    const grunt = iterator.current.isSay() ? (radio ?? '') + text : text;
    messages.force(grunt, iterator.current.current());
    close();
  });

  useSignal(useAtomValue(saySaveAtom), () => {
    const text = current.current.value;
    if (text && iterator.current.isVisible()) {
      messages.save(text, iterator.current.current());
    }
  });

  useSignal(useAtomValue(sayCloseAtom), close);

  function handleChange(e: ChangeEvent<HTMLInputElement>) {
    const raw = e.target.value;
    if (!raw.startsWith(head)) {
      if (prefix) {
        // Backing into a radio label returns to plain Say, like the modal
        setPrefix(null);
        return;
      }
      exitToCommand(raw);
      return;
    }

    let next = raw.slice(head.length);
    const detected = getPrefix(next);
    if (detected && detected !== prefix) {
      setPrefix(detected);
      next = next.slice(3);
      iterator.current.set('Say');
      setChannel('Say');
      if (detected === ':b ') {
        Byond.sendMessage('say/thinking', { visible: false });
      }
    }

    const radio = detected || prefix;
    if (iterator.current.isVisible() && radio !== ':b ') {
      messages.typing();
      messages.save(next, iterator.current.current());
    }
    setValue(next);
  }

  function handleKeyDown(e: KeyboardEvent<HTMLInputElement>) {
    if (e.getModifierState('AltGraph')) {
      return;
    }
    switch (e.key) {
      case 'ArrowUp':
      case 'ArrowDown':
        e.preventDefault();
        browseHistory(e.key === 'ArrowUp');
        break;
      case 'Backspace':
      case 'Delete':
        if (!history.isAtLatest()) {
          history.reset();
          setHistoryIndex(null);
        }
        break;
      case 'Enter':
        e.preventDefault();
        send();
        break;
      case 'Tab':
        e.preventDefault();
        nextChannel();
        break;
      case 'Escape':
        e.preventDefault();
        close();
        break;
    }
  }

  // Keep the caret out of the label; deleting the quote still works from its edge
  function handleSelect(e: SyntheticEvent<HTMLInputElement>) {
    const input = e.currentTarget;
    const start = input.selectionStart ?? 0;
    if (start === input.selectionEnd && start < head.length) {
      input.setSelectionRange(head.length, head.length);
    }
  }

  const theme = prefix ? RADIO_PREFIXES[prefix] : channel;

  return (
    <div className="CommandBar SayBar">
      <div className="CommandBar__input-wrap">
        <input
          ref={inputRef}
          className="CommandBar__input"
          type="text"
          autoCorrect="off"
          spellCheck={false}
          maxLength={head.length + maxLength}
          value={head + value}
          onChange={handleChange}
          onKeyDown={handleKeyDown}
          onSelect={handleSelect}
        />
      </div>
      <button
        className={`CommandBar__mode-button SayBar--${theme}`}
        type="button"
        title="Next channel (Tab)"
        onMouseDown={(e) => e.preventDefault()}
        onClick={nextChannel}
      >
        {historyIndex ?? label}
      </button>
    </div>
  );
}
