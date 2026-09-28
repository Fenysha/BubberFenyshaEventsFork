import { Box, ProgressBar, Section, Stack } from 'tgui-core/components';
import type { BodypartData, InjuryData, OrganData } from './types';

type Props = {
  selectedZone: string | null;
  bodyparts: Record<string, BodypartData>;
  organs: {
    brain: OrganData;
    heart: OrganData;
    lungs: OrganData;
  };
};

export const RightPanel = (props: Props) => {
  const { selectedZone, bodyparts, organs } = props;

  if (!selectedZone) {
    return (
      <Section title="Status" fill>
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
      <Section title="Status" fill>
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

  return (
    <Section title={data.name} fill>
      <Stack vertical>
        <Stack.Item>
          <Box>
            Brute:{' '}
            <ProgressBar
              value={data.brute}
              maxValue={data.max_damage}
              ranges={{
                good: [0, 0.2],
                average: [0.2, 0.5],
                bad: [0.5, Infinity],
              }}
            >
              {Math.round(data.brute)}
            </ProgressBar>
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Box>
            Burn:{' '}
            <ProgressBar
              value={data.burn}
              maxValue={data.max_damage}
              ranges={{
                good: [0, 0.2],
                average: [0.2, 0.5],
                bad: [0.5, Infinity],
              }}
            >
              {Math.round(data.burn)}
            </ProgressBar>
          </Box>
        </Stack.Item>
        {data.disabled && (
          <Stack.Item>
            <Box color="bad">Disabled</Box>
          </Stack.Item>
        )}
        {data.bleed_rate > 0 && (
          <Stack.Item>
            <Box color="bad">Bleeding: {data.bleed_rate.toFixed(1)}</Box>
          </Stack.Item>
        )}
        <Stack.Item>
          <Box bold mt={1}>
            Injuries
          </Box>
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
  return (
    <Section title={name} fill>
      {!data.present ? (
        <Box color="bad" bold>
          Missing
        </Box>
      ) : (
        <Stack vertical>
          <Stack.Item>
            <ProgressBar
              value={data.health}
              maxValue={100}
              ranges={{ good: [70, 100], average: [30, 70], bad: [0, 30] }}
            >
              {Math.round(data.health)}%
            </ProgressBar>
          </Stack.Item>
          {data.failing && (
            <Stack.Item>
              <Box color="bad">Failing</Box>
            </Stack.Item>
          )}
          {data.beating === false && (
            <Stack.Item>
              <Box color="bad">Not beating</Box>
            </Stack.Item>
          )}
          <Stack.Item>
            <Box>{data.status}</Box>
          </Stack.Item>
        </Stack>
      )}
    </Section>
  );
};

const InjuryEntry = (props: { injury: InjuryData }) => {
  const { injury } = props;
  return (
    <Box className="HealthPanel__injury">
      <Box>
        {injury.name}{' '}
        <Box as="span" color="label">
          ({injury.severity_text})
        </Box>
      </Box>
      {injury.bleed_rate > 0 && (
        <Box color="bad" fontSize="0.9em">
          Bleed: {injury.bleed_rate.toFixed(1)}
        </Box>
      )}
      {injury.disabling && (
        <Box color="bad" fontSize="0.9em">
          Disabling
        </Box>
      )}
    </Box>
  );
};
