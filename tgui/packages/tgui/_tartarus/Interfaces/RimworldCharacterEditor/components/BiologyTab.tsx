import { useState } from 'react';
import { useBackend } from 'tgui/backend';
import {
  Box,
  Button,
  Dropdown,
  Input,
  NumberInput,
  Stack,
} from 'tgui-core/components';
import { classes } from 'tgui-core/react';
import type {
  RimworldCharacterEditorData,
  RwSpeciesDef,
  RwXenogeneDef,
} from '../types';
import {
  conflictingGeneIds,
  formatMetabolic,
  geneById,
  genesFromIds,
  geneValueLabel,
  hungerRate,
  sumGeneStats,
  toPngSrc,
} from '../utils';
import { ColorPick } from './shared';

const XENOGENE_CATEGORIES = [
  'cosmetic',
  'stat',
  'ability',
  'archite',
  'aptitude',
  'mood',
  'movement',
  'temperature',
  'resistance',
  'healing',
  'psychic',
  'hemogen',
  'misc',
];

export function BiologyTab() {
  const [subTab, setSubTab] = useState<'race' | 'xenogenes'>('race');
  const { data } = useBackend<RimworldCharacterEditorData>();
  const hasSlotGenes = (data.xenogeneDefs || []).some(
    (gene) => gene.id === 'ears' || gene.id === 'tail' || gene.id === 'wings',
  );

  return (
    <Stack fill vertical>
      <Stack.Item>
        <div className="RimworldCharacterEditor__subTabs">
          <Button
            selected={subTab === 'race'}
            onClick={() => setSubTab('race')}
          >
            Race
          </Button>
          <Button
            selected={subTab === 'xenogenes'}
            onClick={() => setSubTab('xenogenes')}
          >
            Xenogenes
          </Button>
        </div>
      </Stack.Item>
      {!hasSlotGenes && (
        <Stack.Item>
          <Box color="bad">
            Slot xenogenes are not in this Dream Maker build. Recompile the DME,
            restart the game, then reopen Prepare Colonist. tgui-dev is not
            enough.
          </Box>
        </Stack.Item>
      )}
      <Stack.Item grow minHeight={0}>
        {subTab === 'race' ? <RacePane /> : <XenogenePane />}
      </Stack.Item>
    </Stack>
  );
}

export function GeneStats(props: { genes: RwXenogeneDef[] }) {
  const { complexity, metabolic } = sumGeneStats(props.genes);
  return (
    <div className="RimworldCharacterEditor__geneStats">
      <div className="RimworldCharacterEditor__geneStat">
        <span className="RimworldCharacterEditor__geneStatLabel">
          Complexity
        </span>
        <span>{complexity}</span>
      </div>
      <div className="RimworldCharacterEditor__geneStat">
        <span className="RimworldCharacterEditor__geneStatLabel">
          Metabolic efficiency
        </span>
        <span>
          {formatMetabolic(metabolic)}
          <span className="RimworldCharacterEditor__geneStatMuted">
            {' '}
            Hunger rate x{hungerRate(metabolic)}%
          </span>
        </span>
      </div>
    </div>
  );
}

export function GeneArt(props: { gene: RwXenogeneDef }) {
  const { gene } = props;
  if (gene.iconBgSrc || gene.iconSrc) {
    return (
      <span className="RimworldCharacterEditor__geneArt">
        {!!gene.iconBgSrc && <img src={toPngSrc(gene.iconBgSrc)} alt="" />}
        {!!gene.iconSrc && <img src={toPngSrc(gene.iconSrc)} alt="" />}
      </span>
    );
  }
  if (gene.id !== 'hair') {
    return null;
  }
  return (
    <svg
      className="RimworldCharacterEditor__geneArt"
      viewBox="0 0 32 32"
      aria-hidden
    >
      <ellipse
        cx="16"
        cy="13"
        rx="11"
        ry="9"
        fill="#f4f7fb"
        stroke="#1c2430"
        strokeWidth="1.6"
      />
      <ellipse
        cx="9"
        cy="21"
        rx="4.2"
        ry="8"
        fill="#f4f7fb"
        stroke="#1c2430"
        strokeWidth="1.6"
      />
      <ellipse
        cx="23"
        cy="21"
        rx="4.2"
        ry="8"
        fill="#c5cedb"
        stroke="#1c2430"
        strokeWidth="1.6"
      />
    </svg>
  );
}

