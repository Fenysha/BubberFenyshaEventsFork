import {
  Box,
  LabeledList,
  ProgressBar,
  Section,
  Stack,
} from 'tgui-core/components';
import { Cardiogram } from './Cardiogram';
import { LungsIndicator } from './LungsIndicator';
import { TOOLTIPS } from './tooltips';
import type { HealthPanelData } from './types';

type Props = {
  data: HealthPanelData;
};

const BLOOD_FULL_LITERS = 5.0;
const BLOOD_VOLUME_FULL_UNITS = 560;

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

/**
 * Convert backend bleeding rate from blood units/sec into liters/min.
 */
const bloodLossLitersPerMinute = (rate: number): number => {
  if (rate <= 0 || BLOOD_VOLUME_FULL_UNITS <= 0) {
    return 0;
  }

  return rate * 60 * (BLOOD_FULL_LITERS / BLOOD_VOLUME_FULL_UNITS);
};



/**
 * Convert backend blood volume / ratio into liters for display.
 * Prefers absolute volume when present; falls back to ratio × nominal full load.
 */
const bloodLiters = (volume: number, ratio: number): number => {
  if (volume > 0 && BLOOD_VOLUME_FULL_UNITS > 0) {
    return (volume / BLOOD_VOLUME_FULL_UNITS) * BLOOD_FULL_LITERS;
  }
  return Math.max(0, ratio) * BLOOD_FULL_LITERS;
};

/**
 * Format mean systemic pressure for the UI.
 * Backend stores a single composite BP value — show mmHg + clinical band.
 */
const formatBloodPressure = (
  bp: number,
): { value: string; band: string; color: 'good' | 'average' | 'bad' } => {
  const rounded = Math.round(bp);

  if (bp < 40) {
    return { value: `${rounded} mmHg`, band: 'collapse', color: 'bad' };
  }
  if (bp < 70) {
    return { value: `${rounded} mmHg`, band: 'hypotension', color: 'bad' };
  }
  if (bp < 90) {
    return { value: `${rounded} mmHg`, band: 'low', color: 'average' };
  }
  if (bp <= 130) {
    return { value: `${rounded} mmHg`, band: 'normal', color: 'good' };
  }
  if (bp <= 160) {
    return { value: `${rounded} mmHg`, band: 'elevated', color: 'average' };
  }
  return { value: `${rounded} mmHg`, band: 'hypertensive', color: 'bad' };
};

/**
 * 0 = healthy, 1 = critical — drives ECG color and overall urgency.
 */
const getCardiacCriticality = (data: HealthPanelData): number => {
  const hb = data.parameters.heartbeat;
  const circ = data.parameters.circulation;
  const brain = data.organs.brain;

  let score = 0;

  if (
    hb.state === 'missing' ||
    hb.state === 'stopped' ||
    hb.rhythm === 'asystole'
  ) {
    score = 1;
  } else if (
    hb.fibrillating ||
    hb.state === 'fibrillating' ||
    hb.rhythm === 'ventricular_fibrillation' ||
    hb.rhythm === 'fibrillation'
  ) {
    score = 0.95;
  } else if (hb.rhythm === 'ventricular_tachycardia') {
    score = 0.75;
  } else if (hb.state === 'failing' || hb.cardiac_output < 0.35) {
    score = 0.7;
  } else {
    score += (1 - Math.min(hb.cardiac_output, 1)) * 0.35;
    score += (1 - Math.min(circ.blood_ratio, 1)) * 0.25;
    score += (1 - Math.min(circ.perfusion / 1.2, 1)) * 0.2;
    if ((brain.oxygen ?? 100) < 60) {
      score += ((60 - (brain.oxygen ?? 100)) / 60) * 0.2;
    }
  }

  return Math.max(0, Math.min(1, score));
};

export const LeftPanel = (props: Props) => {
  const { parameters, cardiogram, lungs } = props.data;
  const heartbeat = parameters.heartbeat;
  const circulation = parameters.circulation;
  const breathing = parameters.breathing;

  const criticality = getCardiacCriticality(props.data);

  const liters = bloodLiters(circulation.blood_volume, circulation.blood_ratio);
  const pressure = formatBloodPressure(circulation.blood_pressure);
  const bleedPerMin = bloodLossLitersPerMinute(parameters.bleed_rate);

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
          </Stack>
        </Section>
      </Stack.Item>

      <Stack.Item>
        <Section title="Circulation" fitted>
          <LabeledList>
            <LabeledList.Item label="Pressure" tooltip={TOOLTIPS.bloodPressure}>
              <Box color={pressure.color}>
                <Box as="span" bold>
                  {pressure.value}
                </Box>
                <Box as="span" color="label" fontSize="0.85em">
                  {' '}
                  · {pressure.band}
                </Box>
              </Box>
            </LabeledList.Item>

            <LabeledList.Item label="Perfusion" tooltip={TOOLTIPS.perfusion}>
              <ProgressBar
                value={Math.min(circulation.perfusion / 1.2, 1)}
                color={inverseRiskColor(circulation.perfusion, 0.45, 0.75)}
              >
                {Math.round((circulation.perfusion / 1.2) * 100)}%
              </ProgressBar>
            </LabeledList.Item>

            <LabeledList.Item label="Blood" tooltip={TOOLTIPS.bloodVolume}>
              <ProgressBar
                value={Math.min(Math.max(circulation.blood_ratio, 0), 1)}
                color={inverseRiskColor(circulation.blood_ratio, 0.55, 0.8)}
              >
                {liters.toFixed(2)} L
                <Box as="span" color="label" fontSize="0.85em">
                  {' '}
                  ({Math.round(circulation.blood_ratio * 100)}%)
                </Box>
              </ProgressBar>
            </LabeledList.Item>

            <LabeledList.Item label="Bleeding" tooltip={TOOLTIPS.bleedRate}>
              <Box
                color={
                  bleedPerMin > 1.6
                    ? 'bad'
                    : bleedPerMin > 0.54
                      ? 'average'
                      : undefined
                }
              >
                {bleedPerMin < 0.00045
                  ? 'none'
                  : `${bleedPerMin.toFixed(2)} L/min`}
              </Box>
            </LabeledList.Item>
          </LabeledList>
        </Section>
      </Stack.Item>

      <Stack.Item style={{ minWidth: 0, maxWidth: '100%', overflow: 'hidden' }}>
        <Section title="Respiration" fitted>
          <LungsIndicator
            lungs={lungs}
            oxygenation={breathing.oxygenation}
            ventilation={breathing.ventilation}
            iconSize={96}
            iconScale={2}
            offsetX={142}
            offsetY={-40}
          />
        </Section>
      </Stack.Item>

      <Stack.Item grow>
        <Section title="ECG" fitted fill>
          <Cardiogram
            rate={heartbeat.rate}
            rhythm={cardiogram.rhythm}
            strength={heartbeat.strength}
            alert={cardiogram.alert}
            noise={cardiogram.noise ?? 0}
            flatline={cardiogram.flatline ?? 0}
            criticality={criticality}
            cardiacOutput={heartbeat.cardiac_output}
            compact
          />
        </Section>
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
