import { useEffect, useMemo, useState } from 'react';
import { resolveAsset } from 'tgui/assets';
import { useBackend } from 'tgui/backend';
import { Window } from 'tgui/layouts';
import {
  Box,
  Button,
  Divider,
  LabeledList,
  NoticeBox,
  ProgressBar,
  Section,
  Stack,
  Tooltip,
} from 'tgui-core/components';

import type { StorytellerVoteData } from '../Storyteller/types';

const formatTime = (deciseconds: number) => {
  if (deciseconds <= 0) return 'Ended';
  const seconds = Math.ceil(deciseconds / 10);
  const minutes = Math.floor(seconds / 60);
  return minutes > 0 ? `${minutes}m ${seconds % 60}s` : `${seconds}s`;
};

export const StorytellerVote = () => {
  const { data, act } = useBackend<StorytellerVoteData>();
  const {
    storytellers = [],
    difficulty_levels = [],
    personal_selection,
    personal_difficulty = 1,
    total_voters = 0,
    voted_count = 0,
    time_left = 0,
    top_tallies = [],
    is_open = false,
    can_vote = false,
    debug_mode = false,
    admin_mode = false,
    winner_id,
    winner_difficulty,
  } = data;

  // The server owns the ballot; the local copy only makes clicks feel instant.
  const [selected, setSelected] = useState(personal_selection || '');
  useEffect(() => {
    if (personal_selection) setSelected(personal_selection);
  }, [personal_selection]);

  const canInteract = !!is_open && !!can_vote;

  const levelLocked = (minPlayers: number) =>
    !debug_mode && minPlayers > total_voters;

  const select = (id: string) => {
    if (!canInteract) return;
    setSelected(id);
    act('select_storyteller', { id });
  };

  const pickDifficulty = (value: number) => {
    if (!canInteract) return;
    act('set_difficulty', { value });
  };

  const current = useMemo(
    () =>
      storytellers.find((s) => s.id === (is_open ? selected : winner_id)) ||
      storytellers.find((s) => s.id === selected) ||
      null,
    [storytellers, selected, winner_id, is_open],
  );

  const levelLabel = (value?: number | null) =>
    difficulty_levels.find((l) => l.value === value)?.label;

  const hasResults = top_tallies.length > 0 || !!winner_id;
  if (!is_open && !hasResults) {
    return (
      <Window title="Storyteller Vote" width={760} height={300}>
        <Window.Content>
          <NoticeBox>
            Voting has ended without ballots. The current storyteller stays.
          </NoticeBox>
        </Window.Content>
      </Window>
    );
  }

  const winner = storytellers.find((s) => s.id === winner_id);

  return (
    <Window
      title={is_open ? 'Vote for Storyteller' : 'Storyteller Vote Results'}
      width={1000}
      height={700}
    >
      <Window.Content
        style={{
          backgroundImage: current?.portrait_asset
            ? `url(${resolveAsset(current.portrait_asset)})`
            : undefined,
          backgroundSize: '480px 480px',
          backgroundPositionX: '100%',
          backgroundPositionY: '100%',
          backgroundRepeat: 'no-repeat',
          position: 'absolute',
        }}
      >
        {!can_vote && is_open && (
          <NoticeBox>
            You cannot participate in the vote, but you can still view the
            candidates.
          </NoticeBox>
        )}
        {!is_open && winner && (
          <NoticeBox success>
            {winner.name} was chosen
            {levelLabel(winner_difficulty)
              ? ` on "${levelLabel(winner_difficulty)}"`
              : ''}
            .
          </NoticeBox>
        )}

        <Stack fill>
          <Stack.Item style={{ flex: '0 0 240px', boxSizing: 'border-box' }}>
            <Section
              title="Candidates"
              scrollable
              style={{
                maxWidth: '240px',
                height: '100%',
                width: '100%',
                boxSizing: 'border-box',
                overflowX: 'hidden',
                overflowY: 'auto',
              }}
            >
              {storytellers.length ? (
                <Stack fill vertical>
                  {storytellers.map((c) => (
                    <Tooltip
                      key={c.id}
                      content={
                        <Box>
                          <Box bold>{c.name}</Box>
                          {c.ooc_desc && <Box>{c.ooc_desc}</Box>}
                          {c.ooc_difficulty && (
                            <Box color="average">
                              Difficulty: {c.ooc_difficulty}
                            </Box>
                          )}
                        </Box>
                      }
                    >
                      <Button
                        p={1}
                        mb={1}
                        width="96px"
                        height="96px"
                        style={{
                          cursor: canInteract ? 'pointer' : 'default',
                          borderRadius: 4,
                          opacity: is_open ? 1 : 0.6,
                          backgroundImage: c.logo_asset
                            ? `url(${resolveAsset(c.logo_asset)})`
                            : undefined,
                          backgroundSize: 'contain',
                          backgroundRepeat: 'no-repeat',
                          backgroundPosition: 'center',
                          backgroundColor:
                            c.id === (is_open ? selected : winner_id)
                              ? 'rgba(255,255,255,0.255)'
                              : 'rgba(255,255,255,0.00)',
                        }}
                        onClick={() => select(c.id)}
                      >
                        {c.logo_asset ? null : c.name}
                      </Button>
                    </Tooltip>
                  ))}
                </Stack>
              ) : (
                <NoticeBox>No storytellers provided.</NoticeBox>
              )}
            </Section>
          </Stack.Item>

          <Stack.Item grow maxWidth="50%">
            <Section>
              <Box>
                The AI storyteller creates events like weather changes, resource
                drops or enemy raids. Its choices affect the difficulty and
                narrative of the round.
              </Box>
            </Section>

            <Section title={is_open ? 'Your Vote' : 'Selected storyteller'}>
              {current ? (
                <>
                  <h1>{current.name}</h1>
                  <LabeledList>
                    <LabeledList.Item label="Description">
                      {current.desc || '—'}
                    </LabeledList.Item>
                    <LabeledList.Item label="OOC Description">
                      {current.ooc_desc || '-'}
                    </LabeledList.Item>
                    <LabeledList.Item label="OOC Difficulty">
                      {current.ooc_difficulty || '-'}
                    </LabeledList.Item>
                  </LabeledList>

                  <Divider />

                  <LabeledList>
                    <LabeledList.Item
                      label="Difficulty"
                      tooltip="Multiplies the threat points of raids and similar incidents. Higher values mean bigger threats. Some levels need a minimum number of players."
                    >
                      <Stack fill vertical>
                        {difficulty_levels.map((level) => {
                          const locked = levelLocked(level.min_players);
                          const checked = is_open
                            ? level.value === personal_difficulty
                            : level.value === winner_difficulty;
                          return (
                            <Stack.Item key={level.value}>
                              <Tooltip
                                content={
                                  locked
                                    ? `${level.tooltip} (Requires ${level.min_players}+ players)`
                                    : level.tooltip
                                }
                              >
                                <Stack fill>
                                  <Button.Checkbox
                                    checked={checked}
                                    disabled={!canInteract || locked}
                                    onClick={() => pickDifficulty(level.value)}
                                  />
                                  <Box
                                    ml={1}
                                    style={{ opacity: locked ? 0.5 : 1 }}
                                  >
                                    <Box fontSize="1.1em">{level.label}</Box>
                                    {level.min_players > 0 && !debug_mode && (
                                      <Box fontSize="0.8em" color="average">
                                        ({level.min_players}+ players)
                                      </Box>
                                    )}
                                  </Box>
                                </Stack>
                              </Tooltip>
                            </Stack.Item>
                          );
                        })}
                      </Stack>
                    </LabeledList.Item>
                  </LabeledList>
                </>
              ) : (
                <NoticeBox>Select a storyteller on the left.</NoticeBox>
              )}
            </Section>

            <Section title="Vote Progress">
              <LabeledList>
                <LabeledList.Item label="Voters">
                  <ProgressBar
                    value={voted_count}
                    maxValue={Math.max(total_voters, voted_count, 1)}
                    minValue={0}
                    ranges={{
                      good: [0.7, Infinity],
                      average: [0.3, 0.7],
                      bad: [-Infinity, 0.3],
                    }}
                  >
                    {voted_count}/{Math.max(total_voters, voted_count)}
                  </ProgressBar>
                </LabeledList.Item>
                {!!is_open && (
                  <LabeledList.Item label="Time Left">
                    {formatTime(time_left)}
                  </LabeledList.Item>
                )}
              </LabeledList>

              {top_tallies.length > 0 && (
                <>
                  <Divider />
                  <LabeledList>
                    <LabeledList.Item label="Top Choices">
                      {top_tallies.slice(0, 5).map((t) => (
                        <Box key={t.id} mb={0.5}>
                          <ProgressBar
                            value={t.count}
                            maxValue={Math.max(voted_count, 1)}
                            color={t.id === winner_id ? 'good' : 'default'}
                          >
                            <b>{t.name}</b>: {t.count} votes
                            {levelLabel(t.difficulty)
                              ? ` (${levelLabel(t.difficulty)})`
                              : ''}
                          </ProgressBar>
                        </Box>
                      ))}
                    </LabeledList.Item>
                  </LabeledList>
                </>
              )}
            </Section>
          </Stack.Item>
        </Stack>

        {!!admin_mode && !!is_open && (
          <Box position="absolute" bottom={1} left={1}>
            <Button
              color="bad"
              icon="bolt"
              tooltip="Immediately end the storyteller voting (admin only)"
              onClick={() => act('force_end_vote')}
            >
              End vote
            </Button>
          </Box>
        )}
      </Window.Content>
    </Window>
  );
};
