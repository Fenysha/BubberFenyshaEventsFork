import { loadStyleSheet } from 'common/assets';
import { EventBus } from 'tgui-core/eventbus';
import { playMusic, stopMusic } from '../audio/handlers';
import { chatMessage } from '../chat/handlers';
import { pingReply, pingSoft } from '../ping/handlers';
import {
  handleSayClose,
  handleSayForce,
  handleSayOpen,
  handleSayProps,
  handleSaySave,
} from '../say/atoms';
import {
  handleTelemetryData,
  telemetryRequest,
  testTelemetryCommand,
} from '../telemetry/handlers';
import {
  handleAddVerbs,
  handleClearCommandBar,
  handleFocusCommandBar,
  handleHotkeyMode,
  handleRemoveVerbs,
  handleTargets,
  handleTypepaths,
  handleVerbsInit,
} from '../verbs/handlers';
import {
  handleVerbSearchOpen,
  handleVerbSearchStatus,
  handleVerbSearchVerbs,
} from '../verbs/verb-search';
import { handleLoadAssets } from './handlers/assets';
import { playerSet } from './handlers/player';
import { roundrestart } from './handlers/roundrestart';

const listeners = {
  'verbs/add': handleAddVerbs,
  'verbs/clear': handleClearCommandBar,
  'verbs/focus': handleFocusCommandBar,
  'verbs/init': handleVerbsInit,
  'verbs/remove': handleRemoveVerbs,
  'verbs/targets': handleTargets,
  'verbs/typepaths': handleTypepaths,
  'verbs/hotkey_mode': handleHotkeyMode,
  'say/close': handleSayClose,
  'say/force': handleSayForce,
  'say/open': handleSayOpen,
  'say/props': handleSayProps,
  'say/save': handleSaySave,
  'verbsearch/open': handleVerbSearchOpen,
  'verbsearch/status': handleVerbSearchStatus,
  'verbsearch/verbs': handleVerbSearchVerbs,
  'asset/stylesheet': loadStyleSheet,
  'asset/mappings': handleLoadAssets,
  'audio/playMusic': playMusic,
  'audio/stopMusic': stopMusic,
  'chat/message': chatMessage,
  'player/set': playerSet,
  'ping/reply': pingReply,
  'ping/soft': pingSoft,
  roundrestart,
  'telemetry/request': telemetryRequest,
  testTelemetryCommand,
  update: handleTelemetryData,
} as const;

export const bus = new EventBus(listeners);
