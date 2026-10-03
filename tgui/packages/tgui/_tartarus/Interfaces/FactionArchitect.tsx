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

type CostEntry = {
  path: string;
  name: string;
  amount: number;
};

type StuffMaterial = {
  path: string;
  name: string;
  desc: string;
  color: string;
  category: string;
  hp: number;
  beauty: number;
  flammability: number;
  armor_sharp: number;
  armor_blunt: number;
  armor_heat: number;
  value: number;
};

type BlueprintEntry = {
  id: string;
  name: string;
  desc: string;
  tab: string;
  can_rotate: boolean;
  is_multiblock: boolean;
  construction_time: number;
  build_steps: number;
  icon: string;
  icon_state: string;
  extra_costs: CostEntry[];
  stuffed: boolean;
  stuff_cost: number;
  stuff_categories: string[];
  default_stuff: string | null;
  from_faction: boolean;
};

type ArchitectData = {
  tabs: string[];
  blueprints: BlueprintEntry[];
  planning: boolean;
  planning_id: string | null;
  planning_name: string | null;
  planning_dir: string | null;
  planning_material: string | null;
  has_faction: boolean;
  materials: StuffMaterial[];
  material_categories: string[];
  stock: Record<string, number>;
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
    materials = [],
    stock = {},
  } = data;

  const [tab, setTab] = useState(tabs[0] || 'Structure');
  const [search, setSearch] = useState('');
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [materialPath, setMaterialPath] = useState<string | null>(null);
  const [matCategory, setMatCategory] = useState<string>('All');

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

  const allowedMaterials = selected?.stuffed
    ? materials.filter((m) => selected.stuff_categories.includes(m.category))
    : [];
  const allowedCategories = Array.from(
    new Set(allowedMaterials.map((m) => m.category)),
  );
  const shownMaterials =
    matCategory === 'All'
      ? allowedMaterials
      : allowedMaterials.filter((m) => m.category === matCategory);

  const effectiveMaterial: StuffMaterial | undefined = selected?.stuffed
    ? allowedMaterials.find((m) => m.path === materialPath) ||
      allowedMaterials.find((m) => m.path === selected.default_stuff) ||
      allowedMaterials[0]
    : undefined;

  const selectBlueprint = (id: string) => {
    setSelectedId(id);
    setMaterialPath(null);
    setMatCategory('All');
  };

  const plan = (bp: BlueprintEntry) =>
    act('select', {
      id: bp.id,
      material: bp.stuffed ? effectiveMaterial?.path : null,
    });
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
                            onClick={() => selectBlueprint(bp.id)}
                            onDoubleClick={() => {
                              selectBlueprint(bp.id);
                              act('select', {
                                id: bp.id,
                                material: bp.stuffed ? bp.default_stuff : null,
                              });
                            }}
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
                      <Box
                        height="4px"
                        width="96px"
                        backgroundColor={
                          effectiveMaterial?.color || 'transparent'
                        }
                      />
                      <Stack.Item>
                        <Box fontWeight="bold">
                          {effectiveMaterial
                            ? `${effectiveMaterial.name} ${selected.name}`
                            : selected.name}
                        </Box>
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
                          Cost
                        </Box>
                        {selected.stuffed && (
                          <Box
                            color={
                              (stock[effectiveMaterial?.path || ''] || 0) >=
                              selected.stuff_cost
                                ? '#cccccc'
                                : '#ff8888'
                            }
                          >
                            {effectiveMaterial?.name || 'material'} ×{' '}
                            {selected.stuff_cost}
                            <Box as="span" color="#888888">
                              {' '}
                              (have {stock[effectiveMaterial?.path || ''] || 0})
                            </Box>
                          </Box>
                        )}
                        {selected.extra_costs.map((m) => (
                          <Box key={m.path} color="#cccccc">
                            {m.name} × {m.amount}
                          </Box>
                        ))}
                        {!selected.stuffed && !selected.extra_costs.length && (
                          <Box color="#888888">Free</Box>
                        )}
                      </Stack.Item>
                      <Stack.Item>
                        <Box color="#888888" fontSize="12px">
                          Time: {(selected.construction_time / 10).toFixed(1)}s
                          · {selected.build_steps} steps
                        </Box>
                      </Stack.Item>
                    </Stack>
                  ) : (
                    <Box color="#888888">Select a blueprint</Box>
                  )}
                </Section>

                {!!selected?.stuffed && (
                  <Section title="Made of" mb={2}>
                    <Box mb={0.5}>
                      {['All', ...allowedCategories].map((c) => (
                        <Button
                          key={c}
                          compact
                          mr={0.5}
                          color={matCategory === c ? 'grey' : 'transparent'}
                          onClick={() => setMatCategory(c)}
                        >
                          {c}
                        </Button>
                      ))}
                    </Box>
                    <Box style={{ maxHeight: '170px', overflowY: 'auto' }}>
                      {shownMaterials.map((m) => {
                        const have = stock[m.path] || 0;
                        return (
                          <Button
                            key={m.path}
                            fluid
                            mb={0.5}
                            selected={effectiveMaterial?.path === m.path}
                            color="transparent"
                            tooltip={`${m.desc} HP ×${m.hp} · Beauty ×${m.beauty} · Flammability ${Math.round(
                              m.flammability * 100,
                            )}% · Armor ${m.armor_sharp}/${m.armor_blunt}/${m.armor_heat} · Value ${m.value}`}
                            onClick={() => setMaterialPath(m.path)}
                          >
                            <Box
                              as="span"
                              inline
                              mr={1}
                              width="10px"
                              height="10px"
                              backgroundColor={m.color}
                              style={{ border: '1px solid #000' }}
                            />
                            {m.name}
                            <Box
                              as="span"
                              ml={1}
                              color={
                                have >= selected.stuff_cost ? '#8f8' : '#888'
                              }
                            >
                              ({have})
                            </Box>
                          </Button>
                        );
                      })}
                    </Box>
                  </Section>
                )}

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
                    onClick={() => selected && plan(selected)}
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
