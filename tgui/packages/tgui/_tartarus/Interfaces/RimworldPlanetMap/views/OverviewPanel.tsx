import { useBackend } from 'tgui/backend';
import { LabeledList, Section, Stack } from 'tgui-core/components';
import type { PlanetMapData } from '../types';

const formatHour = (hour: number | undefined | null) => {
  if (hour == null || Number.isNaN(hour)) {
    return '—';
  }
  const h = Math.floor(hour) % 24;
  const m = Math.floor((hour % 1) * 60);
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
};

export const OverviewPanel = () => {
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

      <Stack.Item>
        <Section title="Calendar">
          <LabeledList>
            <LabeledList.Item label="Date">
              {data.quadrumName ?? '—'} {data.dayOfQuadrum ?? '—'},{' '}
              {data.currentYear ?? '—'}
            </LabeledList.Item>
            <LabeledList.Item label="Day of year">
              {data.dayOfYear ?? '—'} / {data.daysPerYear ?? 60}
            </LabeledList.Item>
            <LabeledList.Item label="Time">
              {formatHour(data.timeOfDay)}
            </LabeledList.Item>
            <LabeledList.Item label="Season (N)">
              {data.seasonNorth ?? '—'}
            </LabeledList.Item>
            <LabeledList.Item label="Season (S)">
              {data.seasonSouth ?? '—'}
            </LabeledList.Item>
          </LabeledList>
        </Section>
      </Stack.Item>
    </Stack>
  );
};
