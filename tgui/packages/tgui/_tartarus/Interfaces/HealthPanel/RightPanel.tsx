import {
  Box,
  LabeledList,
  ProgressBar,
  Section,
  Stack,
} from 'tgui-core/components';
import { TOOLTIPS } from './tooltips';
import type { BodypartData, InjuryData, OrganData, RhythmType } from './types';

type Props = {
  selectedZone: string | null;
  bodyparts: Record<string, BodypartData>;
  organs: {
    brain: OrganData;
    heart: OrganData;
    lungs: OrganData;
  };
};

const rhythmLabel = (rhythm?: RhythmType) => {
  switch (rhythm) {
    case 'normal':
      return 'Sinus rhythm';
    case 'bradycardia':
      return 'Bradycardia';
    case 'tachycardia':
      return 'Tachycardia';
    case 'ventricular_tachycardia':
      return 'Ventricular tachycardia';
    case 'asystole':
      return 'Asystole';
    case 'fibrillation':
      return 'Fibrillation';
    case 'arrhythmia':
      return 'Arrhythmia';
    case 'pvc':
      return 'PVC';
    default:
      return rhythm ?? 'Unknown';
  }
};

export const RightPanel = (props: Props) => {
  const { selectedZone, bodyparts, organs } = props;

  if (!selectedZone) {
    return (
      <Section title="Inspection" fill>
        <Box color="label">Select a body part or organ.</Box>
      </Section>
    );
  }

  if (
    selectedZone === 'brain' ||
    selectedZone === 'heart' ||
    selectedZone === 'lungs'
  ) {
    const organ = organs[selectedZone];
    return <OrganStatus name={selectedZone} data={organ} />;
  }

  const part = bodyparts[selectedZone];
  if (!part) {
    return (
      <Section title="Inspection" fill>
        <Box color="bad">Unknown zone.</Box>
      </Section>
    );
  }

  return <LimbStatus data={part} />;
};

