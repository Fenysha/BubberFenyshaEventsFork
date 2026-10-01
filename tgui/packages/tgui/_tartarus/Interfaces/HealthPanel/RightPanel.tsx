import { useState } from 'react';
import { useBackend } from 'tgui/backend';
import {
  Box,
  Button,
  LabeledList,
  ProgressBar,
  Section,
  Stack,
} from 'tgui-core/components';
import { TOOLTIPS } from './tooltips';
import type {
  BodypartData,
  HealthPanelData,
  InjuryData,
  OrganData,
  RhythmType,
  TreatOption,
} from './types';

type Props = {
  selectedZone: string | null;
  bodyparts: Record<string, BodypartData>;
  organs: {
    brain: OrganData;
    heart: OrganData;
    lungs: OrganData;
  };
};

const rhythmLabel = (rhythm?: RhythmType | string) => {
  switch (rhythm) {
    case 'normal':
      return 'Sinus rhythm';
    case 'bradycardia':
      return 'Bradycardia';
    case 'tachycardia':
      return 'Tachycardia';
    case 'ventricular_tachycardia':
      return 'Ventricular tachycardia';
    case 'ventricular_fibrillation':
    case 'fibrillation':
      return 'Ventricular fibrillation';
    case 'asystole':
      return 'Asystole';
    case 'arrhythmia':
      return 'Arrhythmia';
    case 'pvc':
      return 'PVC';
    default:
      return rhythm ?? 'Unknown';
  }
};

const treatmentLabel = (quality?: number) => {
  switch (quality) {
    case 1:
      return 'Poorly treated';
    case 2:
      return 'Treated';
    case 3:
      return 'Expertly treated';
    default:
      return 'Untreated';
  }
};

function toPngSrc(value: string) {
  if (value.startsWith('data:')) return value;
  return `data:image/png;base64,${value}`;
}

export const RightPanel = (props: Props) => {
  const { selectedZone, bodyparts, organs } = props;
  const { data } = useBackend<HealthPanelData>();
  const canTreat = data.can_treat === true;
  const canSeeFull = data.can_see_full === true;
  const viewerAccess = data.viewer_access ?? 0;

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
    return (
      <OrganStatus
        name={selectedZone}
        data={organs[selectedZone]}
        canSeeFull={canSeeFull}
        viewerAccess={viewerAccess}
      />
    );
  }

  const part = bodyparts[selectedZone];
  if (!part) {
    return (
      <Section title="Inspection" fill>
        <Box color="bad">Unknown zone.</Box>
      </Section>
    );
  }

  return (
    <LimbStatus
      data={part}
      canTreat={canTreat}
      canSeeFull={canSeeFull}
      viewerAccess={viewerAccess}
    />
  );
};

const integrityColor = (value: number): 'good' | 'average' | 'bad' => {
  if (value <= 25) return 'bad';
  if (value <= 65) return 'average';
  return 'good';
};

