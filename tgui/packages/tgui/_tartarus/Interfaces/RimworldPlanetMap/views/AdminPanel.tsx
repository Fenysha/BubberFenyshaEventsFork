/* eslint-disable max-statements */
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
  Slider,
  Stack,
} from 'tgui-core/components';

import type { PlanetMapData } from '../types';

export const AdminPanel = () => {
  const { act, data } = useBackend<PlanetMapData>();

  const selected = data.selectedTile;
  const selectedObject = data.selectedObject;
  const cell = data.view?.cell;

  const [objectType, setObjectType] = useState('settlement');
  const [objectName, setObjectName] = useState('Settlement');

  const [objectX, setObjectX] = useState<number | null>(selected?.x ?? null);

  const [objectY, setObjectY] = useState<number | null>(selected?.y ?? null);

  const [loadImmediately, setLoadImmediately] = useState(true);

  // The whole generator surface: seed/preset plus 5 simple -5..5 sliders.
  // Everything else (noise scales, elevation bands, climate thresholds) is
  // derived on the Rust side from these, see derive_generation_params() in
  // tp_planet.rs.
  const sliderMin = data.sliderMin ?? -5;
  const sliderMax = data.sliderMax ?? 5;

  const [params, setParams] = useState({
    planetType: data.planetType,
    seed: data.seed,

    mountains: data.mountains ?? 0,
    ocean: data.ocean ?? 0,
    humidity: data.humidity ?? 0,
    temperature: data.temperature ?? 0,
    population: data.population ?? 0,
  });

  const updateParam = (key: string, value: number | string) => {
    setParams((prev) => ({
      ...prev,
      [key]: value,
    }));
  };

  const presets = data.presets ?? [data.planetType];
  const hasSelection = !!selected;
  const hasCell = !!cell;
  const cellLoaded = !!cell?.isGenerated;
  const cellGenerating = !!cell?.isGenerating;

  const objectTypes = ['settlement', 'poi', 'road'];

  return (
    <Stack fill vertical>
      <Stack.Item>
        <Section title="Planet Info">
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
        <Section title="Planet Rotation Control">
          <LabeledList>
            <LabeledList.Item label="Auto Rotation">
              <Button
                fluid
                icon={data.autoRotate ? 'pause' : 'play'}
                color={data.autoRotate ? 'warning' : 'success'}
                onClick={() => act('toggle_rotation')}
              >
                {data.autoRotate ? 'Pause Rotation' : 'Start Rotation'}
              </Button>
            </LabeledList.Item>

            <LabeledList.Item label="Rotation Speed">
              <NumberInput
                width="100%"
                step={0.1}
                minValue={-10}
                maxValue={10}
                value={data.rotationSpeed ?? 0.001}
                onChange={(value) =>
                  act('set_rotation_speed', {
                    speed: value,
                  })
                }
              />
            </LabeledList.Item>

            <LabeledList.Item label="Manual Angle">
              <NumberInput
                width="100%"
                step={15}
                minValue={0}
                maxValue={360}
                value={Math.round(data.rotationAngle ?? 0)}
                onChange={(value) =>
                  act('set_rotation_angle', {
                    angle: value,
                  })
                }
              />
            </LabeledList.Item>
          </LabeledList>
        </Section>
      </Stack.Item>

      <Stack.Item>
        <Section title="Selected Cell">
          {!hasSelection ? (
            <Box color="label">Select a tile on the planet.</Box>
          ) : (
            <Stack vertical>
              <Stack.Item>
                <LabeledList>
                  <LabeledList.Item label="Coordinates">
                    {selected.x}, {selected.y}
                  </LabeledList.Item>

                  <LabeledList.Item label="Biome">
                    {selected.biome}
                  </LabeledList.Item>

                  <LabeledList.Item label="Sub-biome">
                    {selected.subBiome}
                  </LabeledList.Item>

                  <LabeledList.Item label="Elevation">
                    {selected.elevation}
                  </LabeledList.Item>

                  <LabeledList.Item label="Runtime Cell">
                    {hasCell ? cell.id : 'Not created'}
                  </LabeledList.Item>

                  <LabeledList.Item label="Local Map">
                    {!hasCell
                      ? 'Not loaded'
                      : cellGenerating
                        ? 'Generating...'
                        : cellLoaded
                          ? `${cell.localWidth} × ${cell.localHeight}`
                          : 'Unloaded'}
                  </LabeledList.Item>
                </LabeledList>
              </Stack.Item>

              <Stack.Item>
                <Stack>
                  <Stack.Item grow>
                    <Button
                      fluid
                      icon="download"
                      color="good"
                      disabled={cellGenerating || cellLoaded}
                      onClick={() => act('load_cell')}
                    >
                      Load Cell
                    </Button>
                  </Stack.Item>

                  <Stack.Item grow>
                    <Button
                      fluid
                      icon="upload"
                      color="average"
                      disabled={!cellLoaded || cellGenerating}
                      onClick={() => act('unload_cell')}
                    >
                      Unload Cell
                    </Button>
                  </Stack.Item>
                </Stack>
              </Stack.Item>

              <Stack.Item>
                <Button
                  fluid
                  icon="refresh"
                  disabled={cellGenerating}
                  onClick={() => act('reload_cell')}
                >
                  Reload Cell
                </Button>
              </Stack.Item>
            </Stack>
          )}
        </Section>
      </Stack.Item>

      <Stack.Item>
        <Section title="Object Constructor">
          <LabeledList>
            <LabeledList.Item label="Object Type">
              <Dropdown
                width="100%"
                selected={objectType}
                options={objectTypes}
                onSelected={(value) => {
                  setObjectType(value);

                  if (value === 'settlement') {
                    setObjectName('Settlement');
                  } else if (value === 'poi') {
                    setObjectName('Point of Interest');
                  } else if (value === 'road') {
                    setObjectName('');
                  }
                }}
              />
            </LabeledList.Item>

            {objectType !== 'road' && (
              <LabeledList.Item label="Name">
                <Input fluid value={objectName} onChange={setObjectName} />
              </LabeledList.Item>
            )}

            <LabeledList.Item label="X">
              <NumberInput
                width="100%"
                minValue={1}
                maxValue={data.width}
                value={objectX ?? selected?.x ?? 1}
                onChange={setObjectX}
              />
            </LabeledList.Item>

            <LabeledList.Item label="Y">
              <NumberInput
                width="100%"
                minValue={1}
                maxValue={data.height}
                value={objectY ?? selected?.y ?? 1}
                onChange={setObjectY}
              />
            </LabeledList.Item>
          </LabeledList>

          {objectType === 'road' && (
            <Box mt={1}>
              <Stack vertical>
                <Stack.Item>
                  <Box color="label">
                    Road start:{' '}
                    {data.view?.roadStartX != null
                      ? `${data.view.roadStartX}, ${data.view.roadStartY}`
                      : 'Not selected'}
                  </Box>
                </Stack.Item>

                <Stack.Item>
                  <Stack>
                    <Stack.Item grow>
                      <Button
                        fluid
                        disabled={!hasSelection}
                        onClick={() => act('mark_road_start')}
                      >
                        Use Selected as Start
                      </Button>
                    </Stack.Item>

                    <Stack.Item>
                      <Button
                        icon="times"
                        disabled={data.view?.roadStartX == null}
                        onClick={() => act('clear_road_start')}
                      />
                    </Stack.Item>
                  </Stack>
                </Stack.Item>
              </Stack>
            </Box>
          )}

          <Box mt={2}>
            <Button.Checkbox
              fluid
              checked={loadImmediately}
              onClick={() => setLoadImmediately(!loadImmediately)}
            >
              Load destination cell immediately
            </Button.Checkbox>
          </Box>

          <Box mt={2}>
            <Button
              fluid
              icon="plus"
              color="good"
              disabled={
                !hasSelection ||
                (objectType === 'road' && data.view?.roadStartX == null)
              }
              onClick={() =>
                act('create_object', {
                  type: objectType,
                  name: objectName,
                  x: objectX ?? selected?.x,
                  y: objectY ?? selected?.y,
                  loadImmediately,
                  startX: data.view?.roadStartX,
                  startY: data.view?.roadStartY,
                })
              }
            >
              Create {objectType}
            </Button>
          </Box>
        </Section>
      </Stack.Item>

      {!!selectedObject && (
        <Stack.Item>
          <Section title="Selected Object">
            <Stack vertical>
              <Stack.Item>
                <LabeledList>
                  <LabeledList.Item label="Name">
                    {selectedObject.name}
                  </LabeledList.Item>

                  <LabeledList.Item label="Type">
                    {selectedObject.type}
                  </LabeledList.Item>

                  <LabeledList.Item label="ID">
                    {selectedObject.id}
                  </LabeledList.Item>

                  <LabeledList.Item label="Position">
                    {selectedObject.x}, {selectedObject.y}
                  </LabeledList.Item>
                </LabeledList>
              </Stack.Item>

              <Stack.Item>
                <Stack>
                  <Stack.Item grow>
                    <Button
                      fluid
                      icon="location-arrow"
                      disabled={!hasSelection}
                      onClick={() =>
                        act('move_object', {
                          id: selectedObject.id,
                          x: selected?.x,
                          y: selected?.y,
                        })
                      }
                    >
                      Move Here
                    </Button>
                  </Stack.Item>

                  <Stack.Item grow>
                    <Button
                      fluid
                      icon="trash"
                      color="bad"
                      onClick={() =>
                        act('remove_object', {
                          id: selectedObject.id,
                        })
                      }
                    >
                      Remove
                    </Button>
                  </Stack.Item>
                </Stack>
              </Stack.Item>
            </Stack>
          </Section>
        </Stack.Item>
      )}

      <Stack.Item>
        <Section title="Manual Generator Controls">
          <LabeledList>
            <LabeledList.Item label="Preset">
              <Dropdown
                width="100%"
                selected={params.planetType}
                options={presets}
                onSelected={(value) => updateParam('planetType', value)}
              />
            </LabeledList.Item>

            <LabeledList.Item label="Main Seed">
              <NumberInput
                width="100%"
                minValue={0}
                maxValue={2000000000}
                value={params.seed}
                onChange={(value) => updateParam('seed', value)}
              />
            </LabeledList.Item>
          </LabeledList>

          <LabeledList>
            <LabeledList.Item label="Mountains">
              <Slider
                width="100%"
                minValue={sliderMin}
                maxValue={sliderMax}
                step={1}
                stepPixelSize={20}
                value={params.mountains}
                onChange={(e, value) => updateParam('mountains', value)}
              />
            </LabeledList.Item>

            <LabeledList.Item label="Ocean">
              <Slider
                width="100%"
                minValue={sliderMin}
                maxValue={sliderMax}
                step={1}
                stepPixelSize={20}
                value={params.ocean}
                onChange={(e, value) => updateParam('ocean', value)}
              />
            </LabeledList.Item>

            <LabeledList.Item label="Humidity">
              <Slider
                width="100%"
                minValue={sliderMin}
                maxValue={sliderMax}
                step={1}
                stepPixelSize={20}
                value={params.humidity}
                onChange={(e, value) => updateParam('humidity', value)}
              />
            </LabeledList.Item>

            <LabeledList.Item label="Temperature">
              <Slider
                width="100%"
                minValue={sliderMin}
                maxValue={sliderMax}
                step={1}
                stepPixelSize={20}
                value={params.temperature}
                onChange={(e, value) => updateParam('temperature', value)}
              />
            </LabeledList.Item>

            <LabeledList.Item label="Population">
              <Slider
                width="100%"
                minValue={sliderMin}
                maxValue={sliderMax}
                step={1}
                stepPixelSize={20}
                value={params.population}
                onChange={(e, value) => updateParam('population', value)}
              />
            </LabeledList.Item>
          </LabeledList>

          <Box mt={2}>
            <Button.Confirm
              fluid
              icon="globe"
              confirmContent="Regenerate planet with custom parameters?"
              onClick={() => act('regenerate', params)}
            >
              Apply & Regenerate
            </Button.Confirm>
          </Box>
        </Section>
      </Stack.Item>
    </Stack>
  );
};
