import { useBackend } from 'tgui/backend';

import { LabeledList, Section, Stack } from 'tgui-core/components';

import type { PlanetMapData, PlanetTile } from '../types';

import { TileDetails } from './TileDetails';

type OverviewPanelProps = {
  localTile?: PlanetTile | null;
};

export const OverviewPanel = ({ localTile }: OverviewPanelProps) => {
  const { data } = useBackend<PlanetMapData>();

  return (
    <Stack fill vertical>
      <Stack.Item>
        <Section title="Planet">
          <LabeledList>
            <LabeledList.Item label="Name">{data.name}</LabeledList.Item>

            <LabeledList.Item label="Type">{data.planetType}</LabeledList.Item>

            <LabeledList.Item label="Seed">{data.seed}</LabeledList.Item>

            <LabeledList.Item label="Map">
              {data.width} × {data.height}
            </LabeledList.Item>

            <LabeledList.Item label="Revision">
              {data.generationRevision}
            </LabeledList.Item>
          </LabeledList>
        </Section>
      </Stack.Item>

      <Stack.Item grow>
        <TileDetails tile={localTile} title="Tile information" />
      </Stack.Item>
    </Stack>
  );
};
