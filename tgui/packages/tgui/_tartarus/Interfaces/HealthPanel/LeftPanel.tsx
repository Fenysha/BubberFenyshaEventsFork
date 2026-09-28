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
      return 'Sinus rhythm';
    case 'bradycardia':
      return 'Bradycardia';
    case 'tachycardia':
      return 'Tachycardia';
    case 'ventricular_tachycardia':
      return 'Ventricular tachycardia';
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
      return 'Stopped';
    case 'cpr':
      return 'CPR / assisted circulation';
    default:
      return 'Beating';
  }
};

export const LeftPanel = (props: Props) => {
  const { parameters, cardiogram, lungs } = props.data;
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
        <Section title="Vitals" fitted>
          <Stack vertical>
            <Stack.Item>
              <VitalBar
                label="Consciousness"
                value={parameters.consciousness}
                color={inverseRiskColor(parameters.consciousness, 15, 40)}
              />
            </Stack.Item>
            <Stack.Item>
              <VitalBar
                label="Pain"
                value={parameters.pain}
                max={200}
                color={riskColor(parameters.pain, 45, 90)}
              />
            </Stack.Item>
            <Stack.Item>
              <VitalBar
                label="Shock"
                value={parameters.shock}
                color={riskColor(parameters.shock, 50, 75)}
              />
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>

      <Stack.Item>
        <Section title="Circulation" fitted>
          <LabeledList>
            <LabeledList.Item
              label="Blood pressure"
              tooltip={TOOLTIPS.bloodPressure}
            >
              <Box color={inverseRiskColor(circulation.blood_pressure, 45, 70)}>
                {Math.round(circulation.blood_pressure)}
              </Box>
            </LabeledList.Item>
            <LabeledList.Item
              label="Brain perfusion"
              tooltip={TOOLTIPS.perfusion}
            >
              <ProgressBar
                value={Math.min(circulation.perfusion / 1.2, 1)}
                color={inverseRiskColor(circulation.perfusion, 0.45, 0.75)}
              >
                {Math.round((circulation.perfusion / 1.2) * 100)}%
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Item
              label="Blood volume"
              tooltip={TOOLTIPS.bloodVolume}
            >
              <ProgressBar
                value={Math.min(circulation.blood_ratio, 1)}
                color={inverseRiskColor(circulation.blood_ratio, 0.55, 0.8)}
              >
                {Math.round(circulation.blood_ratio * 100)}%
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Item label="Bleed rate" tooltip={TOOLTIPS.bleedRate}>
              <Box
                color={
                  parameters.bleed_rate > 3
                    ? 'bad'
                    : parameters.bleed_rate > 1
                      ? 'average'
                      : undefined
                }
              >
                {parameters.bleed_rate.toFixed(1)} /s
              </Box>
            </LabeledList.Item>
          </LabeledList>
        </Section>
      </Stack.Item>

      <Stack.Item>
        <Section title="Heart" fitted>
          <Stack vertical>
            <Stack.Item>
              <Box bold color={heartColor}>
                {heartStateLabel(heartbeat.state)}
              </Box>
            </Stack.Item>
            <Stack.Item>
              <LabeledList>
                <LabeledList.Item label="Pulse" tooltip={TOOLTIPS.heartbeat}>
                  {heartbeat.rate} bpm
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
              </LabeledList>
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>

      <Stack.Item>
        <Section title="Respiration" fitted>
          <LabeledList>
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
            <LabeledList.Item label="Breathing" tooltip={TOOLTIPS.breathing}>
              {breathing.effective ? 'Effective' : 'Impaired'}
            </LabeledList.Item>
            <LabeledList.Item label="Lung fluid" tooltip={TOOLTIPS.lungFluid}>
              <Box
                color={
                  breathing.fluid_ratio > 0.6
                    ? 'bad'
                    : breathing.fluid_ratio > 0.25
                      ? 'average'
                      : undefined
                }
              >
                {Math.round(breathing.fluid_ratio * 100)}%
              </Box>
            </LabeledList.Item>
          </LabeledList>
        </Section>
      </Stack.Item>

      <Stack.Item grow>
        <Section title="Cardiogram" fill fitted>
          <Cardiogram
            rate={heartbeat.rate}
            rhythm={cardiogram.rhythm}
            strength={heartbeat.strength}
            alert={cardiogram.alert}
            noise={cardiogram.noise ?? 0}
            flatline={cardiogram.flatline ?? 0}
          />
        </Section>
      </Stack.Item>
    </Stack>
  );
};

const VitalBar = (props: {
  label: string;
  value: number;
  max?: number;
  color: 'good' | 'average' | 'bad';
}) => {
  const { label, value, max = 100, color } = props;
  return (
    <Box className="HealthPanel__stat">
      <Box className="HealthPanel__stat-label">{label}</Box>
      <ProgressBar value={value / max} color={color}>
        {Math.round(value)}
      </ProgressBar>
    </Box>
  );
};
