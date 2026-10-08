// THIS IS A BUBBER UI FILE
import { useBackend } from 'tgui/backend';
import { Window } from 'tgui/layouts';
import { Box } from 'tgui-core/components';
// @ts-expect-error
import '../Styles/RimworldCharacterEditor.scss';
import { XenotypeBrowser } from './RimworldCharacterEditor/components/XenotypeBrowser';
import type { RimworldCharacterEditorData } from './RimworldCharacterEditor/types';

export function RimworldXenotypeAdmin() {
  const { data } = useBackend<RimworldCharacterEditorData>();

  return (
    <Window title="Xenotype Manager" width={760} height={680} theme="tartarus">
      <Window.Content className="RimworldCharacterEditor" altDrag={false}>
        <div className="RimworldCharacterEditor__xenotypeAdmin">
          {data.isXenotypeAdmin ? (
            <XenotypeBrowser />
          ) : (
            <Box color="bad" p={2}>
              Administrator access is required to manage saved xenotypes.
            </Box>
          )}
        </div>
      </Window.Content>
    </Window>
  );
}
