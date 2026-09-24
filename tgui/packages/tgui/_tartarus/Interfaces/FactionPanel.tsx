import { useBackend } from 'tgui/backend';
import { Window } from 'tgui/layouts';
import {
  Box,
  Button,
  LabeledList,
  NoticeBox,
  Section,
  Stack,
  Table,
} from 'tgui-core/components';

type MemberEntry = {
  ref: string;
  name: string;
  role: string;
  alive: boolean;
  is_self: boolean;
  can_kick: boolean;
  can_promote: boolean;
  can_demote: boolean;
  can_transfer_leadership: boolean;
  can_nominate: boolean;
};

type FactionPanelData = {
  faction_name: string;
  faction_desc: string;
  leader_name: string;
  member_count: number;
  alive_count: number;
  is_leader: boolean;
  is_chief: boolean;
  can_manage: boolean;
  user_ref: string;
  has_active_vote: boolean;
  vote_candidate?: string;
  vote_initiator?: string;
  vote_yes?: number;
  vote_no?: number;
  vote_needed?: number;
  user_voted?: boolean;
  time_left?: number;
  members: MemberEntry[];
};

const roleLabel = (role: string) => {
  switch (role) {
    case 'leader':
      return 'Leader';
    case 'chief':
      return 'Chief';
    default:
      return 'Member';
  }
};

const roleColor = (role: string) => {
  switch (role) {
    case 'leader':
      return 'yellow';
    case 'chief':
      return 'good';
    default:
      return 'label';
  }
};

export const FactionPanel = () => {
  const { act, data } = useBackend<FactionPanelData>();

  return (
    <Window title={data.faction_name} width={620} height={580}>
      <Window.Content scrollable>
        <Stack fill vertical>
          {/* Faction information */}
          <Stack.Item>
            <Section title="Faction">
              <LabeledList>
                <LabeledList.Item label="Name">
                  {data.faction_name}
                </LabeledList.Item>
                <LabeledList.Item label="Description">
                  {data.faction_desc}
                </LabeledList.Item>
                <LabeledList.Item label="Leader">
                  <Box color="yellow">{data.leader_name}</Box>
                </LabeledList.Item>
                <LabeledList.Item label="Members">
                  {data.alive_count} alive / {data.member_count} total
                </LabeledList.Item>
                <LabeledList.Item label="Your role">
                  <Box
                    color={roleColor(
                      data.is_leader
                        ? 'leader'
                        : data.is_chief
                          ? 'chief'
                          : 'member',
                    )}
                  >
                    {data.is_leader
                      ? 'Leader'
                      : data.is_chief
                        ? 'Chief'
                        : 'Member'}
                  </Box>
                </LabeledList.Item>
              </LabeledList>

              <Box mt={1}>
                <Button
                  icon="sign-out-alt"
                  color="bad"
                  fluid
                  onClick={() => act('leave_faction')}
                >
                  Leave Faction
                </Button>
              </Box>
            </Section>
          </Stack.Item>

          {/* Active vote */}
          {!!data.has_active_vote && (
            <Stack.Item>
              <NoticeBox info>
                <Stack vertical>
                  <Stack.Item>
                    <strong>Leadership vote</strong>
                  </Stack.Item>
                  <Stack.Item>
                    Candidate: <b>{data.vote_candidate}</b> (initiator:{' '}
                    {data.vote_initiator})
                  </Stack.Item>
                  <Stack.Item>
                    Yes: {data.vote_yes} / No: {data.vote_no} (needed{' '}
                    {data.vote_needed}) · Time left: {data.time_left}s
                  </Stack.Item>
                  <Stack.Item>
                    <Stack>
                      {!data.user_voted && (
                        <>
                          <Stack.Item>
                            <Button
                              icon="check"
                              color="good"
                              onClick={() => act('vote_yes')}
                            >
                              Yes
                            </Button>
                          </Stack.Item>
                          <Stack.Item>
                            <Button
                              icon="times"
                              color="bad"
                              onClick={() => act('vote_no')}
                            >
                              No
                            </Button>
                          </Stack.Item>
                        </>
                      )}
                      {!!data.is_leader && (
                        <Stack.Item>
                          <Button
                            icon="ban"
                            color="average"
                            onClick={() => act('cancel_vote')}
                          >
                            Cancel Vote
                          </Button>
                        </Stack.Item>
                      )}
                    </Stack>
                  </Stack.Item>
                </Stack>
              </NoticeBox>
            </Stack.Item>
          )}

          {/* Member list */}
          <Stack.Item grow>
            <Section title="Faction Members" fill scrollable>
              <Table>
                <Table.Row header>
                  <Table.Cell>Name</Table.Cell>
                  <Table.Cell>Role</Table.Cell>
                  <Table.Cell>Status</Table.Cell>
                  <Table.Cell>Actions</Table.Cell>
                </Table.Row>
                {data.members.map((m) => (
                  <Table.Row key={m.ref}>
                    <Table.Cell>
                      {m.name}
                      {m.is_self ? ' (you)' : ''}
                    </Table.Cell>
                    <Table.Cell>
                      <Box color={roleColor(m.role)}>{roleLabel(m.role)}</Box>
                    </Table.Cell>
                    <Table.Cell>
                      <Box color={m.alive ? 'good' : 'bad'}>
                        {m.alive ? 'Alive' : 'Dead'}
                      </Box>
                    </Table.Cell>
                    <Table.Cell>
                      <Stack wrap>
                        {m.can_kick && (
                          <Stack.Item>
                            <Button
                              icon="user-slash"
                              color="bad"
                              tooltip="Kick"
                              onClick={() => act('kick', { ref: m.ref })}
                            />
                          </Stack.Item>
                        )}
                        {m.can_promote && (
                          <Stack.Item>
                            <Button
                              icon="star"
                              color="good"
                              tooltip="Appoint as Chief"
                              onClick={() =>
                                act('promote_chief', { ref: m.ref })
                              }
                            />
                          </Stack.Item>
                        )}
                        {m.can_demote && (
                          <Stack.Item>
                            <Button
                              icon="star-half-alt"
                              color="average"
                              tooltip="Remove as Chief"
                              onClick={() =>
                                act('demote_chief', { ref: m.ref })
                              }
                            />
                          </Stack.Item>
                        )}
                        {m.can_transfer_leadership && (
                          <Stack.Item>
                            <Button
                              icon="crown"
                              color="yellow"
                              tooltip="Transfer Leadership"
                              onClick={() =>
                                act('transfer_leadership', { ref: m.ref })
                              }
                            />
                          </Stack.Item>
                        )}
                        {m.can_nominate && (
                          <Stack.Item>
                            <Button
                              icon="vote-yea"
                              tooltip="Nominate for leadership vote"
                              onClick={() => act('start_vote', { ref: m.ref })}
                            />
                          </Stack.Item>
                        )}
                      </Stack>
                    </Table.Cell>
                  </Table.Row>
                ))}
              </Table>
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
