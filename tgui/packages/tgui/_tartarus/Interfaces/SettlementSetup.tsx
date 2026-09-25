import { useBackend } from 'tgui/backend';
import { Window } from 'tgui/layouts';
import {
  Box,
  Button,
  Input,
  LabeledList,
  Section,
  Stack,
  TextArea,
} from 'tgui-core/components';

type SettlementSetupData = {
  isJoin: boolean;
  targetX: number;
  targetY: number;
  factionName: string;
  factionDesc: string;
  factionIcon: string;
  factionIdeology: string;
  settlementName?: string;
  population?: number;
};

export const SettlementSetup = () => {
  const { act, data } = useBackend<SettlementSetupData>();

  const isJoin = !!data.isJoin;

  return (
    <Window
      title={isJoin ? 'Join Settlement' : 'Found Settlement'}
      width={360}
      height={isJoin ? 280 : 420}
    >
      <Window.Content>
        <Stack fill vertical>
          <Stack.Item>
            <Section title={isJoin ? 'Settlement Info' : 'New Settlement'}>
              <LabeledList>
                <LabeledList.Item label="Location">
                  {data.targetX}, {data.targetY}
                </LabeledList.Item>

                {isJoin && (
                  <>
                    <LabeledList.Item label="Name">
                      {data.settlementName || data.factionName}
                    </LabeledList.Item>
                    <LabeledList.Item label="Population">
                      {data.population ?? 0}
                    </LabeledList.Item>
                    <LabeledList.Item label="Faction">
                      {data.factionName}
                    </LabeledList.Item>
                  </>
                )}
              </LabeledList>
            </Section>
          </Stack.Item>

          {!isJoin && (
            <Stack.Item>
              <Section title="Faction Setup">
                <LabeledList>
                  <LabeledList.Item label="Name">
                    <Input
                      fluid
                      value={data.factionName}
                      onChange={(value) =>
                        act('set_faction_name', { name: value })
                      }
                    />
                  </LabeledList.Item>
                  <LabeledList.Item label="Description">
                    <TextArea
                      fluid
                      height="60px"
                      value={data.factionDesc}
                      onChange={(value) =>
                        act('set_faction_desc', { desc: value })
                      }
                    />
                  </LabeledList.Item>
                  <LabeledList.Item label="Icon">
                    <Box color="label" mb={0.5}>
                      Placeholder
                    </Box>
                    <Input
                      fluid
                      value={data.factionIcon}
                      onChange={(value) =>
                        act('set_faction_icon', { icon: value })
                      }
                    />
                  </LabeledList.Item>
                  <LabeledList.Item label="Ideology">
                    <Box color="label" mb={0.5}>
                      Placeholder
                    </Box>
                    <Input
                      fluid
                      value={data.factionIdeology}
                      onChange={(value) =>
                        act('set_faction_ideology', { ideology: value })
                      }
                    />
                  </LabeledList.Item>
                </LabeledList>
              </Section>
            </Stack.Item>
          )}

          <Stack.Item>
            <Stack>
              <Stack.Item grow>
                <Button
                  fluid
                  color="good"
                  icon={isJoin ? 'users' : 'flag'}
                  onClick={() => act('confirm')}
                >
                  {isJoin ? 'Join' : 'Found Settlement'}
                </Button>
              </Stack.Item>
              <Stack.Item grow>
                <Button fluid icon="times" onClick={() => act('cancel')}>
                  Cancel
                </Button>
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
