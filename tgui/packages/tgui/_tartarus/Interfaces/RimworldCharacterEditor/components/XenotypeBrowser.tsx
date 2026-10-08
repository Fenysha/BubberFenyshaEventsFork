import { useMemo, useState } from 'react';
import { useBackend } from 'tgui/backend';
import { Box, Button, Dropdown, Input, Stack } from 'tgui-core/components';
import type {
  RwBrowserGene,
  RwBrowserXenotype,
  XenotypeBrowserData,
} from '../types';
import { toPngSrc } from '../utils';

type BrowserProps = {
  onClose?: () => void;
};

const categoryName = (category: string) =>
  category ? `${category[0].toUpperCase()}${category.slice(1)}` : 'Other';

function GeneIcon({ gene }: { gene: RwBrowserGene }) {
  if (!gene.iconSrc && !gene.iconBgSrc) {
    return (
      <span className="RimworldCharacterEditor__xenotypeGeneFallback">✦</span>
    );
  }
  return (
    <span className="RimworldCharacterEditor__xenotypeGeneIcon">
      {!!gene.iconBgSrc && <img src={toPngSrc(gene.iconBgSrc)} alt="" />}
      {!!gene.iconSrc && <img src={toPngSrc(gene.iconSrc)} alt="" />}
    </span>
  );
}

