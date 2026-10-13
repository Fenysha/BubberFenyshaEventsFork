import { useMemo, useState } from 'react';
import { resolveAsset } from 'tgui/assets';
import { useBackend } from 'tgui/backend';
import { Window } from 'tgui/layouts';
import {
  Box,
  Button,
  Dropdown,
  Input,
  NoticeBox,
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
  const [eventSearch, setEventSearch] = useState('');

  const storytellerOptions = useMemo(
    () =>
      data.storytellers.map((profile) => ({
        displayText: profile.name,
        value: profile.id,
      })),
    [data.storytellers],
  );

  const filteredEvents = useMemo(() => {
    const query = eventSearch.trim().toLowerCase();
    if (!query) return data.available_events;

    return data.available_events.filter(
      (event) =>
        event.name.toLowerCase().includes(query) ||
        event.category.toLowerCase().includes(query) ||
        event.id.toLowerCase().includes(query),
    );
  }, [data.available_events, eventSearch]);

  const eventOptions = useMemo(
    () =>
      filteredEvents.map((event) => ({
        displayText: `${event.name} · ${event.category}`,
        value: event.id,
      })),
    [filteredEvents],
  );

  const effectiveEventId =
    eventId && filteredEvents.some((e) => e.id === eventId)
      ? eventId
      : filteredEvents[0]?.id || '';

  const portraitSrc = data.active_id
    ? resolveAsset(`${data.active_id}_portrait.png`)
    : null;
  const logoSrc = data.active_id
    ? resolveAsset(`${data.active_id}_logo.png`)
    : null;

  return (
    <Window width={1200} height={820} title="Storyteller Admin">
      <Window.Content
        style={{
          backgroundImage: portraitSrc ? `url(${portraitSrc})` : undefined,
          backgroundSize: '520px 520px',
          backgroundPosition: '100% 100%',
          backgroundRepeat: 'no-repeat',
          backgroundColor: 'rgba(0, 0, 0, 0.55)',
          backgroundBlendMode: 'multiply',
        }}
      >
        <Stack fill>
          <Stack.Item style={{ flex: '0 0 380px', minWidth: 0 }}>
            <Stack fill vertical>
              <Stack.Item>
                <Section
                  title="Active Storyteller"
                  buttons={
                    <Button
                      icon="refresh"
                      tooltip="Reload storyteller profiles from JSON"
                      onClick={() => act('reload_profiles')}
                    />
                  }
                >
                  <Stack vertical>
                    <Stack.Item>
                      <Stack align="start">
                        <Stack.Item>
                          {logoSrc ? (
                            <Box
                              width="96px"
                              height="96px"
                              style={{
                                backgroundImage: `url(${logoSrc})`,
                                backgroundSize: 'contain',
                                backgroundRepeat: 'no-repeat',
                                backgroundPosition: 'center',
                                borderRadius: '6px',
                                backgroundColor: 'rgba(255,255,255,0.08)',
                              }}
                            />
                          ) : portraitSrc ? (
                            <img
                              src={portraitSrc}
                              width={96}
                              height={96}
                              style={{
                                objectFit: 'cover',
                                borderRadius: '6px',
                                display: 'block',
                              }}
                            />
                          ) : (
                            <Box
                              width="96px"
                              height="96px"
                              backgroundColor="rgba(0,0,0,0.25)"
                              style={{ borderRadius: '6px' }}
                            />
                          )}
                        </Stack.Item>

                        <Stack.Item grow ml={1.5}>
                          <Box fontSize="1.3em" bold>
                            {data.active_name || 'None'}
                          </Box>
                          <Box mt={0.5} color="label">
                            {data.active_desc || '—'}
                          </Box>
                          {data.active_ooc_desc && (
                            <Box mt={0.75} color="average" fontSize="0.9em">
                              {data.active_ooc_desc}
                            </Box>
                          )}
                        </Stack.Item>
                      </Stack>
                    </Stack.Item>

                    <Stack.Item mt={1.5}>
                      <Box mb={0.5} color="label">
                        Switch storyteller
                      </Box>
                      <Dropdown
                        options={storytellerOptions}
                        selected={data.active_id}
                        onSelected={(id) => act('set_storyteller', { id })}
                        width="100%"
                      />
                    </Stack.Item>

                    <Stack.Item mt={1.5}>
                      <Box mb={0.5}>
                        Difficulty:{' '}
                        <b>{Number(data.difficulty_multiplier).toFixed(1)}×</b>
                      </Box>
                      <input
                        type="range"
                        min="0.3"
                        max="5"
                        step="0.1"
                        value={difficulty}
                        onChange={(e) =>
                          setDifficulty(Number(e.currentTarget.value))
                        }
                        style={{ width: '100%' }}
                      />
                      <Button
                        fluid
                        mt={0.75}
                        icon="check"
                        onClick={() =>
                          act('set_difficulty', { value: difficulty })
                        }
                      >
                        Apply difficulty
                      </Button>
                    </Stack.Item>

                    <Stack.Item mt={1.5}>
                      <Stack>
                        <Stack.Item grow>
                          <Button
                            fluid
                            icon="vote-yea"
                            disabled={data.vote_active}
                            onClick={() => act('start_vote')}
                          >
                            Start vote
                          </Button>
                        </Stack.Item>
                        <Stack.Item grow>
                          <Button
                            fluid
                            icon="stop"
                            color="bad"
                            disabled={!data.vote_active}
                            onClick={() => act('end_vote')}
                          >
                            End vote
                          </Button>
                        </Stack.Item>
                      </Stack>
                    </Stack.Item>

                    <Stack.Item mt={1}>
                      <Box color="label" fontSize="0.9em">
                        {data.event_count} registered incidents · planet day{' '}
                        {Number(data.current_day).toFixed(2)}
                        {data.vote_active && (
                          <Box inline color="good" ml={1}>
                            · Vote active
                          </Box>
                        )}
                      </Box>
                    </Stack.Item>
                  </Stack>
                </Section>
              </Stack.Item>

              <Stack.Item grow>
                <Section title="Planet Cells" fill scrollable>
                  {!data.cells.length ? (
                    <NoticeBox>
                      No runtime cells have been created yet. Open or load a
                      planet cell first.
                    </NoticeBox>
                  ) : (
                    <Stack vertical>
                      {data.cells.map((cell) => (
                        <Stack.Item key={cell.id}>
                          <Button
                            fluid
                            color={
                              cell.id === data.selected_cell_id
                                ? 'good'
                                : 'default'
                            }
                            onClick={() => act('select_cell', { id: cell.id })}
                          >
                            <Box>
                              <Box bold>{cell.name}</Box>
                              <Box fontSize="0.85em" color="label">
                                ({cell.x}, {cell.y}) ·{' '}
                                {cell.loaded ? 'Loaded' : 'Unloaded'}
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
          </Stack.Item>

          <Stack.Item grow>
            {!selectedCell ? (
              <Section fill>
                <NoticeBox>
                  Select a planet cell on the left to manage its event plan.
                </NoticeBox>
              </Section>
            ) : (
              <Stack fill vertical>
                <Stack.Item>
                  <Section
                    title={`Event Plan · ${selectedCell.name}`}
                    buttons={
                      <Stack>
                        <Stack.Item>
                          <Button
                            icon="play"
                            tooltip="Force process the selected cell"
                            onClick={() => act('force_think')}
                          >
                            Process cell
                          </Button>
                        </Stack.Item>
                        <Stack.Item>
                          <Button
                            icon="rotate"
                            onClick={() => act('replan_cell')}
                          >
                            Replan
                          </Button>
                        </Stack.Item>
                      </Stack>
                    }
                  >
                    <Box color="label">
                      Coordinates {selectedCell.x}, {selectedCell.y} ·{' '}
                      {selectedCell.biome} · Weather: {selectedCell.weather} ·{' '}
                      {selectedCell.loaded
                        ? 'Local map loaded'
                        : 'Local map unloaded'}
                    </Box>
                    <Box color="label" mt={0.5}>
                      {selectedCell.has_colony ? 'Player colony' : 'No colony'}{' '}
                      · colonists {selectedCell.colonists} · colony age{' '}
                      {Number(selectedCell.colony_age_days).toFixed(1)} d ·
                      threat points <b>{selectedCell.threat_points}</b>
                    </Box>

                    <Stack mt={1.5} align="end">
                      <Stack.Item grow>
                        <Box mb={0.5} color="label">
                          Search & add incident
                        </Box>
                        <Input
                          placeholder="Search by name or category..."
                          value={eventSearch}
                          onChange={(value) => setEventSearch(value)}
                          fluid
                        />
                        <Box mt={0.75}>
                          <Dropdown
                            options={eventOptions}
                            selected={effectiveEventId}
                            onSelected={(id) => setEventId(id)}
                            width="100%"
                            disabled={!eventOptions.length}
                          />
                        </Box>
                        {!filteredEvents.length && eventSearch && (
                          <Box mt={0.5} color="average" fontSize="0.85em">
                            No events match “{eventSearch}”
                          </Box>
                        )}
                      </Stack.Item>
                      <Stack.Item width="120px">
                        <Box mb={0.5} color="label">
                          Days from now
                        </Box>
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
                          disabled={!effectiveEventId}
                          onClick={() =>
                            act('add_event', {
                              event_id: effectiveEventId,
                              days_from_now: daysFromNow,
                            })
                          }
                        >
                          Add
                        </Button>
                      </Stack.Item>
                    </Stack>

                    <Stack mt={1.5} align="end">
                      <Stack.Item grow>
                        <Box mb={0.5} color="label">
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
                  </Section>
                </Stack.Item>

                <Stack.Item grow>
                  <Section title="Upcoming Incidents" fill scrollable>
                    {!selectedCell.upcoming.length ? (
                      <Box color="label">
                        No incidents are currently eligible for this cell.
                      </Box>
                    ) : (
                      <Table>
                        <Table.Row header>
                          <Table.Cell>Incident</Table.Cell>
                          <Table.Cell collapsing>Category</Table.Cell>
                          <Table.Cell collapsing>Timing</Table.Cell>
                          <Table.Cell collapsing>Controls</Table.Cell>
                        </Table.Row>
                        {selectedCell.upcoming.map((entry) => (
                          <Table.Row key={entry.id}>
                            <Table.Cell>
                              <Box bold>{entry.name}</Box>
                              <Box color="label" fontSize="0.9em">
                                {entry.description}
                              </Box>
                            </Table.Cell>
                            <Table.Cell>{entry.category}</Table.Cell>
                            <Table.Cell>
                              <Box>Day {Number(entry.fire_day).toFixed(2)}</Box>
                              <Box color="label" fontSize="0.85em">
                                in {Number(entry.days_until).toFixed(2)} days
                                {entry.manual ? ' · manual' : ''}
                              </Box>
                            </Table.Cell>
                            <Table.Cell>
                              <Stack>
                                <Stack.Item>
                                  <Button
                                    icon="play"
                                    color="good"
                                    disabled={!selectedCell.loaded}
                                    tooltip={
                                      selectedCell.loaded
                                        ? 'Fire now'
                                        : 'Cell map must be loaded'
                                    }
                                    onClick={() =>
                                      act('trigger_event', {
                                        entry_id: entry.id,
                                      })
                                    }
                                  />
                                </Stack.Item>
                                <Stack.Item>
                                  <Button
                                    icon="clock"
                                    tooltip="Reschedule"
                                    onClick={() =>
                                      act('reschedule_event', {
                                        entry_id: entry.id,
                                        days_from_now: rescheduleDays,
                                      })
                                    }
                                  />
                                </Stack.Item>
                                <Stack.Item>
                                  <Button
                                    icon="trash"
                                    color="bad"
                                    tooltip="Remove"
                                    onClick={() =>
                                      act('remove_event', {
                                        entry_id: entry.id,
                                      })
                                    }
                                  />
                                </Stack.Item>
                              </Stack>
                              <Box mt={0.5}>
                                <Input
                                  placeholder="Days..."
                                  value={String(rescheduleDays)}
                                  onChange={(value) =>
                                    setRescheduleDays(
                                      Math.max(0, Number(value) || 0),
                                    )
                                  }
                                  width="70px"
                                />
                              </Box>
                            </Table.Cell>
                          </Table.Row>
                        ))}
                      </Table>
                    )}
                  </Section>
                </Stack.Item>
              </Stack>
            )}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
