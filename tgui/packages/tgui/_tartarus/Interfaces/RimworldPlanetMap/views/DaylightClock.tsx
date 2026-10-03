import { useBackend } from 'tgui/backend';
import { Slider } from 'tgui-core/components';
import type { PlanetMapData } from '../types';

export const formatHour = (hour: number | undefined | null) => {
  if (hour == null || Number.isNaN(hour)) {
    return '—';
  }
  const h = Math.floor(hour) % 24;
  const m = Math.floor((hour % 1) * 60);
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
};

/** Turns the planet clock; the globe and every colony's daylight follow it. */
export const DaylightClock = () => {
  const { act, data } = useBackend<PlanetMapData>();
  return (
    <Slider
      width="100%"
      minValue={0}
      maxValue={24}
      step={0.25}
      stepPixelSize={6}
      value={data.timeOfDay ?? 0}
      format={formatHour}
      onChange={(e, value) => act('set_time_of_day', { hour: value })}
    />
  );
};
