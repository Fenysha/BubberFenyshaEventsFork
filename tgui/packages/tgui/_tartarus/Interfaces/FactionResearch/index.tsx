import { useState } from 'react';
import { useBackend } from 'tgui/backend';
import { Window } from 'tgui/layouts';
import {
  Box,
  Dropdown,
  Icon,
  Input,
  Section,
  Stack,
  Tabs,
} from 'tgui-core/components';

import { TECH_ERAS } from './constants';
import { DetailsPanel } from './DetailsPanel';
import { QueueBar } from './QueueBar';
import { TreeView } from './TreeView';
import type { NodeEntry, ResearchData } from './types';

export const FactionResearch = () => {
  const { act, data } = useBackend<ResearchData>();
  const {
    nodes = [],
    researched = [],
    current,
    progress = {},
    queue = [],
    can_manage,
    bench_ready,
    bench_text,
    is_admin = false,
    admin_view = false,
    factions = [],
    current_faction_id = null,
    current_faction_name = null,
    current_faction_color = null,
  } = data;

  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [eraFilter, setEraFilter] = useState<string | null>(null);

  const byId = new Map(nodes.map((n) => [n.id, n]));
  const researchedSet = new Set(researched);
  const queueSet = new Set(queue);

  const isVisible = (node: NodeEntry) => {
    // Admins see every non-disabled node
    if (is_admin && admin_view) {
      if (node.flags.includes('disabled')) return false;
      return true;
    }
    if (node.flags.includes('disabled')) return false;
    if (researchedSet.has(node.id)) return true;
    if (!node.flags.includes('hidden')) return true;
    return node.prereqs.some((p) => researchedSet.has(p));
  };

  const searchLower = search.trim().toLowerCase();

  const filteredNodes = nodes.filter((n) => {
    if (!isVisible(n)) return false;
    if (eraFilter && n.era !== eraFilter) return false;
    if (
      searchLower &&
      !n.name.toLowerCase().includes(searchLower) &&
      !n.desc.toLowerCase().includes(searchLower)
    ) {
      return false;
    }
    return true;
  });

  const selected = selectedId ? byId.get(selectedId) : undefined;

  // Effective manage rights: normal researchers OR admin viewing a faction
  const effectiveManage = !!can_manage || (is_admin && admin_view);

  const factionOptions = factions.map((f) => ({
    value: f.id,
    displayText: `${f.name}${
      typeof f.researched_count === 'number'
        ? ` (${f.researched_count})`
        : ''
    }`,
  }));

  const windowTitle = admin_view
    ? `Research — Admin${current_faction_name ? `: ${current_faction_name}` : ''}`
    : 'Faction Research';

  return (
    <Window title={windowTitle} width={1320} height={860}>
      <Window.Content>
        <Stack fill vertical>
          {is_admin && (
            <Stack.Item>
              <Section
                fitted
                style={{
                  background: admin_view
                    ? 'rgba(155, 89, 182, 0.12)'
                    : 'rgba(0,0,0,0.2)',
                  borderBottom: admin_view
                    ? '1px solid rgba(155, 89, 182, 0.35)'
                    : undefined,
                }}
              >
                <Stack align="center" p={1}>
                  <Stack.Item>
                    <Icon
                      name="shield-halved"
                      color={admin_view ? 'purple' : 'label'}
                    />
                  </Stack.Item>
                  <Stack.Item grow>
                    <Box bold color={admin_view ? 'purple' : undefined}>
                      Admin research browser
                    </Box>
                    <Box color="label" fontSize="11px">
                      View any faction techweb and force-unlock technologies.
                    </Box>
                  </Stack.Item>
                  <Stack.Item>
                    <Box color="label" mr={1} inline>
                      Faction:
                    </Box>
                    <Dropdown
                      width="260px"
                      options={
                        factionOptions.length
                          ? factionOptions
                          : [{ value: '', displayText: 'No factions' }]
                      }
                      selected={current_faction_id || ''}
                      onSelected={(value) => {
                        if (value) {
                          act('admin_select_faction', { id: value });
                        }
                      }}
                      disabled={!factionOptions.length}
                    />
                  </Stack.Item>
                  {admin_view && (
                    <Stack.Item ml={1}>
                      <Box
                        inline
                        style={{
                          padding: '2px 8px',
                          borderRadius: '3px',
                          background: 'rgba(155, 89, 182, 0.3)',
                          color: '#d2a8ff',
                          fontSize: '11px',
                          fontWeight: 'bold',
                        }}
                      >
                        ADMIN VIEW
                      </Box>
                    </Stack.Item>
                  )}
                </Stack>
              </Section>
            </Stack.Item>
          )}

          <Stack.Item>
            <QueueBar
              current={current}
              queue={queue}
              progress={progress}
              byId={byId}
              canManage={effectiveManage}
              benchReady={!!bench_ready}
              benchText={bench_text || ''}
              act={act}
              onSelect={setSelectedId}
              factionName={current_faction_name}
              factionColor={current_faction_color}
            />
          </Stack.Item>

          <Stack.Item>
            <Stack>
              <Stack.Item grow>
                <Input
                  placeholder="Search technologies..."
                  value={search}
                  onChange={setSearch}
                  expensive
                />
              </Stack.Item>
              <Stack.Item>
                <Tabs>
                  <Tabs.Tab
                    selected={!eraFilter}
                    onClick={() => setEraFilter(null)}
                  >
                    All
                  </Tabs.Tab>
                  {TECH_ERAS.map((era) => (
                    <Tabs.Tab
                      key={era.id}
                      selected={eraFilter === era.id}
                      onClick={() => setEraFilter(era.id)}
                    >
                      {era.label}
                    </Tabs.Tab>
                  ))}
                </Tabs>
              </Stack.Item>
            </Stack>
          </Stack.Item>

          <Stack.Item grow>
            <Stack fill>
              <Stack.Item grow>
                <TreeView
                  nodes={filteredNodes}
                  researched={researchedSet}
                  current={current}
                  queue={queueSet}
                  selectedId={selectedId}
                  progress={progress}
                  onSelect={setSelectedId}
                  adminView={!!admin_view}
                />
              </Stack.Item>
              <Stack.Item width="380px">
                <DetailsPanel
                  node={selected}
                  nodes={nodes}
                  researched={researchedSet}
                  current={current}
                  queue={queueSet}
                  progress={progress}
                  canManage={effectiveManage}
                  isAdmin={!!is_admin && !!admin_view}
                  act={act}
                  onSelect={setSelectedId}
                />
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
