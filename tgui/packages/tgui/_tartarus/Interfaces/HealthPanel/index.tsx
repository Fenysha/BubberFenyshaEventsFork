// tgui/interfaces/HealthPanel/index.tsx

import { useState } from 'react';
import { useBackend } from 'tgui/backend';
import { Window } from 'tgui/layouts';
import { Box, Button, Section, Stack } from 'tgui-core/components';
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

  const heartStopped =
    data.parameters.heartbeat.state === 'stopped' ||
    data.parameters.heartbeat.state === 'missing';
  const brainCritical =
    data.organs.brain.present && (data.organs.brain.oxygen ?? 100) < 30;
  const bleeding = data.parameters.bleed_rate > 3;

  const patientStatus = heartStopped
    ? 'Cardiac arrest'
    : brainCritical
      ? 'Severe cerebral hypoxia'
      : bleeding
        ? 'Major hemorrhage'
        : data.parameters.consciousness <= 15
          ? 'Unresponsive'
          : data.parameters.shock >= 75
            ? 'Critical shock'
            : 'Stable';

  const patientColor =
    heartStopped || brainCritical
      ? 'bad'
      : bleeding || data.parameters.shock >= 75
        ? 'average'
        : 'good';

  return (
    <Window title="Medical Status" width={920} height={620}>
      <Window.Content fitted className="HealthPanel">
        <Stack vertical fill>
          <Stack.Item>
            <Section fitted>
              <Stack align="center">
                <Stack.Item grow>
                  <Box bold fontSize="1.1em">
                    Patient status
                  </Box>
                  <Box color={patientColor}>{patientStatus}</Box>
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon="times"
                    color="danger"
                    tooltip={TOOLTIPS.close}
                    onClick={() => act('close')}
                  >
                    Close
                  </Button>
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>

          <Stack.Item grow>
            <Stack fill>
              <Stack.Item basis="275px" shrink={0}>
                <LeftPanel data={data} />
              </Stack.Item>

              <Stack.Item grow>
                <Section title="Anatomy" fill fitted>
                  <BodyDoll
                    bodyparts={data.bodyparts}
                    organs={data.organs}
                    selectedZone={selectedZone}
                    onSelect={setSelectedZone}
                  />
                </Section>
              </Stack.Item>

              <Stack.Item basis="300px" shrink={0}>
                <RightPanel
                  selectedZone={selectedZone}
                  bodyparts={data.bodyparts}
                  organs={data.organs}
                />
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