export function GeneTile(props: {
  gene: RwXenogeneDef;
  selected?: boolean;
  innate?: boolean;
  disabled?: boolean;
  inheritable?: boolean;
  compact?: boolean;
  onClick?: () => void;
  onConfigure?: () => void;
}) {
  const {
    gene,
    selected,
    innate,
    disabled,
    inheritable,
    compact,
    onClick,
    onConfigure,
  } = props;
  const className = classes([
    'RimworldCharacterEditor__gene',
    compact && 'RimworldCharacterEditor__gene--compact',
    selected && 'RimworldCharacterEditor__gene--selected',
    innate && 'RimworldCharacterEditor__gene--innate',
    disabled && 'RimworldCharacterEditor__gene--disabled',
    inheritable && 'RimworldCharacterEditor__gene--inheritable',
    gene.negative && 'RimworldCharacterEditor__gene--negative',
  ]);
  const body = (
    <>
      <span className="RimworldCharacterEditor__geneFrame">
        <span
          className={classes([
            'RimworldCharacterEditor__geneGlyph',
            gene.negative
              ? 'RimworldCharacterEditor__geneGlyph--negative'
              : 'RimworldCharacterEditor__geneGlyph--positive',
          ])}
        />
        <GeneArt gene={gene} />
      </span>
      {!compact && (
        <span className="RimworldCharacterEditor__geneName">{gene.name}</span>
      )}
    </>
  );
  const onContextMenu = onConfigure
    ? (event: { preventDefault: () => void }) => {
        event.preventDefault();
        onConfigure();
      }
    : undefined;
  if (!onClick || compact) {
    return (
      <span
        title={gene.desc}
        className={className}
        onContextMenu={onContextMenu}
      >
        {body}
      </span>
    );
  }
  return (
    <button
      type="button"
      disabled={disabled}
      title={gene.desc}
      className={className}
      onClick={onClick}
      onContextMenu={onContextMenu}
    >
      {body}
    </button>
  );
}

export function GeneOptionEditor(props: { gene: RwXenogeneDef }) {
  const { act, data } = useBackend<RimworldCharacterEditorData>();
  const { gene } = props;
  const option = gene.option;
  if (!option) {
    return null;
  }
  const raw = data.xenogeneValues?.[gene.id];
  if (option.kind === 'numeric') {
    const value = typeof raw === 'number' ? raw : Number(raw) || 1;
    return (
      <Box mt={1}>
        <Box color="label" mb={0.4}>
          Size
        </Box>
        <NumberInput
          width="100%"
          value={value}
          minValue={option.min ?? 0.8}
          maxValue={option.max ?? 1.5}
          step={option.step ?? 0.01}
          onChange={(next) =>
            act('set_xenogene_option', { id: gene.id, value: next })
          }
        />
      </Box>
    );
  }
  if (option.kind === 'tricolor') {
    const colors = Array.isArray(raw)
      ? raw.map((piece) => String(piece))
      : ['#c0965f', '#c0965f', '#c0965f'];
    return (
      <Box mt={1}>
        <Box color="label" mb={0.4}>
          Colors
        </Box>
        <Stack>
          {[0, 1, 2].map((index) => (
            <Stack.Item key={index}>
              <ColorPick
                color={colors[index] || '#c0965f'}
                onClick={() =>
                  act('pick_xenogene_color', { id: gene.id, index: index + 1 })
                }
              />
            </Stack.Item>
          ))}
        </Stack>
      </Box>
    );
  }
  const choices = option.choices || [];
  const selected = typeof raw === 'string' ? raw : String(raw || '');
  return (
    <Box mt={1}>
      <Box color="label" mb={0.4}>
        Variant
      </Box>
      <Dropdown
        width="100%"
        selected={selected}
        options={choices}
        onSelected={(value) =>
          act('set_xenogene_option', { id: gene.id, value })
        }
      />
    </Box>
  );
}

