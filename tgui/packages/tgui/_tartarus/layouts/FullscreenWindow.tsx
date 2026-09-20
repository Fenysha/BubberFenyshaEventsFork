import {
  type ComponentProps,
  type PropsWithChildren,
  useEffect,
  useLayoutEffect,
} from 'react';
import { UI_DISABLED, UI_INTERACTIVE } from 'tgui-core/constants';
import { globalEvents } from 'tgui-core/events';
import { useBackend } from '../../backend';
import { Layout } from '../../layouts/Layout';

type Props = PropsWithChildren<{
  theme?: string;
}>;

const FOLLOW_INTERVAL_MS = 500;
/** DM's host control inside the map pane (MAP_UI_BROWSER), which it sizes and shows itself */
const MAP_UI_BROWSER = 'map_ui_browser';

type Point = { x: number; y: number };

/** DreamSeeker's interior on screen: outer-pos is the frame, inner-pos the interior's offset in it. */
async function getGameWindowRect(): Promise<string | null> {
  const main = await Byond.winget('mainwindow', [
    'outer-pos',
    'inner-pos',
    'inner-size',
  ]);
  const outer: Point | undefined = main?.['outer-pos'];
  const inner: Point | undefined = main?.['inner-pos'];
  const size: Point | undefined = main?.['inner-size'];
  if (!outer || !inner || !size?.x || !size?.y) {
    return null;
  }
  return `${outer.x + inner.x},${outer.y + inner.y};${size.x}x${size.y}`;
}

/**
 * A tgui window with no titlebar or resize handles. Inside the map pane's host control it just
 * fills it; as a pop-up it covers the DreamSeeker window and follows it if it moves or resizes. Use Window.Content inside it as usual; the interface
 * supplies its own close control.
 */
export function FullscreenWindow(props: Props) {
  const { theme, children } = props;
  const { config, suspended } = useBackend();

  const embedded = Byond.windowId === MAP_UI_BROWSER;

  // A pop-up stays hidden until placed, or it flashes at its old size first
  useLayoutEffect(() => {
    if (!embedded) {
      Byond.winset(Byond.windowId, { 'is-visible': false });
    }
  }, []);

  useEffect(() => {
    if (suspended) {
      return;
    }
    if (embedded) {
      Byond.sendMessage('visible');
      globalEvents.emit('window-geometry-finished');
      return;
    }
    let lastRect: string | null = null;
    let shown = false;
    let cancelled = false;

    const fit = async () => {
      const rect = await getGameWindowRect();
      if (cancelled || !rect || rect === lastRect) {
        return;
      }
      lastRect = rect;
      const [pos, size] = rect.split(';');
      Byond.winset(Byond.windowId, { pos, size });
      if (!shown) {
        shown = true;
        Byond.winset(Byond.windowId, { 'can-close': true, 'is-visible': true });
        Byond.sendMessage('visible');
        globalEvents.emit('window-geometry-finished');
      }
    };

    fit();
    const timer = setInterval(fit, FOLLOW_INTERVAL_MS);
    return () => {
      cancelled = true;
      clearInterval(timer);
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

/**
 * Window.Content's stand-in. That one drags the window on Alt+mouse down, which here drags the
 * host control around the map pane, and it insets its children - a fullscreen view wants neither.
 */
function FullscreenWindowContent(props: ComponentProps<typeof Layout.Content>) {
  return <Layout.Content {...props} />;
}

FullscreenWindow.Content = FullscreenWindowContent;
