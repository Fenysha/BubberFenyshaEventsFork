import { useBackend } from 'tgui/backend';
import { Box, LabeledList, Section, Stack } from 'tgui-core/components';

import type { PlanetMapData, PlanetTile } from '../types';

type OverviewPanelProps = {
  localTile?: PlanetTile | null;
};

export const OverviewPanel = (props: OverviewPanelProps) => {
  const { data } = useBackend<PlanetMapData>();

  const selected = data.selectedTile;

  return (
    <Stack fill vertical>
      <Stack.Item>
        <Section title="Planet">
          <LabeledList>
            <LabeledList.Item label="Name">{data.name}</LabeledList.Item>
            <LabeledList.Item label="Type">{data.planetType}</LabeledList.Item>
          </LabeledList>
        </Section>
      </Stack.Item>

      <Stack.Item grow>
        <Section fill title="Tile">
          {!selected && <Box color="label">Click a hex to inspect it.</Box>}
          {!!selected && (
            <LabeledList>
              <LabeledList.Item label="X">{selected.x}</LabeledList.Item>
              <LabeledList.Item label="Y">{selected.y}</LabeledList.Item>
              <LabeledList.Item label="Biome">
                {props.localTile?.biome ?? selected.biome ?? '—'}
              </LabeledList.Item>
              <LabeledList.Item label="Elevation">
                {props.localTile?.elevation ?? '—'}
              </LabeledList.Item>
            </LabeledList>
          )}
        </Section>
      </Stack.Item>
    </Stack>
  );
};
