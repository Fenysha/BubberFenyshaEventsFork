import { useBackend } from 'tgui/backend';
import { Window } from 'tgui/layouts';
import {
  Box,
  Button,
  ColorBox,
  LabeledList,
  NumberInput,
  Section,
  Slider,
  Stack,
} from 'tgui-core/components';

type DaylightControlData = {
  cycle_locked: boolean;
  time_locked: boolean;
  manual_time: number;
  daylight_cycle: number;
  current_intensity: number;
  current_color: string;
  current_phase: string;
  active_weather_count: number;
  visual_weather_mode: string;
  use_planet_time?: boolean;
  planet_time_of_day?: number;
  planet_rotation?: number;
  planet_year?: number;
  planet_quadrum?: string;
  planet_day?: number;
};

const formatHour = (hour: number | undefined | null) => {
  if (hour == null || Number.isNaN(hour)) {
    return '—';
  }
  const h = Math.floor(hour) % 24;
  const m = Math.floor((hour % 1) * 60);
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
};

const WEATHER_OPTIONS = [
  { id: 'auto', label: 'Auto', icon: 'magic' },
  { id: 'rain', label: 'Rain', icon: 'cloud-rain' },
  { id: 'snow', label: 'Snow', icon: 'snowflake' },
  { id: 'mist', label: 'Mist', icon: 'smog' },
  { id: 'radiation', label: 'Dust', icon: 'wind' },
] as const;

