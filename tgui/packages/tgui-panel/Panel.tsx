/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { useAtom, useAtomValue } from 'jotai';
import { useCallback, useEffect } from 'react';
import { Pane } from 'tgui/layouts';
import { Button, Section, Stack } from 'tgui-core/components';
import { visibleAtom } from './audio/atoms';
import { NowPlayingWidget } from './audio/NowPlayingWidget';
import { ChatPanel } from './chat/ChatPanel';
import { ChatTabs } from './chat/ChatTabs';
import {
  ResizeHandles,
  startChatMove,
  startPopupMove,
} from './chat/ResizeHandles';
import { chatRenderer } from './chat/renderer';
import { useChatPersistence } from './chat/use-chat-persistence';
import { useChatPlacement } from './chat/use-chat-placement';
import { gameAtom } from './game/atoms';
import { useKeepAlive } from './game/use-keep-alive';
import { Notifications } from './Notifications';
import { PingIndicator } from './ping/PingIndicator';
import { ReconnectButton } from './reconnect';
import { saySessionAtom } from './say/atoms'; // FENYSHA EDIT ADDITION - TRANSPARENT_CHAT
import { SayBar } from './say/SayBar'; // FENYSHA EDIT ADDITION - TRANSPARENT_CHAT
import { settingsVisibleAtom } from './settings/atoms';
import { SettingsPanel } from './settings/SettingsPanel';
import { useSettings } from './settings/use-settings';
import { CommandBar } from './verbs/CommandBar';
import { PinnedChips } from './verbs/PinnedChips'; // FENYSHA EDIT ADDITION - VERB_SEARCH
import { VerbSearch } from './verbs/VerbSearch'; // FENYSHA EDIT ADDITION - VERB_SEARCH
import { verbSearchOpenAtom } from './verbs/verb-search'; // FENYSHA EDIT ADDITION - VERB_SEARCH

