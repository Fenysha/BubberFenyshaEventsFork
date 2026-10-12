import './styles/main.scss';

import { useEffect, useRef, useState } from 'react';
import { dragStartHandler } from 'tgui/drag';
import { isEscape, KEY } from 'tgui-core/keys';
import { type BooleanLike, classes } from 'tgui-core/react';

import { type Channel, ChannelIterator } from './ChannelIterator';
import { ChatHistory } from './ChatHistory';
import { LineLength, RADIO_PREFIXES, WindowSize } from './constants';
import { getPrefix, windowClose, windowOpen, windowSet } from './helpers';
import { byondMessages } from './timers';
// FENYSHA EDIT ADDITION BEGIN - SAY_VERB_INPUT
import { useVerbInput } from './verbInput';

/** Room for the suggestion list under the input */
const SUGGESTION_HEIGHT = 17;
// FENYSHA EDIT ADDITION END

type ByondOpen = {
  channel: Channel;
  verbs?: BooleanLike;
};

type ByondProps = {
  maxLength: number;
  lightMode: BooleanLike;
  scale: BooleanLike;
};

export function TguiSay() {
  const innerRef = useRef<HTMLTextAreaElement>(null);
  const channelIterator = useRef(new ChannelIterator());
  const chatHistory = useRef(new ChatHistory());
  const messages = useRef(byondMessages);
  const scale = useRef(true);
  const currentPrefix = useRef<keyof typeof RADIO_PREFIXES | null>(null);

  // I initially wanted to make these an object or a reducer, but it's not really worth it.
  // You lose the granulatity and add a lot of boilerplate.
  const [buttonContent, setButtonContent] = useState('');
  const [lightMode, setLightMode] = useState(false);
  const [maxLength, setMaxLength] = useState(1024);
  const [size, setSize] = useState(WindowSize.Small);
  const [value, setValue] = useState('');
  // FENYSHA EDIT ADDITION BEGIN - SAY_VERB_INPUT
  const [verbMode, setVerbMode] = useState(false);
  const verbs = useVerbInput({
    value,
    setValue,
    onChannel: (channel) => {
      setVerbMode(false);
      channelIterator.current.set(channel);
      setButtonContent(channelIterator.current.current());
      setValue('');
      messages.current.channelIncrementMsg(channelIterator.current.isVisible());
    },
    onDone: () => handleClose(),
  });
  const suggestions = verbMode ? verbs.suggestions : [];
  const selected = verbs.selected;
  // FENYSHA EDIT ADDITION END

  const position = useRef([window.screenX, window.screenY]);
  const isDragging = useRef(false);

  function setCurrentPrefix(prefix: keyof typeof RADIO_PREFIXES | null): void {
    currentPrefix.current = prefix;
  }

  function handleArrowKeys(direction: KEY.Up | KEY.Down): void {
    const chat = chatHistory.current;
    const iterator = channelIterator.current;

    if (direction === KEY.Up) {
      if (chat.isAtLatest() && value) {
        // Save current message to temp history if at the most recent message
        chat.saveTemp(value);
      }
      // Try to get the previous message, fall back to the current value if none
      const prevMessage = chat.getOlderMessage();

      if (prevMessage) {
        setButtonContent(chat.getIndex().toString());
        setValue(prevMessage);
      }
    } else {
      const nextMessage = chat.getNewerMessage() || chat.getTemp() || '';

      const newContent = chat.isAtLatest()
        ? iterator.current()
        : chat.getIndex().toString();

      setButtonContent(newContent);
      setValue(nextMessage);
    }
  }

  function handleBackspaceDelete(): void {
    const chat = chatHistory.current;
    const iterator = channelIterator.current;

    // User is on a chat history message
    if (!chat.isAtLatest()) {
      chat.reset();
      setButtonContent(currentPrefix.current ?? iterator.current());

      // Empty input, resets the channel
    } else if (
      currentPrefix.current &&
      iterator.isSay() &&
      value?.length === 0
    ) {
      setCurrentPrefix(null);
      setButtonContent(iterator.current());
    }
  }

  function handleButtonClick(event: React.MouseEvent<HTMLButtonElement>): void {
    isDragging.current = true;

    setTimeout(() => {
      // So the button doesn't jump around accidentally
      if (isDragging.current) {
        dragStartHandler(event.nativeEvent);
      }
    }, 50);
  }

  // Prevents the button from changing channels if it's dragged
  function handleButtonRelease(): void {
    isDragging.current = false;
    const currentPosition = [window.screenX, window.screenY];

    if (JSON.stringify(position.current) !== JSON.stringify(currentPosition)) {
      position.current = currentPosition;
      return;
    }

    handleIncrementChannel();
  }

  function handleClose(): void {
    innerRef.current?.blur();
    windowClose(scale.current);

    setTimeout(() => {
      chatHistory.current.reset();
      channelIterator.current.reset();
      unloadChat();
    }, 25);
  }

  function handleEnter(): void {
    // FENYSHA EDIT ADDITION - SAY_VERB_INPUT
    if (verbMode) {
      chatHistory.current.add(value.trim());
      verbs.submit();
      return;
    }
    const iterator = channelIterator.current;
    const prefix = currentPrefix.current ?? '';

    if (value?.length && value.length < maxLength) {
      chatHistory.current.add(value);
      Byond.sendMessage('entry', {
        channel: iterator.current(),
        entry: iterator.isSay() ? prefix + value : value,
      });
    }

    handleClose();
  }

  function handleForceSay(): void {
    const iterator = channelIterator.current;
    const currentValue = innerRef.current?.value;

    // FENYSHA EDIT ADDITION - SAY_VERB_INPUT - a verb line is not speech to blurt out
    if (verbMode) return;

    // Only force say if we're on a visible channel and have typed something
    if (!currentValue || !iterator.isVisible()) return;

    const prefix = currentPrefix.current ?? '';
    const grunt = iterator.isSay() ? prefix + currentValue : currentValue;

    messages.current.forceSayMsg(grunt, iterator.current());
    handleClose();
  }

  function handleSaveText(): void {
    const iterator = channelIterator.current;
    const currentValue = innerRef.current?.value;

    if (!currentValue || !iterator.isVisible()) return;

    messages.current.saveText(currentValue, iterator.current());
  }

  function handleIncrementChannel(): void {
    const iterator = channelIterator.current;

    // FENYSHA EDIT ADDITION - SAY_VERB_INPUT - cycling the channel goes back to speaking
    setVerbMode(false);

    iterator.next();
    setButtonContent(iterator.current());
    setCurrentPrefix(null);
    messages.current.channelIncrementMsg(iterator.isVisible());
  }

  function handleInput(event: React.FormEvent<HTMLTextAreaElement>): void {
    const iterator = channelIterator.current;
    let newValue = event.currentTarget.value;

    // FENYSHA EDIT ADDITION BEGIN - SAY_VERB_INPUT - no channels, prefixes or typing indicators
    if (verbMode) {
      verbs.onInput(newValue);
      return;
    }
    // FENYSHA EDIT ADDITION END

    const newPrefix = getPrefix(newValue) || currentPrefix.current;
    // Handles switching prefixes
    if (newPrefix && newPrefix !== currentPrefix.current) {
      setButtonContent(RADIO_PREFIXES[newPrefix]);
      setCurrentPrefix(newPrefix);
      newValue = newValue.slice(3);
      iterator.set('Say');

      if (newPrefix === ':b ') {
        Byond.sendMessage('thinking', { visible: false });
      }
    }

    // Handles typing indicators
    if (channelIterator.current.isVisible() && newPrefix !== ':b ') {
      messages.current.typingMsg();
      messages.current.saveText(newValue, iterator.current());
    }

    setValue(newValue);
  }

  function handleKeyDown(
    event: React.KeyboardEvent<HTMLTextAreaElement>,
  ): void {
    if (event.getModifierState('AltGraph')) return;

    switch (event.key) {
      case KEY.Up:
      case KEY.Down:
        event.preventDefault();
        // FENYSHA EDIT ADDITION BEGIN - SAY_VERB_INPUT
        if (suggestions.length) {
          verbs.setSelected(
            event.key === KEY.Up
              ? Math.max(selected - 1, 0)
              : Math.min(selected + 1, suggestions.length - 1),
          );
          break;
        }
        // FENYSHA EDIT ADDITION END
        handleArrowKeys(event.key);
        break;

      case KEY.Delete:
      case KEY.Backspace:
        handleBackspaceDelete();
        break;

      case KEY.Enter:
        event.preventDefault();
        handleEnter();
        break;

      case KEY.Tab:
        event.preventDefault();
        // FENYSHA EDIT ADDITION - SAY_VERB_INPUT
        if (suggestions.length) {
          verbs.complete();
          break;
        }
        handleIncrementChannel();
        break;

      default:
        if (isEscape(event.key)) {
          handleClose();
        }
    }
  }

  function handleOpen(data: ByondOpen): void {
    channelIterator.current.set(data.channel);

    setCurrentPrefix(null);
    // FENYSHA EDIT ADDITION BEGIN - SAY_VERB_INPUT
    const asVerbs = !!data.verbs;
    setVerbMode(asVerbs);
    verbs.reset();
    if (asVerbs) {
      Byond.sendMessage('verbs/request');
      setButtonContent('Cmd');
      windowOpen(channelIterator.current.current(), scale.current, true);
      innerRef.current?.focus();
      return;
    }
    // FENYSHA EDIT ADDITION END
    setButtonContent(channelIterator.current.current());

    windowOpen(channelIterator.current.current(), scale.current);

    innerRef.current?.focus();
  }

  // FENYSHA EDIT ADDITION BEGIN - SAY_VERB_INPUT
  function handleVerbs(data: {
    verbs: Parameters<typeof verbs.setVerbs>[0];
  }): void {
    verbs.setVerbs(data.verbs);
  }

  function handleTargets(data: {
    targets: Parameters<typeof verbs.setTargets>[0];
  }): void {
    verbs.setTargets(data.targets);
  }

  function handleTypepaths(data: { paths: string[] }): void {
    verbs.setTypepaths(data.paths);
  }
  // FENYSHA EDIT ADDITION END

  function handleProps(data: ByondProps): void {
    setMaxLength(data.maxLength);
    setLightMode(!!data.lightMode);
    scale.current = !!data.scale;
  }

  function unloadChat(): void {
    setCurrentPrefix(null);
    setButtonContent(channelIterator.current.current());
    setValue('');
  }

  /** Subscribe to Byond messages */
  useEffect(() => {
    Byond.subscribeTo('props', handleProps);
    Byond.subscribeTo('force', handleForceSay);
    Byond.subscribeTo('open', handleOpen);
    Byond.subscribeTo('save', handleSaveText);
    Byond.subscribeTo('close', handleClose);
    // FENYSHA EDIT ADDITION BEGIN - SAY_VERB_INPUT
    Byond.subscribeTo('verbs', handleVerbs);
    Byond.subscribeTo('verbs/targets', handleTargets);
    Byond.subscribeTo('verbs/typepaths', handleTypepaths);
    // FENYSHA EDIT ADDITION END
  }, []);

  /** Value has changed, we need to check if the size of the window is ok */
  useEffect(() => {
    const len = value?.length || 0;

    let newSize: WindowSize;
    if (len > LineLength.Medium) {
      newSize = WindowSize.Large;
    } else if (len <= LineLength.Medium && len > LineLength.Small) {
      newSize = WindowSize.Medium;
    } else {
      newSize = WindowSize.Small;
    }

    // FENYSHA EDIT ADDITION - SAY_VERB_INPUT - the list needs room inside the window
    newSize = (newSize + suggestions.length * SUGGESTION_HEIGHT) as WindowSize;

    if (size !== newSize) {
      windowSet(newSize, scale.current);
      setSize(newSize);
    }
  }, [value, suggestions.length]);

  const theme =
    (lightMode && 'lightMode') ||
    (currentPrefix.current && RADIO_PREFIXES[currentPrefix.current]) ||
    channelIterator.current.current();

  return (
    <>
      <div
        className={`window window-${theme} window-${size}`}
        // FENYSHA EDIT ADDITION - SAY_VERB_INPUT - sizes outside the three fixed ones
        style={{ height: `${size}px` }}
        onMouseDown={dragStartHandler}
      >
        {!lightMode && <div className={`shine shine-${theme}`} />}
      </div>
      <div
        className={classes(['content', lightMode && 'content-lightMode'])}
        style={{
          zoom: scale.current ? '' : `${100 / window.devicePixelRatio}%`,
        }}
      >
        <button
          className={`button button-${theme}`}
          onMouseDown={handleButtonClick}
          onMouseUp={handleButtonRelease}
          type="button"
        >
          {buttonContent}
        </button>
        <textarea
          autoCorrect="off"
          className={classes([
            'textarea',
            `textarea-${theme}`,
            value.length > LineLength.Large && 'textarea-large',
          ])}
          maxLength={maxLength}
          onInput={handleInput}
          onKeyDown={handleKeyDown}
          ref={innerRef}
          spellCheck={false}
          value={value}
        />
        {/* FENYSHA EDIT ADDITION BEGIN - SAY_VERB_INPUT */}
        {suggestions.length > 0 && (
          <div className="suggestions">
            {suggestions.map((suggestion, index) => (
              <button
                className={classes([
                  'suggestion',
                  index === selected && 'suggestion-selected',
                ])}
                key={suggestion.label}
                onMouseDown={(event) => event.preventDefault()}
                onClick={suggestion.apply}
                type="button"
              >
                <span className="suggestion-name">{suggestion.label}</span>
                <span className="suggestion-category">{suggestion.detail}</span>
              </button>
            ))}
          </div>
        )}
        {/* FENYSHA EDIT ADDITION END */}
      </div>
    </>
  );
}
