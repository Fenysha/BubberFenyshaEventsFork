import { useMemo, useState } from 'react';
import { resolveAsset } from 'tgui/assets';
import { useBackend } from 'tgui/backend';
import { Window } from 'tgui/layouts';
import {
  Box,
  Button,
  Dropdown,
  Input,
  Section,
  Stack,
  Table,
} from 'tgui-core/components';
import type { StorytellerAdminData } from './types';

export const Storyteller = () => {
  const { act, data } = useBackend<StorytellerAdminData>();
  const selectedCell = data.selected_cell;

  const [difficulty, setDifficulty] = useState(data.difficulty_multiplier);
  const [eventId, setEventId] = useState('');
  const [daysFromNow, setDaysFromNow] = useState(0);
  const [intervalDays, setIntervalDays] = useState(
    selectedCell?.interval_override_days || 0,
  );
  const [rescheduleDays, setRescheduleDays] = useState(0);

  const storytellerOptions = useMemo(
    () =>
      data.storytellers.map((profile) => ({
        displayText: profile.name,
        value: profile.id,
      })),
    [data.storytellers],
  );
  const eventOptions = useMemo(
    () =>
      data.available_events.map((event) => ({
        displayText: `${event.name} · ${event.category}`,
        value: event.id,
      })),
    [data.available_events],
  );

  return (
    <Window width={1080} height={780}>
      <Window.Content scrollable>
        <Section
          title="Active storyteller"
          buttons={
            <Stack>
              <Stack.Item>
                <Button icon="play" onClick={() => act('force_think')}>
                  Process selected cell
                </Button>
              </Stack.Item>
              <Stack.Item>
                <Button
                  icon="vote-yea"
                  onClick={() => act('start_vote')}
                  disabled={data.vote_active}
                >
                  Start vote
                </Button>
              </Stack.Item>
              <Stack.Item>
                <Button
                  icon="stop"
                  onClick={() => act('end_vote')}
                  disabled={!data.vote_active}
                >
                  End vote
                </Button>
              </Stack.Item>
              <Stack.Item>
                <Button icon="refresh" onClick={() => act('reload_profiles')}>
                  Reload JSON
                </Button>
              </Stack.Item>
            </Stack>
          }
        >
          <Stack align="center">
            <Stack.Item>
              {data.active_id ? (
                <img
                  src={resolveAsset(`${data.active_id}_portrait.png`)}
                  width="100"
                  height="100"
                />
              ) : null}
            </Stack.Item>
            <Stack.Item grow>
              <Box fontSize="18px" bold>
                {data.active_name}
              </Box>
              <Box>{data.active_desc}</Box>
              <Box color="label" mt={1}>
                {data.active_ooc_desc}
              </Box>
            </Stack.Item>
            <Stack.Item width="300px">
              <Box mb={1}>Switch storyteller</Box>
              <Dropdown
                options={storytellerOptions}
                selected={data.active_id}
                onSelected={(id) => act('set_storyteller', { id })}
                width="100%"
              />
              <Box mt={2}>
                Difficulty: {Number(data.difficulty_multiplier).toFixed(1)}×
              </Box>
              <input
                type="range"
                min="0.3"
                max="5"
                step="0.1"
                value={difficulty}
                onChange={(event) =>
                  setDifficulty(Number(event.currentTarget.value))
                }
                style={{ width: '100%' }}
              />
              <Button
                fluid
                onClick={() => act('set_difficulty', { value: difficulty })}
              >
                Apply difficulty
              </Button>
            </Stack.Item>
          </Stack>
          <Box mt={1} color="label">
            {data.event_count} registered incidents · planet day{' '}
            {Number(data.current_day).toFixed(2)}
          </Box>
        </Section>

        <Section title="Planet cells">
          {!data.cells.length ? (
            <Box color="label">
              No runtime cells have been created yet. Open or load a planet cell
              first.
            </Box>
          ) : null}
          <Table>
            {data.cells.map((cell) => (
              <Table.Row key={cell.id}>
                <Table.Cell>
                  <Button
                    fluid
                    color={
                      cell.id === data.selected_cell_id ? 'good' : 'default'
                    }
                    onClick={() => act('select_cell', { id: cell.id })}
                  >
                    {cell.name} ({cell.x}, {cell.y})
                  </Button>
                </Table.Cell>
                <Table.Cell collapsing>
                  {cell.loaded ? 'Loaded' : 'Unloaded'}
                </Table.Cell>
              </Table.Row>
            ))}
          </Table>
        </Section>

        {selectedCell ? (
          <Section title={`Event plan · ${selectedCell.name}`}>
            <Box color="label">
              Coordinates {selectedCell.x}, {selectedCell.y} ·{' '}
              {selectedCell.biome} · Weather: {selectedCell.weather} ·{' '}
              {selectedCell.loaded ? 'Local map loaded' : 'Local map unloaded'}
            </Box>
            <Box color="label">
              {selectedCell.has_colony ? 'Player colony' : 'No colony'} ·
              colonists {selectedCell.colonists} · colony age{' '}
              {Number(selectedCell.colony_age_days).toFixed(1)} d · threat
              points <b>{selectedCell.threat_points}</b>
            </Box>
            <Stack mt={2} align="end">
              <Stack.Item grow>
                <Box mb={1}>Add incident</Box>
                <Dropdown
                  options={eventOptions}
                  selected={eventId || data.available_events[0]?.id}
                  onSelected={(id) => setEventId(id)}
                  width="100%"
                />
              </Stack.Item>
              <Stack.Item width="130px">
                <Box mb={1}>Days from now</Box>
                <Input
                  value={String(daysFromNow)}
                  onChange={(value) =>
                    setDaysFromNow(Math.max(0, Number(value) || 0))
                  }
                />
              </Stack.Item>
              <Stack.Item>
                <Button
                  icon="plus"
                  color="good"
                  disabled={!data.available_events.length}
                  onClick={() =>
                    act('add_event', {
                      event_id: eventId || data.available_events[0]?.id,
                      days_from_now: daysFromNow,
                    })
                  }
                >
                  Add
                </Button>
              </Stack.Item>
              <Stack.Item>
                <Button icon="rotate" onClick={() => act('replan_cell')}>
                  Replan
                </Button>
              </Stack.Item>
            </Stack>

            <Stack mt={2} align="end">
              <Stack.Item grow>
                <Box mb={1}>
                  Cell interval override (days, 0 = storyteller default)
                </Box>
                <Input
                  value={String(intervalDays)}
                  onChange={(value) =>
                    setIntervalDays(Math.max(0, Number(value) || 0))
                  }
                />
              </Stack.Item>
              <Stack.Item>
                <Button
                  onClick={() =>
                    act('set_cell_interval', { value: intervalDays })
                  }
                >
                  Apply interval
                </Button>
              </Stack.Item>
            </Stack>

            <Table mt={2}>
              <Table.Row header>
                <Table.Cell>Incident</Table.Cell>
                <Table.Cell>Category</Table.Cell>
                <Table.Cell>Timing</Table.Cell>
                <Table.Cell>Controls</Table.Cell>
              </Table.Row>
              {selectedCell.upcoming.map((entry) => (
                <Table.Row key={entry.id}>
                  <Table.Cell>
                    <Box bold>{entry.name}</Box>
                    <Box color="label">{entry.description}</Box>
                  </Table.Cell>
                  <Table.Cell>{entry.category}</Table.Cell>
                  <Table.Cell>
                    <Box>Day {Number(entry.fire_day).toFixed(2)}</Box>
                    <Box color="label">
                      in {Number(entry.days_until).toFixed(2)} days
                      {entry.manual ? ' · manual' : ''}
                    </Box>
                  </Table.Cell>
                  <Table.Cell>
                    <Stack vertical>
                      <Stack.Item>
                        <Button
                          icon="play"
                          color="good"
                          disabled={!selectedCell.loaded}
                          onClick={() =>
                            act('trigger_event', { entry_id: entry.id })
                          }
                        >
                          Fire
                        </Button>
                      </Stack.Item>
                      <Stack.Item>
                        <Input
                          value={String(rescheduleDays)}
                          onChange={(value) =>
                            setRescheduleDays(Math.max(0, Number(value) || 0))
                          }
                        />
                      </Stack.Item>
                      <Stack.Item>
                        <Button
                          icon="clock"
                          onClick={() =>
                            act('reschedule_event', {
                              entry_id: entry.id,
                              days_from_now: rescheduleDays,
                            })
                          }
                        >
                          Reschedule
                        </Button>
                        <Button
                          icon="trash"
                          color="bad"
                          onClick={() =>
                            act('remove_event', { entry_id: entry.id })
                          }
                        >
                          Remove
                        </Button>
                      </Stack.Item>
                    </Stack>
                  </Table.Cell>
                </Table.Row>
              ))}
            </Table>
            {!selectedCell.upcoming.length ? (
              <Box color="label" mt={1}>
                No incidents are currently eligible for this cell.
              </Box>
            ) : null}
          </Section>
        ) : null}
      </Window.Content>
    </Window>
  );
};
