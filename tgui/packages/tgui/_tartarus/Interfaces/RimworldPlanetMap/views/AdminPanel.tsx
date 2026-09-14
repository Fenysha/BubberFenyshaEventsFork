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

  const [objectName, setObjectName] = useState('Settlement');

  const [params, setParams] = useState({
    planetType: data.planetType,
    seed: data.seed,
    terrainSeed: data.terrainSeed ?? data.seed,
    heatSeed: data.heatSeed ?? data.seed + 1,
    humiditySeed: data.humiditySeed ?? data.seed + 2,
    noiseScale: data.noiseScale ?? 60,
    terrainScale: data.terrainScale ?? 120,
    heatScale: data.heatScale ?? 140,
    humidityScale: data.humidityScale ?? 130,
    elevationCoastLow: data.elevationCoastLow ?? -0.05,
    elevationCoastHigh: data.elevationCoastHigh ?? 0.08,
    elevationLowlandLow: data.elevationLowlandLow ?? 0.08,
    elevationLowlandHigh: data.elevationLowlandHigh ?? 0.42,
    elevationHighlandLow: data.elevationHighlandLow ?? 0.42,
    elevationHighlandHigh: data.elevationHighlandHigh ?? 0.65,
    elevationMountainLow: data.elevationMountainLow ?? 0.65,
    elevationMountainHigh: data.elevationMountainHigh ?? 0.82,
    elevationSnowLow: data.elevationSnowLow ?? 0.82,
    elevationSnowHigh: data.elevationSnowHigh ?? 1.1,
    heatThresholdLow: data.heatThresholdLow ?? -0.2,
    heatThresholdHigh: data.heatThresholdHigh ?? 0.25,
    humidityThresholdLow: data.humidityThresholdLow ?? -0.18,
    humidityThresholdHigh: data.humidityThresholdHigh ?? 0.25,
  });

  const updateParam = (key: string, value: number | string) => {
    setParams((prev) => ({ ...prev, [key]: value }));
  };

  const presets = data.presets ?? [data.planetType];
  const hasSelection = !!selected;

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
              value={data.rotationSpeed ?? 1.0}
              onChange={(val) => act('set_rotation_speed', { speed: val })}
            />
          </LabeledList.Item>

          <LabeledList.Item label="Manual Angle">
            <NumberInput
              width="100%"
              step={15}
              minValue={0}
              maxValue={360}
              value={Math.round(data.rotationAngle ?? 0)}
              onChange={(val) => act('set_rotation_angle', { angle: val })}
            />
          </LabeledList.Item>
        </LabeledList>
      </Section>

      <Stack.Item>
        <Section title="Manual Generator Controls">
          <LabeledList>
            <LabeledList.Item label="Preset">
              <Dropdown
                width="100%"
                selected={params.planetType}
                options={presets}
                onSelected={(val) => updateParam('planetType', val)}
              />
            </LabeledList.Item>

            <LabeledList.Item label="Main Seed">
              <NumberInput
                width="100%"
                minValue={0}
                maxValue={2000000000}
                value={params.seed}
                onChange={(val) => updateParam('seed', val)}
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
                  onChange={(val) => updateParam('noiseScale', val)}
                />
              </LabeledList.Item>

              <LabeledList.Item label="Terrain Stamp">
                <NumberInput
                  width="100%"
                  minValue={1}
                  maxValue={500}
                  value={params.terrainScale}
                  onChange={(val) => updateParam('terrainScale', val)}
                />
              </LabeledList.Item>

              <LabeledList.Item label="Heat Stamp">
                <NumberInput
                  width="100%"
                  minValue={1}
                  maxValue={500}
                  value={params.heatScale}
                  onChange={(val) => updateParam('heatScale', val)}
                />
              </LabeledList.Item>

              <LabeledList.Item label="Humidity Stamp">
                <NumberInput
                  width="100%"
                  minValue={1}
                  maxValue={500}
                  value={params.humidityScale}
                  onChange={(val) => updateParam('humidityScale', val)}
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
                  onChange={(val) => updateParam('terrainSeed', val)}
                />
              </LabeledList.Item>

              <LabeledList.Item label="Heat Seed">
                <NumberInput
                  width="100%"
                  minValue={0}
                  maxValue={2000000000}
                  value={params.heatSeed}
                  onChange={(val) => updateParam('heatSeed', val)}
                />
              </LabeledList.Item>

              <LabeledList.Item label="Humidity Seed">
                <NumberInput
                  width="100%"
                  minValue={0}
                  maxValue={2000000000}
                  value={params.humiditySeed}
                  onChange={(val) => updateParam('humiditySeed', val)}
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
                      onChange={(val) => updateParam('elevationCoastLow', val)}
                    />
                  </Stack.Item>
                  <Stack.Item grow>
                    <NumberInput
                      width="100%"
                      step={0.01}
                      value={params.elevationCoastHigh}
                      onChange={(val) => updateParam('elevationCoastHigh', val)}
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
                      onChange={(val) =>
                        updateParam('elevationLowlandLow', val)
                      }
                    />
                  </Stack.Item>
                  <Stack.Item grow>
                    <NumberInput
                      width="100%"
                      step={0.01}
                      value={params.elevationLowlandHigh}
                      onChange={(val) =>
                        updateParam('elevationLowlandHigh', val)
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
                      onChange={(val) =>
                        updateParam('elevationHighlandLow', val)
                      }
                    />
                  </Stack.Item>
                  <Stack.Item grow>
                    <NumberInput
                      width="100%"
                      step={0.01}
                      value={params.elevationHighlandHigh}
                      onChange={(val) =>
                        updateParam('elevationHighlandHigh', val)
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
                      onChange={(val) =>
                        updateParam('elevationMountainLow', val)
                      }
                    />
                  </Stack.Item>
                  <Stack.Item grow>
                    <NumberInput
                      width="100%"
                      step={0.01}
                      value={params.elevationMountainHigh}
                      onChange={(val) =>
                        updateParam('elevationMountainHigh', val)
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
                      onChange={(val) => updateParam('elevationSnowLow', val)}
                    />
                  </Stack.Item>
                  <Stack.Item grow>
                    <NumberInput
                      width="100%"
                      step={0.01}
                      value={params.elevationSnowHigh}
                      onChange={(val) => updateParam('elevationSnowHigh', val)}
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
                      onChange={(val) => updateParam('heatThresholdLow', val)}
                    />
                  </Stack.Item>
                  <Stack.Item grow>
                    <NumberInput
                      width="100%"
                      step={0.01}
                      value={params.heatThresholdHigh}
                      onChange={(val) => updateParam('heatThresholdHigh', val)}
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
                      onChange={(val) =>
                        updateParam('humidityThresholdLow', val)
                      }
                    />
                  </Stack.Item>
                  <Stack.Item grow>
                    <NumberInput
                      width="100%"
                      step={0.01}
                      value={params.humidityThresholdHigh}
                      onChange={(val) =>
                        updateParam('humidityThresholdHigh', val)
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

      {!!selectedObject && (
        <Stack.Item>
          <Section title="Selected object">
            <Box bold>{selectedObject.name}</Box>
            <Box color="label">{selectedObject.type}</Box>
            <Box color="label">ID: {selectedObject.id}</Box>
          </Section>
        </Stack.Item>
      )}

      <Stack.Item>
        <Section title="Place & Objects">
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
            <Box color="label" mt={1}>
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
