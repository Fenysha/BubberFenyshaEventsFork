import { type PropsWithChildren, useEffect, useLayoutEffect } from 'react';
import { UI_DISABLED, UI_INTERACTIVE } from 'tgui-core/constants';
import { globalEvents } from 'tgui-core/events';
import { useBackend } from '../../backend';
import { Layout } from '../../layouts/Layout';

type Props = PropsWithChildren<{
  theme?: string;
}>;

/**
 * A tgui window with no titlebar or resize handles that fills the screen. Use Window.Content
 * inside it as usual; the interface supplies its own close control.
 */
export function FullscreenWindow(props: Props) {
  const { theme, children } = props;
  const { config, suspended } = useBackend();

  // Hidden until maximised, or it flashes at its old size first
  useLayoutEffect(() => {
    Byond.winset(Byond.windowId, { 'is-visible': false });
  }, []);

  useEffect(() => {
    if (suspended) {
      return;
    }
    Byond.winset(Byond.windowId, {
      'can-close': true,
      'is-maximized': true,
      'is-visible': true,
    });
    Byond.sendMessage('visible');
    globalEvents.emit('window-geometry-finished');

    // tgui recycles windows, and a maximised one would stay that way for the next interface
    return () => {
      Byond.winset(Byond.windowId, { 'is-maximized': false });
    };
  }, [suspended]);

  const showDimmer =
    config.user &&
    (config.user.observer
      ? config.status < UI_DISABLED
      : config.status < UI_INTERACTIVE);

  if (suspended) {
    return null;
  }

  return (
    <Layout className="Window" theme={theme}>
      <div className="Window__rest" style={{ top: 0 }}>
        {children}
        {showDimmer && <div className="Window__dimmer" />}
      </div>
    </Layout>
  );
}