export const DaylightControl = () => {
  const { act, data } = useBackend<DaylightControlData>();

  const isManual = data.manual_time >= 0;
  const manualValue = isManual ? data.manual_time : data.current_intensity;
  const weatherMode = data.visual_weather_mode || 'auto';
  const weatherActive = weatherMode !== 'none';

  return (
    <Window title="Daylight Control" width={420} height={560}>
      <Window.Content scrollable>
        <Stack fill vertical>
          {/* Status */}
          <Stack.Item>
            <Section title="Status">
              <LabeledList>
                <LabeledList.Item label="Mode">
                  {data.use_planet_time ? 'Planet' : 'Station'}
                </LabeledList.Item>
                <LabeledList.Item label="Phase">
                  {data.current_phase}
                </LabeledList.Item>
                <LabeledList.Item label="Intensity">
                  {(data.current_intensity * 100).toFixed(0)}%
                </LabeledList.Item>
                <LabeledList.Item label="Color">
                  <Stack align="center">
                    <Stack.Item>
                      <ColorBox color={data.current_color} />
                    </Stack.Item>
                    <Stack.Item>
                      <Box as="span" color="label">
                        {data.current_color}
                      </Box>
                    </Stack.Item>
                  </Stack>
                </LabeledList.Item>
                <LabeledList.Item label="Cycle">
                  {data.cycle_locked ? (
                    <Box color="bad">Locked</Box>
                  ) : (
                    <Box color="good">Running</Box>
                  )}
                </LabeledList.Item>
                <LabeledList.Item label="Time control">
                  {data.time_locked || isManual ? (
                    <Box color="average">Manual</Box>
                  ) : (
                    <Box color="good">Auto</Box>
                  )}
                </LabeledList.Item>
              </LabeledList>
            </Section>
          </Stack.Item>

          {/* Planet clock (only on rimworld maps) */}
          {!!data.use_planet_time && (
            <Stack.Item>
              <Section title="Planet clock">
                <LabeledList>
                  <LabeledList.Item label="Date">
                    {data.planet_quadrum ?? '—'} {data.planet_day ?? '—'},{' '}
                    {data.planet_year ?? '—'}
                  </LabeledList.Item>
                  <LabeledList.Item label="Local time">
                    {formatHour(data.planet_time_of_day)}
                  </LabeledList.Item>
                  <LabeledList.Item label="Rotation">
                    {(data.planet_rotation ?? 0).toFixed(1)}°
                  </LabeledList.Item>
                  <LabeledList.Item label="Set hour">
                    <NumberInput
                      width="100%"
                      minValue={0}
                      maxValue={24}
                      step={0.25}
                      value={Number(
                        (data.planet_time_of_day ?? 12).toFixed?.(2) ?? 12,
                      )}
                      onChange={(value) => act('set_planet_hour', { value })}
                    />
                  </LabeledList.Item>
                </LabeledList>
              </Section>
            </Stack.Item>
          )}

          {/* Manual intensity */}
          <Stack.Item>
            <Section
              title="Forced intensity"
              buttons={
                <Button
                  icon="undo"
                  tooltip="Return to automatic cycle"
                  disabled={!isManual && !data.cycle_locked}
                  onClick={() => act('set_auto')}
                >
                  Auto
                </Button>
              }
            >
              <Box mb={1} color="label">
                Drag to force a fixed day/night level. −1 / Auto restores the
                normal cycle.
              </Box>
              <Slider
                minValue={0}
                maxValue={1}
                step={0.01}
                stepPixelSize={4}
                value={manualValue}
                unit="×"
                onChange={(_e, value) => act('set_manual', { value })}
                onDrag={(value) => act('set_manual', { value })}
              />
              <Box mt={1}>
                <Stack>
                  <Stack.Item grow>
                    <Button
                      fluid
                      icon="moon"
                      color="grey"
                      onClick={() => act('set_manual', { value: 0 })}
                    >
                      Night
                    </Button>
                  </Stack.Item>
                  <Stack.Item grow>
                    <Button
                      fluid
                      icon="adjust"
                      onClick={() => act('set_manual', { value: 0.35 })}
                    >
                      Dusk
                    </Button>
                  </Stack.Item>
                  <Stack.Item grow>
                    <Button
                      fluid
                      icon="sun"
                      color="yellow"
                      onClick={() => act('set_manual', { value: 1 })}
                    >
                      Day
                    </Button>
                  </Stack.Item>
                </Stack>
              </Box>
            </Section>
          </Stack.Item>

          {/* Station cycle length (hidden on planet maps — rotation owns the day) */}
          {!data.use_planet_time && (
            <Stack.Item>
              <Section title="Station day length">
                <LabeledList>
                  <LabeledList.Item label="Minutes / day">
                    <NumberInput
                      width="100%"
                      minValue={5}
                      maxValue={240}
                      step={1}
                      value={data.daylight_cycle}
                      unit="min"
                      onChange={(value) => act('set_cycle_minutes', { value })}
                    />
                  </LabeledList.Item>
                </LabeledList>
                <Box mt={1} color="label">
                  How many real minutes map to one in-game 24h cycle.
                </Box>
              </Section>
            </Stack.Item>
          )}

          {/* Locks */}
          <Stack.Item>
            <Section title="Locks">
              <Button
                fluid
                icon={data.cycle_locked ? 'lock' : 'lock-open'}
                color={data.cycle_locked ? 'bad' : 'good'}
                onClick={() => act('toggle_cycle_lock')}
              >
                {data.cycle_locked
                  ? 'Unlock day/night cycle'
                  : 'Lock day/night cycle'}
              </Button>
            </Section>
          </Stack.Item>

          {/* Visual weather */}
          <Stack.Item>
            <Section
              title="Visual weather"
              buttons={
                <Button
                  icon="ban"
                  color={weatherActive ? 'bad' : undefined}
                  selected={!weatherActive}
                  onClick={() => act('stop_weather')}
                >
                  None
                </Button>
              }
            >
              <Stack wrap>
                {WEATHER_OPTIONS.map((opt) => (
                  <Stack.Item key={opt.id} grow basis="45%">
                    <Button
                      fluid
                      icon={opt.icon}
                      selected={weatherMode === opt.id}
                      onClick={() =>
                        act('start_weather', { weather_type: opt.id })
                      }
                    >
                      {opt.label}
                    </Button>
                  </Stack.Item>
                ))}
              </Stack>
              <Box mt={1} color="label">
                Current: <strong>{weatherMode}</strong>
                {data.active_weather_count > 0 ? ' (active)' : ' (off)'}
              </Box>
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
