import { useState } from 'react';
import { useBackend } from 'tgui/backend';
import { Box, Button, Input, Stack } from 'tgui-core/components';
import type { RimworldCharacterEditorData } from '../types';
import { ChoiceCard } from './shared';

export function PossessionsTab() {
  const { act, data } = useBackend<RimworldCharacterEditorData>();
  const [search, setSearch] = useState('');
  const items = data.loadoutDefs || [];

  const isSelected = (id: string) => data.loadout.includes(id);

  const toggleItem = (id: string) => {
    act('toggle_loadout', { id });
  };

  const selectedItems = items.filter((item) => isSelected(item.id));
  const selectedCost = selectedItems.reduce(
    (sum, item) => sum + (item.cost || 0),
    0,
  );
  const needle = search.trim().toLowerCase();
  const visible = needle
    ? items.filter(
        (item) =>
          item.name.toLowerCase().includes(needle) ||
          (item.desc || '').toLowerCase().includes(needle),
      )
    : items;
  const sorted = [...visible].sort((a, b) => {
    const aSel = isSelected(a.id) ? 0 : 1;
    const bSel = isSelected(b.id) ? 0 : 1;
    if (aSel !== bSel) return aSel - bSel;
    return (a.name || '').localeCompare(b.name || '');
  });

  return (
    <div className="RimworldCharacterEditor__loadoutBoard">
      <Stack fill vertical>
        <Stack.Item>
          <Stack align="center">
            <Stack.Item grow>
              <Box className="RimworldCharacterEditor__sectionTitle">
                Loadout
              </Box>
            </Stack.Item>
            <Stack.Item>
              <Box
                color={
                  selectedCost > 0
                    ? 'average'
                    : selectedItems.length
                      ? 'good'
                      : 'label'
                }
              >
                {selectedItems.length} items · {selectedCost} pts
              </Box>
            </Stack.Item>
          </Stack>
          <Input
            fluid
            mt={0.5}
            placeholder="Search loadout..."
            value={search}
            onChange={setSearch}
          />
        </Stack.Item>
        {selectedItems.length > 0 && (
          <Stack.Item>
            <Box className="RimworldCharacterEditor__sectionTitle" mt={0.5}>
              Equipped
            </Box>
            <div className="RimworldCharacterEditor__loadoutSelected">
              {selectedItems.map((item) => (
                <Button
                  key={`sel-${item.id}`}
                  compact
                  icon="times"
                  tooltip={`Remove (${item.cost} pts)`}
                  onClick={() => toggleItem(item.id)}
                >
                  {item.name}
                  <span className="RimworldCharacterEditor__choiceCost--pos">
                    {' '}
                    +{item.cost}
                  </span>
                </Button>
              ))}
            </div>
          </Stack.Item>
        )}
        <Stack.Item grow minHeight={0}>
          <div className="RimworldCharacterEditor__loadoutGrid">
            {sorted.map((item) => {
              const selected = isSelected(item.id);
              const cannotAfford =
                !selected &&
                (item.cost || 0) > 0 &&
                data.budgetRemaining < (item.cost || 0);
              return (
                <ChoiceCard
                  key={item.id}
                  name={item.name}
                  desc={item.desc}
                  cost={item.cost}
                  positive
                  selected={selected}
                  disabled={cannotAfford}
                  onClick={() => {
                    if (cannotAfford) return;
                    toggleItem(item.id);
                  }}
                />
              );
            })}
            {!sorted.length && (
              <Box color="label" p={1}>
                {items.length
                  ? 'No loadout items match the search.'
                  : 'No loadout items defined on the server.'}
              </Box>
            )}
          </div>
        </Stack.Item>
      </Stack>
    </div>
  );
}
