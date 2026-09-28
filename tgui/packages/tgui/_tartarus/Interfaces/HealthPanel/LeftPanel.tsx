import {
  Box,
  LabeledList,
  ProgressBar,
  Section,
  Stack,
} from 'tgui-core/components';
import { Cardiogram } from './Cardiogram';
import { TOOLTIPS } from './tooltips';
import type { HealthPanelData } from './types';

type Props = {
  data: HealthPanelData;
};

const vitalsColor = (
  value: number,
  dangerAt: number,
): 'good' | 'average' | 'bad' => {
  if (value >= dangerAt) return 'bad';
  if (value >= dangerAt * 0.6) return 'average';
  return 'good';
};

export const LeftPanel = (props: Props) => {
  const { parameters, cardiogram, lungs } = props.data;

  return (
    <Stack vertical fill>
      <Stack.Item>
        <Section title="Vitals" fitted>
          <LabeledList>
            <LabeledList.Item
              label="Consciousness"
              tooltip={TOOLTIPS.consciousness}
            >
              <ProgressBar
                value={parameters.consciousness / 100}
                color={vitalsColor(100 - parameters.consciousness, 60)}
              >
                {Math.round(parameters.consciousness)}
              </ProgressBar>
            </LabeledList.Item>

            <LabeledList.Item label="Pain" tooltip={TOOLTIPS.pain}>
              <ProgressBar
                value={parameters.pain / 200}
                color={vitalsColor(parameters.pain, 90)}
              >
                {Math.round(parameters.pain)}
              </ProgressBar>
            </LabeledList.Item>

            <LabeledList.Item label="Shock" tooltip={TOOLTIPS.shock}>
              <ProgressBar
                value={parameters.shock / 100}
                color={vitalsColor(parameters.shock, 50)}
              >
                {Math.round(parameters.shock)}
              </ProgressBar>
            </LabeledList.Item>

            <LabeledList.Item label="Heart" tooltip={TOOLTIPS.heartbeat}>
              {parameters.heartbeat.rate} bpm ({parameters.heartbeat.rhythm})
            </LabeledList.Item>

            <LabeledList.Item label="Breathing" tooltip={TOOLTIPS.breathing}>
              {parameters.breathing.rate}/min
              {!parameters.breathing.effective && (
                <Box inline color="bad" ml={1}>
                  impaired
                </Box>
              )}
            </LabeledList.Item>

            <LabeledList.Item label="Bleed rate" tooltip={TOOLTIPS.bleedRate}>
              <Box color={parameters.bleed_rate > 1 ? 'bad' : undefined}>
                {parameters.bleed_rate.toFixed(1)}
              </Box>
            </LabeledList.Item>
          </LabeledList>
        </Section>
      </Stack.Item>

      <Stack.Item>
        <Section title="Lungs" fitted>
          <Stack>
            <Stack.Item grow>
              <LungSide label="L" data={lungs.left} />
            </Stack.Item>
            <Stack.Item grow>
              <LungSide label="R" data={lungs.right} />
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>

      <Stack.Item grow>
        <Section title="Cardiogram" fill fitted>
          <Cardiogram
            rate={parameters.heartbeat.rate}
            rhythm={cardiogram.rhythm}
            strength={parameters.heartbeat.strength}
            alert={cardiogram.alert}
            noise={cardiogram.noise ?? 0}
            flatline={cardiogram.flatline ?? 0}
          />
        </Section>
      </Stack.Item>
    </Stack>
  );
};

const LungSide = (props: {
  label: string;
  data: HealthPanelData['lungs']['left'];
}) => {
  const { label, data } = props;
  const isOk =
    data.functional &&
    !data.collapsed &&
    data.fill_blood === 0 &&
    data.fill_fluid === 0;

  return (
    <Box className="HealthPanel__lung">
      <Box bold>{label}</Box>
      {data.collapsed && <Box color="bad">Collapsed</Box>}
      {!data.functional && <Box color="bad">Non-functional</Box>}
      {data.fill_blood > 0 && (
        <Box color="bad">Blood: {Math.round(data.fill_blood * 100)}%</Box>
      )}
      {data.fill_fluid > 0 && (
        <Box color="average">Fluid: {Math.round(data.fill_fluid * 100)}%</Box>
      )}
      {isOk && <Box color="good">OK</Box>}
    </Box>
  );
};
