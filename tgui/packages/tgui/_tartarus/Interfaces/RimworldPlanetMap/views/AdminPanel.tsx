/* eslint-disable max-statements */
import { useState } from 'react';

import { useBackend } from 'tgui/backend';

import {
  Box,
  Button,
  Collapsible,
  Dropdown,
  Input,
  LabeledList,
  NumberInput,
  Section,
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

  const [params, setParams] = useState({
    planetType: data.planetType,
    seed: data.seed,

    terrainSeed: data.terrainSeed ?? data.seed,
    heatSeed: data.heatSeed ?? data.seed + 1,
    humiditySeed: data.humiditySeed ?? data.seed + 2,
    geologySeed: data.geologySeed ?? data.seed + 3,
    precipitationSeed: data.precipitationSeed ?? data.seed + 4,

    noiseScale: data.noiseScale ?? 60,
    terrainScale: data.terrainScale ?? 340,
    heatScale: data.heatScale ?? 150,
    humidityScale: data.humidityScale ?? 140,
    geologyScale: data.geologyScale ?? 96,
    precipitationScale: data.precipitationScale ?? 110,

    elevationCoastLow: data.elevationCoastLow ?? -0.02,
    elevationCoastHigh: data.elevationCoastHigh ?? 0.04,

    elevationLowlandLow: data.elevationLowlandLow ?? 0.04,
    elevationLowlandHigh: data.elevationLowlandHigh ?? 0.18,

    elevationHighlandLow: data.elevationHighlandLow ?? 0.18,
    elevationHighlandHigh: data.elevationHighlandHigh ?? 0.3,

    elevationMountainLow: data.elevationMountainLow ?? 0.3,
    elevationMountainHigh: data.elevationMountainHigh ?? 0.42,

    elevationSnowLow: data.elevationSnowLow ?? 0.42,
    elevationSnowHigh: data.elevationSnowHigh ?? 0.5,

    heatThresholdLow: data.heatThresholdLow ?? -0.2,
    heatThresholdHigh: data.heatThresholdHigh ?? 0.25,

    humidityThresholdLow: data.humidityThresholdLow ?? -0.18,
    humidityThresholdHigh: data.humidityThresholdHigh ?? 0.25,
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

          <Collapsible title="Noise & Stamp Scales">
            <LabeledList>
              <LabeledList.Item label="Noise Scale">
                <NumberInput
                  width="100%"
                  minValue={1}
                  maxValue={500}
                  value={params.noiseScale}
                  onChange={(value) => updateParam('noiseScale', value)}
                />
              </LabeledList.Item>

              <LabeledList.Item label="Terrain Stamp">
                <NumberInput
                  width="100%"
                  minValue={1}
                  maxValue={500}
                  value={params.terrainScale}
                  onChange={(value) => updateParam('terrainScale', value)}
                />
              </LabeledList.Item>

              <LabeledList.Item label="Heat Stamp">
                <NumberInput
                  width="100%"
                  minValue={1}
                  maxValue={500}
                  value={params.heatScale}
                  onChange={(value) => updateParam('heatScale', value)}
                />
              </LabeledList.Item>

              <LabeledList.Item label="Humidity Stamp">
                <NumberInput
                  width="100%"
                  minValue={1}
                  maxValue={500}
                  value={params.humidityScale}
                  onChange={(value) => updateParam('humidityScale', value)}
                />
              </LabeledList.Item>

              <LabeledList.Item label="Geology Stamp">
                <NumberInput
                  width="100%"
                  minValue={1}
                  maxValue={500}
                  value={params.geologyScale}
                  onChange={(value) => updateParam('geologyScale', value)}
                />
              </LabeledList.Item>

              <LabeledList.Item label="Precipitation Stamp">
                <NumberInput
                  width="100%"
                  minValue={1}
                  maxValue={500}
                  value={params.precipitationScale}
                  onChange={(value) => updateParam('precipitationScale', value)}
                />
              </LabeledList.Item>
            </LabeledList>
          </Collapsible>

          <Collapsible title="Sub-Noise Seeds">
            <LabeledList>
              <LabeledList.Item label="Terrain Seed">
                <NumberInput
                  width="100%"
                  minValue={0}
                  maxValue={2000000000}
                  value={params.terrainSeed}
                  onChange={(value) => updateParam('terrainSeed', value)}
                />
              </LabeledList.Item>

              <LabeledList.Item label="Heat Seed">
                <NumberInput
                  width="100%"
                  minValue={0}
                  maxValue={2000000000}
                  value={params.heatSeed}
                  onChange={(value) => updateParam('heatSeed', value)}
                />
              </LabeledList.Item>

              <LabeledList.Item label="Humidity Seed">
                <NumberInput
                  width="100%"
                  minValue={0}
                  maxValue={2000000000}
                  value={params.humiditySeed}
                  onChange={(value) => updateParam('humiditySeed', value)}
                />
              </LabeledList.Item>

              <LabeledList.Item label="Geology Seed">
                <NumberInput
                  width="100%"
                  minValue={0}
                  maxValue={2000000000}
                  value={params.geologySeed}
                  onChange={(value) => updateParam('geologySeed', value)}
                />
              </LabeledList.Item>

              <LabeledList.Item label="Precipitation Seed">
                <NumberInput
                  width="100%"
                  minValue={0}
                  maxValue={2000000000}
                  value={params.precipitationSeed}
                  onChange={(value) => updateParam('precipitationSeed', value)}
                />
              </LabeledList.Item>
            </LabeledList>
          </Collapsible>

          <Collapsible title="Elevation Thresholds">
            <LabeledList>
              <LabeledList.Item label="Coast Low / High">
                <Stack>
                  <Stack.Item grow>
                    <NumberInput
                      width="100%"
                      step={0.01}
                      value={params.elevationCoastLow}
                      onChange={(value) =>
                        updateParam('elevationCoastLow', value)
                      }
                    />
                  </Stack.Item>

                  <Stack.Item grow>
                    <NumberInput
                      width="100%"
                      step={0.01}
                      value={params.elevationCoastHigh}
                      onChange={(value) =>
                        updateParam('elevationCoastHigh', value)
                      }
                    />
                  </Stack.Item>
                </Stack>
              </LabeledList.Item>

              <LabeledList.Item label="Lowland Low / High">
                <Stack>
                  <Stack.Item grow>
                    <NumberInput
                      width="100%"
                      step={0.01}
                      value={params.elevationLowlandLow}
                      onChange={(value) =>
                        updateParam('elevationLowlandLow', value)
                      }
                    />
                  </Stack.Item>

                  <Stack.Item grow>
                    <NumberInput
                      width="100%"
                      step={0.01}
                      value={params.elevationLowlandHigh}
                      onChange={(value) =>
                        updateParam('elevationLowlandHigh', value)
                      }
                    />
                  </Stack.Item>
                </Stack>
              </LabeledList.Item>

              <LabeledList.Item label="Highland Low / High">
                <Stack>
                  <Stack.Item grow>
                    <NumberInput
                      width="100%"
                      step={0.01}
                      value={params.elevationHighlandLow}
                      onChange={(value) =>
                        updateParam('elevationHighlandLow', value)
                      }
                    />
                  </Stack.Item>

                  <Stack.Item grow>
                    <NumberInput
                      width="100%"
                      step={0.01}
                      value={params.elevationHighlandHigh}
                      onChange={(value) =>
                        updateParam('elevationHighlandHigh', value)
                      }
                    />
                  </Stack.Item>
                </Stack>
              </LabeledList.Item>

              <LabeledList.Item label="Mountain Low / High">
                <Stack>
                  <Stack.Item grow>
                    <NumberInput
                      width="100%"
                      step={0.01}
                      value={params.elevationMountainLow}
                      onChange={(value) =>
                        updateParam('elevationMountainLow', value)
                      }
                    />
                  </Stack.Item>

                  <Stack.Item grow>
                    <NumberInput
                      width="100%"
                      step={0.01}
                      value={params.elevationMountainHigh}
                      onChange={(value) =>
                        updateParam('elevationMountainHigh', value)
                      }
                    />
                  </Stack.Item>
                </Stack>
              </LabeledList.Item>

              <LabeledList.Item label="Snow Low / High">
                <Stack>
                  <Stack.Item grow>
                    <NumberInput
                      width="100%"
                      step={0.01}
                      value={params.elevationSnowLow}
                      onChange={(value) =>
                        updateParam('elevationSnowLow', value)
                      }
                    />
                  </Stack.Item>

                  <Stack.Item grow>
                    <NumberInput
                      width="100%"
                      step={0.01}
                      value={params.elevationSnowHigh}
                      onChange={(value) =>
                        updateParam('elevationSnowHigh', value)
                      }
                    />
                  </Stack.Item>
                </Stack>
              </LabeledList.Item>
            </LabeledList>
          </Collapsible>

          <Collapsible title="Climate Thresholds">
            <LabeledList>
              <LabeledList.Item label="Heat Low / High">
                <Stack>
                  <Stack.Item grow>
                    <NumberInput
                      width="100%"
                      step={0.01}
                      value={params.heatThresholdLow}
                      onChange={(value) =>
                        updateParam('heatThresholdLow', value)
                      }
                    />
                  </Stack.Item>

                  <Stack.Item grow>
                    <NumberInput
                      width="100%"
                      step={0.01}
                      value={params.heatThresholdHigh}
                      onChange={(value) =>
                        updateParam('heatThresholdHigh', value)
                      }
                    />
                  </Stack.Item>
                </Stack>
              </LabeledList.Item>

              <LabeledList.Item label="Humidity Low / High">
                <Stack>
                  <Stack.Item grow>
                    <NumberInput
                      width="100%"
                      step={0.01}
                      value={params.humidityThresholdLow}
                      onChange={(value) =>
                        updateParam('humidityThresholdLow', value)
                      }
                    />
                  </Stack.Item>

                  <Stack.Item grow>
                    <NumberInput
                      width="100%"
                      step={0.01}
                      value={params.humidityThresholdHigh}
                      onChange={(value) =>
                        updateParam('humidityThresholdHigh', value)
                      }
                    />
                  </Stack.Item>
                </Stack>
              </LabeledList.Item>
            </LabeledList>
          </Collapsible>

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
