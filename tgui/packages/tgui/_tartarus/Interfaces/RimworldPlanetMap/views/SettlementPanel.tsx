import { useBackend } from 'tgui/backend';
import { Box, Button, LabeledList, Section, Stack } from 'tgui-core/components';
import type { PlanetMapData } from '../types';

export const SettlementPanel = () => {
  const { act, data } = useBackend<PlanetMapData>();
  const view = data.view || {};
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
                      <Box>{sett.name}</Box>
                      <Box color="label" fontSize="0.85em">
                        {sett.faction} · pop. {sett.population} · {sett.x},
                        {sett.y}
                      </Box>
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
