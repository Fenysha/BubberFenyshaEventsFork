import { Box, Icon, LabeledList, Section } from 'tgui-core/components';
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
        {/* Отображение координат */}
        {tile.x !== undefined && tile.y !== undefined && (
          <LabeledList.Item label="Coordinates">
            <Box color="label">
              X: {tile.x}, Y: {tile.y}
            </Box>
          </LabeledList.Item>
        )}

        <LabeledList.Item label="Biome">{tile.biome}</LabeledList.Item>

        <LabeledList.Item label="Elevation">{tile.elevation}</LabeledList.Item>

        <LabeledList.Item label="Temperature">
          {tile.temperature.toFixed(1)} °C
        </LabeledList.Item>

        <LabeledList.Item label="Heat">{tile.heat}</LabeledList.Item>

        <LabeledList.Item label="Humidity">{tile.humidity}</LabeledList.Item>

        {/* Список объектов на тайле (если есть) */}
        {!!tile.objects?.length && (
          <LabeledList.Item label="Objects">
            {tile.objects.map((obj) => (
              <Box key={obj.id} mb={0.5}>
                {obj.icon && <Icon name={obj.icon} mr={1} />}
                <strong>{obj.name}</strong> ({obj.type})
              </Box>
            ))}
          </LabeledList.Item>
        )}
      </LabeledList>
    </Section>
  );
};
