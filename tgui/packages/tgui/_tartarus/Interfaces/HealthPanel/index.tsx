// tgui/interfaces/HealthPanel/index.tsx

import type { CSSProperties } from 'react';
import { useMemo, useState } from 'react';
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

const clamp01 = (value: number) => Math.max(0, Math.min(value, 1));

const getOverallStateScore = (data: HealthPanelData) => {
  const consciousness = clamp01(data.parameters.consciousness / 100);
  const shock = 1 - clamp01(data.parameters.shock / 100);
  const oxygenation = clamp01(data.parameters.breathing.oxygenation / 100);
  const bloodVolume = clamp01(data.parameters.circulation.blood_ratio);
  const perfusion = clamp01(data.parameters.circulation.perfusion / 1.2);
  const cardiacOutput = clamp01(data.parameters.heartbeat.cardiac_output);

  return clamp01(
    consciousness * 0.28 +
      shock * 0.18 +
      oxygenation * 0.15 +
      bloodVolume * 0.14 +
      perfusion * 0.13 +
      cardiacOutput * 0.12,
  );
};

export const HealthPanel = () => {
  const { data, act } = useBackend<HealthPanelData>();
  const [selectedZone, setSelectedZone] = useState<string | null>('chest');

  const stateScore = useMemo(() => getOverallStateScore(data), [data]);

  const stateHue = Math.round(stateScore * 220);
  const stateGradientStyle = {
    '--health-state-hue': stateHue,
  } as CSSProperties;

  const heartStopped =
    data.parameters.heartbeat.state === 'stopped' ||
    data.parameters.heartbeat.state === 'missing';

  const brainCritical =
    !data.organs.brain.present ||
    data.organs.brain.health <= 25 ||
    (data.organs.brain.oxygen ?? 100) < 30;

  const bleeding = data.parameters.bleed_rate > 3;

  const patientStatus = heartStopped
    ? 'Cardiac arrest'
    : brainCritical
      ? 'Critical cerebral injury'
      : bleeding
        ? 'Major hemorrhage'
        : data.parameters.consciousness <= 15
          ? 'Unresponsive'
          : data.parameters.shock >= 75
            ? 'Critical shock'
            : data.parameters.breathing.oxygenation < 60
              ? 'Severe hypoxia'
              : 'Stable';

  const patientColor =
    stateScore < 0.25 ? 'bad' : stateScore < 0.6 ? 'average' : 'good';

  return (
    <Window title="Physiological Status" width={900} height={580}>
      <Window.Content fitted className="HealthPanel">
        <div
          className="HealthPanel__state-gradient"
          style={stateGradientStyle}
        />

        <Stack vertical fill className="HealthPanel__content">
          <Stack.Item>
            <Section fitted>
              <Stack align="center">
                <Stack.Item grow>
                  <Box bold fontSize="1.1em">
                    Physiological state
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
              <Stack.Item basis="250px" shrink={0}>
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

              <Stack.Item basis="275px" shrink={0}>
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
