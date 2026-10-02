import { useState } from 'react';
import { useBackend } from 'tgui/backend';
import { Window } from 'tgui/layouts';
import { Input, Stack, Tabs } from 'tgui-core/components';

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
  } = data;

  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [eraFilter, setEraFilter] = useState<string | null>(null);

  const byId = new Map(nodes.map((n) => [n.id, n]));
  const researchedSet = new Set(researched);
  const queueSet = new Set(queue);

  const isVisible = (node: NodeEntry) => {
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

  return (
    <Window title="Faction Research" width={1280} height={820}>
      <Window.Content>
        <Stack fill vertical>
          <Stack.Item>
            <QueueBar
              current={current}
              queue={queue}
              progress={progress}
              byId={byId}
              canManage={!!can_manage}
              benchReady={!!bench_ready}
              benchText={bench_text || ''}
              act={act}
              onSelect={setSelectedId}
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
                  onSelect={setSelectedId}
                />
              </Stack.Item>
              <Stack.Item width="360px">
                <DetailsPanel
                  node={selected}
                  nodes={nodes}
                  researched={researchedSet}
                  current={current}
                  queue={queueSet}
                  progress={progress}
                  canManage={!!can_manage}
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
