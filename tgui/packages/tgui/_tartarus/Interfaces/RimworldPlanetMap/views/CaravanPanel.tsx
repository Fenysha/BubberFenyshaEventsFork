import { useBackend } from 'tgui/backend';
import {
  Box,
  Button,
  LabeledList,
  Section,
  Stack,
} from 'tgui-core/components';
import type { CaravanMapData, CaravanViewData } from './types';

export const CaravanPanel = () => {
  const { act, data } = useBackend<CaravanMapData>();
  const view: CaravanViewData = data.view ?? {};

  const nearby = view.nearbyCaravans ?? [];
  const pendingMerges = view.pendingMerges ?? [];
  const pendingAttacks = view.pendingAttacks ?? [];
  const members = view.members ?? [];

  return (
    <Stack fill vertical>
      <Stack.Item>
        <Section title="Caravan">
          <Box color="average" mb={1}>
            {view.status || 'Idle'}
          </Box>

          <LabeledList>
            <LabeledList.Item label="ID">
              {view.caravanId || '—'}
            </LabeledList.Item>

            <LabeledList.Item label="Position">
              {view.currentX != null
                ? `${view.currentX}, ${view.currentY}`
                : '—'}
            </LabeledList.Item>

            <LabeledList.Item label="Origin">
              {view.originX != null ? `${view.originX}, ${view.originY}` : '—'}
            </LabeledList.Item>

            <LabeledList.Item label="Destination">
              {view.destinationX != null
                ? `${view.destinationX}, ${view.destinationY}`
                : '—'}
            </LabeledList.Item>

            <LabeledList.Item label="Leader">
              {view.isLeader ? 'You' : 'Other'}
            </LabeledList.Item>

            <LabeledList.Item label="Vehicle">
              {view.hasVehicle
                ? view.hasInterior
                  ? 'With interior'
                  : 'Exterior only'
                : 'None'}
            </LabeledList.Item>

            <LabeledList.Item label="Members">
              {members.length ? members.join(', ') : '—'}
            </LabeledList.Item>
          </LabeledList>
        </Section>
      </Stack.Item>

      <Stack.Item>
        <Section title="Travel">
          <Stack vertical>
            <Stack.Item>
              <Button
                fluid
                icon="route"
                disabled={!view.canTravel}
                onClick={() => act('travel')}
              >
                Start Travel
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button fluid icon="hand" onClick={() => act('stop_travel')}>
                Stop Travel
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button
                fluid
                icon="door-open"
                disabled={!view.canEnter}
                onClick={() => act('enter_tile')}
              >
                Enter Tile
              </Button>
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>

      <Stack.Item>
        <Section title="Character">
          <Stack vertical>
            <Stack.Item>
              <Button fluid icon="heart" onClick={() => act('open_health')}>
                Open Health UI
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button fluid icon="user" onClick={() => act('view_persona')}>
                View Persona
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button fluid icon="flag" onClick={() => act('view_faction')}>
                View Faction
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button fluid icon="scissors" onClick={() => act('split')}>
                Split From Caravan
              </Button>
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>

      {!!pendingMerges.length && (
        <Stack.Item>
          <Section title="Merge Requests">
            {pendingMerges.map((id) => (
              <Stack key={id} mb={1}>
                <Stack.Item grow>{id}</Stack.Item>
                <Stack.Item>
                  <Button
                    icon="check"
                    color="good"
                    onClick={() => act('accept_merge', { id })}
                  >
                    Accept
                  </Button>
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon="times"
                    color="bad"
                    onClick={() => act('deny_merge', { id })}
                  >
                    Deny
                  </Button>
                </Stack.Item>
              </Stack>
            ))}
          </Section>
        </Stack.Item>
      )}

      {!!pendingAttacks.length && (
        <Stack.Item>
          <Section title="Attack Challenges">
            {pendingAttacks.map((id) => (
              <Stack key={id} mb={1}>
                <Stack.Item grow>{id}</Stack.Item>
                <Stack.Item>
                  <Button
                    icon="check"
                    color="bad"
                    onClick={() => act('accept_attack', { id })}
                  >
                    Accept
                  </Button>
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon="times"
                    onClick={() => act('deny_attack', { id })}
                  >
                    Deny
                  </Button>
                </Stack.Item>
              </Stack>
            ))}
          </Section>
        </Stack.Item>
      )}

      {!!nearby.length && (
        <Stack.Item>
          <Section title="Nearby Caravans">
            {nearby.map((c) => (
              <Box key={c.id} mb={1}>
                <Box>
                  <b>{c.id}</b> — {c.leader} ({c.members} members)
                  {c.hasVehicle ? ' [vehicle]' : ''}
                </Box>
                <Stack mt={0.5}>
                  <Stack.Item grow>
                    <Button
                      fluid
                      icon="handshake"
                      onClick={() => act('request_merge', { id: c.id })}
                    >
                      Request Merge
                    </Button>
                  </Stack.Item>
                  <Stack.Item grow>
                    <Button
                      fluid
                      icon="burst"
                      color="bad"
                      onClick={() => act('request_attack', { id: c.id })}
                    >
                      Attack
                    </Button>
                  </Stack.Item>
                </Stack>
              </Box>
            ))}
          </Section>
        </Stack.Item>
      )}
    </Stack>
  );
};