const LimbStatus = ({
  data,
  canTreat,
  canSeeFull,
  viewerAccess,
}: {
  data: BodypartData;
  canTreat: boolean;
  canSeeFull: boolean;
  viewerAccess: number;
}) => {
  if (!data.present) {
    return (
      <Section title={data.name} fill>
        <Box color="bad" bold>
          Absent
        </Box>
      </Section>
    );
  }

  const showIntegrity = viewerAccess >= 1 || canSeeFull;

  return (
    <Section title={data.name} fill>
      <Stack vertical>
        {showIntegrity && (
          <Stack.Item>
            <LabeledList>
              <LabeledList.Item label="Structure">
                <ProgressBar
                  value={Math.max(
                    0,
                    Math.min(data.structural_integrity / 100, 1),
                  )}
                  color={integrityColor(data.structural_integrity)}
                >
                  {Math.round(data.structural_integrity)}%
                </ProgressBar>
              </LabeledList.Item>

              <LabeledList.Item label="Skin">
                <ProgressBar
                  value={Math.max(0, Math.min(data.skin_integrity / 100, 1))}
                  color={integrityColor(data.skin_integrity)}
                >
                  {Math.round(data.skin_integrity)}%
                </ProgressBar>
              </LabeledList.Item>
            </LabeledList>
          </Stack.Item>
        )}

        {(data.disabled || data.bleed_rate > 0) && (
          <Stack.Item>
            <Stack>
              {data.disabled && (
                <Stack.Item grow>
                  <Box color="bad" bold>
                    Disabled
                  </Box>
                </Stack.Item>
              )}
              {data.bleed_rate > 0 && (
                <Stack.Item grow>
                  <Box color="bad">
                    Bleeding: {data.bleed_rate.toFixed(1)}/s
                  </Box>
                </Stack.Item>
              )}
            </Stack>
          </Stack.Item>
        )}

        <Stack.Item>
          <Box bold>Active injuries</Box>
          {data.injuries.length === 0 && (
            <Box color="label">No visible injuries.</Box>
          )}
          {data.injuries.map((injury) => (
            <InjuryEntry
              key={injury.id}
              injury={injury}
              canTreat={canTreat}
              canSeeFull={canSeeFull}
            />
          ))}
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const OrganStatus = ({
  name,
  data,
  canSeeFull,
  viewerAccess,
}: {
  name: string;
  data: OrganData;
  canSeeFull: boolean;
  viewerAccess: number;
}) => {
  if (!data.present) {
    return (
      <Section title={name} fill>
        <Box color="bad" bold>
          Missing
        </Box>
      </Section>
    );
  }

  if (viewerAccess < 1 && !canSeeFull) {
    return (
      <Section title={name} fill>
        <Box color="label">{data.status}</Box>
        {data.failing && (
          <Box color="bad" bold>
            Appears compromised
          </Box>
        )}
      </Section>
    );
  }

  if (name === 'heart') return <HeartStatus data={data} />;
  if (name === 'brain') return <BrainStatus data={data} />;
  return <LungStatus data={data} />;
};

const OrganIntegrity = ({ value }: { value: number }) => (
  <ProgressBar
    value={Math.max(0, Math.min(value / 100, 1))}
    color={integrityColor(value)}
  >
    {Math.round(value)}%
  </ProgressBar>
);

const HeartStatus = ({ data }: { data: OrganData }) => {
  const fibrillating =
    data.fibrillating ||
    data.state === 'fibrillating' ||
    data.rhythm === 'ventricular_fibrillation' ||
    data.rhythm === 'fibrillation';
  const stopped =
    data.state === 'stopped' ||
    data.state === 'missing' ||
    data.rhythm === 'asystole';
  const failing = data.state === 'failing';

  let statusText = 'Heart beating';
  let statusColor: string = 'good';
  if (data.state === 'cpr') {
    statusText = 'CPR / assisted circulation';
    statusColor = 'average';
  } else if (fibrillating) {
    statusText = 'Ventricular fibrillation';
    statusColor = 'bad';
  } else if (stopped) {
    statusText = 'Cardiac arrest';
    statusColor = 'bad';
  } else if (failing) {
    statusText = 'Heart failing';
    statusColor = 'average';
  }

  return (
    <Section title="Heart" fill>
      <Stack vertical>
        <Stack.Item>
          <Box bold color={statusColor}>
            {statusText}
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
            <LabeledList.Item label="Preload">
              <ProgressBar value={data.preload ?? 1}>
                {Math.round((data.preload ?? 1) * 100)}%
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Item label="Cardiac output">
              <ProgressBar value={Math.min(data.cardiac_output ?? 0, 1)}>
                {Math.round((data.cardiac_output ?? 0) * 100)}%
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Item label="Myocardial integrity">
              <OrganIntegrity value={data.health} />
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
              <OrganIntegrity value={data.health} />
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
              <OrganIntegrity value={data.health} />
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

const TreatButtons = ({
  injuryId,
  options,
}: {
  injuryId: string;
  options: TreatOption[];
}) => {
  const { act } = useBackend<HealthPanelData>();

  if (!options.length) return null;

  return (
    <Stack className="HealthPanel__treat-row">
      {options.map((opt) => (
        <Stack.Item key={opt.type}>
          <Button
            className="HealthPanel__treat-btn"
            tooltip={`Treat with ${opt.name}`}
            onClick={() =>
              act('treat_injury', {
                injury_id: injuryId,
                item_type: opt.type,
              })
            }
          >
            {opt.iconSrc ? (
              <img
                className="HealthPanel__treat-icon"
                src={toPngSrc(opt.iconSrc)}
                alt={opt.name}
                draggable={false}
              />
            ) : (
              <span className="HealthPanel__treat-fallback">{opt.name}</span>
            )}
          </Button>
        </Stack.Item>
      ))}
    </Stack>
  );
};

const InjuryEntry = ({
  injury,
  canTreat,
  canSeeFull,
}: {
  injury: InjuryData;
  canTreat: boolean;
  canSeeFull: boolean;
}) => {
  const [open, setOpen] = useState(false);
  const healing = injury.healing_progress ?? 0;
  const treated = injury.treated || (injury.treatment_quality ?? 0) > 0;
  const displayName =
    canSeeFull || !injury.undiagnosed_name
      ? injury.name
      : injury.undiagnosed_name;

  const treatOptions =
    canTreat &&
    Array.isArray(injury.treat_options) &&
    injury.treat_options.length > 0
      ? injury.treat_options
      : [];

  return (
    <Box className="HealthPanel__injury">
      <Stack align="center" className="HealthPanel__injury-header">
        <Stack.Item grow>
          <Box bold>
            {displayName}{' '}
            <Box as="span" color="label">
              ({injury.severity_text})
            </Box>
          </Box>
        </Stack.Item>
        {treatOptions.length > 0 && (
          <Stack.Item>
            <TreatButtons injuryId={injury.id} options={treatOptions} />
          </Stack.Item>
        )}
      </Stack>

      <Box
        className="HealthPanel__injury-toggle"
        onClick={() => setOpen(!open)}
      >
        {open ? '▾ details' : '▸ details'}
      </Box>

      {open && (
        <Box className="HealthPanel__injury-body">
          {injury.desc && (
            <Box color="label" fontSize="0.9em">
              {injury.desc}
            </Box>
          )}

          <Stack>
            {injury.bleed_rate > 0 && (
              <Stack.Item grow>
                <Box color="bad">
                  Blood loss: {injury.bleed_rate.toFixed(1)}/s
                </Box>
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

          <Box fontSize="0.85em" color="label">
            {treatmentLabel(injury.treatment_quality)}
            {healing > 0.05 && ` · healing ${Math.round(healing * 100)}%`}
            {treated && healing <= 0.05 && ' · stabilizing'}
          </Box>

          {healing > 0.05 && (
            <ProgressBar value={Math.max(0, Math.min(healing, 1))} color="good">
              {Math.round(healing * 100)}%
            </ProgressBar>
          )}
        </Box>
      )}
    </Box>
  );
};