const LimbStatus = (props: { data: BodypartData }) => {
  const { data } = props;

  if (!data.present) {
    return (
      <Section title={data.name} fill>
        <Box color="bad" bold>
          Missing
        </Box>
      </Section>
    );
  }

  const damageRatio =
    data.max_damage > 0
      ? Math.min((data.brute + data.burn) / data.max_damage, 1)
      : 0;

  return (
    <Section title={data.name} fill>
      <Stack vertical>
        <Stack.Item>
          <LabeledList>
            <LabeledList.Item label="Brute" tooltip={TOOLTIPS.limbBrute}>
              <ProgressBar
                value={data.brute / Math.max(data.max_damage, 1)}
                color={damageColor(data.brute / Math.max(data.max_damage, 1))}
              >
                {Math.round(data.brute)}
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Item label="Burn" tooltip={TOOLTIPS.limbBurn}>
              <ProgressBar
                value={data.burn / Math.max(data.max_damage, 1)}
                color={damageColor(data.burn / Math.max(data.max_damage, 1))}
              >
                {Math.round(data.burn)}
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Item label="Integrity">
              <ProgressBar
                value={1 - damageRatio}
                color={
                  damageRatio > 0.7
                    ? 'bad'
                    : damageRatio > 0.35
                      ? 'average'
                      : 'good'
                }
              >
                {Math.round((1 - damageRatio) * 100)}%
              </ProgressBar>
            </LabeledList.Item>
          </LabeledList>
        </Stack.Item>

        {(data.disabled || data.bleed_rate > 0) && (
          <Stack.Item>
            {data.disabled && (
              <Box color="bad" bold>
                Disabled
              </Box>
            )}
            {data.bleed_rate > 0 && (
              <Box color="bad">Bleeding: {data.bleed_rate.toFixed(1)} /s</Box>
            )}
          </Stack.Item>
        )}

        <Stack.Item>
          <Box bold>Injuries</Box>
          {data.injuries.length === 0 && <Box color="label">None</Box>}
          {data.injuries.map((injury) => (
            <InjuryEntry key={injury.id} injury={injury} />
          ))}
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const OrganStatus = (props: { name: string; data: OrganData }) => {
  const { name, data } = props;
  const title = name.charAt(0).toUpperCase() + name.slice(1);

  if (!data.present) {
    return (
      <Section title={title} fill>
        <Box color="bad" bold>
          Missing
        </Box>
      </Section>
    );
  }

  if (name === 'heart') {
    return <HeartStatus data={data} />;
  }
  if (name === 'brain') {
    return <BrainStatus data={data} />;
  }
  return <LungStatus data={data} />;
};

const HeartStatus = ({ data }: { data: OrganData }) => {
  return (
    <Section title="Heart" fill>
      <Stack vertical>
        <Stack.Item>
          <Box
            bold
            color={
              data.state === 'stopped' || data.state === 'missing'
                ? 'bad'
                : data.state === 'failing' || (data.cardiac_output ?? 0) < 0.6
                  ? 'average'
                  : 'good'
            }
          >
            {data.state === 'cpr'
              ? 'CPR / assisted circulation'
              : data.state === 'stopped'
                ? 'Cardiac arrest'
                : data.state === 'failing'
                  ? 'Heart failing'
                  : 'Heart beating'}
          </Box>
        </Stack.Item>
        <Stack.Item>
          <LabeledList>
            <LabeledList.Item label="Rate">
              {data.rate ?? 0} bpm
            </LabeledList.Item>
            <LabeledList.Item label="Rhythm">
              {rhythmLabel(data.rhythm)}
            </LabeledList.Item>
            <LabeledList.Item label="Contractility">
              <ProgressBar value={data.contractility ?? 0}>
                {Math.round((data.contractility ?? 0) * 100)}%
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Item label="Stroke efficiency">
              <ProgressBar value={data.stroke_efficiency ?? 0}>
                {Math.round((data.stroke_efficiency ?? 0) * 100)}%
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Item label="Cardiac output">
              <ProgressBar value={Math.min(data.cardiac_output ?? 0, 1)}>
                {Math.round((data.cardiac_output ?? 0) * 100)}%
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Item label="Myocardium">
              <ProgressBar
                value={data.health / 100}
                color={
                  data.health < 30
                    ? 'bad'
                    : data.health < 70
                      ? 'average'
                      : 'good'
                }
              >
                {Math.round(data.health)}%
              </ProgressBar>
            </LabeledList.Item>
          </LabeledList>
        </Stack.Item>
        {data.cpr && (
          <Stack.Item>
            <Box color="average">
              External circulation currently supported by CPR.
            </Box>
          </Stack.Item>
        )}
        <Stack.Item>
          <Box color="label">{data.status}</Box>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const BrainStatus = ({ data }: { data: OrganData }) => {
  const oxygen = data.oxygen ?? 0;
  const perfusion = data.perfusion ?? 0;
  return (
    <Section title="Brain" fill>
      <Stack vertical>
        <Stack.Item>
          <LabeledList>
            <LabeledList.Item label="Integrity">
              <ProgressBar
                value={data.health / 100}
                color={
                  data.health < 30
                    ? 'bad'
                    : data.health < 70
                      ? 'average'
                      : 'good'
                }
              >
                {Math.round(data.health)}%
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Item label="Brain O₂" tooltip={TOOLTIPS.brainOxygen}>
              <ProgressBar
                value={oxygen / 100}
                color={oxygen < 30 ? 'bad' : oxygen < 60 ? 'average' : 'good'}
              >
                {Math.round(oxygen)}%
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Item label="Perfusion" tooltip={TOOLTIPS.perfusion}>
              <ProgressBar
                value={Math.min(perfusion / 1.2, 1)}
                color={
                  perfusion < 0.45
                    ? 'bad'
                    : perfusion < 0.75
                      ? 'average'
                      : 'good'
                }
              >
                {Math.round((perfusion / 1.2) * 100)}%
              </ProgressBar>
            </LabeledList.Item>
          </LabeledList>
        </Stack.Item>
        {data.failing && (
          <Stack.Item>
            <Box color="bad" bold>
              Failing
            </Box>
          </Stack.Item>
        )}
        <Stack.Item>
          <Box color="label">{data.status}</Box>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const LungStatus = ({ data }: { data: OrganData }) => {
  const ventilation = data.ventilation ?? 0;
  const fluid = data.fluid_ratio ?? 0;
  return (
    <Section title="Lungs" fill>
      <Stack vertical>
        <Stack.Item>
          <LabeledList>
            <LabeledList.Item label="Integrity">
              <ProgressBar
                value={data.health / 100}
                color={
                  data.health < 30
                    ? 'bad'
                    : data.health < 70
                      ? 'average'
                      : 'good'
                }
              >
                {Math.round(data.health)}%
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Item
              label="Ventilation"
              tooltip={TOOLTIPS.ventilation}
            >
              <ProgressBar
                value={ventilation}
                color={
                  ventilation < 0.3
                    ? 'bad'
                    : ventilation < 0.7
                      ? 'average'
                      : 'good'
                }
              >
                {Math.round(ventilation * 100)}%
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Item label="Blood O₂" tooltip={TOOLTIPS.oxygenation}>
              <ProgressBar
                value={(data.oxygenation ?? 0) / 100}
                color={
                  (data.oxygenation ?? 0) < 60
                    ? 'bad'
                    : (data.oxygenation ?? 0) < 90
                      ? 'average'
                      : 'good'
                }
              >
                {Math.round(data.oxygenation ?? 0)}%
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Item label="Fluid" tooltip={TOOLTIPS.lungFluid}>
              <ProgressBar
                value={fluid}
                color={fluid > 0.6 ? 'bad' : fluid > 0.25 ? 'average' : 'good'}
              >
                {Math.round(fluid * 100)}%
              </ProgressBar>
            </LabeledList.Item>
          </LabeledList>
        </Stack.Item>
        {data.failing && (
          <Stack.Item>
            <Box color="bad" bold>
              Failing
            </Box>
          </Stack.Item>
        )}
        <Stack.Item>
          <Box color="label">{data.status}</Box>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const damageColor = (ratio: number): 'good' | 'average' | 'bad' => {
  if (ratio >= 0.5) return 'bad';
  if (ratio >= 0.2) return 'average';
  return 'good';
};

const InjuryEntry = (props: { injury: InjuryData }) => {
  const { injury } = props;
  return (
    <Box className="HealthPanel__injury">
      <Box bold>
        {injury.name}{' '}
        <Box as="span" color="label">
          ({injury.severity_text})
        </Box>
      </Box>
      {injury.desc && (
        <Box color="label" fontSize="0.9em">
          {injury.desc}
        </Box>
      )}
      <Stack>
        {injury.bleed_rate > 0 && (
          <Stack.Item grow>
            <Box color="bad">Bleed: {injury.bleed_rate.toFixed(1)} /s</Box>
          </Stack.Item>
        )}
        {injury.pain > 0 && (
          <Stack.Item grow>
            <Box color="average">Pain: {Math.round(injury.pain)}</Box>
          </Stack.Item>
        )}
        {injury.disabling && (
          <Stack.Item>
            <Box color="bad">Disabling</Box>
          </Stack.Item>
        )}
      </Stack>
    </Box>
  );
};
