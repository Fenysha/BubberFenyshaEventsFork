import { useState } from 'react';
import { useBackend } from 'tgui/backend';
import { Box, Button, Input, Stack } from 'tgui-core/components';
import type { RimworldCharacterEditorData } from '../types';
import { ChoiceCard } from './shared';

export function PossessionsTab() {
  const { act, data } = useBackend<RimworldCharacterEditorData>();
  const [search, setSearch] = useState('');
  const [category, setCategory] = useState('All');
  const [undoSnapshot, setUndoSnapshot] = useState<string[] | null>(null);
  const items = data.loadoutDefs || [];
  const selectedIds = data.loadout || [];

  const isSelected = (id: string) => selectedIds.includes(id);

  const toggleItem = (id: string) => {
    setUndoSnapshot([...selectedIds]);
    act('toggle_loadout', { id });
  };

  const undoLastChange = () => {
    if (!undoSnapshot) return;
    const before = new Set(undoSnapshot);
    const current = new Set(selectedIds);
    for (const id of new Set([...before, ...current])) {
      if (before.has(id) !== current.has(id)) {
        act('toggle_loadout', { id });
      }
    }
    setUndoSnapshot(null);
  };

  const categoryFor = (item: (typeof items)[number]) => {
    const haystack = `${item.id} ${item.name} ${item.desc || ''}`.toLowerCase();
    if (/weapon|gun|rifle|pistol|sword|knife|melee|ammo|grenade/.test(haystack)) {
      return 'Weapon';
    }
    if (/armor|armour|helmet|vest|shield|plate|uniform|clothing/.test(haystack)) {
      return 'Armor';
    }
    if (/medical|medic|medicine|medkit|medkit|bandage|drug|surgery|health/.test(haystack)) {
      return 'Medical';
    }
    if (/survival|food|water|ration|oxygen|mask|shelter|flare|torch|warmth/.test(haystack)) {
      return 'Survival';
    }
    return 'Utility';
  };

  const categories = ['All', 'Weapon', 'Armor', 'Medical', 'Survival', 'Utility'];

  const selectedItems = items.filter((item) => isSelected(item.id));
  const selectedCost = selectedItems.reduce(
    (sum, item) => sum + (item.cost || 0),
    0,
  );
  const needle = search.trim().toLowerCase();
  const visible = items.filter((item) => {
    if (category !== 'All' && categoryFor(item) !== category) return false;
    if (!needle) return true;
    return `${item.id} ${item.name} ${item.desc || ''}`
      .toLowerCase()
      .includes(needle);
  });
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
              <Stack align="center">
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
                <Stack.Item>
                  <Button
                    icon="rotate-left"
                    disabled={!undoSnapshot}
                    tooltip="Undo the last loadout change"
                    onClick={undoLastChange}
                  >
                    Undo
                  </Button>
                </Stack.Item>
              </Stack>
            </Stack.Item>
          </Stack>
          <Input
            fluid
            mt={0.5}
            placeholder="Search loadout..."
            value={search}
            onChange={setSearch}
          />
          <div className="RimworldCharacterEditor__filterChips">
            {categories.map((entry) => (
              <Button
                key={entry}
                compact
                selected={category === entry}
                onClick={() => setCategory(entry)}
              >
                {entry}
              </Button>
            ))}
          </div>
        </Stack.Item>
        <Stack.Item>
          <Box className="RimworldCharacterEditor__sectionTitle" mt={0.5}>
            Chosen items
          </Box>
          {selectedItems.length ? (
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
          ) : (
            <Box color="label">No items selected.</Box>
          )}
        </Stack.Item>
        <Stack.Item grow minHeight={0}>
          <div className="RimworldCharacterEditor__loadoutCatalogPane">
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
                    ? 'No loadout items match the search and category.'
                    : 'No loadout items defined on the server.'}
                </Box>
              )}
            </div>
          </div>
        </Stack.Item>
      </Stack>
    </div>
  );
}