export function GeneInspector(props: {
  gene?: RwXenogeneDef;
  innate?: boolean;
  equipped?: boolean;
}) {
  const { act, data } = useBackend<RimworldCharacterEditorData>();
  const { gene, innate, equipped } = props;
  if (!gene) {
    return <Box color="label">Select a xenogene to see what it changes.</Box>;
  }
  const effects = gene.effects?.length ? gene.effects : [gene.desc];
  const optionLabel = geneValueLabel(gene, data.xenogeneValues);
  const inheritableIds = data.xenogeneInheritable || [];
  const innateIds = data.innateXenogenes || [];
  const pawnInheritable = inheritableIds.includes(gene.id);
  const innateConflicts = conflictingGeneIds(
    gene,
    innateIds,
    data.xenogeneDefs,
  );
  const blockedByInnate = !innate && !equipped && innateConflicts.length > 0;
  const conflictNames = innateConflicts
    .map((id) => geneById(data.xenogeneDefs, id)?.name || id)
    .join(', ');
  const pointCost = gene.pointCost ?? 0;
  const cannotAfford =
    !innate && !equipped && pointCost > 0 && data.budgetRemaining < pointCost;
  return (
    <div className="RimworldCharacterEditor__geneInspect">
      <Box className="RimworldCharacterEditor__sectionTitle">{gene.name}</Box>
      <Box color="label" mb={0.5}>
        {gene.category}
        {innate ? ' · from race' : ''}
        {(innate || equipped) &&
          (pawnInheritable ? ' · inheritable' : ' · not inheritable')}
      </Box>
      {!innate && (
        <Box
          mb={0.5}
          className={
            pointCost > 0
              ? 'RimworldCharacterEditor__choiceCost--pos'
              : pointCost < 0
                ? 'RimworldCharacterEditor__choiceCost--neg'
                : undefined
          }
        >
          Cost: {pointCost > 0 ? `+${pointCost}` : pointCost}
        </Box>
      )}
      {effects.map((line) => (
        <Box key={line} mb={0.4}>
          {line}
        </Box>
      ))}
      {!!optionLabel && (
        <Box mt={0.6} color="label">
          Current: {optionLabel}
        </Box>
      )}
      {blockedByInnate && (
        <Box mt={0.6} color="bad">
          Incompatible with {conflictNames}.
        </Box>
      )}
      {cannotAfford && (
        <Box mt={0.6} color="bad">
          Not enough budget ({data.budgetRemaining} remaining).
        </Box>
      )}
      <GeneOptionEditor gene={gene} />
      {!innate && (
        <Button
          mt={1}
          fluid
          selected={equipped}
          disabled={blockedByInnate || cannotAfford}
          onClick={() => act('toggle_xenogene', { id: gene.id })}
        >
          {equipped ? 'Remove gene' : 'Add gene'}
        </Button>
      )}
    </div>
  );
}

export function raceTitle(species?: RwSpeciesDef) {
  return species?.label || species?.name || 'Race';
}

export function RacePane() {
  const { act, data } = useBackend<RimworldCharacterEditorData>();
  const [inspectedId, setInspectedId] = useState<string | null>(null);
  const currentSpecies = (data.speciesDefs || []).find(
    (species) => species.path === data.speciesPath,
  );
  const innateIds =
    currentSpecies?.innateXenogenes || data.innateXenogenes || [];
  const innateGenes = genesFromIds(data.xenogeneDefs, innateIds);
  const perks = currentSpecies?.perks || [];
  const inspected =
    geneById(data.xenogeneDefs, inspectedId || '') || innateGenes[0];

  return (
    <Stack fill>
      <Stack.Item basis="220px" className="RimworldCharacterEditor__scrollPane">
        {(data.speciesDefs || []).map((species) => {
          const selected = species.path === data.speciesPath;
          const preview = genesFromIds(
            data.xenogeneDefs,
            species.innateXenogenes || [],
          );
          return (
            <button
              key={species.path}
              type="button"
              className={classes([
                'RimworldCharacterEditor__raceCard',
                selected && 'RimworldCharacterEditor__raceCard--selected',
              ])}
              onClick={() => act('set_species', { value: species.path })}
            >
              <span className="RimworldCharacterEditor__raceCardName">
                {raceTitle(species)}
              </span>
              {!!species.subtitle && (
                <span className="RimworldCharacterEditor__raceCardSub">
                  {species.subtitle}
                </span>
              )}
              <span className="RimworldCharacterEditor__raceCardGenes">
                {preview.map((gene) => (
                  <GeneTile key={gene.id} gene={gene} compact innate />
                ))}
              </span>
            </button>
          );
        })}
      </Stack.Item>
      <Stack.Item grow className="RimworldCharacterEditor__scrollPane">
        <div className="RimworldCharacterEditor__geneView">
          <Box className="RimworldCharacterEditor__geneViewTitle">
            View genes: {raceTitle(currentSpecies)}
          </Box>
          {innateGenes.length ? (
            <div className="RimworldCharacterEditor__geneGrid">
              {innateGenes.map((gene) => (
                <GeneTile
                  key={gene.id}
                  gene={gene}
                  selected={inspected?.id === gene.id}
                  innate
                  onClick={() => setInspectedId(gene.id)}
                  onConfigure={() => setInspectedId(gene.id)}
                />
              ))}
            </div>
          ) : (
            <Box color="label" mb={1}>
              This race has no innate xenogenes.
            </Box>
          )}
          <GeneStats genes={innateGenes} />
          {!!currentSpecies?.desc && (
            <Box mb={1} style={{ whiteSpace: 'pre-wrap' }}>
              {currentSpecies.desc}
            </Box>
          )}
          {!!perks.length && (
            <>
              <Box className="RimworldCharacterEditor__sectionTitle" mt={1}>
                Effects
              </Box>
              {perks.map((perk) => (
                <Box key={`${perk.type}-${perk.name}`} mb={0.6}>
                  <Box>
                    {perk.name}
                    {perk.type ? ` (${perk.type})` : ''}
                  </Box>
                  {!!perk.desc && <Box color="label">{perk.desc}</Box>}
                </Box>
              ))}
            </>
          )}
          {!!currentSpecies?.lore && (
            <>
              <Box className="RimworldCharacterEditor__sectionTitle" mt={1}>
                Lore
              </Box>
              <Box color="label" style={{ whiteSpace: 'pre-wrap' }}>
                {currentSpecies.lore}
              </Box>
            </>
          )}
        </div>
      </Stack.Item>
      <Stack.Item basis="220px" className="RimworldCharacterEditor__scrollPane">
        <GeneInspector gene={inspected} innate equipped />
      </Stack.Item>
    </Stack>
  );
}

