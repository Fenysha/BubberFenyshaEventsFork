import { Box, Icon, LabeledList, Section } from 'tgui-core/components';

import type { PlanetTile, SelectedPlanetTile } from '../types';

type TileDetailsProps = {
  tile?: PlanetTile | SelectedPlanetTile | null;
  title?: string;
};

const formatNumber = (value: number | undefined | null, digits = 3) => {
  if (value == null || Number.isNaN(value)) {
    return '—';
  }

  return value.toFixed(digits);
};

const formatPercent = (value: number | undefined | null) => {
  if (value == null || Number.isNaN(value)) {
    return '—';
  }

  return `${(value * 100).toFixed(1)}%`;
};

const formatEnum = (value: string | undefined | null) => {
  if (!value) {
    return '—';
  }

  return value
    .replaceAll('_', ' ')
    .replace(/\b\w/g, (character) => character.toUpperCase());
};

export const TileDetails = ({
  tile,
  title = 'Selected Tile',
}: TileDetailsProps) => {
  if (!tile) {
    return (
      <Section title={title}>Click a tile on the planet to inspect it.</Section>
    );
  }

  return (
    <Section title={title}>
      <LabeledList>
        <LabeledList.Item label="Coordinates">
          <Box color="label">
            X: {tile.x ?? '—'}, Y: {tile.y ?? '—'}
          </Box>
        </LabeledList.Item>

        <LabeledList.Item label="Latitude">
          {tile.latitude != null ? `${formatNumber(tile.latitude, 2)}°` : '—'}
        </LabeledList.Item>

        <LabeledList.Item label="Biome">
          {formatEnum(tile.biome)}
        </LabeledList.Item>

        <LabeledList.Item label="Sub-biome">
          {formatEnum(tile.subBiome)}
        </LabeledList.Item>

        <LabeledList.Item label="Season">
          {formatEnum(tile.season)}
        </LabeledList.Item>

        <LabeledList.Item label="Daylight">
          {tile.isDaylight == null ? '—' : tile.isDaylight ? 'Day' : 'Night'}
        </LabeledList.Item>

        <LabeledList.Item label="Sun intensity">
          {formatPercent(tile.sunIntensity)}
        </LabeledList.Item>

        <LabeledList.Item label="Elevation">
          {formatEnum(tile.elevation)}
        </LabeledList.Item>

        <LabeledList.Item label="Material">
          {formatEnum(tile.material)}
        </LabeledList.Item>

        <LabeledList.Item label="Temperature">
          {formatNumber(tile.temperature, 4)}
        </LabeledList.Item>

        <LabeledList.Item label="Heat">
          {formatEnum(tile.heat)}
        </LabeledList.Item>

        <LabeledList.Item label="Humidity">
          {formatEnum(tile.humidity)}
        </LabeledList.Item>

        <LabeledList.Item label="Precipitation">
          {formatPercent(tile.precipitation)}
        </LabeledList.Item>

        <LabeledList.Item label="Rainfall">
          {formatPercent(tile.rainfall)}
        </LabeledList.Item>

        <LabeledList.Item label="Snowfall">
          {formatPercent(tile.snowfall)}
        </LabeledList.Item>

        <LabeledList.Item label="Water Availability">
          {formatPercent(tile.waterAvailability)}
        </LabeledList.Item>

        <LabeledList.Item label="Objects">
          {tile.objects?.length ? (
            tile.objects.map((object) => (
              <Box key={object.id} mb={0.5}>
                {object.icon && <Icon name={object.icon} mr={1} />}

                <strong>{object.name}</strong>

                <Box as="span" color="label" ml={1}>
                  ({formatEnum(object.type)})
                </Box>
              </Box>
            ))
          ) : (
            <Box color="label">None</Box>
          )}
        </LabeledList.Item>
      </LabeledList>
    </Section>
  );
};
