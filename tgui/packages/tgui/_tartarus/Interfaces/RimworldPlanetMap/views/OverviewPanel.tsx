import { useBackend } from 'tgui/backend';
import { LabeledList, Section, Stack } from 'tgui-core/components';
import { DaylightClock, formatHour } from './DaylightClock';
import type { OverviewMapData } from './types';

export const OverviewPanel = () => {
  const { data } = useBackend<OverviewMapData>();

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
              {data.canControlTime ? (
                <DaylightClock />
              ) : (
                formatHour(data.timeOfDay)
              )}
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
