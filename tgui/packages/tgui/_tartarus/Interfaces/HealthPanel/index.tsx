// tgui/interfaces/HealthPanel/index.tsx

import { useState } from 'react';
import { useBackend } from 'tgui/backend';
import { Window } from 'tgui/layouts';
import { Button, Section, Stack } from 'tgui-core/components';
import { BodyDoll } from './BodyDoll';
import { LeftPanel } from './LeftPanel';
import { RightPanel } from './RightPanel';
import { TOOLTIPS } from './tooltips';
import type { HealthPanelData } from './types';
// @ts-expect-error
import '../../Styles/HealthPanel.scss';

export const HealthPanel = () => {
  const { data, act } = useBackend<HealthPanelData>();
  const [selectedZone, setSelectedZone] = useState<string | null>('chest');

  return (
    <Window title="Health" width={800} height={540} theme="ntos">
      <Window.Content fitted className="HealthPanel">
        <Stack fill>
          <Stack.Item basis="250px" shrink={0}>
            <LeftPanel data={data} />
          </Stack.Item>

          <Stack.Item grow>
            <Stack vertical fill>
              <Stack.Item align="center" mt={1}>
                <Button
                  icon="times"
                  color="danger"
                  tooltip={TOOLTIPS.close}
                  onClick={() => act('close')}
                >
                  Close
                </Button>
              </Stack.Item>
              <Stack.Item grow>
                <Section title="Body" fill fitted>
                  <BodyDoll
                    bodyparts={data.bodyparts}
                    organs={data.organs}
                    selectedZone={selectedZone}
                    onSelect={setSelectedZone}
                  />
                </Section>
              </Stack.Item>
            </Stack>
          </Stack.Item>

          <Stack.Item basis="250px" shrink={0}>
            <RightPanel
              selectedZone={selectedZone}
              bodyparts={data.bodyparts}
              organs={data.organs}
            />
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
