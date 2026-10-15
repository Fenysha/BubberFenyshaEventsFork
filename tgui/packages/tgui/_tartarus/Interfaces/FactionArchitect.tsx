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
  Tooltip,
} from 'tgui-core/components';

type CostEntry = {
  path: string;
  name: string;
  amount: number;
  iconSrc?: string | null;
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
  iconSrc?: string | null;
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
  is_cancel?: boolean;
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
  is_admin: boolean;
  instant_build: boolean;
  materials: StuffMaterial[];
  material_categories: string[];
  stock: Record<string, number>;
  inventory: Record<string, number>;
};

const GRID_STYLE: React.CSSProperties = {
  display: 'grid',
  gridTemplateColumns: 'repeat(auto-fill, minmax(84px, 1fr))',
  gap: '8px',
};

const COLOR_BG = '#333333';
const COLOR_CARD = '#444444';
const COLOR_CARD_SELECTED = '#666666';
const COLOR_ACTIVE = '#2d6a4f';
const COLOR_OK = '#8fe08f';
const COLOR_BAD = '#ff8c8c';
const COLOR_ADMIN = '#b46cff';

const toSrc = (src?: string | null) =>
  src ? `data:image/png;base64,${src}` : undefined;

/** A small pixel-art icon from a base64 PNG. Renders an empty slot if there is none. */
function ItemIcon(props: { src?: string | null; size?: number }) {
  const { src, size = 32 } = props;
  const url = toSrc(src);
  if (!url) {
    return <Box inline width={`${size}px`} height={`${size}px`} />;
  }
  return (
    <img
      src={url}
      width={size}
      height={size}
      style={{ imageRendering: 'pixelated', verticalAlign: 'middle' }}
    />
  );
}

