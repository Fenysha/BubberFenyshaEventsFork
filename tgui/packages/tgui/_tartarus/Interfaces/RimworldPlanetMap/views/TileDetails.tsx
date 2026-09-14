import { LabeledList, Section } from 'tgui-core/components';

import type { PlanetTile } from '../types';

type TileDetailsProps = {
  tile?: PlanetTile | null;
  title?: string;
};

export const TileDetails = ({
  tile,
  title = 'Selected tile',
}: TileDetailsProps) => {
  if (!tile) {
    return (
      <Section title={title}>Click a hex on the planet to inspect it.</Section>
    );
  }

  return (
    <Section title={title} fill scrollable>
      <LabeledList>
        <LabeledList.Item label="Biome">{tile.biome}</LabeledList.Item>

        <LabeledList.Item label="Elevation">{tile.elevation}</LabeledList.Item>

        <LabeledList.Item label="Heat">{tile.heat}</LabeledList.Item>

        <LabeledList.Item label="Humidity">{tile.humidity}</LabeledList.Item>

        <LabeledList.Item label="Temperature">
          {tile.temperature.toFixed(3)}
        </LabeledList.Item>
      </LabeledList>
    </Section>
  );
};
