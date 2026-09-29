import {
  Box,
  LabeledList,
  ProgressBar,
  Section,
  Stack,
} from 'tgui-core/components';
import { Cardiogram } from './Cardiogram';
import { TOOLTIPS } from './tooltips';
import type { HealthPanelData, RhythmType } from './types';

type Props = {
  data: HealthPanelData;
};

const riskColor = (
  value: number,
  warning: number,
  danger: number,
): 'good' | 'average' | 'bad' => {
  if (value >= danger) return 'bad';
  if (value >= warning) return 'average';
  return 'good';
};

const inverseRiskColor = (
  value: number,
  danger: number,
  warning: number,
): 'good' | 'average' | 'bad' => {
  if (value <= danger) return 'bad';
  if (value <= warning) return 'average';
  return 'good';
};

const rhythmLabel = (rhythm: RhythmType) => {
  switch (rhythm) {
    case 'normal':
      return 'Sinus';
    case 'bradycardia':
      return 'Brady';
    case 'tachycardia':
      return 'Tachy';
    case 'ventricular_tachycardia':
      return 'VT';
    case 'arrhythmia':
      return 'Arrhythmia';
    case 'fibrillation':
      return 'Fibrillation';
    case 'pvc':
      return 'PVC';
    case 'asystole':
      return 'Asystole';
    default:
      return rhythm;
  }
};

const heartStateLabel = (
  state: HealthPanelData['parameters']['heartbeat']['state'],
) => {
  switch (state) {
    case 'missing':
      return 'Missing';
    case 'failing':
      return 'Failing';
    case 'stopped':
      return 'Arrest';
    case 'cpr':
      return 'CPR';
    default:
      return 'Beating';
  }
};

export const LeftPanel = (props: Props) => {
  const { parameters, cardiogram } = props.data;
  const heartbeat = parameters.heartbeat;
  const circulation = parameters.circulation;
  const breathing = parameters.breathing;

  const heartColor =
    heartbeat.state === 'missing' || heartbeat.state === 'stopped'
      ? 'bad'
      : heartbeat.state === 'failing' || heartbeat.cardiac_output < 0.6
        ? 'average'
        : 'good';

  return (
    <Stack vertical fill>
      <Stack.Item>
        <Section title="Physiology" fitted>
          <Stack vertical>
            <Stack.Item>
              <StatBar
                label="Consciousness"
                value={parameters.consciousness}
                color={inverseRiskColor(parameters.consciousness, 15, 40)}
              />
            </Stack.Item>
            <Stack.Item>
              <StatBar
                label="Pain"
                value={parameters.pain}
                max={200}
                color={riskColor(parameters.pain, 45, 90)}
              />
            </Stack.Item>
            <Stack.Item>
              <StatBar
                label="Shock"
                value={parameters.shock}
                color={riskColor(parameters.shock, 50, 75)}
              />
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>

      <Stack.Item>
        <Section title="Circulation & respiration" fitted>
          <Stack>
            <Stack.Item grow>
              <LabeledList>
                <LabeledList.Item
                  label="Pressure"
                  tooltip={TOOLTIPS.bloodPressure}
                >
                  <Box
                    color={inverseRiskColor(circulation.blood_pressure, 45, 70)}
                  >
                    {Math.round(circulation.blood_pressure)}
                  </Box>
                </LabeledList.Item>

                <LabeledList.Item
                  label="Perfusion"
                  tooltip={TOOLTIPS.perfusion}
                >
                  <ProgressBar
                    value={Math.min(circulation.perfusion / 1.2, 1)}
                    color={inverseRiskColor(circulation.perfusion, 0.45, 0.75)}
                  >
                    {Math.round((circulation.perfusion / 1.2) * 100)}%
                  </ProgressBar>
                </LabeledList.Item>

                <LabeledList.Item label="Blood" tooltip={TOOLTIPS.bloodVolume}>
                  <ProgressBar
                    value={Math.min(circulation.blood_ratio, 1)}
                    color={inverseRiskColor(circulation.blood_ratio, 0.55, 0.8)}
                  >
                    {Math.round(circulation.blood_ratio * 100)}%
                  </ProgressBar>
                </LabeledList.Item>

                <LabeledList.Item label="Bleeding" tooltip={TOOLTIPS.bleedRate}>
                  <Box
                    color={
                      parameters.bleed_rate > 3
                        ? 'bad'
                        : parameters.bleed_rate > 1
                          ? 'average'
                          : undefined
                    }
                  >
                    {parameters.bleed_rate.toFixed(1)}/s
                  </Box>
                </LabeledList.Item>
              </LabeledList>
            </Stack.Item>

            <Stack.Item grow>
              <LabeledList>
                <LabeledList.Item label="Pulse" tooltip={TOOLTIPS.heartbeat}>
                  <Box color={heartColor}>{heartbeat.rate} bpm</Box>
                </LabeledList.Item>

                <LabeledList.Item label="Rhythm" tooltip={TOOLTIPS.heartbeat}>
                  {rhythmLabel(heartbeat.rhythm)}
                </LabeledList.Item>

                <LabeledList.Item
                  label="Output"
                  tooltip={TOOLTIPS.cardiacOutput}
                >
                  {(heartbeat.cardiac_output * 100).toFixed(0)}%
                </LabeledList.Item>

                <LabeledList.Item label="SpO₂" tooltip={TOOLTIPS.oxygenation}>
                  <Box color={inverseRiskColor(breathing.oxygenation, 60, 90)}>
                    {Math.round(breathing.oxygenation)}%
                  </Box>
                </LabeledList.Item>

                <LabeledList.Item
                  label="Ventilation"
                  tooltip={TOOLTIPS.ventilation}
                >
                  <ProgressBar
                    value={breathing.ventilation / 100}
                    color={inverseRiskColor(breathing.ventilation, 30, 70)}
                  >
                    {Math.round(breathing.ventilation)}%
                  </ProgressBar>
                </LabeledList.Item>
              </LabeledList>
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>

      <Stack.Item>
        <Section title="ECG" fitted>
          <Cardiogram
            rate={heartbeat.rate}
            rhythm={cardiogram.rhythm}
            strength={heartbeat.strength}
            alert={cardiogram.alert}
            noise={cardiogram.noise ?? 0}
            flatline={cardiogram.flatline ?? 0}
            compact
          />
        </Section>
      </Stack.Item>

      <Stack.Item>
        <Box color="label" fontSize="0.85em">
          Heart: {heartStateLabel(heartbeat.state)} · Brain perfusion:{' '}
          {Math.round((circulation.perfusion / 1.2) * 100)}%
        </Box>
      </Stack.Item>
    </Stack>
  );
};

const StatBar = (props: {
  label: string;
  value: number;
  max?: number;
  color: 'good' | 'average' | 'bad';
}) => {
  const { label, value, max = 100, color } = props;
  const safeValue = Math.max(0, Math.min(value, max));

  return (
    <Box className="HealthPanel__stat">
      <Box className="HealthPanel__stat-label">{label}</Box>
      <ProgressBar value={safeValue / max} color={color}>
        {Math.round(value)}
      </ProgressBar>
    </Box>
  );
};