export function Panel(props) {
  const [audioVisible, setAudioVisible] = useAtom(visibleAtom);
  const game = useAtomValue(gameAtom);
  const { settings, updateSettings } = useSettings();
  const [settingsVisible, setSettingsVisible] = useAtom(settingsVisibleAtom);
  const [searchOpen, setSearchOpen] = useAtom(verbSearchOpenAtom); // FENYSHA EDIT ADDITION - VERB_SEARCH
  const sayOpen = !!useAtomValue(saySessionAtom); // FENYSHA EDIT ADDITION - TRANSPARENT_CHAT
  useChatPersistence();
  const { isOnMap, isPopup, chatCorner } = useChatPlacement();
  useKeepAlive();

  const frameless = isOnMap && settings.chatFrameless;

  // FENYSHA EDIT ADDITION BEGIN - VERB_SEARCH - Don't reopen on the next switch back to overlay
  useEffect(() => {
    if (!isOnMap) {
      setSearchOpen(false);
    }
  }, [isOnMap]);
  // FENYSHA EDIT ADDITION END
  const chatTop = frameless && chatCorner.startsWith('top');
  const messageBg = frameless && settings.chatMessageBg;

  // Frameless chat is invisible until the mouse is over it, so the body carries the state
  useEffect(() => {
    const body = document.body;
    const clearClasses = () =>
      body.classList.remove(
        'frameless',
        'frameless-visible',
        'chat-message-bg',
        'chat-top',
      );

    if (!frameless) {
      clearClasses();
      chatRenderer.setFrameless(false);
      return;
    }

    body.classList.add('frameless');
    body.classList.toggle('chat-message-bg', !!messageBg);
    body.classList.toggle('chat-top', chatTop);
    body.classList.toggle(
      'frameless-visible',
      settingsVisible || searchOpen || sayOpen,
    );
    chatRenderer.setFrameless(true);

    const show = () => {
      body.classList.add('frameless-visible');
      chatRenderer.scrollToBottom();
    };
    const hide = () => {
      if (!settingsVisible && !searchOpen && !sayOpen) {
        body.classList.remove('frameless-visible');
      }
    };

    body.addEventListener('mouseenter', show);
    body.addEventListener('mouseleave', hide);

    return () => {
      body.removeEventListener('mouseenter', show);
      body.removeEventListener('mouseleave', hide);
      clearClasses();
      chatRenderer.setFrameless(false);
    };
  }, [frameless, messageBg, chatTop, settingsVisible, searchOpen, sayOpen]);

  // The on-map chat has no titlebar either, so its header doubles as one.
  // tgui's Button and Tabs render as divs, so match their classes rather than <button>.
  const onHeaderDrag = useCallback((e: React.PointerEvent) => {
    if (
      (e.target as HTMLElement).closest(
        'button, a, input, [role="button"], .Button, .Tab, .Dropdown',
      )
    ) {
      return;
    }
    startChatMove(e);
  }, []);

  // The popup has no titlebar of its own, so the drag bar moves the window
  const onPopupDrag = useCallback((e: React.PointerEvent) => {
    startPopupMove(e);
  }, []);

  return (
    <Pane theme={settings.theme} canSuspend={false}>
      {isOnMap && <ResizeHandles corner={chatCorner} />}
      {isPopup && (
        <>
          <ResizeHandles allEdges target="tgui_panel_popup" />
          <div className="PanelDragBar" onPointerDown={onPopupDrag} />
        </>
      )}
      <Stack fill vertical className="Panel__stack">
        <Stack.Item>
          <Section fitted className="Panel__header">
            {/* Plain div: Stack only forwards a fixed allowlist of handlers, and
                onPointerDown is not among them */}
            <div
              onPointerDown={isOnMap ? onHeaderDrag : undefined}
              style={isOnMap ? { cursor: 'grab' } : undefined}
            >
              <Stack mr={1} align="center">
                <Stack.Item grow>
                  <ChatTabs />
                </Stack.Item>
                <Stack.Item>
                  <PingIndicator />
                </Stack.Item>
                {/* FENYSHA EDIT ADDITION BEGIN - VERB_SEARCH - The docked layouts still have the statpanel */}
                {isOnMap && (
                  <Stack.Item>
                    <Button
                      color="transparent"
                      icon="search"
                      selected={searchOpen}
                      tooltip="Search verbs (Ctrl+K)"
                      tooltipPosition="bottom-start"
                      onClick={() => setSearchOpen((o) => !o)}
                    />
                  </Stack.Item>
                )}
                {/* FENYSHA EDIT ADDITION END */}
                <Stack.Item>
                  <Button
                    color="transparent"
                    icon={isOnMap ? 'columns' : 'window-maximize'}
                    tooltip={isOnMap ? 'Switch to panel' : 'Switch to overlay'}
                    tooltipPosition="bottom-start"
                    onClick={() => Byond.sendMessage('panel/toggle_layout')}
                  />
                </Stack.Item>
                {isOnMap && (
                  <Stack.Item>
                    <Button
                      color="transparent"
                      icon={settings.chatFrameless ? 'eye-slash' : 'eye'}
                      tooltip={
                        settings.chatFrameless
                          ? 'Show chat frame'
                          : 'Hide chat frame'
                      }
                      tooltipPosition="bottom-start"
                      onClick={() =>
                        updateSettings({
                          chatFrameless: !settings.chatFrameless,
                        })
                      }
                    />
                  </Stack.Item>
                )}
                <Stack.Item>
                  <Button
                    color="grey"
                    selected={audioVisible}
                    icon="music"
                    tooltip="Music player"
                    tooltipPosition="bottom-start"
                    onClick={() => setAudioVisible((v) => !v)}
                  />
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon={settingsVisible ? 'times' : 'cog'}
                    selected={settingsVisible}
                    tooltip={
                      settingsVisible ? 'Close settings' : 'Open settings'
                    }
                    tooltipPosition="bottom-start"
                    onClick={() => setSettingsVisible((v) => !v)}
                  />
                </Stack.Item>
              </Stack>
            </div>
          </Section>
        </Stack.Item>
        {audioVisible && (
          <Stack.Item>
            <Section>
              <NowPlayingWidget />
            </Section>
          </Stack.Item>
        )}
        {settingsVisible && (
          <Stack.Item>
            <SettingsPanel isOnMap={isOnMap} />
          </Stack.Item>
        )}
        <Stack.Item grow>
          <Section fill fitted position="relative">
            <Pane.Content scrollable id="chat-pane">
              <ChatPanel lineHeight={settings.lineHeight} />
            </Pane.Content>
            <Notifications>
              {game.connectionLostAt && (
                <Notifications.Item rightSlot={<ReconnectButton />}>
                  You are either AFK, experiencing lag or the connection has
                  closed.
                </Notifications.Item>
              )}
              {game.roundRestartedAt && (
                <Notifications.Item>
                  The connection has been closed because the server is
                  restarting. Please wait while you automatically reconnect.
                </Notifications.Item>
              )}
            </Notifications>
            {/* FENYSHA EDIT ADDITION - VERB_SEARCH */}
            {isOnMap && <VerbSearch />}
          </Section>
        </Stack.Item>
        {/* FENYSHA EDIT ADDITION BEGIN - VERB_SEARCH */}
        {isOnMap && (
          <Stack.Item>
            <PinnedChips />
          </Stack.Item>
        )}
        {/* FENYSHA EDIT ADDITION END */}
        <Stack.Item>
          {/* FENYSHA EDIT CHANGE BEGIN - TRANSPARENT_CHAT - Speech hotkeys take over the input bar */}
          {/* <CommandBar /> - FENYSHA EDIT ORIGINAL */}
          <SayBar />
          {/* Hidden, not unmounted: mounting it asks DM to rebuild the verb list */}
          <div style={sayOpen ? { display: 'none' } : undefined}>
            <CommandBar />
          </div>
          {/* FENYSHA EDIT CHANGE END */}
        </Stack.Item>
      </Stack>
    </Pane>
  );
}
