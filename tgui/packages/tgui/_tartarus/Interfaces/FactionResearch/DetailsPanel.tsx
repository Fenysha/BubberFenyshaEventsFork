import {
  Box,
  Button,
  Divider,
  LabeledList,
  Section,
  Stack,
} from 'tgui-core/components';

import { ERA_COLORS, STATUS_COLOR, STATUS_LABEL, type Status } from './constants';
import type { NodeEntry } from './types';

type Props = {
  node: NodeEntry | undefined;
  nodes: NodeEntry[];
  researched: Set<string>;
  current: string | null;
  queue: Set<string>;
  progress: Record<string, number>;
  canManage: boolean;
  isAdmin?: boolean;
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
    isAdmin = false,
    act,
    onSelect,
  } = props;

  if (!node) {
    return (
      <Section fill title="Details">
        <Box color="label" italic>
          Select a technology on the tree to inspect it.
        </Box>
      </Section>
    );
  }

  const status = statusOf(node, researched, current, queue);
  const nodeProgress = progress[node.id] ?? 0;
  const unlocks = nodes.filter((n) => n.prereqs.includes(node.id));
  const nameOf = (id: string) => nodes.find((n) => n.id === id)?.name ?? id;
  const eraColor = ERA_COLORS[node.era] || '#aaa';

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
        <Section
          fill
          scrollable
          title="Details"
          buttons={
            <Box
              inline
              style={{
                color: eraColor,
                fontSize: '11px',
                fontWeight: 'bold',
                letterSpacing: '0.05em',
                textTransform: 'uppercase',
              }}
            >
              {node.era || '—'}
            </Box>
          }
        >
          <Stack vertical>
            <Stack.Item>
              <Box
                bold
                fontSize="1.2em"
                color={STATUS_COLOR[status]}
                style={{ lineHeight: 1.25 }}
              >
                {node.name}
              </Box>
              <Box
                mt={0.4}
                style={{
                  display: 'inline-block',
                  padding: '1px 8px',
                  borderRadius: '3px',
                  fontSize: '11px',
                  fontWeight: 'bold',
                  background:
                    status === 'researched'
                      ? 'rgba(39,174,96,0.25)'
                      : status === 'current'
                        ? 'rgba(52,152,219,0.3)'
                        : status === 'queued'
                          ? 'rgba(142,68,173,0.25)'
                          : status === 'available'
                            ? 'rgba(255,255,255,0.08)'
                            : 'rgba(80,80,80,0.35)',
                  color:
                    status === 'researched'
                      ? '#2ecc71'
                      : status === 'current'
                        ? '#5dade2'
                        : status === 'queued'
                          ? '#bb8fce'
                          : status === 'available'
                            ? '#ddd'
                            : '#999',
                }}
              >
                {STATUS_LABEL[status]}
              </Box>
            </Stack.Item>

            <Stack.Item>
              <Box color="label" style={{ lineHeight: 1.4 }}>
                {node.desc}
              </Box>
            </Stack.Item>

            <Stack.Item>
              <LabeledList>
                <LabeledList.Item label="Cost">
                  {status === 'researched' ? (
                    node.cost
                  ) : (
                    <Box inline>
                      <Box
                        inline
                        bold
                        color={
                          nodeProgress >= node.cost ? 'good' : undefined
                        }
                      >
                        {Math.floor(nodeProgress)}
                      </Box>
                      {' / '}
                      {node.cost}
                    </Box>
                  )}
                </LabeledList.Item>

                <LabeledList.Item label="Requires">
                  {node.prereqs.length ? (
                    <Stack wrap>
                      {node.prereqs.map((p) => (
                        <Stack.Item key={p}>
                          <Button
                            compact
                            color={researched.has(p) ? 'good' : 'bad'}
                            onClick={() => onSelect(p)}
                          >
                            {nameOf(p)}
                          </Button>
                        </Stack.Item>
                      ))}
                    </Stack>
                  ) : (
                    <Box color="label">—</Box>
                  )}
                </LabeledList.Item>

                <LabeledList.Item label="Leads to">
                  {unlocks.length ? (
                    <Stack wrap>
                      {unlocks.map((u) => (
                        <Stack.Item key={u.id}>
                          <Button
                            compact
                            color="transparent"
                            onClick={() => onSelect(u.id)}
                          >
                            {u.name}
                          </Button>
                        </Stack.Item>
                      ))}
                    </Stack>
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
                  {node.attachments.length
                    ? node.attachments.join(', ')
                    : '—'}
                </LabeledList.Item>

                <LabeledList.Item label="Unlocks">
                  {node.rewards.length ? (
                    node.rewards.map((r, i) => (
                      <Box key={i}>
                        <Box
                          inline
                          color={r.kind === 'blueprint' ? 'blue' : 'average'}
                          bold
                          mr={0.5}
                        >
                          {r.kind === 'blueprint' ? 'Building' : 'Recipe'}
                        </Box>
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
                          (canEnqueue
                            ? undefined
                            : 'Prerequisites are missing')
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

            {isAdmin && (
              <Stack.Item>
                <Divider />
                <Box
                  mb={0.75}
                  style={{
                    fontSize: '11px',
                    fontWeight: 'bold',
                    letterSpacing: '0.05em',
                    textTransform: 'uppercase',
                    color: '#bb8fce',
                  }}
                >
                  Admin tools
                </Box>
                <Stack wrap>
                  {status !== 'researched' && (
                    <Stack.Item>
                      <Button
                        icon="unlock"
                        color="purple"
                        tooltip="Instantly unlock this node for the viewed faction (ignores prerequisites)"
                        onClick={() =>
                          act('admin_force_research', { id: node.id })
                        }
                      >
                        Force research
                      </Button>
                    </Stack.Item>
                  )}
                  {status === 'researched' && (
                    <Stack.Item>
                      <Button
                        icon="lock"
                        color="bad"
                        tooltip="Remove this node from researched (does not cascade)"
                        onClick={() =>
                          act('admin_force_unresearch', { id: node.id })
                        }
                      >
                        Force unresearch
                      </Button>
                    </Stack.Item>
                  )}
                  {status !== 'researched' && status !== 'current' && (
                    <Stack.Item>
                      <Button
                        icon="bolt"
                        color="average"
                        tooltip="Set as current research and fill progress to almost complete"
                        onClick={() =>
                          act('admin_force_progress', { id: node.id })
                        }
                      >
                        Force near-complete
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
