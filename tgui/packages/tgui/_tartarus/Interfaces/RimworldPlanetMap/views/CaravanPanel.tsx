import { useBackend } from 'tgui/backend';

import { Box, Button, LabeledList, Section, Stack } from 'tgui-core/components';

import type { PlanetMapData, PlanetTile } from '../types';

import { TileDetails } from './TileDetails';

type CaravanPanelProps = {
  localTile?: PlanetTile | null;
};

export const CaravanPanel = ({ localTile }: CaravanPanelProps) => {
  const { act, data } = useBackend<PlanetMapData>();

  const view = data.view ?? {};

  return (
    <Stack fill vertical>
      <Stack.Item>
        <Section title="Caravan">
          <Box color="average" mb={1}>
            {view.status || 'Caravan travel is not implemented yet.'}
          </Box>

          <LabeledList>
            <LabeledList.Item label="ID">
              {view.caravanId || '—'}
            </LabeledList.Item>

            <LabeledList.Item label="Origin">
              {view.originX != null ? `${view.originX}, ${view.originY}` : '—'}
            </LabeledList.Item>

            <LabeledList.Item label="Destination">
              {view.destinationX != null
                ? `${view.destinationX}, ${view.destinationY}`
                : '—'}
            </LabeledList.Item>

            <LabeledList.Item label="Travel">
              {view.canTravel ? 'Available' : 'Unavailable'}
            </LabeledList.Item>
          </LabeledList>
        </Section>
      </Stack.Item>

      <Stack.Item grow>
        <TileDetails tile={localTile} title="Destination tile" />
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
