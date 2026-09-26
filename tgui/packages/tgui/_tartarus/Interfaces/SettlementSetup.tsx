import { useEffect, useState } from 'react';
import { resolveAsset } from 'tgui/assets';
import { useBackend } from 'tgui/backend';
import { Window } from 'tgui/layouts';
import {
  Box,
  Button,
  Input,
  LabeledList,
  NoticeBox,
  ProgressBar,
  Section,
  Stack,
  TextArea,
} from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';

type SettlementSetupData = {
  isJoin: boolean;
  targetX: number;
  targetY: number;

  isLoading: BooleanLike;
  loadingProgress: number;
  loadingStage: string;
  loadingDetail: string;
  loadingCurrent: number;
  loadingTotal: number;
  loadingUnit: string;
  loadingError?: string;

  factionName: string;
  factionDesc: string;
  factionIcon: string;
  factionColor: string;
  iconChoices?: string[];
  factionIdeology: string;

  settlementName?: string;
  population?: number;
};

export const SettlementSetup = () => {
  const { act, data } = useBackend<SettlementSetupData>();

  const isJoin = !!data.isJoin;
  const isLoading = !!data.isLoading;
  const hasError = !!data.loadingError;

  const progress = Math.max(
    0,
    Math.min(1, Number(data.loadingProgress) || 0),
  );

  const percent = Math.round(progress * 100);

  const windowHeight = isLoading
    ? 330
    : hasError
      ? 350
      : isJoin
        ? 340
        : 520;

  return (
    <Window
      title={
        isLoading
          ? 'Establishing Settlement'
          : isJoin
            ? 'Join Settlement'
            : 'Found Settlement'
      }
      width={390}
      height={windowHeight}
    >
      <Window.Content>
        <Stack fill vertical>
          <Stack.Item>
            <Section>
              <Stack align="center">
                <Stack.Item grow>
                  <Box bold fontSize="1.1rem">
                    {isLoading
                      ? 'Establishing Settlement'
                      : isJoin
                        ? data.settlementName || data.factionName
                        : 'New Settlement'}
                  </Box>

                  <Box color="label" mt={0.25}>
                    Landing site: {data.targetX}, {data.targetY}
                  </Box>
                </Stack.Item>

                {!isLoading && (
                  <Stack.Item>
                    <Box color="label" textAlign="right">
                      {isJoin ? 'JOIN' : 'FOUND'}
                    </Box>
                  </Stack.Item>
                )}
              </Stack>
            </Section>
          </Stack.Item>

          {isLoading ? (
            <Stack.Item grow>
              <Section fill title={data.loadingStage || 'Preparing'}>
                <Stack vertical fill>
                  <Stack.Item>
                    <Box color="label" mb={1}>
                      {data.loadingDetail || 'Preparing the local world...'}
                    </Box>

                    <ProgressBar value={progress} color="good">
                      {percent}%
                    </ProgressBar>
                  </Stack.Item>

                  <Stack.Item grow>
                    <Stack align="center" mt={2}>
                      <Stack.Item grow>
                        <Box bold>
                          {data.loadingCurrent > 0 &&
                          data.loadingTotal > 0
                            ? `${data.loadingCurrent.toLocaleString()} / ${data.loadingTotal.toLocaleString()} ${data.loadingUnit || ''}`
                            : 'Working...'}
                        </Box>

                        <Box color="label" mt={0.5}>
                          The settlement map is being generated. Please wait.
                        </Box>
                      </Stack.Item>
                    </Stack>
                  </Stack.Item>

                  <Stack.Item>
                    <Box color="label" textAlign="center">
                      Do not close this window while generation is in progress.
                    </Box>
                  </Stack.Item>
                </Stack>
              </Section>
            </Stack.Item>
          ) : hasError ? (
            <Stack.Item grow>
              <Section title="Generation Failed">
                <Stack vertical>
                  <Stack.Item>
                    <NoticeBox>
                      {data.loadingError}
                    </NoticeBox>
                  </Stack.Item>

                  <Stack.Item>
                    <Box color="label">
                      The local map could not be generated. No settlement was
                      created.
                    </Box>
                  </Stack.Item>

                  <Stack.Item>
                    <Stack>
                      <Stack.Item grow>
                        <Button
                          fluid
                          color="good"
                          icon="redo"
                          onClick={() => act('retry')}
                        >
                          Try Again
                        </Button>
                      </Stack.Item>

                      <Stack.Item grow>
                        <Button
                          fluid
                          icon="times"
                          onClick={() => act('cancel')}
                        >
                          Cancel
                        </Button>
                      </Stack.Item>
                    </Stack>
                  </Stack.Item>
                </Stack>
              </Section>
            </Stack.Item>
          ) : (
            <>
              <Stack.Item>
                <Section title={isJoin ? 'Settlement Info' : 'Colony Charter'}>
                  <LabeledList>
                    {isJoin && (
                      <>
                        <LabeledList.Item label="Population">
                          {data.population ?? 0}
                        </LabeledList.Item>

                        <LabeledList.Item label="Faction">
                          {data.factionName}
                        </LabeledList.Item>

                        {!!data.factionDesc && (
                          <LabeledList.Item label="Description">
                            <Box color="label">{data.factionDesc}</Box>
                          </LabeledList.Item>
                        )}
                        <LabeledList.Item label="Icon">
                          <SettlementMark
                            icon={data.factionIcon}
                            color={data.factionColor}
                          />
                        </LabeledList.Item>
                        <LabeledList.Item label="Color">
                          <Box
                            inline
                            width="14px"
                            height="14px"
                            style={{ background: data.factionColor || '#ffffff' }}
                          />
                        </LabeledList.Item>
                      </>
                    )}

                    {!isJoin && (
                      <>
                        <LabeledList.Item label="Name">
                          <Input
                            fluid
                            value={data.factionName}
                            disabled={isLoading}
                            onChange={(value) =>
                              act('set_faction_name', { name: value })
                            }
                          />
                        </LabeledList.Item>

                        <LabeledList.Item label="Description">
                          <TextArea
                            fluid
                            height="70px"
                            value={data.factionDesc}
                            disabled={isLoading}
                            onChange={(value) =>
                              act('set_faction_desc', { desc: value })
                            }
                          />
                        </LabeledList.Item>

                        <LabeledList.Item label="Icon">
                          <Stack align="center">
                            {(data.iconChoices || []).map((iconId) => (
                              <Stack.Item key={iconId}>
                                <button
                                  type="button"
                                  title={iconId}
                                  disabled={isLoading}
                                  onClick={() =>
                                    act('set_faction_icon', { icon: iconId })
                                  }
                                  style={{
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                    width: 40,
                                    height: 40,
                                    margin: 0,
                                    padding: 0,
                                    boxSizing: 'border-box',
                                    background: '#141414',
                                    border: '2px solid',
                                    borderColor:
                                      data.factionIcon === iconId
                                        ? '#f2f2f2'
                                        : '#3a3a3a',
                                    lineHeight: 0,
                                    cursor: isLoading ? 'default' : 'pointer',
                                  }}
                                >
                                  <SettlementMark
                                    icon={iconId}
                                    color={data.factionColor}
                                    size={26}
                                  />
                                </button>
                              </Stack.Item>
                            ))}
                          </Stack>
                        </LabeledList.Item>

                        <LabeledList.Item label="Color">
                          <Stack align="center">
                            <Stack.Item>
                              <input
                                type="color"
                                value={data.factionColor || '#ffffff'}
                                disabled={isLoading}
                                onChange={(event) =>
                                  act('set_faction_color', {
                                    color: event.target.value,
                                  })
                                }
                              />
                            </Stack.Item>
                            <Stack.Item>
                              <Box color="label">{data.factionColor}</Box>
                            </Stack.Item>
                          </Stack>
                        </LabeledList.Item>

                        <LabeledList.Item label="Ideology">
                          <Input
                            fluid
                            value={data.factionIdeology}
                            disabled={isLoading}
                            onChange={(value) =>
                              act('set_faction_ideology', { ideology: value })
                            }
                          />
                        </LabeledList.Item>
                      </>
                    )}
                  </LabeledList>
                </Section>
              </Stack.Item>

              <Stack.Item grow />

              <Stack.Item>
                <Stack>
                  <Stack.Item grow>
                    <Button
                      fluid
                      color="good"
                      icon={isJoin ? 'users' : 'flag'}
                      disabled={isLoading}
                      onClick={() => act('confirm')}
                    >
                      {isJoin ? 'Join Settlement' : 'Found Settlement'}
                    </Button>
                  </Stack.Item>

                  <Stack.Item grow>
                    <Button
                      fluid
                      icon="times"
                      disabled={isLoading}
                      onClick={() => act('cancel')}
                    >
                      Cancel
                    </Button>
                  </Stack.Item>
                </Stack>
              </Stack.Item>
            </>
          )}
        </Stack>
      </Window.Content>
    </Window>
  );
};

