/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import './styles/main.scss';
import './styles/themes/light.scss';
import './styles/themes/tartarus.scss'; // FENYSHA EDIT ADDITION - TARTARUS_THEME

import { createRoot } from 'react-dom/client';
import { setupGlobalEvents } from 'tgui-core/events';
import { captureExternalLinks } from 'tgui-core/links';
import { setupHotReloading } from 'tgui-dev-server/link/client';
import { App } from './app';
// FENYSHA EDIT ADDITION BEGIN - AUTOTRANSLATE
// Side-effect import. This module registers its renderer event subscription
// and its watchdog at module scope, and nothing else imports it - without
// this line the bundler tree-shakes the whole feature out and translations
// silently never apply.
import './chat/translation';
// FENYSHA EDIT ADDITION END
import { bus } from './events/listeners';
import { setupPanelFocusHacks } from './panelFocus';
import { wsSend } from './websocket/helpers';

const root = createRoot(document.getElementById('react-root')!);

function render(component: React.ReactElement) {
  root.render(component);
}

function setupApp() {
  // Delay setup
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', setupApp);
    return;
  }

  setupGlobalEvents({
    ignoreWindowFocus: true,
  });

  setupPanelFocusHacks();
  captureExternalLinks();

  render(<App />);

  // Dispatch incoming messages as store actions
  Byond.subscribe((type, payload) => {
    bus.dispatch({ type, payload });
    wsSend({ type, payload });
  });

  // FENYSHA EDIT CHANGE BEGIN - TRANSPARENT_CHAT - moved into use-chat-placement, which runs
  // once the layout is known. Doing it here steals the pane back from the floating host.
  // Byond.winset('output_selector.legacy_output_selector', { left: 'output_browser' }); - FENYSHA EDIT ORIGINAL
  // FENYSHA EDIT CHANGE END

  // FENYSHA EDIT CHANGE BEGIN - TRANSPARENT_CHAT - skip while the chat floats over the map,
  // where use-chat-placement owns the geometry and this would race it and win
  if (!document.body.classList.contains('onmap')) {
    Byond.winget('output_browser').then((output: { size: string }) => {
      Byond.winset('browseroutput', {
        size: output.size,
      });
    });
  }
  // FENYSHA EDIT CHANGE END

  // Enable hot module reloading
  if (import.meta.webpackHot) {
    setupHotReloading();

    import.meta.webpackHot.accept(['./app'], () => {
      render(<App />);
    });
  }
}

setupApp();
