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

const ZONES = [
  { id: 'head', label: 'Head' },
  { id: 'chest', label: 'Chest' },
  { id: 'l_arm', label: 'L Arm' },
  { id: 'r_arm', label: 'R Arm' },
  { id: 'l_leg', label: 'L Leg' },
  { id: 'r_leg', label: 'R Leg' },
] as const;

export const BodyDoll = (props: Props) => {
  const { bodyparts, organs, selectedZone, onSelect } = props;

  return (
    <Stack vertical fill align="center">
      <Stack.Item>
        <Box className="HealthPanel__doll">
          {/* Schematic layout */}
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
  const damaged =
    data && (data.brute > 0 || data.burn > 0 || data.injuries.length > 0);

  return (
    <Button
      className="HealthPanel__zone"
      selected={selected}
      color={missing ? 'bad' : damaged ? 'average' : 'good'}
      onClick={() => onSelect(zone)}
    >
      {data?.name ?? zone}
      {missing && ' (missing)'}
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
  return (
    <Button
      selected={selected}
      color={
        !data.present || data.failing
          ? 'bad'
          : data.health < 50
            ? 'average'
            : 'good'
      }
      onClick={onClick}
    >
      {label}
    </Button>
  );
};
