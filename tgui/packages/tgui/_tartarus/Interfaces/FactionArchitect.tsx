import { useMemo, useState } from 'react';
import { useBackend } from 'tgui/backend';
import { Window } from 'tgui/layouts';
import {
  Box,
  Button,
  DmIcon,
  Input,
  NoticeBox,
  Section,
  Stack,
} from 'tgui-core/components';

type MaterialEntry = {
  path: string;
  name: string;
  amount: number;
};

type BlueprintEntry = {
  id: string;
  name: string;
  desc: string;
  tab: string;
  can_rotate: boolean;
  is_multiblock: boolean;
  construction_time: number;
  icon: string;
  icon_state: string;
  materials: MaterialEntry[];
  from_faction: boolean;
};

type ArchitectData = {
  tabs: string[];
  blueprints: BlueprintEntry[];
  planning: boolean;
  planning_id: string | null;
  planning_name: string | null;
  planning_dir: string | null;
  has_faction: boolean;
};

const GRID_STYLE: React.CSSProperties = {
  display: 'grid',
  gridTemplateColumns: 'repeat(4, 1fr)',
  gap: '8px',
};

export function FactionArchitect() {
  const { act, data } = useBackend<ArchitectData>();
  const {
    tabs = [],
    blueprints = [],
    planning,
    planning_id,
    planning_name,
    planning_dir,
    has_faction,
  } = data;

  const [tab, setTab] = useState(tabs[0] || 'Structure');
  const [search, setSearch] = useState('');
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [materialPath, setMaterialPath] = useState<string | null>(null);

  const normalizedSearch = search.trim().toLowerCase();

  const visible = useMemo(() => {
    return blueprints.filter((bp) => {
      if (bp.tab !== tab) return false;
      if (!normalizedSearch) return true;
      return (
        bp.name.toLowerCase().includes(normalizedSearch) ||
        bp.desc.toLowerCase().includes(normalizedSearch)
      );
    });
  }, [blueprints, tab, normalizedSearch]);

  const selected = blueprints.find((b) => b.id === selectedId);
  const fallback = <Box width="48px" height="48px" />;

  return (
    <Window width={1000} height={700} title="Architect">
      <Window.Content style={{ backgroundColor: '#333333' }}>
        <Stack vertical fill>
          {!!planning && (
            <Stack.Item>
              <NoticeBox info>
                Planning: <b>{planning_name}</b>
                {planning_dir ? ` · ${planning_dir}` : ''}
                <Button ml={1} icon="sync" onClick={() => act('rotate')}>
                  Rotate
                </Button>
                <Button
                  ml={1}
                  icon="times"
                  color="bad"
                  onClick={() => act('cancel')}
                >
                  Cancel
                </Button>
              </NoticeBox>
            </Stack.Item>
          )}

          <Stack.Item>
            <Input
              fluid
              placeholder="Search blueprints..."
              value={search}
              onChange={setSearch}
            />
          </Stack.Item>

          <Stack.Item grow>
            <Stack fill>
              <Stack.Item basis="180px">
                <Section fill scrollable title="Categories">
                  {tabs.map((t) => (
                    <Button
                      key={t}
                      fluid
                      mb={0.5}
                      color={tab === t ? 'grey' : 'transparent'}
                      onClick={() => setTab(t)}
                    >
                      {t}
                    </Button>
                  ))}
                </Section>
              </Stack.Item>

              <Stack.Item grow>
                <Section fill scrollable title={tab}>
                  <Box style={GRID_STYLE}>
                    {visible.map((bp) => {
                      const isSelected = selectedId === bp.id;
                      const isActive = planning_id === bp.id;
                      return (
                        <Box key={bp.id}>
                          <Button
                            tooltip={`${bp.name}${bp.from_faction ? ' (faction)' : ''}`}
                            backgroundColor={
                              isActive
                                ? '#2d6a4f'
                                : isSelected
                                  ? '#666666'
                                  : '#444444'
                            }
                            onClick={() => setSelectedId(bp.id)}
                            onDoubleClick={() =>
                              act('select', {
                                id: bp.id,
                                material: materialPath,
                              })
                            }
                          >
                            <DmIcon
                              icon={bp.icon}
                              icon_state={bp.icon_state}
                              width="64px"
                              fallback={fallback}
                              backgroundColor={
                                isSelected ? '#666666' : '#444444'
                              }
                            />
                          </Button>
                          <Box
                            textAlign="center"
                            fontSize="11px"
                            color={bp.from_faction ? '#9bdbff' : '#cccccc'}
                            mt={0.3}
                            style={{
                              overflow: 'hidden',
                              textOverflow: 'ellipsis',
                              whiteSpace: 'nowrap',
                            }}
                          >
                            {bp.name}
                          </Box>
                        </Box>
                      );
                    })}
                  </Box>
                  {!visible.length && (
                    <Box color="#888888" textAlign="center" py={4}>
                      No blueprints in this category
                    </Box>
                  )}
                </Section>
              </Stack.Item>

              <Stack.Item basis="300px">
                <Section title="Selected" mb={2}>
                  {selected ? (
                    <Stack vertical>
                      <DmIcon
                        icon={selected.icon}
                        icon_state={selected.icon_state}
                        width="96px"
                        fallback={fallback}
                      />
                      <Stack.Item>
                        <Box fontWeight="bold">{selected.name}</Box>
                      </Stack.Item>
                      <Stack.Item>
                        <Box color="#b0b0b0">{selected.desc || '—'}</Box>
                      </Stack.Item>
                      <Stack.Item>
                        <Box color="#aaaaaa" fontSize="12px">
                          {selected.is_multiblock
                            ? 'Multi-tile'
                            : 'Single tile'}
                          {selected.can_rotate ? ' · Rotatable' : ''}
                          {selected.from_faction ? ' · Faction tech' : ''}
                        </Box>
                      </Stack.Item>
                    </Stack>
                  ) : (
                    <Box color="#aaaaaa">Nothing selected</Box>
                  )}
                </Section>

                <Section title="Build settings" mb={2}>
                  {selected ? (
                    <Stack vertical>
                      <Stack.Item>
                        <Box color="#d2d2d2" mb={0.5}>
                          Materials
                        </Box>
                        {selected.materials?.length ? (
                          selected.materials.map((m) => (
                            <Button
                              key={m.path}
                              fluid
                              mb={0.5}
                              color={
                                materialPath === m.path ? 'grey' : 'transparent'
                              }
                              onClick={() =>
                                setMaterialPath(
                                  materialPath === m.path ? null : m.path,
                                )
                              }
                            >
                              {m.name} × {m.amount}
                            </Button>
                          ))
                        ) : (
                          <Box color="#888888">No materials listed</Box>
                        )}
                      </Stack.Item>
                      <Stack.Item>
                        <Box color="#888888" fontSize="12px">
                          Time: {(selected.construction_time / 10).toFixed(1)}s
                        </Box>
                      </Stack.Item>
                    </Stack>
                  ) : (
                    <Box color="#888888">Select a blueprint</Box>
                  )}
                </Section>

                {!has_faction && (
                  <Section mb={2}>
                    <Box color="#888888" fontSize="12px">
                      Join a faction to unlock additional blueprints via
                      research.
                    </Box>
                  </Section>
                )}

                <Section>
                  <Button
                    fluid
                    icon="pencil-alt"
                    color="good"
                    disabled={!selected}
                    onClick={() =>
                      selected &&
                      act('select', {
                        id: selected.id,
                        material: materialPath,
                      })
                    }
                  >
                    Plan
                  </Button>
                  {!!planning && (
                    <Button
                      fluid
                      mt={1}
                      icon="times"
                      color="bad"
                      onClick={() => act('cancel')}
                    >
                      Cancel planning
                    </Button>
                  )}
                </Section>
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
}
