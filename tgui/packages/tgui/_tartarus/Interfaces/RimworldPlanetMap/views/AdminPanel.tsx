import { useState } from 'react';
import { useBackend } from 'tgui/backend';
import {
  Box,
  Button,
  Dropdown,
  Input,
  LabeledList,
  NumberInput,
  Section,
  Stack,
} from 'tgui-core/components';

import type { PlanetMapData, PlanetTile } from '../types';

type AdminPanelProps = {
  localTile?: PlanetTile | null;
};

export const AdminPanel = (props: AdminPanelProps) => {
  const { act, data } = useBackend<PlanetMapData>();

  const selected = data.selectedTile;

  const selectedObject = data.selectedObject;

  const [objectName, setObjectName] = useState('Settlement');

  const [seedValue, setSeedValue] = useState(data.seed);

  const [planetType, setPlanetType] = useState(data.planetType);

  const presets = data.presets ?? [data.planetType];

  const hasSelection = !!selected;

  return (
    <Stack fill vertical>
      <Stack.Item>
        <Section title="Planet">
          <LabeledList>
            <LabeledList.Item label="Name">{data.name}</LabeledList.Item>
            <LabeledList.Item label="Type">{data.planetType}</LabeledList.Item>
            <LabeledList.Item label="Seed">{data.seed}</LabeledList.Item>
            <LabeledList.Item label="Revision">
              {data.generationRevision}
            </LabeledList.Item>
          </LabeledList>
        </Section>
      </Stack.Item>

      <Stack.Item>
        <Section title="Regenerate">
          <Box mb={1}>
            <Dropdown
              width="100%"
              selected={planetType}
              options={presets}
              onSelected={setPlanetType}
            />
          </Box>
          <Box mb={1}>
            <NumberInput
              width="100%"
              minValue={0}
              maxValue={2000000000}
              step={1}
              stepPixelSize={3}
              value={seedValue}
              onChange={setSeedValue}
            />
          </Box>
          <Button.Confirm
            fluid
            icon="globe"
            confirmContent="Regenerate planet?"
            onClick={() =>
              act('regenerate', {
                planetType,
                seed: seedValue,
              })
            }
          >
            Regenerate
          </Button.Confirm>
        </Section>
      </Stack.Item>

      <Stack.Item grow>
        <Section fill scrollable title="Selected tile">
          {!hasSelection && <Box color="label">Click a hex on the planet.</Box>}

          {hasSelection && (
            <LabeledList>
              <LabeledList.Item label="X">{selected.x}</LabeledList.Item>
              <LabeledList.Item label="Y">{selected.y}</LabeledList.Item>
              <LabeledList.Item label="Biome">
                {props.localTile?.biome ?? selected.biome ?? 'client'}
              </LabeledList.Item>
              <LabeledList.Item label="Elevation">
                {props.localTile?.elevation ?? selected.elevation ?? '—'}
              </LabeledList.Item>
              <LabeledList.Item label="Heat">
                {props.localTile?.heat ?? selected.heat ?? '—'}
              </LabeledList.Item>
              <LabeledList.Item label="Humidity">
                {props.localTile?.humidity ?? selected.humidity ?? '—'}
              </LabeledList.Item>
              <LabeledList.Item label="Temp">
                {(
                  props.localTile?.temperature ?? selected.temperature
                )?.toFixed?.(3) ?? '—'}
              </LabeledList.Item>
              <LabeledList.Item label="Image">
                {selected.image || 'none'}
              </LabeledList.Item>
            </LabeledList>
          )}

          {!!selectedObject && (
            <Box mt={1}>
              <Box bold>{selectedObject.name}</Box>
              <Box color="label">
                {selectedObject.type} ({selectedObject.id})
              </Box>
            </Box>
          )}
        </Section>
      </Stack.Item>

      <Stack.Item>
        <Section title="Place">
          <Input fluid value={objectName} onChange={setObjectName} />
          <Stack mt={1}>
            <Stack.Item grow>
              <Button
                fluid
                disabled={!hasSelection}
                onClick={() =>
                  act('place_settlement', {
                    name: objectName,
                  })
                }
              >
                Settlement
              </Button>
            </Stack.Item>
            <Stack.Item grow>
              <Button
                fluid
                disabled={!hasSelection}
                onClick={() =>
                  act('place_poi', {
                    name: objectName,
                  })
                }
              >
                POI
              </Button>
            </Stack.Item>
          </Stack>
          <Stack mt={1}>
            <Stack.Item grow>
              <Button
                fluid
                disabled={!hasSelection}
                onClick={() => act('mark_road_start')}
              >
                Road start
              </Button>
            </Stack.Item>
            <Stack.Item grow>
              <Button
                fluid
                disabled={!hasSelection}
                onClick={() => act('place_road')}
              >
                Road here
              </Button>
            </Stack.Item>
          </Stack>
          {data.view?.roadStartX != null && (
            <Box mt={1} color="label">
              Road start: {data.view.roadStartX}, {data.view.roadStartY}
            </Box>
          )}
          <Stack mt={1}>
            <Stack.Item grow>
              <Button
                fluid
                color="bad"
                disabled={!selectedObject}
                onClick={() => act('remove_object')}
              >
                Remove object
              </Button>
            </Stack.Item>
            <Stack.Item grow>
              <Button
                fluid
                disabled={!selectedObject || !hasSelection}
                onClick={() => act('move_object')}
              >
                Move here
              </Button>
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>
    </Stack>
  );
};