/** Icon + "have / need", coloured by availability. */
function CostChip(props: {
  iconSrc?: string | null;
  name: string;
  need: number;
  have: number;
  admin?: boolean;
}) {
  const { iconSrc, name, need, have, admin } = props;
  const ok = admin || have >= need;
  return (
    <Tooltip content={`${name}: need ${need}, you carry ${have}`}>
      <Box
        inline
        mr={1}
        mb={1}
        px={0.5}
        py={0.25}
        style={{
          border: `1px solid ${ok ? '#3f7a3f' : '#8a3a3a'}`,
          borderRadius: '4px',
          backgroundColor: ok ? '#243324' : '#3a2424',
        }}
      >
        <ItemIcon src={iconSrc} size={28} />
        <Box as="span" ml={0.5} bold color={ok ? COLOR_OK : COLOR_BAD}>
          {admin ? need : `${Math.min(have, 999)}/${need}`}
        </Box>
      </Box>
    </Tooltip>
  );
}

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
    is_admin,
    instant_build,
    materials = [],
    stock = {},
    inventory = {},
  } = data;

  const [tab, setTab] = useState(tabs[0] || 'Structure');
  const [search, setSearch] = useState('');
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [materialPath, setMaterialPath] = useState<string | null>(null);
  const [matCategory, setMatCategory] = useState<string>('All');

  const normalizedSearch = search.trim().toLowerCase();
  const searching = normalizedSearch.length > 0;

  const matches = (bp: BlueprintEntry) =>
    bp.name.toLowerCase().includes(normalizedSearch) ||
    bp.desc.toLowerCase().includes(normalizedSearch);

  // While searching, look through every category at once.
  const visible = useMemo(
    () =>
      blueprints.filter((bp) => {
        if (searching) return matches(bp);
        return bp.tab === tab;
      }),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [blueprints, tab, normalizedSearch],
  );

  const tabCounts = useMemo(() => {
    const counts: Record<string, number> = {};
    for (const bp of blueprints) {
      counts[bp.tab] = (counts[bp.tab] || 0) + 1;
    }
    return counts;
  }, [blueprints]);

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

  /** Can the user pay for this blueprint right now, with the given material? */
  const canAfford = (bp: BlueprintEntry, mat?: StuffMaterial) => {
    if (instant_build) return true;
    for (const c of bp.extra_costs) {
      if ((inventory[c.path] || 0) < c.amount) return false;
    }
    if (bp.stuffed) {
      const path = mat?.path || bp.default_stuff;
      if (!path || (stock[path] || 0) < bp.stuff_cost) return false;
    }
    return true;
  };

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

  const selectedAffordable = selected
    ? canAfford(selected, effectiveMaterial)
    : true;

  return (
    <Window width={1000} height={700} title="Architect">
      <Window.Content style={{ backgroundColor: COLOR_BG }}>
        <Stack vertical fill>
          {!!planning && (
            <Stack.Item>
              <NoticeBox info>
                Planning: <b>{planning_name}</b>
                {planning_dir ? ` · ${planning_dir}` : ''}
                {!!instant_build && (
                  <Box as="span" ml={1} bold color={COLOR_ADMIN}>
                    · INSTANT
                  </Box>
                )}
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
            <Stack>
              <Stack.Item grow>
                <Input
                  fluid
                  placeholder="Search all blueprints..."
                  value={search}
                  onChange={setSearch}
                />
              </Stack.Item>
              {!!is_admin && (
                <Stack.Item>
                  <Button
                    icon={instant_build ? 'bolt' : 'hammer'}
                    selected={instant_build}
                    color={instant_build ? 'purple' : 'default'}
                    tooltip="Admin only. When on, planned buildings are completed instantly and cost nothing."
                    onClick={() => act('toggle_instant')}
                  >
                    Instant build: {instant_build ? 'ON' : 'OFF'}
                  </Button>
                </Stack.Item>
              )}
            </Stack>
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
                      color={!searching && tab === t ? 'grey' : 'transparent'}
                      onClick={() => {
                        setSearch('');
                        setTab(t);
                      }}
                    >
                      {t}
                      <Box as="span" ml={1} color="#999999">
                        {tabCounts[t] || 0}
                      </Box>
                    </Button>
                  ))}
                </Section>
              </Stack.Item>

              <Stack.Item grow>
                <Section
                  fill
                  scrollable
                  title={searching ? `Search: "${search}"` : tab}
                >
                  <Box style={GRID_STYLE}>
                    {visible.map((bp) => {
                      const isSelected = selectedId === bp.id;
                      const isActive = planning_id === bp.id;
                      const affordable =
                        bp.is_cancel || canAfford(bp, undefined);
                      return (
                        <Box key={bp.id}>
                          <Button
                            fluid
                            tooltip={`${bp.name}${bp.from_faction ? ' (faction)' : ''}${
                              affordable ? '' : ' — you lack resources'
                            }`}
                            backgroundColor={
                              isActive
                                ? COLOR_ACTIVE
                                : isSelected
                                  ? COLOR_CARD_SELECTED
                                  : COLOR_CARD
                            }
                            style={{
                              display: 'flex',
                              justifyContent: 'center',
                              borderBottom: `3px solid ${
                                affordable ? 'transparent' : '#8a3a3a'
                              }`,
                            }}
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
                      {searching
                        ? 'Nothing found'
                        : 'No blueprints in this category'}
                    </Box>
                  )}
                </Section>
              </Stack.Item>

              <Stack.Item basis="320px">
                <Stack vertical fill>
                  <Stack.Item grow>
                    <Section fill scrollable title="Selected">
                      {selected ? (
                        <Stack vertical>
                          <Stack.Item>
                            <Stack>
                              <Stack.Item>
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
                              </Stack.Item>
                              <Stack.Item grow ml={1}>
                                <Box fontWeight="bold">
                                  {effectiveMaterial
                                    ? `${effectiveMaterial.name} ${selected.name}`
                                    : selected.name}
                                </Box>
                                <Box color="#aaaaaa" fontSize="12px" mt={0.5}>
                                  {selected.is_multiblock
                                    ? 'Multi-tile'
                                    : 'Single tile'}
                                  {selected.can_rotate ? ' · Rotatable' : ''}
                                  {selected.from_faction
                                    ? ' · Faction tech'
                                    : ''}
                                </Box>
                              </Stack.Item>
                            </Stack>
                          </Stack.Item>
                          <Stack.Item>
                            <Box color="#b0b0b0">{selected.desc || '—'}</Box>
                          </Stack.Item>

                          <Stack.Item>
                            <Box color="#d2d2d2" mb={0.5}>
                              Cost
                              {!!instant_build && (
                                <Box as="span" ml={1} color={COLOR_ADMIN}>
                                  (free — instant build)
                                </Box>
                              )}
                            </Box>
                            <Box>
                              {selected.stuffed && (
                                <CostChip
                                  iconSrc={effectiveMaterial?.iconSrc}
                                  name={effectiveMaterial?.name || 'material'}
                                  need={selected.stuff_cost}
                                  have={stock[effectiveMaterial?.path || ''] || 0}
                                  admin={instant_build}
                                />
                              )}
                              {selected.extra_costs.map((c) => (
                                <CostChip
                                  key={c.path}
                                  iconSrc={c.iconSrc}
                                  name={c.name}
                                  need={c.amount}
                                  have={inventory[c.path] || 0}
                                  admin={instant_build}
                                />
                              ))}
                            </Box>
                            {!selected.stuffed &&
                              !selected.extra_costs.length && (
                                <Box color="#888888">Free</Box>
                              )}
                            <Box color="#888888" fontSize="12px">
                              {instant_build
                                ? 'Completes instantly'
                                : `Time: ${(selected.construction_time / 10).toFixed(1)}s · ${selected.build_steps} steps`}
                            </Box>
                          </Stack.Item>

                          {!!selected.stuffed && (
                            <Stack.Item>
                              <Box color="#d2d2d2" mb={0.5}>
                                Made of
                              </Box>
                              <Box mb={0.5}>
                                {['All', ...allowedCategories].map((c) => (
                                  <Button
                                    key={c}
                                    compact
                                    mr={0.5}
                                    color={
                                      matCategory === c ? 'grey' : 'transparent'
                                    }
                                    onClick={() => setMatCategory(c)}
                                  >
                                    {c}
                                  </Button>
                                ))}
                              </Box>
                              <Box
                                style={{ maxHeight: '190px', overflowY: 'auto' }}
                              >
                                {shownMaterials.map((m) => {
                                  const have = stock[m.path] || 0;
                                  const enough =
                                    instant_build ||
                                    have >= selected.stuff_cost;
                                  return (
                                    <Button
                                      key={m.path}
                                      fluid
                                      mb={0.5}
                                      selected={
                                        effectiveMaterial?.path === m.path
                                      }
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
                                        color={enough ? COLOR_OK : '#888'}
                                      >
                                        ({have})
                                      </Box>
                                    </Button>
                                  );
                                })}
                              </Box>
                            </Stack.Item>
                          )}
                        </Stack>
                      ) : (
                        <Box color="#aaaaaa">
                          Select a blueprint. Double-click to plan it at once.
                        </Box>
                      )}
                      {!has_faction && (
                        <Box color="#888888" fontSize="12px" mt={2}>
                          Join a faction to unlock additional blueprints via
                          research.
                        </Box>
                      )}
                    </Section>
                  </Stack.Item>

                  <Stack.Item>
                    <Section>
                      <Button
                        fluid
                        icon="pencil-alt"
                        color={
                          instant_build
                            ? 'purple'
                            : selectedAffordable
                              ? 'good'
                              : 'average'
                        }
                        disabled={!selected}
                        tooltip={
                          selected && !selectedAffordable
                            ? 'You can plan it, but you do not carry all resources yet.'
                            : undefined
                        }
                        onClick={() => selected && plan(selected)}
                      >
                        {instant_build ? 'Plan (instant)' : 'Plan'}
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
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
}
