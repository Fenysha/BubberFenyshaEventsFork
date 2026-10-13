import { describe, expect, mock, test } from 'bun:test';
import { fireEvent, render, waitFor } from '@testing-library/react';
import {
  ARG_SOURCE_LIST,
  ARG_TYPE_MOB,
  ARG_TYPE_TEXT,
} from 'common/verb-constants';
import { act } from 'react';

mock.module('./styles/main.scss', () => ({}));

const listeners: Record<string, (payload: any) => void> = {};
const sent: { type: string; payload: any }[] = [];
const commands: string[] = [];
(globalThis as any).Byond = {
  windowId: 'tgui_say',
  subscribeTo: (type: string, fn: (p: any) => void) => {
    listeners[type] = fn;
  },
  sendMessage: (type: string, payload: any) => sent.push({ type, payload }),
  command: (line: string) => commands.push(line),
  winset: () => {},
  winget: async () => ({}),
};

const { TguiSay } = await import('./TguiSay');

const VERBS = [
  { name: 'Say', category: '', type: '/mob/verb/say_verb', args: [] },
  { name: 'OOC', category: '', type: '/client/verb/ooc', args: [] },
  {
    name: 'Set Flavor',
    category: 'IC',
    type: '/mob/verb/set_flavor',
    args: [{ name: 'text', arg_type: ARG_TYPE_TEXT, source: null }],
  },
  {
    name: 'Point At',
    category: 'IC',
    type: '/mob/verb/point_at',
    args: [{ name: 'target', arg_type: ARG_TYPE_MOB, source: null }],
  },
  {
    name: 'Set Mood',
    category: 'IC',
    type: '/mob/verb/set_mood',
    args: [
      {
        name: 'mood',
        arg_type: ARG_TYPE_TEXT,
        source: ARG_SOURCE_LIST,
        options: ['Happy', 'Sad'],
      },
    ],
  },
];

async function openPopup() {
  sent.length = 0;
  commands.length = 0;
  const view = render(<TguiSay />);
  await act(async () => {
    listeners.props?.({ maxLength: 1024, lightMode: 0, scale: 0 });
  });
  await act(async () => {
    listeners.open?.({ channel: 'Say', verbs: true });
  });
  await act(async () => {
    listeners.verbs?.({ verbs: VERBS });
  });
  return view;
}

const type = async (view: any, text: string) => {
  const input = view.container.querySelector('textarea')!;
  await act(async () => {
    fireEvent.input(input, { target: { value: text } });
  });
  return input;
};

const labels = (view: any) =>
  [...view.container.querySelectorAll('.suggestion-name')].map(
    (n) => n.textContent,
  );

describe('speech keys, opened without the verb flag', () => {
  test('the box still speaks, with no verb suggestions', async () => {
    sent.length = 0;
    commands.length = 0;
    const view = render(<TguiSay />);
    await act(async () => {
      listeners.props?.({ maxLength: 1024, lightMode: 0, scale: 0 });
    });
    await act(async () => {
      listeners.open?.({ channel: 'Say' });
    });
    await act(async () => {
      listeners.verbs?.({ verbs: VERBS });
    });
    expect(view.container.querySelector('button')?.textContent).toBe('Say');

    const input = view.container.querySelector('textarea')!;
    await act(async () => {
      fireEvent.input(input, { target: { value: 'say' } });
    });
    expect(view.container.querySelectorAll('.suggestion-name').length).toBe(0);

    await act(async () => {
      fireEvent.keyDown(input, { key: 'Enter' });
    });
    expect(sent.find((m) => m.type === 'entry')?.payload).toMatchObject({
      channel: 'Say',
      entry: 'say',
    });
    expect(commands).toEqual([]);
  });
});

