import { useEffect, useState } from 'react';
import { resolveAsset } from 'tgui/assets';
import { useBackend } from 'tgui/backend';
import { Box, Button, LabeledList, Section, Stack } from 'tgui-core/components';
import type { SettlementMapData, SettlementViewData } from './types';

export const SettlementPanel = () => {
  const { act, data } = useBackend<SettlementMapData>();
  const view: SettlementViewData = data.view || {};
  const mode = view.mode || 'start';
  const selected = data.selectedTile;

  if (mode === 'observer') {
    const loadedCells = view.loadedCells || [];
    return (
      <Stack fill vertical>
        <Stack.Item>
          <Section title="Loaded Cells">
            {loadedCells.length === 0 ? (
              <Box color="label">No cells loaded.</Box>
            ) : (
              <Stack vertical>
                {loadedCells.map((cell) => (
                  <Stack.Item key={`${cell.x}:${cell.y}`}>
                    <Button
                      fluid
                      icon="location-arrow"
                      onClick={() =>
                        act('jump_to_cell', { x: cell.x, y: cell.y })
                      }
                    >
                      {cell.name || `${cell.x}, ${cell.y}`}
                    </Button>
                  </Stack.Item>
                ))}
              </Stack>
            )}
          </Section>
        </Stack.Item>
        <Stack.Item>
          <Box color="label" fontSize="0.9em">
            Double-click any loaded cell or settlement to jump.
          </Box>
        </Stack.Item>
      </Stack>
    );
  }

  // mode === "start"
  const playerSettlements = view.playerSettlements || [];

  return (
    <Stack fill vertical>
      <Stack.Item>
        <Section title="Selected Location">
          {!selected ? (
            <Box color="label">Select a tile on the planet map.</Box>
          ) : (
            <LabeledList>
              <LabeledList.Item label="Coordinates">
                {selected.x}, {selected.y}
              </LabeledList.Item>
              <LabeledList.Item label="Biome">
                {selected.biome}
              </LabeledList.Item>
              <LabeledList.Item label="Elevation">
                {selected.elevation}
              </LabeledList.Item>
              {view.joinSettlementId && (
                <LabeledList.Item label="Status">
                  <Box color="good">Player settlement present</Box>
                </LabeledList.Item>
              )}
            </LabeledList>
          )}
        </Section>
      </Stack.Item>

      <Stack.Item>
        <Stack>
          <Stack.Item grow>
            <Button
              fluid
              color="good"
              icon="flag"
              disabled={!view.canCreate}
              onClick={() => act('open_create_setup')}
            >
              Found Settlement
            </Button>
          </Stack.Item>
          <Stack.Item grow>
            <Button
              fluid
              color="average"
              icon="users"
              disabled={!view.canJoin}
              onClick={() =>
                act('open_join_setup', { id: view.joinSettlementId })
              }
            >
              Join Settlement
            </Button>
          </Stack.Item>
        </Stack>
      </Stack.Item>

      <Stack.Item>
        <Section title="Player Settlements">
          {playerSettlements.length === 0 ? (
            <Box color="label">No player settlements loaded yet.</Box>
          ) : (
            <Stack vertical>
              {playerSettlements.map((sett) => (
                <Stack.Item key={sett.id}>
                  <Button
                    fluid
                    selected={view.joinSettlementId === sett.id}
                    onClick={() => act('select_settlement', { id: sett.id })}
                  >
                    <Box>
                      <Stack align="center">
                        <Stack.Item>
                          <SettlementMark icon={sett.icon} color={sett.color} />
                        </Stack.Item>
                        <Stack.Item grow>
                          <Box>{sett.name}</Box>
                          <Box color="label" fontSize="0.85em">
                            {sett.faction} · pop. {sett.population} · {sett.x},
                            {sett.y}
                          </Box>
                        </Stack.Item>
                      </Stack>
                    </Box>
                  </Button>
                </Stack.Item>
              ))}
            </Stack>
          )}
        </Section>
      </Stack.Item>
    </Stack>
  );
};

function markerSrc(icon?: string | null) {
  if (!icon) {
    return '';
  }
  try {
    return resolveAsset(`rimworld_planet_icon_${icon}.png`);
  } catch {
    return '';
  }
}

function SettlementMark(props: { icon?: string | null; color?: string | null }) {
  const src = markerSrc(props.icon);
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
      const raw = (props.color || '#ffffff').replace('#', '');
      const full =
        raw.length === 3
          ? raw
              .split('')
              .map((char) => char + char)
              .join('')
          : raw;
      const value = Number.parseInt(full, 16);
      const tint = Number.isNaN(value)
        ? { r: 255, g: 255, b: 255 }
        : {
            r: (value >> 16) & 255,
            g: (value >> 8) & 255,
            b: value & 255,
          };
      const pixels = frame.data;
      for (let i = 0; i < pixels.length; i += 4) {
        if (pixels[i + 3] < 8) {
          continue;
        }
        const whiteness =
          (pixels[i] + pixels[i + 1] + pixels[i + 2]) / (255 * 3);
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
    return null;
  }
  return (
    <img
      src={painted}
      alt=""
      width={24}
      height={24}
      style={{ display: 'block', imageRendering: 'pixelated' }}
    />
  );
}
