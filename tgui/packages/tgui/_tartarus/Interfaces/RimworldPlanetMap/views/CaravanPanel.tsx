import {
  Box,
  Button,
  LabeledList,
  Section,
  Stack,
} from 'tgui-core/components';

import { useBackend } from 'tgui/backend';

import type {
  PlanetMapData,
  PlanetTile,
} from '../types';

type CaravanPanelProps = {
  localTile?: PlanetTile | null;
};

export const CaravanPanel = (
  props: CaravanPanelProps,
) => {
  const { act, data } =
    useBackend<PlanetMapData>();

  const view = data.view ?? {};
  const selected = data.selectedTile;

  return (
    <Stack fill vertical>
      <Stack.Item>
        <Section title="Caravan">
          <Box color="average" mb={1}>
            {view.status ||
              'Caravan travel is not implemented yet.'}
          </Box>
          <LabeledList>
            <LabeledList.Item label="Id">
              {view.caravanId || '—'}
            </LabeledList.Item>
            <LabeledList.Item label="Origin">
              {view.originX != null
                ? `${view.originX}, ${view.originY}`
                : '—'}
            </LabeledList.Item>
            <LabeledList.Item label="Destination">
              {view.destinationX != null
                ? `${view.destinationX}, ${view.destinationY}`
                : '—'}
            </LabeledList.Item>
          </LabeledList>
        </Section>
      </Stack.Item>

      <Stack.Item grow>
        <Section fill title="Looked tile">
          {!selected && (
            <Box color="label">
              Click a destination on the planet.
            </Box>
          )}
          {!!selected && (
            <LabeledList>
              <LabeledList.Item label="X">
                {selected.x}
              </LabeledList.Item>
              <LabeledList.Item label="Y">
                {selected.y}
              </LabeledList.Item>
              <LabeledList.Item label="Biome">
                {props.localTile?.biome ??
                  selected.biome ??
                  '—'}
              </LabeledList.Item>
            </LabeledList>
          )}
        </Section>
      </Stack.Item>

      <Stack.Item>
        <Button
          fluid
          icon="route"
          disabled={!view.canTravel}
          onClick={() => act('travel')}
        >
          Travel
        </Button>
      </Stack.Item>
    </Stack>
  );
};