function markerSrc(icon: string) {
  try {
    return resolveAsset(`rimworld_planet_icon_${icon}.png`);
  } catch {
    return '';
  }
}

function hexToRgb(hex: string) {
  const raw = hex.replace('#', '');
  const full =
    raw.length === 3
      ? raw
          .split('')
          .map((char) => char + char)
          .join('')
      : raw;
  const value = Number.parseInt(full, 16);
  if (Number.isNaN(value)) {
    return { r: 255, g: 255, b: 255 };
  }
  return {
    r: (value >> 16) & 255,
    g: (value >> 8) & 255,
    b: value & 255,
  };
}

function SettlementMark(props: { icon?: string; color?: string; size?: number }) {
  const src = props.icon ? markerSrc(props.icon) : '';
  const size = props.size ?? 24;
  const [painted, setPainted] = useState('');

  useEffect(() => {
    if (!src) {
      setPainted('');
      return;
    }
    let cancelled = false;
    const image = new Image();
    image.onload = () => {
      const canvas = document.createElement('canvas');
      canvas.width = image.width;
      canvas.height = image.height;
      const context = canvas.getContext('2d');
      if (!context) {
        return;
      }
      context.drawImage(image, 0, 0);
      const frame = context.getImageData(0, 0, canvas.width, canvas.height);
      const tint = hexToRgb(props.color || '#ffffff');
      const pixels = frame.data;
      for (let i = 0; i < pixels.length; i += 4) {
        if (pixels[i + 3] < 8) {
          continue;
        }
        const whiteness = (pixels[i] + pixels[i + 1] + pixels[i + 2]) / (255 * 3);
        pixels[i] = tint.r * whiteness;
        pixels[i + 1] = tint.g * whiteness;
        pixels[i + 2] = tint.b * whiteness;
      }
      context.putImageData(frame, 0, 0);
      if (!cancelled) {
        setPainted(canvas.toDataURL());
      }
    };
    image.src = src;
    return () => {
      cancelled = true;
    };
  }, [src, props.color]);

  if (!painted) {
    return <span style={{ display: 'block', width: size, height: size }} />;
  }
  return (
    <img
      src={painted}
      alt=""
      width={size}
      height={size}
      style={{ display: 'block', imageRendering: 'pixelated' }}
    />
  );
}