describe('argument hints while typing, as the chat does', () => {
  test('a string argument opens a quote, and so does the next one', async () => {
    const view = await openPopup();
    await act(async () =>
      listeners.verbs?.({
        verbs: [
          {
            name: 'Note Thing',
            category: 'Debug',
            type: '/mob/verb/note_thing',
            args: [
              { name: 'first', arg_type: 1, source: 'input' },
              { name: 'second', arg_type: 1, source: 'input' },
            ],
          },
        ],
      }),
    );
    const input = await type(view, 'note-thing');
    await act(async () => {
      fireEvent.keyDown(input, { key: 'Tab' });
    });
    expect(view.container.querySelector('textarea')?.value).toBe(
      'Note-Thing "',
    );

    await type(view, 'Note-Thing "hello" ');
    expect(view.container.querySelector('textarea')?.value).toBe(
      'Note-Thing "hello" "',
    );
  });

  test('editing the verb away goes back to picking one', async () => {
    const view = await openPopup();
    const input = await type(view, 'set-fl');
    await act(async () => {
      fireEvent.keyDown(input, { key: 'Tab' });
    });
    expect(view.container.querySelector('textarea')?.value).toBe(
      'Set-Flavor "',
    );
    await type(view, 'set-f');
    expect(labels(view)).toEqual(['Set-Flavor']);
  });

  test('typing a path asks the server for its children', async () => {
    const view = await openPopup();
    const input = await type(view, 'spawn-it');
    await act(async () =>
      listeners.verbs?.({
        verbs: [
          {
            name: 'Spawn It',
            category: 'Debug',
            type: '/datum/admin_verb/spawn_it',
            args: [{ name: 'object', arg_type: 2048, source: 'input' }],
          },
        ],
      }),
    );
    await act(async () => {
      fireEvent.input(input, { target: { value: 'spawn-it' } });
    });
    await act(async () => {
      fireEvent.keyDown(input, { key: 'Tab' });
    });
    sent.length = 0;
    await type(view, 'Spawn-It /obj/');
    expect(
      sent.find((m) => m.type === 'verbs/request_typepaths')?.payload,
    ).toEqual({ parent: '/obj' });
    await act(async () =>
      listeners['verbs/typepaths']?.({
        parent: '/obj',
        paths: ['/obj/item', '/obj/machinery'],
      }),
    );
    expect(labels(view)).toEqual(['/obj/item', '/obj/machinery']);
  });
});

describe('say popup verb input', () => {
  test('speech verbs switch the box to that chat mode', async () => {
    const view = await openPopup();
    const input = await type(view, 'ooc');
    expect(labels(view)).toContain('OOC');
    await act(async () => {
      fireEvent.keyDown(input, { key: 'Enter' });
    });
    expect(view.container.querySelector('button')?.textContent).toBe('OOC');
    expect(sent.find((m) => m.type === 'verbs/invoke')).toBeUndefined();
    // Back to speaking: what is typed now is said on that channel
    await type(view, 'hello');
    await act(async () => {
      fireEvent.keyDown(view.container.querySelector('textarea')!, {
        key: 'Enter',
      });
    });
    expect(sent.find((m) => m.type === 'entry')?.payload).toMatchObject({
      channel: 'OOC',
      entry: 'hello',
    });
  });

  test('a text argument is quoted and sent as an argument', async () => {
    const view = await openPopup();
    const input = await type(view, 'set-fl');
    expect(labels(view)).toEqual(['Set-Flavor']);
    await act(async () => {
      fireEvent.keyDown(input, { key: 'Tab' });
    });
    expect(view.container.querySelector('textarea')?.value).toBe(
      'Set-Flavor "',
    );

    await type(view, 'Set-Flavor "tall and grim"');
    await act(async () => {
      fireEvent.keyDown(view.container.querySelector('textarea')!, {
        key: 'Enter',
      });
    });
    expect(sent.find((m) => m.type === 'verbs/invoke')?.payload).toEqual({
      verb_type: '/mob/verb/set_flavor',
      args: { text: 'tall and grim' },
    });
  });

  test('entity arguments ask for targets and fill in the ref', async () => {
    const view = await openPopup();
    const input = await type(view, 'point-at');
    await act(async () => {
      fireEvent.keyDown(input, { key: 'Tab' });
    });
    expect(
      sent.find((m) => m.type === 'verbs/request_targets')?.payload,
    ).toEqual({ verb_type: '/mob/verb/point_at' });

    await act(async () => {
      listeners['verbs/targets']?.({
        targets: [{ name: 'Urist McHands', ref: '[0x3000001]' }],
      });
    });
    await waitFor(() => expect(labels(view)).toEqual(['Urist McHands']));
    await act(async () => {
      fireEvent.keyDown(view.container.querySelector('textarea')!, {
        key: 'Enter',
      });
    });
    await act(async () => {
      fireEvent.keyDown(view.container.querySelector('textarea')!, {
        key: 'Enter',
      });
    });
    expect(sent.find((m) => m.type === 'verbs/invoke')?.payload).toEqual({
      verb_type: '/mob/verb/point_at',
      args: { target: '[0x3000001]' },
    });
  });

  test('list arguments offer their options', async () => {
    const view = await openPopup();
    const input = await type(view, 'set-mood');
    await act(async () => {
      fireEvent.keyDown(input, { key: 'Tab' });
    });
    await waitFor(() => expect(labels(view)).toEqual(['Happy', 'Sad']));
  });
});
