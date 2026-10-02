import { Box, Button, LabeledList, Section, Stack } from 'tgui-core/components';

import { STATUS_COLOR, STATUS_LABEL, type Status } from './constants';
import type { NodeEntry } from './types';

type Props = {
  node: NodeEntry | undefined;
  nodes: NodeEntry[];
  researched: Set<string>;
  current: string | null;
  queue: Set<string>;
  progress: Record<string, number>;
  canManage: boolean;
  act: (action: string, payload?: object) => void;
  onSelect: (id: string) => void;
};

const statusOf = (
  node: NodeEntry,
  researched: Set<string>,
  current: string | null,
  queue: Set<string>,
): Status => {
  if (researched.has(node.id)) return 'researched';
  if (node.id === current) return 'current';
  if (queue.has(node.id)) return 'queued';
  if (node.prereqs.every((p) => researched.has(p))) return 'available';
  return 'locked';
};

export const DetailsPanel = (props: Props) => {
  const {
    node,
    nodes,
    researched,
    current,
    queue,
    progress,
    canManage,
    act,
    onSelect,
  } = props;

  if (!node) {
    return (
      <Section fill title="Details">
        <Box color="label">Select a technology to see details.</Box>
      </Section>
    );
  }

  const status = statusOf(node, researched, current, queue);
  const nodeProgress = progress[node.id] ?? 0;
  const unlocks = nodes.filter((n) => n.prereqs.includes(node.id));
  const nameOf = (id: string) => nodes.find((n) => n.id === id)?.name ?? id;

  const canEnqueue =
    status === 'available' || status === 'locked'
      ? node.prereqs.every(
          (p) => researched.has(p) || p === current || queue.has(p),
        )
      : false;

  const canStartNow = status === 'available' || status === 'queued';
  const tip = canManage ? undefined : 'Only researchers can manage research';

  return (
    <Stack fill vertical>
      <Stack.Item grow>
        <Section fill scrollable title="Details">
          <Stack vertical>
            <Stack.Item>
              <Box bold fontSize="1.15em" color={STATUS_COLOR[status]}>
                {node.name}
              </Box>
              <Box color="label" italic>
                {STATUS_LABEL[status]}
              </Box>
            </Stack.Item>

            <Stack.Item>{node.desc}</Stack.Item>

            <Stack.Item>
              <LabeledList>
                <LabeledList.Item label="Cost">
                  {status === 'researched'
                    ? node.cost
                    : `${Math.floor(nodeProgress)} / ${node.cost}`}
                </LabeledList.Item>

                <LabeledList.Item label="Era">
                  {node.era || '—'}
                </LabeledList.Item>

                <LabeledList.Item label="Requires">
                  {node.prereqs.length ? (
                    node.prereqs.map((p) => (
                      <Button
                        key={p}
                        compact
                        color={researched.has(p) ? 'good' : 'bad'}
                        onClick={() => onSelect(p)}
                      >
                        {nameOf(p)}
                      </Button>
                    ))
                  ) : (
                    <Box color="label">—</Box>
                  )}
                </LabeledList.Item>

                <LabeledList.Item label="Leads to">
                  {unlocks.length ? (
                    unlocks.map((u) => (
                      <Button
                        key={u.id}
                        compact
                        color="transparent"
                        onClick={() => onSelect(u.id)}
                      >
                        {u.name}
                      </Button>
                    ))
                  ) : (
                    <Box color="label">—</Box>
                  )}
                </LabeledList.Item>

                <LabeledList.Item label="Workbench">
                  {node.benches.length
                    ? node.benches.join(', ')
                    : 'Any research bench'}
                </LabeledList.Item>

                <LabeledList.Item label="Attachments">
                  {node.attachments.length ? node.attachments.join(', ') : '—'}
                </LabeledList.Item>

                <LabeledList.Item label="Unlocks">
                  {node.rewards.length ? (
                    node.rewards.map((r, i) => (
                      <Box key={i}>
                        {r.kind === 'blueprint' ? 'Building' : 'Recipe'}:{' '}
                        {r.name}
                      </Box>
                    ))
                  ) : (
                    <Box color="label">—</Box>
                  )}
                </LabeledList.Item>
              </LabeledList>
            </Stack.Item>

            {status !== 'researched' && (
              <Stack.Item>
                <Stack wrap>
                  {status === 'current' && (
                    <Stack.Item>
                      <Button
                        icon="ban"
                        color="bad"
                        disabled={!canManage}
                        tooltip={tip}
                        onClick={() => act('cancel_current')}
                      >
                        Cancel research
                      </Button>
                    </Stack.Item>
                  )}

                  {status === 'queued' && (
                    <Stack.Item>
                      <Button
                        icon="times"
                        color="bad"
                        disabled={!canManage}
                        tooltip={tip}
                        onClick={() => act('dequeue', { id: node.id })}
                      >
                        Remove from queue
                      </Button>
                    </Stack.Item>
                  )}

                  {(status === 'available' || status === 'locked') && (
                    <Stack.Item>
                      <Button
                        icon="plus"
                        color="good"
                        disabled={!canManage || !canEnqueue}
                        tooltip={
                          tip ??
                          (canEnqueue ? undefined : 'Prerequisites are missing')
                        }
                        onClick={() => act('enqueue', { id: node.id })}
                      >
                        Add to queue
                      </Button>
                    </Stack.Item>
                  )}

                  {canStartNow && (
                    <Stack.Item>
                      <Button
                        icon="play"
                        disabled={!canManage}
                        tooltip={
                          tip ??
                          'Current research goes back to the front of the queue'
                        }
                        onClick={() => act('start_now', { id: node.id })}
                      >
                        Start now
                      </Button>
                    </Stack.Item>
                  )}
                </Stack>
              </Stack.Item>
            )}
          </Stack>
        </Section>
      </Stack.Item>

      <Stack.Item>
        <Section
          title={`Queue (${queue.size})`}
          buttons={
            <Button
              icon="trash"
              color="bad"
              disabled={!canManage || queue.size === 0}
              tooltip={tip}
              onClick={() => act('clear_queue')}
            >
              Clear
            </Button>
          }
        >
          {queue.size === 0 && <Box color="label">Queue is empty.</Box>}
          {[...queue].map((id, i) => (
            <Stack key={id} align="center" mb={0.5}>
              <Stack.Item grow>
                <Button
                  fluid
                  ellipsis
                  color="transparent"
                  onClick={() => onSelect(id)}
                >
                  {`${i + 1}. ${nameOf(id)}`}
                </Button>
              </Stack.Item>
              <Stack.Item>
                <Button
                  icon="arrow-up"
                  disabled={!canManage || i === 0}
                  onClick={() => act('queue_move', { id, dir: -1 })}
                />
                <Button
                  icon="arrow-down"
                  disabled={!canManage || i === queue.size - 1}
                  onClick={() => act('queue_move', { id, dir: 1 })}
                />
                <Button
                  icon="times"
                  color="bad"
                  disabled={!canManage}
                  onClick={() => act('dequeue', { id })}
                />
              </Stack.Item>
            </Stack>
          ))}
        </Section>
      </Stack.Item>
    </Stack>
  );
};
