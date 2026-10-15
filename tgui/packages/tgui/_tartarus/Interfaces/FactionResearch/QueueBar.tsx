import {
  Box,
  Button,
  NoticeBox,
  ProgressBar,
  Section,
  Stack,
} from 'tgui-core/components';

import type { NodeEntry } from './types';

type Props = {
  current: string | null;
  queue: string[];
  progress: Record<string, number>;
  byId: Map<string, NodeEntry>;
  canManage: boolean;
  benchReady: boolean;
  benchText: string;
  act: (action: string, payload?: object) => void;
  onSelect: (id: string) => void;
  factionName?: string | null;
  factionColor?: string | null;
};

export const QueueBar = (props: Props) => {
  const {
    current,
    queue,
    progress,
    byId,
    canManage,
    benchReady,
    benchText,
    act,
    onSelect,
    factionName,
    factionColor,
  } = props;

  const currentNode = current ? byId.get(current) : undefined;
  const currentProgress = currentNode ? (progress[currentNode.id] ?? 0) : 0;
  const currentFraction = currentNode
    ? Math.min(1, currentProgress / Math.max(1, currentNode.cost))
    : 0;

  const noRights = 'Only researchers can manage research';

  return (
    <Section
      title={
        <Box inline>
          Current research
          {factionName && (
            <Box
              inline
              ml={1}
              style={{
                color: factionColor || '#aaa',
                fontWeight: 'normal',
                fontSize: '0.9em',
              }}
            >
              — {factionName}
            </Box>
          )}
        </Box>
      }
      buttons={
        !!currentNode && (
          <Button
            icon="ban"
            color="bad"
            disabled={!canManage}
            tooltip={canManage ? 'Progress is kept' : noRights}
            onClick={() => act('cancel_current')}
          >
            Cancel
          </Button>
        )
      }
    >
      {currentNode ? (
        <Stack vertical>
          <Stack.Item>
            <Button
              color="transparent"
              onClick={() => onSelect(currentNode.id)}
            >
              <b>{currentNode.name}</b>
            </Button>
            <Box inline color="label" ml={1}>
              {Math.floor(currentProgress)} / {currentNode.cost}
            </Box>
          </Stack.Item>
          <Stack.Item>
            <ProgressBar
              value={currentFraction}
              color={benchReady ? 'good' : 'average'}
            >
              {Math.floor(currentFraction * 100)}%
            </ProgressBar>
          </Stack.Item>
          {!benchReady && (
            <Stack.Item>
              <NoticeBox mb={0}>{benchText}</NoticeBox>
            </Stack.Item>
          )}
          {!!queue.length && (
            <Stack.Item>
              <Box color="label" mb={0.5}>
                Queue:
              </Box>
              <Stack wrap>
                {queue.map((id, i) => (
                  <Stack.Item key={id}>
                    <Button compact onClick={() => onSelect(id)}>
                      {i + 1}. {byId.get(id)?.name ?? id}
                    </Button>
                  </Stack.Item>
                ))}
              </Stack>
            </Stack.Item>
          )}
        </Stack>
      ) : (
        <Box color="label">
          Nothing is being researched. Select a node from the tree.
        </Box>
      )}
    </Section>
  );
};
