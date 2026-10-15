import { Box, Icon, LabeledList, Section } from 'tgui-core/components';

import type { SelectedPlanetTile } from '../types';

type TileDetailsProps = {
  tile?: SelectedPlanetTile | null;
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
    .replace(/^rw_(elevation|climate|biome|subbiome)_/i, '')
    .replaceAll('_', ' ')
    .replace(/\b\w/g, (character) => character.toUpperCase());
};

const formatTerrain = (value: string | undefined | null) => {
  if (!value) {
    return '—';
  }

  const key = value.toLowerCase().replace(/^rw_elevation_/, '').replaceAll('_', ' ');
  const terrainNames: Record<string, string> = {
    ocean: 'Open ocean',
    coast: 'Coastal shelf',
    lowland: 'Lowlands and plains',
    highland: 'Highlands and hills',
    mountain: 'Mountain range',
    snow: 'Snow-capped peaks',
  };

  return terrainNames[key] ?? formatEnum(value);
};

const formatClimateLevel = (value: string | undefined | null) => {
  if (!value) {
    return '—';
  }

  const key = value.toLowerCase().replace(/^rw_climate_/, '');
  const levels: Record<string, string> = {
    low: 'Low',
    medium: 'Moderate',
    high: 'High',
  };

  return levels[key] ?? formatEnum(value);
};

const formatTemperature = (value: number | undefined | null) => {
  if (value == null || Number.isNaN(value)) {
    return '—';
  }

  return `${value.toFixed(1)} °C`;
};

const formatWind = (tile: SelectedPlanetTile) => {
  if (tile.windSpeed == null || Number.isNaN(tile.windSpeed)) {
    return '—';
  }

  const direction = tile.windDirection || 'Variable';
  const strength = tile.windStrength ? ` · ${tile.windStrength}` : '';
  return `${direction}, ${Math.round(tile.windSpeed)} km/h${strength}`;
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

        <LabeledList.Item label="Terrain">
          {formatTerrain(tile.elevation)}
        </LabeledList.Item>

        <LabeledList.Item label="Material">
          {formatEnum(tile.material)}
        </LabeledList.Item>

        <LabeledList.Item label="Current temperature">
          {formatTemperature(tile.temperature)}
        </LabeledList.Item>

        <LabeledList.Item label="Annual mean temperature">
          {formatTemperature(tile.annualMeanTemperature)}
        </LabeledList.Item>

        <LabeledList.Item label="Weather">
          {formatEnum(tile.weatherType)}
          {tile.weatherIntensity != null && tile.weatherIntensity > 0
            ? ` (${Math.round(tile.weatherIntensity * 100)}%)`
            : ''}
        </LabeledList.Item>

        <LabeledList.Item label="Wind">
          {formatWind(tile)}
        </LabeledList.Item>

        <LabeledList.Item label="Heat zone">
          {formatClimateLevel(tile.heat)}
        </LabeledList.Item>

        <LabeledList.Item label="Humidity zone">
          {formatClimateLevel(tile.humidity)}
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
