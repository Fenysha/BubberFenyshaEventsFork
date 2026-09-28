import { Box, Button, Stack } from 'tgui-core/components';
import type { BodypartData, OrganData } from './types';

type Props = {
  bodyparts: Record<string, BodypartData>;
  organs: {
    brain: OrganData;
    heart: OrganData;
    lungs: OrganData;
  };
  selectedZone: string | null;
  onSelect: (zone: string) => void;
};

export const BodyDoll = (props: Props) => {
  const { bodyparts, organs, selectedZone, onSelect } = props;

  return (
    <Stack vertical fill align="center">
      <Stack.Item>
        <Box className="HealthPanel__doll">
          <div className="HealthPanel__doll-row">
            <ZoneButton
              zone="head"
              data={bodyparts.head}
              selected={selectedZone === 'head'}
              onSelect={onSelect}
            />
          </div>
          <div className="HealthPanel__doll-row">
            <ZoneButton
              zone="l_arm"
              data={bodyparts.l_arm}
              selected={selectedZone === 'l_arm'}
              onSelect={onSelect}
            />
            <ZoneButton
              zone="chest"
              data={bodyparts.chest}
              selected={selectedZone === 'chest'}
              onSelect={onSelect}
            />
            <ZoneButton
              zone="r_arm"
              data={bodyparts.r_arm}
              selected={selectedZone === 'r_arm'}
              onSelect={onSelect}
            />
          </div>
          <div className="HealthPanel__doll-row">
            <ZoneButton
              zone="l_leg"
              data={bodyparts.l_leg}
              selected={selectedZone === 'l_leg'}
              onSelect={onSelect}
            />
            <ZoneButton
              zone="r_leg"
              data={bodyparts.r_leg}
              selected={selectedZone === 'r_leg'}
              onSelect={onSelect}
            />
          </div>
        </Box>
      </Stack.Item>

      <Stack.Item>
        <Box bold>Vital organs</Box>
      </Stack.Item>

      <Stack.Item>
        <Stack>
          <Stack.Item>
            <OrganIcon
              label="Brain"
              data={organs.brain}
              selected={selectedZone === 'brain'}
              onClick={() => onSelect('brain')}
            />
          </Stack.Item>
          <Stack.Item>
            <OrganIcon
              label="Heart"
              data={organs.heart}
              selected={selectedZone === 'heart'}
              onClick={() => onSelect('heart')}
            />
          </Stack.Item>
          <Stack.Item>
            <OrganIcon
              label="Lungs"
              data={organs.lungs}
              selected={selectedZone === 'lungs'}
              onClick={() => onSelect('lungs')}
            />
          </Stack.Item>
        </Stack>
      </Stack.Item>
    </Stack>
  );
};

const ZoneButton = (props: {
  zone: string;
  data?: BodypartData;
  selected: boolean;
  onSelect: (zone: string) => void;
}) => {
  const { zone, data, selected, onSelect } = props;
  const missing = !data?.present;
  const injured =
    !!data && (data.brute > 0 || data.burn > 0 || data.injuries.length > 0);
  const bleeding = !!data && data.bleed_rate > 0;

  return (
    <Button
      className="HealthPanel__zone"
      selected={selected}
      color={missing ? 'bad' : bleeding ? 'bad' : injured ? 'average' : 'good'}
      onClick={() => onSelect(zone)}
    >
      {data?.name ?? zone}
      {missing
        ? ' · missing'
        : bleeding
          ? ' · bleeding'
          : data?.disabled
            ? ' · disabled'
            : ''}
    </Button>
  );
};

const OrganIcon = (props: {
  label: string;
  data: OrganData;
  selected: boolean;
  onClick: () => void;
}) => {
  const { label, data, selected, onClick } = props;
  const heartCritical =
    label === 'Heart' &&
    (data.state === 'stopped' || data.rhythm === 'asystole');
  const brainCritical = label === 'Brain' && (data.oxygen ?? 100) < 30;
  const lungCritical = label === 'Lungs' && !(data.functional ?? false);
  const critical =
    !data.present ||
    data.failing ||
    heartCritical ||
    brainCritical ||
    lungCritical;
  const warning = !critical && data.health < 50;

  return (
    <Button
      selected={selected}
      color={critical ? 'bad' : warning ? 'average' : 'good'}
      onClick={onClick}
    >
      {label}
      {label === 'Heart' && data.rate !== undefined
        ? ` · ${data.rate} bpm`
        : ''}
      {label === 'Brain' && data.oxygen !== undefined
        ? ` · O₂ ${Math.round(data.oxygen)}%`
        : ''}
      {label === 'Lungs' && data.oxygenation !== undefined
        ? ` · O₂ ${Math.round(data.oxygenation)}%`
        : ''}
    </Button>
  );
};