export function XenotypeBrowser(props: BrowserProps) {
  const { act, data } = useBackend<XenotypeBrowserData>();
  const [search, setSearch] = useState('');
  const [selectedId, setSelectedId] = useState('');
  const [newName, setNewName] = useState('');
  const [newDescription, setNewDescription] = useState('');
  const [newIconGene, setNewIconGene] = useState('');
  const xenotypes = data.xenotypes || [];
  const genes = data.xenogeneDefs || [];
  const pinnedIds = data.pinnedGenes || [];
  const isAdmin = !!data.canManage;
  const byId = useMemo(
    () => new Map(genes.map((gene) => [gene.id, gene])),
    [genes],
  );
  const needle = search.trim().toLowerCase();
  const visible = [...xenotypes]
    .filter(
      (entry) =>
        !needle ||
        [
          entry.name,
          entry.description,
          entry.speciesName,
          entry.species,
          ...entry.genes,
        ]
          .join(' ')
          .toLowerCase()
          .includes(needle),
    )
    .sort(
      (a, b) =>
        Number(b.favorite) - Number(a.favorite) ||
        Number(b.pinned) - Number(a.pinned) ||
        a.name.localeCompare(b.name),
    );
  const selected =
    visible.find((entry) => entry.id === selectedId) || visible[0];
  const pinnedXenotypes = visible.filter((entry) => entry.pinned);
  const favoriteXenotypes = visible.filter(
    (entry) => entry.favorite && !entry.pinned,
  );
  const otherXenotypes = visible.filter(
    (entry) => !entry.favorite && !entry.pinned,
  );
  const selectedGenes = (selected?.geneIds || [])
    .map((id) => byId.get(id))
    .filter((gene): gene is RwBrowserGene => !!gene);
  const grouped = new Map<string, RwBrowserGene[]>();
  for (const gene of selectedGenes) {
    const group = grouped.get(gene.category) || [];
    group.push(gene);
    grouped.set(gene.category, group);
  }
  const pinned = pinnedIds
    .map((id) => byId.get(id))
    .filter((gene): gene is RwBrowserGene => !!gene);

  const saveCurrent = () => {
    if (!newName.trim()) return;
    act('save_xenotype', {
      name: newName.trim(),
      description: newDescription.trim(),
      iconGene:
        newIconGene ||
        data.currentGeneIds?.find(
          (id) => byId.get(id)?.iconSrc || byId.get(id)?.iconBgSrc,
        ) ||
        '',
    });
    setNewName('');
    setNewDescription('');
  };

  const renderXenotype = (entry: RwBrowserXenotype) => (
    <div
      key={entry.id}
      className={`RimworldCharacterEditor__xenotypeCard${selected?.id === entry.id ? ' RimworldCharacterEditor__xenotypeCard--selected' : ''}`}
      onClick={() => setSelectedId(entry.id)}
    >
      <span className="RimworldCharacterEditor__xenotypeCardIcon">
        {!!entry.iconBgSrc && <img src={toPngSrc(entry.iconBgSrc)} alt="" />}
        {!!entry.iconSrc && <img src={toPngSrc(entry.iconSrc)} alt="" />}
      </span>
      <span className="RimworldCharacterEditor__xenotypeInfo">
        <span className="RimworldCharacterEditor__xenotypeName">
          {entry.name}
          {entry.builtin ? ' · BASELINE' : ''}
        </span>
        <span className="RimworldCharacterEditor__xenotypeMeta">
          {entry.speciesName || entry.species} · {entry.genes.length} genes
          {entry.pinned ? ' · pinned' : ''}
        </span>
        {!!entry.description && (
          <span className="RimworldCharacterEditor__xenotypeGenes">
            {entry.description}
          </span>
        )}
      </span>
      <span
        className="RimworldCharacterEditor__xenotypeActions"
        onClick={(event) => event.stopPropagation()}
      >
        {isAdmin && (
          <Button
            compact
            icon={entry.favorite ? 'star' : 'star-o'}
            selected={entry.favorite}
            tooltip={entry.favorite ? 'Unfavorite' : 'Mark favorite'}
            onClick={() => act('toggle_xenotype_favorite', { id: entry.id })}
          />
        )}
        {isAdmin && !entry.builtin && (
          <Button
            compact
            icon="thumbtack"
            selected={entry.pinned}
            tooltip={entry.pinned ? 'Unpin xenotype' : 'Pin xenotype'}
            onClick={() => act('toggle_xenotype_pin', { id: entry.id })}
          />
        )}
        <Button
          compact
          icon="check"
          tooltip="Apply xenotype"
          onClick={() => act('apply_xenotype', { id: entry.id })}
        />
        {isAdmin && !entry.builtin && (
          <Button.Confirm
            compact
            icon="trash"
            tooltip="Delete xenotype"
            onClick={() => act('delete_xenotype', { id: entry.id })}
          />
        )}
      </span>
    </div>
  );

  return (
    <Stack fill vertical className="RimworldCharacterEditor__xenotypeBrowser">
      <Stack.Item>
        <Stack align="center">
          <Stack.Item grow>
            <Box className="RimworldCharacterEditor__sectionTitle">
              {data.isAdminManager ? 'Xenotype manager' : 'Xenotype browser'}
            </Box>
          </Stack.Item>
          {!!props.onClose && (
            <Stack.Item>
              <Button
                icon="times"
                tooltip="Close browser"
                onClick={props.onClose}
              />
            </Stack.Item>
          )}
        </Stack>
        <Input
          fluid
          placeholder="Search by xenotype, race, description, or gene..."
          value={search}
          onChange={setSearch}
        />
        {isAdmin && data.isAdminManager && (
          <Stack mt={0.5} vertical>
            <Stack align="center">
              <Stack.Item grow>
                <Input
                  fluid
                  maxLength={48}
                  placeholder={`Save ${data.currentXenotypeName || 'current editor xenotype'} as...`}
                  value={newName}
                  onChange={setNewName}
                />
              </Stack.Item>
              <Stack.Item>
                <Button
                  icon="plus"
                  disabled={!newName.trim()}
                  onClick={saveCurrent}
                >
                  Add
                </Button>
              </Stack.Item>
            </Stack>
            <Stack align="center">
              <Stack.Item grow>
                <Input
                  fluid
                  maxLength={512}
                  placeholder="Description"
                  value={newDescription}
                  onChange={setNewDescription}
                />
              </Stack.Item>
              <Stack.Item basis="220px">
                <Dropdown
                  width="100%"
                  selected={newIconGene || 'Choose icon gene'}
                  options={[
                    'Choose icon gene',
                    ...(data.currentGeneIds || []).filter(
                      (id) => byId.get(id)?.iconSrc || byId.get(id)?.iconBgSrc,
                    ),
                  ]}
                  onSelected={(value) =>
                    setNewIconGene(value === 'Choose icon gene' ? '' : value)
                  }
                />
              </Stack.Item>
            </Stack>
          </Stack>
        )}
      </Stack.Item>
      {!!pinned.length && (
        <Stack.Item className="RimworldCharacterEditor__xenotypePinned">
          <Box className="RimworldCharacterEditor__sectionTitle">
            Pinned genes · visible to everyone
          </Box>
          <div className="RimworldCharacterEditor__xenotypeGeneGrid">
            {pinned.map((gene) => (
              <div
                className="RimworldCharacterEditor__xenotypeGeneCard"
                key={gene.id}
                title={gene.desc}
              >
                <GeneIcon gene={gene} />
                <span>{gene.name}</span>
                {isAdmin && (
                  <Button
                    compact
                    icon="thumbtack"
                    tooltip="Unpin gene for all players"
                    onClick={() => act('toggle_gene_pin', { id: gene.id })}
                  />
                )}
              </div>
            ))}
          </div>
        </Stack.Item>
      )}
      <Stack.Item
        grow
        minHeight={0}
        className="RimworldCharacterEditor__xenotypeBrowserTop"
      >
        <div className="RimworldCharacterEditor__xenotypeList">
          {!!pinnedXenotypes.length && (
            <>
              <Box className="RimworldCharacterEditor__sectionTitle">
                Pinned xenotypes
              </Box>
              {pinnedXenotypes.map(renderXenotype)}
            </>
          )}
          {!!favoriteXenotypes.length && (
            <>
              <Box className="RimworldCharacterEditor__sectionTitle" mt={1}>
                Favorites
              </Box>
              {favoriteXenotypes.map(renderXenotype)}
            </>
          )}
          {!!otherXenotypes.length && (
            <>
              <Box className="RimworldCharacterEditor__sectionTitle" mt={1}>
                All xenotypes
              </Box>
              {otherXenotypes.map(renderXenotype)}
            </>
          )}
          {!visible.length && (
            <Box color="label" p={1}>
              {xenotypes.length
                ? 'No xenotypes match this search.'
                : 'No saved xenotypes yet.'}
            </Box>
          )}
        </div>
      </Stack.Item>
      <Stack.Item className="RimworldCharacterEditor__xenotypeDetail">
        {selected ? (
          <>
            <Stack align="center">
              <Stack.Item grow>
                <Box className="RimworldCharacterEditor__sectionTitle">
                  {selected.name} · {selected.speciesName || selected.species}
                </Box>
                <Box color="label">
                  {selected.description || 'No description.'}
                </Box>
              </Stack.Item>
            </Stack>
            <div className="RimworldCharacterEditor__xenotypeDetailGrid">
              {[...grouped.entries()].map(([category, categoryGenes]) => (
                <section
                  className="RimworldCharacterEditor__xenotypeCategory"
                  key={category}
                >
                  <Box className="RimworldCharacterEditor__sectionTitle">
                    {categoryName(category)}
                  </Box>
                  {categoryGenes.map((gene) => (
                    <div
                      className="RimworldCharacterEditor__xenotypeGeneCard"
                      key={gene.id}
                      title={gene.desc}
                    >
                      <GeneIcon gene={gene} />
                      <span>{gene.name}</span>
                      {isAdmin && (
                        <Button
                          compact
                          icon="thumbtack"
                          selected={pinnedIds.includes(gene.id)}
                          tooltip={
                            pinnedIds.includes(gene.id)
                              ? 'Unpin for all players'
                              : 'Pin for all players'
                          }
                          onClick={() =>
                            act('toggle_gene_pin', { id: gene.id })
                          }
                        />
                      )}
                    </div>
                  ))}
                </section>
              ))}
              {!selectedGenes.length && (
                <Box color="label">This xenotype has no active genes.</Box>
              )}
            </div>
          </>
        ) : (
          <Box color="label">Select a xenotype to see its gene details.</Box>
        )}
      </Stack.Item>
    </Stack>
  );
}
