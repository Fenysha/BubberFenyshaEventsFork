// THIS IS A BUBBER UI FILE
import { Window } from 'tgui/layouts';
// @ts-expect-error
import '../Styles/RimworldCharacterEditor.scss';
import { XenotypeBrowser } from './RimworldCharacterEditor/components/XenotypeBrowser';

export function RimworldXenotypeBrowser() {
  return (
    <Window title="Xenotype Browser" width={900} height={760} theme="tartarus">
      <Window.Content className="RimworldCharacterEditor" altDrag={false}>
        <div className="RimworldCharacterEditor__xenotypeAdmin">
          <XenotypeBrowser />
        </div>
      </Window.Content>
    </Window>
  );
}