export function XenogenePane() {
  const { act, data } = useBackend<RimworldCharacterEditorData>();
  const innateIds = data.innateXenogenes || [];
  const equippedIds = data.xenogenes || [];
  const inheritableIds = data.xenogeneInheritable || [];
  const [inspectedId, setInspectedId] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [category, setCategory] = useState('all');
  const [xenotypeName, setXenotypeName] = useState('');
  const [xenotypeDescription, setXenotypeDescription] = useState('');
  const [xenotypeIconGene, setXenotypeIconGene] = useState(
    data.xenotypeIconGene || '',
  );

  const fromRace = genesFromIds(data.xenogeneDefs, innateIds);
  const equipped = genesFromIds(data.xenogeneDefs, equippedIds).filter(
    (gene) => !innateIds.includes(gene.id),
  );
  const available = data.xenogeneDefs.filter(
    (gene) => !equippedIds.includes(gene.id) && !innateIds.includes(gene.id),
  );
  const needle = search.trim().toLowerCase();
  const filteredAvailable = available.filter((gene) => {
    if (category !== 'all' && gene.category !== category) return false;
    if (!needle) return true;
    return [
      gene.id,
      gene.name,
      gene.desc,
      gene.category,
      ...(gene.effects || []),
    ]
      .filter(Boolean)
      .join(' ')
      .toLowerCase()
      .includes(needle);
  });
  const allActive = [...fromRace, ...equipped];

  const inspected =
    geneById(data.xenogeneDefs, inspectedId || '') ||
    fromRace[0] ||
    equipped[0] ||
    available[0];

  return (
    <Stack fill>
      <Stack.Item grow className="RimworldCharacterEditor__scrollPane">
        <Stack mb={1} align="center" wrap>
          <Stack.Item grow>
            <Box className="RimworldCharacterEditor__sectionTitle">
              Xenogene catalog
            </Box>
          </Stack.Item>
          <Stack.Item>
            <Button
              icon="book-open"
              onClick={() => act('open_xenotype_browser')}
            >
              Browse xenotypes
            </Button>
          </Stack.Item>
        </Stack>
        <Stack mb={0.5} align="center">
          <Stack.Item grow>
            <Input
              fluid
              placeholder="Search xenogenes by name, effect, or category..."
              value={search}
              onChange={setSearch}
            />
          </Stack.Item>
        </Stack>
        <div className="RimworldCharacterEditor__filterChips">
          {['all', ...XENOGENE_CATEGORIES].map((entry) => (
            <Button
              key={entry}
              compact
              selected={category === entry}
              onClick={() => setCategory(entry)}
            >
              {entry === 'all' ? 'All' : entry}
            </Button>
          ))}
        </div>
        <Box className="RimworldCharacterEditor__sectionTitle">From race</Box>
        {fromRace.length ? (
          <div className="RimworldCharacterEditor__geneGrid">
            {fromRace.map((gene) => (
              <GeneTile
                key={gene.id}
                gene={gene}
                selected={inspected?.id === gene.id}
                innate
                inheritable={inheritableIds.includes(gene.id)}
                onClick={() => setInspectedId(gene.id)}
                onConfigure={() => setInspectedId(gene.id)}
              />
            ))}
          </div>
        ) : (
          <Box color="label" mb={1}>
            None
          </Box>
        )}
        <Box className="RimworldCharacterEditor__sectionTitle" mt={1}>
          Equipped
        </Box>
        {equipped.length ? (
          <div className="RimworldCharacterEditor__geneGrid">
            {equipped.map((gene) => (
              <GeneTile
                key={gene.id}
                gene={gene}
                selected={inspected?.id === gene.id}
                inheritable={inheritableIds.includes(gene.id)}
                onClick={() => setInspectedId(gene.id)}
                onConfigure={() => setInspectedId(gene.id)}
              />
            ))}
          </div>
        ) : (
          <Box color="label" mb={1}>
            None
          </Box>
        )}
        <Box className="RimworldCharacterEditor__sectionTitle" mt={1}>
          Available ({filteredAvailable.length})
        </Box>
        {filteredAvailable.length ? (
          <div className="RimworldCharacterEditor__geneGrid">
            {filteredAvailable.map((gene) => {
              const conflicted =
                conflictingGeneIds(gene, innateIds, data.xenogeneDefs).length >
                0;
              const unaffordable =
                (gene.pointCost ?? 0) > 0 &&
                data.budgetRemaining < (gene.pointCost ?? 0);
              return (
                <GeneTile
                  key={gene.id}
                  gene={gene}
                  selected={inspected?.id === gene.id}
                  disabled={conflicted || unaffordable}
                  onClick={() => setInspectedId(gene.id)}
                  onConfigure={() => setInspectedId(gene.id)}
                />
              );
            })}
          </div>
        ) : (
          <Box color="label">
            {available.length
              ? 'No xenogenes match the current search and category.'
              : 'None'}
          </Box>
        )}
        <GeneStats genes={allActive} />
        <Box className="RimworldCharacterEditor__sectionTitle" mt={1}>
          Save current xenotype
        </Box>
        <Input
          fluid
          maxLength={512}
          mt={0.5}
          placeholder="Xenotype description"
          value={xenotypeDescription || data.xenotypeDescription || ''}
          onChange={setXenotypeDescription}
        />
        <Stack mt={0.5} align="center">
          <Stack.Item>
            <Box color="label">Icon gene</Box>
          </Stack.Item>
          <Stack.Item grow>
            <Dropdown
              width="100%"
              selected={xenotypeIconGene || data.xenotypeIconGene || ''}
              options={[
                '',
                ...data.xenogeneDefs
                  .filter((gene) => gene.iconSrc || gene.iconBgSrc)
                  .map((gene) => gene.id),
              ]}
              onSelected={setXenotypeIconGene}
            />
          </Stack.Item>
        </Stack>
        <Stack>
          <Stack.Item grow>
            <Input
              fluid
              maxLength={48}
              placeholder="Xenotype name"
              value={xenotypeName}
              onChange={setXenotypeName}
              onEnter={() => {
                if (!xenotypeName.trim()) return;
                act('save_xenotype', {
                  name: xenotypeName.trim(),
                  description:
                    xenotypeDescription || data.xenotypeDescription || '',
                  iconGene: xenotypeIconGene || data.xenotypeIconGene || '',
                });
                setXenotypeName('');
              }}
            />
          </Stack.Item>
          <Stack.Item>
            <Button
              icon="save"
              disabled={!xenotypeName.trim()}
              onClick={() => {
                if (!xenotypeName.trim()) return;
                act('save_xenotype', {
                  name: xenotypeName.trim(),
                  description:
                    xenotypeDescription || data.xenotypeDescription || '',
                  iconGene: xenotypeIconGene || data.xenotypeIconGene || '',
                });
                setXenotypeName('');
              }}
            >
              Save
            </Button>
          </Stack.Item>
        </Stack>
      </Stack.Item>
      <Stack.Item basis="220px" className="RimworldCharacterEditor__scrollPane">
        <GeneInspector
          gene={inspected}
          innate={!!inspected && innateIds.includes(inspected.id)}
          equipped={!!inspected && equippedIds.includes(inspected.id)}
        />
      </Stack.Item>
    </Stack>
  );
}
