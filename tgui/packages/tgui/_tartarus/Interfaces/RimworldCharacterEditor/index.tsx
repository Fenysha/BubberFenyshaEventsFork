import { memo, type ReactNode, useEffect, useState } from 'react';
import { resolveAsset } from 'tgui/assets';
import { useBackend } from 'tgui/backend';
import {
  Box,
  Button,
  ByondUi,
  ColorBox,
  Dropdown,
  Floating,
  Input,
  NumberInput,
  ProgressBar,
  Section,
  Slider,
  Stack,
  TextArea,
} from 'tgui-core/components';
import { fetchRetry } from 'tgui-core/http';
import { classes } from 'tgui-core/react';
import { Window } from '../../../layouts';
import '../../Styles/RimworldCharacterEditor.scss';
import type {
  RimworldCharacterEditorData,
  RwClothingChooser,
  RwSkillDef,
  RwSkillRow,
  RwSpeciesDef,
  RwXenogeneDef,
} from './types';

type TabId = 'biology' | 'features' | 'persona' | 'possessions' | 'ideology';

const TABS: { id: TabId; label: string }[] = [
  { id: 'persona', label: 'Persona' },
  { id: 'features', label: 'Features' },
  { id: 'biology', label: 'Biology' },
  { id: 'possessions', label: 'Possessions' },
  { id: 'ideology', label: 'Ideology' },
];

const PASSION_MARK = ['○', '◐', '●'];

const CLOTHING_DEFAULTS: Record<string, string> = {
  hairstyle: 'Bald',
  facial: 'Shaved',
  underwear: 'Nude',
  undershirt: 'Nude',
  bra: 'Nude',
  socks: 'Nude',
};

function asStringMap(value: unknown): Record<string, string> | undefined {
  if (!value || typeof value !== 'object') {
    return undefined;
  }
  const result: Record<string, string> = {};
  if (Array.isArray(value)) {
    for (const entry of value) {
      if (Array.isArray(entry) && entry[0] && entry[1]) {
        result[String(entry[0])] = String(entry[1]);
      }
    }
  } else {
    for (const [key, mapped] of Object.entries(
      value as Record<string, unknown>,
    )) {
      if (typeof mapped === 'string' && mapped.length) {
        result[key] = mapped;
      }
    }
  }
  return Object.keys(result).length ? result : undefined;
}

const PREF_JSON_KEY: Record<string, string> = {
  hair: 'hairstyle_name',
  facial: 'facial_style_name',
  underwear: 'underwear',
  undershirt: 'undershirt',
  bra: 'bra',
  socks: 'socks',
};

function usePrefCatalog() {
  const [icons, setIcons] = useState<Record<string, Record<string, string>>>(
    {},
  );
  const [choices, setChoices] = useState<Record<string, string[]>>({});

  useEffect(() => {
    fetchRetry(resolveAsset('preferences.json'))
      .then((response) => response.json())
      .then((raw) => {
        const json = raw as Record<
          string,
          { icons?: unknown; choices?: unknown }
        >;
        const nextIcons: Record<string, Record<string, string>> = {};
        const nextChoices: Record<string, string[]> = {};
        for (const [thumbsKey, jsonKey] of Object.entries(PREF_JSON_KEY)) {
          const iconsMap = asStringMap(json[jsonKey]?.icons);
          if (iconsMap) {
            nextIcons[thumbsKey] = iconsMap;
          }
          const names = json[jsonKey]?.choices;
          if (Array.isArray(names)) {
            nextChoices[thumbsKey] = names.filter(
              (name): name is string => typeof name === 'string' && !!name,
            );
          }
        }
        setIcons(nextIcons);
        setChoices(nextChoices);
      })
      .catch(() => {});
  }, []);

  return { icons, choices };
}

function isPortraitPng(value: unknown): value is string {
  return (
    typeof value === 'string' &&
    value.length > 32 &&
    value !== 'error' &&
    !value.startsWith('{')
  );
}

function SlotPortrait(props: { png: string; alt: string }) {
  const [failed, setFailed] = useState(false);
  if (failed) {
    return null;
  }
  return (
    <img
      src={`data:image/png;base64,${props.png}`}
      alt=""
      onError={() => setFailed(true)}
    />
  );
}

export const RimworldCharacterEditor = () => {
  const { act, data } = useBackend<RimworldCharacterEditorData>();
  const [tab, setTab] = useState<TabId>('persona');
  const prefCatalog = usePrefCatalog();

  return (
    <Window title="Prepare Colonist" width={1320} height={760} theme="tartarus">
      <Window.Content className="RimworldCharacterEditor" altDrag={false}>
        <Stack fill vertical>
          <Stack.Item className="RimworldCharacterEditor__tabBar">
            {TABS.map((entry) => (
              <Button
                key={entry.id}
                selected={tab === entry.id}
                onClick={() => setTab(entry.id)}
              >
                {entry.label}
              </Button>
            ))}
          </Stack.Item>
          <Stack.Item grow className="RimworldCharacterEditor__main">
            <Stack fill>
              <Stack.Item className="RimworldCharacterEditor__colony">
                <ColonyList />
              </Stack.Item>
              <Stack.Item className="RimworldCharacterEditor__preview">
                <PawnIdentity prefCatalog={prefCatalog} />
              </Stack.Item>
              <Stack.Item grow className="RimworldCharacterEditor__tabBody">
                {tab === 'biology' && <BiologyTab />}
                {tab === 'persona' && <PersonaTab />}
                {tab === 'features' && <FeaturesTab />}
                {tab === 'possessions' && <PossessionsTab />}
                {tab === 'ideology' && (
                  <Box color="label" p={2}>
                    Ideology is not implemented yet.
                  </Box>
                )}
              </Stack.Item>
            </Stack>
          </Stack.Item>
          <Stack.Item className="RimworldCharacterEditor__budget">
            <Stack align="center">
              <Stack.Item>
                <Box className="RimworldCharacterEditor__sectionTitle">
                  Budget
                </Box>
              </Stack.Item>
              <Stack.Item grow>
                <ProgressBar
                  value={data.budgetRemaining}
                  maxValue={data.budgetMax}
                >
                  {data.budgetRemaining} / {data.budgetMax}
                </ProgressBar>
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

function splitColonistName(profile: {
  firstName?: string;
  lastName?: string;
  name?: string;
}) {
  if (profile.firstName || profile.lastName) {
    return {
      first: profile.firstName || '',
      last: profile.lastName || '',
    };
  }
  const parts = (profile.name || '').trim().split(/\s+/).filter(Boolean);
  if (parts.length <= 1) {
    return { first: parts[0] || '', last: '' };
  }
  return {
    first: parts.slice(0, -1).join(' '),
    last: parts[parts.length - 1] || '',
  };
}

function slotDisplayName(profile: {
  firstName?: string;
  lastName?: string;
  name: string;
}) {
  const { first, last } = splitColonistName(profile);
  return [first, last].filter(Boolean).join(' ') || profile.name;
}

function ColonyList() {
  const { act, data } = useBackend<RimworldCharacterEditorData>();
  return (
    <Section fill title="Colony" scrollable>
      {(data.profiles || []).map((profile) => (
        <div
          key={profile.slot}
          className={classes([
            'RimworldCharacterEditor__slot',
            profile.slot === data.activeSlot &&
              'RimworldCharacterEditor__slot--selected',
            profile.empty && 'RimworldCharacterEditor__slot--empty',
          ])}
          onClick={() => act('change_slot', { slot: profile.slot })}
        >
          <div className="RimworldCharacterEditor__slotMeta">
            <div className="RimworldCharacterEditor__slotName">
              {slotDisplayName(profile)}
            </div>
            <div
              className={classes([
                'RimworldCharacterEditor__slotNick',
                !profile.nickname &&
                  'RimworldCharacterEditor__slotNick--placeholder',
              ])}
            >
              {profile.nickname ||
                splitColonistName(profile).last ||
                (profile.empty ? '' : ' ')}
            </div>
          </div>
          <div className="RimworldCharacterEditor__slotPortrait">
            {isPortraitPng(profile.portrait) && (
              <SlotPortrait png={profile.portrait} alt={profile.name} />
            )}
          </div>
        </div>
      ))}
    </Section>
  );
}

const PawnMap = memo(function PawnMap(props: { id: string }) {
  return (
    <ByondUi
      className="RimworldCharacterEditor__pawnMap"
      width="160px"
      height="240px"
      params={{
        id: props.id,
        type: 'map',
        'background-color': 'none',
      }}
    />
  );
});

const DEFAULT_CLOTHING: RwClothingChooser[] = [
  { id: 'hairstyle', name: 'Hairstyle', thumbs: 'hair', hasColor: true },
  { id: 'facial', name: 'Facial hair', thumbs: 'facial', hasColor: true },
  { id: 'bra', name: 'Bra', thumbs: 'bra', hasColor: true },
  {
    id: 'undershirt',
    name: 'Undershirt',
    thumbs: 'undershirt',
    hasColor: true,
  },
  { id: 'underwear', name: 'Underwear', thumbs: 'underwear', hasColor: true },
  { id: 'socks', name: 'Socks', thumbs: 'socks', hasColor: true },
];

function mergeChoosers(fromServer?: RwClothingChooser[]) {
  const byId = new Map(
    DEFAULT_CLOTHING.map((chooser) => [chooser.id, chooser]),
  );
  for (const chooser of fromServer || []) {
    byId.set(chooser.id, { ...byId.get(chooser.id), ...chooser });
  }
  const ids = DEFAULT_CLOTHING.map((chooser) => chooser.id);
  for (const chooser of fromServer || []) {
    if (!ids.includes(chooser.id)) {
      ids.push(chooser.id);
    }
  }
  return ids
    .filter((id) => id !== 'backpack' && id !== 'jumpsuit')
    .map((id) => byId.get(id)!);
}

function clothingIconsFor(
  data: RimworldCharacterEditorData,
  thumbsKey: string,
  prefIcons: Record<string, Record<string, string>>,
) {
  return (
    asStringMap(data.clothingIcons?.[thumbsKey]) ||
    prefIcons[thumbsKey] ||
    (thumbsKey === 'hair' ? asStringMap(data.hairIcons) : undefined) ||
    (thumbsKey === 'underwear' ? asStringMap(data.underwearIcons) : undefined)
  );
}

function selectedClothing(data: RimworldCharacterEditorData, id: string) {
  return (
    data.clothing?.[id] ||
    (typeof (data as Record<string, unknown>)[id] === 'string'
      ? ((data as Record<string, unknown>)[id] as string)
      : undefined) ||
    CLOTHING_DEFAULTS[id] ||
    ''
  );
}

function selectedClothingColor(data: RimworldCharacterEditorData, id: string) {
  return (
    data.clothingColors?.[id] ||
    (id === 'hairstyle' ? data.hairColor : undefined) ||
    (id === 'facial' ? data.facialHairColor : undefined) ||
    (id === 'underwear' ? data.underwearColor : undefined) ||
    (id === 'undershirt' ? data.undershirtColor : undefined) ||
    (id === 'bra' ? data.braColor : undefined) ||
    (id === 'socks' ? data.socksColor : undefined)
  );
}

const GENDER_OPTIONS = [
  { value: 'male', icon: 'mars', label: 'He/Him' },
  { value: 'female', icon: 'venus', label: 'She/Her' },
  { value: 'plural', icon: 'transgender', label: 'They/Them' },
  { value: 'neuter', icon: 'neuter', label: 'It/Its' },
] as const;

function GenderButton(props: {
  gender: string;
  onSelect: (value: string) => void;
}) {
  const current =
    GENDER_OPTIONS.find((option) => option.value === props.gender) ||
    GENDER_OPTIONS[0];
  return (
    <Floating
      placement="right"
      content={
        <Stack backgroundColor="black" p={0.3}>
          {GENDER_OPTIONS.map((option) => (
            <Stack.Item key={option.value}>
              <Button
                selected={option.value === props.gender}
                onClick={() => props.onSelect(option.value)}
                fontSize="22px"
                icon={option.icon}
                tooltip={option.label}
                tooltipPosition="top"
              />
            </Stack.Item>
          ))}
        </Stack>
      }
    >
      <Button
        className="RimworldCharacterEditor__pawnControlBtn"
        icon={current.icon}
        tooltip="Gender"
        tooltipPosition="top"
      />
    </Floating>
  );
}

function PawnIdentity(props: {
  prefCatalog: {
    icons: Record<string, Record<string, string>>;
    choices: Record<string, string[]>;
  };
}) {
  const { act, data } = useBackend<RimworldCharacterEditorData>();
  const { first, last } = splitColonistName({
    firstName: data.firstName,
    lastName: data.lastName,
    name: data.realName,
  });
  const [picked, setPicked] = useState<Record<string, string>>({});
  useEffect(() => {
    setPicked({});
  }, [data.activeSlot]);
  const choosers = mergeChoosers(data.clothingDefs);
  return (
    <div className="RimworldCharacterEditor__identity">
      <div className="RimworldCharacterEditor__nameBlock">
        <div className="RimworldCharacterEditor__nameStack">
          <Input
            key={`first-${data.activeSlot}`}
            fluid
            alwaysUpdate
            placeholder="Имя"
            value={first}
            onChange={(value) => act('set_first_name', { value })}
          />
          <Input
            key={`nick-${data.activeSlot}`}
            fluid
            alwaysUpdate
            placeholder={last}
            value={data.nickname || ''}
            onChange={(value) => act('set_nickname', { value })}
          />
          <Input
            key={`last-${data.activeSlot}`}
            fluid
            alwaysUpdate
            placeholder="Фамилия"
            value={last}
            onChange={(value) => act('set_last_name', { value })}
          />
        </div>
        <Button
          className="RimworldCharacterEditor__nameRandom"
          icon="dice"
          tooltip="Randomize name"
          tooltipPosition="right"
          onClick={() => act('randomize_names')}
        />
      </div>
      <Stack mt={0.5}>
        <Stack.Item>
          <Box className="RimworldCharacterEditor__fieldLabel">Bio age</Box>
          <NumberInput
            width="72px"
            value={data.biologicalAge ?? 21}
            minValue={18}
            maxValue={100}
            step={1}
            onChange={(value) => act('set_bio_age', { value })}
          />
        </Stack.Item>
        <Stack.Item>
          <Box className="RimworldCharacterEditor__fieldLabel">Chrono age</Box>
          <NumberInput
            width="72px"
            value={data.chronologicalAge ?? 21}
            minValue={18}
            maxValue={9999}
            step={1}
            onChange={(value) => act('set_chrono_age', { value })}
          />
        </Stack.Item>
      </Stack>
      <div className="RimworldCharacterEditor__pawnStage">
        <div className="RimworldCharacterEditor__pawnColumn">
          <div className="RimworldCharacterEditor__pawnMapWrap">
            {!!data.characterPreviewView && (
              <PawnMap id={data.characterPreviewView} />
            )}
          </div>
          <div className="RimworldCharacterEditor__pawnControls">
            <Button
              className="RimworldCharacterEditor__pawnControlBtn"
              icon="undo"
              onClick={() => act('rotate', { left: 1 })}
            />
            <Button
              className="RimworldCharacterEditor__pawnControlBtn"
              icon="redo"
              onClick={() => act('rotate')}
            />
            <GenderButton
              gender={data.gender}
              onSelect={(value) => act('set_gender', { value })}
            />
            <Button
              className="RimworldCharacterEditor__pawnControlBtn RimworldCharacterEditor__pawnRandomize"
              icon="dice"
              tooltip="Randomize colonist"
              tooltipPosition="top"
              onClick={() => act('randomize')}
            />
          </div>
          <div className="RimworldCharacterEditor__bodyType">
            <Box className="RimworldCharacterEditor__fieldLabel" mt={0.7}>
              Body type
            </Box>
            <Dropdown
              width="100%"
              selected={data.bodyType || 'Use gender'}
              options={['Use gender', 'male', 'female']}
              onSelected={(value) => act('set_body_type', { value })}
            />
          </div>
        </div>
        <div className="RimworldCharacterEditor__pawnAccessories">
          {choosers.map((chooser) => (
            <AccessoryChooser
              key={chooser.id}
              slot={chooser.id}
              name={chooser.name}
              icons={clothingIconsFor(
                data,
                chooser.thumbs,
                props.prefCatalog.icons,
              )}
              fallbackNames={
                chooser.choices ||
                props.prefCatalog.choices[chooser.thumbs] ||
                (chooser.id === 'hairstyle' ? data.hairstyles : undefined) ||
                (chooser.id === 'facial' ? data.facials : undefined)
              }
              selected={
                picked[chooser.id] ||
                String(selectedClothing(data, chooser.id) || '')
              }
              onSelect={(value) => {
                setPicked((current) => ({ ...current, [chooser.id]: value }));
                act('set_clothing', { id: chooser.id, value });
                act(`set_${chooser.id}`, { value });
              }}
              color={
                chooser.hasColor
                  ? selectedClothingColor(data, chooser.id)
                  : undefined
              }
              onPickColor={
                chooser.hasColor
                  ? () => {
                      act('pick_clothing_color', { id: chooser.id });
                      act(
                        chooser.id === 'hairstyle'
                          ? 'pick_hair_color'
                          : `pick_${chooser.id}_color`,
                      );
                    }
                  : undefined
              }
            />
          ))}
        </div>
      </div>
    </div>
  );
}

const CHOOSER_CELL = 54;

function catalogEntries(
  icons?: Record<string, string>,
  fallbackNames?: string[],
): { name: string; css: string | null }[] {
  const names = new Set<string>();
  for (const name of Object.keys(icons || {})) {
    names.add(name);
  }
  for (const name of fallbackNames || []) {
    if (typeof name === 'string' && name) {
      names.add(name);
    }
  }
  return Array.from(names).map((name) => ({
    name,
    css: icons?.[name] || null,
  }));
}

function AccessoryArt(props: { css: string | null; name: string }) {
  if (props.css) {
    return (
      <Box
        className={classes([
          'preferences32x32',
          props.css,
          'RimworldCharacterEditor__chooserArt',
        ])}
      />
    );
  }
  return (
    <Box className="RimworldCharacterEditor__chooserLabel">{props.name}</Box>
  );
}

function AccessoryChooser(props: {
  slot?: string;
  name: string;
  icons?: Record<string, string>;
  fallbackNames?: string[];
  selected: string;
  onSelect: (value: string) => void;
  color?: string;
  onPickColor?: () => void;
}) {
  const [searchText, setSearchText] = useState('');
  const entries = catalogEntries(props.icons, props.fallbackNames);
  const query = searchText.toLowerCase();
  const visible = query
    ? entries.filter((entry) => entry.name.toLowerCase().includes(query))
    : entries;
  const selected = entries.find((entry) => entry.name === props.selected) ||
    entries.find((entry) => entry.name === 'Nude') ||
    entries.find((entry) => entry.name === 'Jumpsuit') ||
    entries[0] || {
      name: props.name,
      css: props.icons?.[props.selected] || null,
    };

  return (
    <Floating
      stopChildPropagation
      placement="right-start"
      content={
        <Box className="RimworldCharacterEditor__chooser">
          <Stack fill vertical g={0}>
            <Stack.Item>
              <Box className="RimworldCharacterEditor__chooserHeader">
                <Box className="RimworldCharacterEditor__sectionTitle">
                  Select {props.name.toLowerCase()}
                </Box>
                {!!props.onPickColor && (
                  <Button tooltip="Color" onClick={props.onPickColor}>
                    <ColorBox color={props.color || '#ffffff'} />
                  </Button>
                )}
              </Box>
              <Input
                autoFocus
                fluid
                placeholder="Search..."
                value={searchText}
                onChange={setSearchText}
              />
            </Stack.Item>
            <Stack.Item grow>
              <Box className="RimworldCharacterEditor__chooserGrid">
                {visible.map((entry) => (
                  <Button
                    key={entry.name}
                    selected={entry.name === props.selected}
                    tooltip={entry.name}
                    tooltipPosition="right"
                    className="RimworldCharacterEditor__chooserCell"
                    onClick={() => props.onSelect(entry.name)}
                  >
                    <AccessoryArt css={entry.css} name={entry.name} />
                  </Button>
                ))}
              </Box>
            </Stack.Item>
          </Stack>
        </Box>
      }
    >
      <div>
        <Button
          className={classes([
            'RimworldCharacterEditor__chooserBtn',
            props.slot && `RimworldCharacterEditor__chooserBtn--${props.slot}`,
          ])}
          tooltip={props.name}
          tooltipPosition="right"
          position="relative"
          style={{
            height: `${CHOOSER_CELL}px`,
            width: `${CHOOSER_CELL}px`,
          }}
        >
          <AccessoryArt
            css={selected.css}
            name={selected.css ? selected.name : props.name}
          />
        </Button>
      </div>
    </Floating>
  );
}

function BiologyTab() {
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

function geneById(defs: RwXenogeneDef[], id: string) {
  return defs.find((gene) => gene.id === id);
}

function genesFromIds(defs: RwXenogeneDef[], ids: string[]) {
  return ids
    .map((id) => geneById(defs, id))
    .filter((gene): gene is RwXenogeneDef => !!gene);
}

function sumGeneStats(genes: RwXenogeneDef[]) {
  let complexity = 0;
  let metabolic = 0;
  for (const gene of genes) {
    complexity += gene.complexity ?? 1;
    metabolic += gene.metabolicEfficiency ?? 0;
  }
  return { complexity, metabolic };
}

function hungerRate(metabolic: number) {
  return Math.max(45, Math.round((1 - metabolic * 0.1) * 100));
}

function formatMetabolic(value: number) {
  if (value > 0) {
    return `+${value}`;
  }
  return `${value}`;
}

function GeneStats(props: { genes: RwXenogeneDef[] }) {
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

function geneConflicts(gene: RwXenogeneDef, other: RwXenogeneDef) {
  if (gene.id === other.id) {
    return false;
  }
  if ((gene.incompatibleWith || []).includes(other.id)) {
    return true;
  }
  if ((other.incompatibleWith || []).includes(gene.id)) {
    return true;
  }
  return !!(
    gene.incompatibilityGroup &&
    gene.incompatibilityGroup === other.incompatibilityGroup
  );
}

function conflictingGeneIds(
  gene: RwXenogeneDef,
  ownedIds: string[],
  defs: RwXenogeneDef[],
) {
  return ownedIds.filter((id) => {
    const other = geneById(defs, id);
    return !!other && geneConflicts(gene, other);
  });
}

function geneValueLabel(
  gene: RwXenogeneDef,
  values?: Record<string, unknown>,
) {
  const raw = values?.[gene.id];
  if (gene.option?.kind === 'tricolor' && Array.isArray(raw)) {
    return raw.map((piece) => String(piece)).join(' ');
  }
  if (raw === undefined || raw === null || raw === '') {
    return '';
  }
  return String(raw);
}

function toPngSrc(value: string) {
  if (value.startsWith('data:')) {
    return value;
  }
  return `data:image/png;base64,${value}`;
}

function GeneArt(props: { gene: RwXenogeneDef }) {
  const { gene } = props;
  if (gene.iconBgSrc || gene.iconSrc) {
    return (
      <span className="RimworldCharacterEditor__geneArt">
        {!!gene.iconBgSrc && (
          <img src={toPngSrc(gene.iconBgSrc)} alt="" />
        )}
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
      <ellipse cx="16" cy="13" rx="11" ry="9" fill="#f4f7fb" stroke="#1c2430" strokeWidth="1.6" />
      <ellipse cx="9" cy="21" rx="4.2" ry="8" fill="#f4f7fb" stroke="#1c2430" strokeWidth="1.6" />
      <ellipse cx="23" cy="21" rx="4.2" ry="8" fill="#c5cedb" stroke="#1c2430" strokeWidth="1.6" />
    </svg>
  );
}

function GeneTile(props: {
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

function GeneOptionEditor(props: { gene: RwXenogeneDef }) {
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

function GeneInspector(props: {
  gene?: RwXenogeneDef;
  innate?: boolean;
  equipped?: boolean;
}) {
  const { act, data } = useBackend<RimworldCharacterEditorData>();
  const { gene, innate, equipped } = props;
  if (!gene) {
    return (
      <Box color="label">Select a xenogene to see what it changes.</Box>
    );
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
  return (
    <div className="RimworldCharacterEditor__geneInspect">
      <Box className="RimworldCharacterEditor__sectionTitle">{gene.name}</Box>
      <Box color="label" mb={0.5}>
        {gene.category}
        {innate ? ' · from race' : ''}
        {(innate || equipped) &&
          (pawnInheritable ? ' · inheritable' : ' · not inheritable')}
      </Box>
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
      <GeneOptionEditor gene={gene} />
      {!innate && (
        <Button
          mt={1}
          fluid
          selected={equipped}
          disabled={blockedByInnate}
          onClick={() => act('toggle_xenogene', { id: gene.id })}
        >
          {equipped ? 'Remove gene' : 'Add gene'}
        </Button>
      )}
    </div>
  );
}

function raceTitle(species?: RwSpeciesDef) {
  return species?.label || species?.name || 'Race';
}

function RacePane() {
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
      <Stack.Item
        basis="220px"
        className="RimworldCharacterEditor__scrollPane"
      >
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

function XenogenePane() {
  const { data } = useBackend<RimworldCharacterEditorData>();
  const innateIds = data.innateXenogenes || [];
  const equippedIds = data.xenogenes || [];
  const inheritableIds = data.xenogeneInheritable || [];
  const [inspectedId, setInspectedId] = useState<string | null>(null);

  const fromRace = genesFromIds(data.xenogeneDefs, innateIds);
  const equipped = genesFromIds(data.xenogeneDefs, equippedIds).filter(
    (gene) => !innateIds.includes(gene.id),
  );
  const available = data.xenogeneDefs.filter(
    (gene) =>
      !equippedIds.includes(gene.id) && !innateIds.includes(gene.id),
  );
  const allActive = [...fromRace, ...equipped];

  const inspected =
    geneById(data.xenogeneDefs, inspectedId || '') ||
    fromRace[0] ||
    equipped[0] ||
    available[0];

  return (
    <Stack fill>
      <Stack.Item grow className="RimworldCharacterEditor__scrollPane">
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
          Available
        </Box>
        {available.length ? (
          <div className="RimworldCharacterEditor__geneGrid">
            {available.map((gene) => (
              <GeneTile
                key={gene.id}
                gene={gene}
                selected={inspected?.id === gene.id}
                disabled={
                  conflictingGeneIds(gene, innateIds, data.xenogeneDefs)
                    .length > 0
                }
                onClick={() => setInspectedId(gene.id)}
                onConfigure={() => setInspectedId(gene.id)}
              />
            ))}
          </div>
        ) : (
          <Box color="label">None</Box>
        )}
        <GeneStats genes={allActive} />
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

function PersonaTab() {
  return (
    <Stack fill className="RimworldCharacterEditor__persona">
      <Stack.Item grow className="RimworldCharacterEditor__scrollPane">
        <AppearancePanel />
      </Stack.Item>
    </Stack>
  );
}

const VISUAL_CHILDHOODS = [
  {
    id: 'vis_cave',
    name: 'Caveworld Tender',
    desc: 'Raised in the dark, learning which mushrooms are food.',
  },
  {
    id: 'vis_urchin',
    name: 'Urbworld Urchin',
    desc: 'Grew up in alleys, picking pockets and scrap.',
  },
  {
    id: 'vis_vassal',
    name: 'Medieval Vassal',
    desc: 'A castle childhood of chores, hymns, and swords.',
  },
  {
    id: 'vis_vat',
    name: 'Vatgrown',
    desc: 'Decanted with a manual and no parents.',
  },
  {
    id: 'vis_tribe',
    name: 'Tribe Child',
    desc: 'Learned stories, bows, and the names of stars.',
  },
  {
    id: 'vis_industrial',
    name: 'Industrial Brat',
    desc: 'Factory smoke, shift bells, and stolen tools.',
  },
  {
    id: 'vis_starship',
    name: 'Starship Youth',
    desc: 'Corridors for a playground, gravity for a toy.',
  },
  {
    id: 'vis_farm',
    name: 'Farmhand',
    desc: 'Dawns, livestock, and a long walk to school.',
  },
  {
    id: 'vis_shelter',
    name: 'Shelter Kid',
    desc: 'Moved whenever the raids got close.',
  },
  {
    id: 'vis_stellarch',
    name: 'Stellarch Heir',
    desc: 'Tutors, banquets, and very careful manners.',
  },
  {
    id: 'vis_waster',
    name: 'Waster Child',
    desc: 'Toxins, masks, and a talent for not dying.',
  },
  {
    id: 'vis_prodigy',
    name: 'Musical Prodigy',
    desc: 'Practiced until the neighbors gave up.',
  },
];

const VISUAL_ADULTHOODS = [
  {
    id: 'vis_miner',
    name: 'Miner',
    desc: 'Years underground, following the ore.',
  },
  {
    id: 'vis_chef',
    name: 'Chef',
    desc: 'Kept a kitchen running on whatever came in.',
  },
  {
    id: 'vis_surgeon',
    name: 'Surgeon',
    desc: 'Steady hands and a shortage of anesthetic.',
  },
  {
    id: 'vis_researcher',
    name: 'Researcher',
    desc: 'Labs, notes, and arguments about theory.',
  },
  {
    id: 'vis_soldier',
    name: 'Soldier',
    desc: 'Followed orders until the unit broke apart.',
  },
  {
    id: 'vis_painter',
    name: 'Painter',
    desc: 'Sold pictures of places people missed.',
  },
  {
    id: 'vis_farmer',
    name: 'Crop Farmer',
    desc: 'One bad season away from leaving.',
  },
  {
    id: 'vis_sheriff',
    name: 'Sheriff',
    desc: 'Kept a small town quieter than it wanted.',
  },
  {
    id: 'vis_pirate',
    name: 'Pirate',
    desc: 'Boarding actions and very short contracts.',
  },
  {
    id: 'vis_priest',
    name: 'Priest',
    desc: 'Preached, buried, and kept the books.',
  },
  {
    id: 'vis_machinist',
    name: 'Machinist',
    desc: 'Built the machines that built everything else.',
  },
  {
    id: 'vis_trader',
    name: 'Caravan Trader',
    desc: 'Knew every price and most of the roads.',
  },
  {
    id: 'vis_janitor',
    name: 'Janitor',
    desc: 'Saw the station from the side nobody cleans.',
  },
  {
    id: 'vis_arch',
    name: 'Archaeologist',
    desc: 'Opened ruins that were better left shut.',
  },
];

const TRAIT_PLACEHOLDERS = Array.from({ length: 12 }, (_, index) => {
  const number = index + 1;
  const positive = number <= 8;
  return {
    id: 'trait_placeholder_' + number,
    name: 'Trait Placeholder ' + number,
    desc: 'Placeholder trait. Replace this entry.',
    cost: positive ? number * 100 : -(number - 8) * 100,
    positive,
  };
});

const VISUAL_SKILLS = [
  { id: 'vis_melee', name: 'Melee', level: 8, passion: 2, sortOrder: 2 },
  {
    id: 'vis_construction',
    name: 'Construction',
    level: 4,
    passion: 1,
    sortOrder: 3,
  },
  { id: 'vis_mining', name: 'Mining', level: 6, passion: 0, sortOrder: 4 },
  { id: 'vis_cooking', name: 'Cooking', level: 5, passion: 1, sortOrder: 5 },
  { id: 'vis_plants', name: 'Plants', level: 3, passion: 0, sortOrder: 6 },
  { id: 'vis_animals', name: 'Animals', level: 2, passion: 1, sortOrder: 7 },
  {
    id: 'vis_crafting',
    name: 'Crafting',
    level: 10,
    passion: 2,
    sortOrder: 8,
  },
  { id: 'vis_artistic', name: 'Artistic', level: 7, passion: 2, sortOrder: 9 },
  { id: 'vis_medical', name: 'Medical', level: 9, passion: 1, sortOrder: 10 },
  { id: 'vis_social', name: 'Social', level: 1, passion: 0, sortOrder: 11 },
  {
    id: 'vis_intellectual',
    name: 'Intellectual',
    level: 8,
    passion: 2,
    sortOrder: 12,
  },
];

const VISUAL_LOADOUT = [
  {
    id: 'vis_rifle',
    name: 'Bolt-Action Rifle',
    desc: 'A reliable long gun and a box of rounds.',
    cost: 250,
  },
  {
    id: 'vis_pistol',
    name: 'Autopistol',
    desc: 'Sidearm for when the rifle is empty.',
    cost: 120,
  },
  {
    id: 'vis_knife',
    name: 'Knife',
    desc: 'Short blade. Useful for more than fighting.',
    cost: 40,
  },
  {
    id: 'vis_helmet',
    name: 'Simple Helmet',
    desc: 'Keeps rocks and glances off the skull.',
    cost: 80,
  },
  {
    id: 'vis_vest',
    name: 'Flak Vest',
    desc: 'Light armor over the ribs.',
    cost: 160,
  },
  {
    id: 'vis_medkit',
    name: 'Medicine',
    desc: 'A pouch of real medicine, not herbal.',
    cost: 180,
  },
  {
    id: 'vis_herbal',
    name: 'Herbal Medicine',
    desc: 'Enough to stop a bleed in the field.',
    cost: 60,
  },
  {
    id: 'vis_meal',
    name: 'Packaged Meals',
    desc: 'Food that survives a bad week.',
    cost: 50,
  },
  {
    id: 'vis_pemmican',
    name: 'Pemmican',
    desc: 'Dense rations for a long walk.',
    cost: 40,
  },
  {
    id: 'vis_bedroll',
    name: 'Bedroll',
    desc: 'Somewhere to sleep that is not the floor.',
    cost: 30,
  },
  {
    id: 'vis_components',
    name: 'Components',
    desc: 'Spare parts for the first machines.',
    cost: 140,
  },
  {
    id: 'vis_steel',
    name: 'Steel',
    desc: 'A stack of metal to start building.',
    cost: 70,
  },
  {
    id: 'vis_wood',
    name: 'Wood',
    desc: 'Planks, if the map has no trees.',
    cost: 30,
  },
  {
    id: 'vis_silver',
    name: 'Silver',
    desc: 'Starting money for traders.',
    cost: 100,
  },
  {
    id: 'vis_bow',
    name: 'Recurve Bow',
    desc: 'Quiet, and it does not need bullets.',
    cost: 90,
  },
  {
    id: 'vis_spear',
    name: 'Spear',
    desc: 'A long stick with a point.',
    cost: 35,
  },
  {
    id: 'vis_duster',
    name: 'Duster',
    desc: 'Coat against weather and light hits.',
    cost: 110,
  },
  {
    id: 'vis_radio',
    name: 'Radio',
    desc: 'A way to hear who else is out there.',
    cost: 75,
  },
];

function onlyNew<T extends { id: string }>(real: T[], extra: T[]) {
  const ids = new Set(real.map((row) => row.id));
  return extra.filter((row) => !ids.has(row.id));
}

type StoryGrant = { skill: string; amount: number };

const STORY_GRANTS: Record<string, StoryGrant[]> = {
  vis_cave: [
    { skill: 'Plants', amount: 2 },
    { skill: 'Animals', amount: 1 },
  ],
  vis_urchin: [
    { skill: 'Social', amount: 2 },
    { skill: 'Melee', amount: 1 },
  ],
  vis_vassal: [
    { skill: 'Melee', amount: 2 },
    { skill: 'Social', amount: 1 },
  ],
  vis_vat: [{ skill: 'Intellectual', amount: 3 }],
  vis_tribe: [
    { skill: 'Plants', amount: 2 },
    { skill: 'Shooting', amount: 1 },
  ],
  vis_industrial: [
    { skill: 'Crafting', amount: 2 },
    { skill: 'Construction', amount: 1 },
  ],
  vis_starship: [
    { skill: 'Intellectual', amount: 1 },
    { skill: 'Construction', amount: 2 },
  ],
  vis_farm: [
    { skill: 'Plants', amount: 3 },
    { skill: 'Animals', amount: 2 },
  ],
  vis_shelter: [{ skill: 'Construction', amount: 2 }],
  vis_stellarch: [{ skill: 'Social', amount: 3 }],
  vis_waster: [
    { skill: 'Mining', amount: 1 },
    { skill: 'Medical', amount: 1 },
  ],
  vis_prodigy: [{ skill: 'Artistic', amount: 4 }],
  vis_miner: [
    { skill: 'Mining', amount: 5 },
    { skill: 'Construction', amount: 1 },
  ],
  vis_chef: [{ skill: 'Cooking', amount: 6 }],
  vis_surgeon: [{ skill: 'Medical', amount: 6 }],
  vis_researcher: [{ skill: 'Intellectual', amount: 6 }],
  vis_soldier: [
    { skill: 'Shooting', amount: 4 },
    { skill: 'Melee', amount: 2 },
  ],
  vis_painter: [{ skill: 'Artistic', amount: 6 }],
  vis_farmer: [{ skill: 'Plants', amount: 6 }],
  vis_sheriff: [
    { skill: 'Shooting', amount: 3 },
    { skill: 'Social', amount: 3 },
  ],
  vis_pirate: [
    { skill: 'Melee', amount: 3 },
    { skill: 'Shooting', amount: 2 },
  ],
  vis_priest: [{ skill: 'Social', amount: 5 }],
  vis_machinist: [
    { skill: 'Crafting', amount: 5 },
    { skill: 'Construction', amount: 2 },
  ],
  vis_trader: [{ skill: 'Social', amount: 5 }],
  vis_janitor: [{ skill: 'Construction', amount: 2 }],
  vis_arch: [{ skill: 'Intellectual', amount: 4 }],
};

function storyGrants(story?: {
  id: string;
  grants?: StoryGrant[];
}): StoryGrant[] {
  if (!story) {
    return [];
  }
  if (story.grants?.length) {
    return story.grants;
  }
  return STORY_GRANTS[story.id] || [];
}

function StoryGrants(props: { grants: StoryGrant[] }) {
  if (!props.grants.length) {
    return null;
  }
  return (
    <div className="RimworldCharacterEditor__storyGrants">
      {props.grants.map((grant) => (
        <span
          key={`${grant.skill}-${grant.amount}`}
          className={classes([
            'RimworldCharacterEditor__storyGrant',
            grant.amount < 0
              ? 'RimworldCharacterEditor__choiceCost--neg'
              : 'RimworldCharacterEditor__choiceCost--pos',
          ])}
        >
          {grant.amount > 0 ? `+${grant.amount}` : grant.amount} {grant.skill}
        </span>
      ))}
    </div>
  );
}

function StoryOption(props: {
  name: string;
  desc?: string;
  grants: StoryGrant[];
}) {
  return (
    <div className="RimworldCharacterEditor__storyOption">
      <div className="RimworldCharacterEditor__storyOptionName">
        {props.name}
      </div>
      {!!props.desc && (
        <div className="RimworldCharacterEditor__storyOptionDesc">
          {props.desc}
        </div>
      )}
      <StoryGrants grants={props.grants} />
    </div>
  );
}

function ChoiceCard(props: {
  name: string;
  desc?: string;
  selected: boolean;
  cost?: number;
  positive?: boolean;
  onClick: () => void;
}) {
  const costClass =
    props.positive === false || (props.cost || 0) < 0
      ? 'RimworldCharacterEditor__choiceCost--neg'
      : 'RimworldCharacterEditor__choiceCost--pos';
  const costLabel =
    typeof props.cost === 'number'
      ? props.cost > 0
        ? `+${props.cost}`
        : `${props.cost}`
      : null;

  return (
    <button
      type="button"
      title={props.desc}
      className={classes([
        'RimworldCharacterEditor__choiceCard',
        props.selected && 'RimworldCharacterEditor__choiceCard--on',
      ])}
      onClick={props.onClick}
    >
      <div className="RimworldCharacterEditor__choiceCardName">
        <span>{props.name}</span>
        {costLabel && <span className={costClass}>{costLabel}</span>}
      </div>
      {!!props.desc && (
        <div className="RimworldCharacterEditor__choiceCardDesc">
          {props.desc}
        </div>
      )}
    </button>
  );
}

function PreviewSkillRow(props: {
  name: string;
  level: number;
  passion: number;
  skillMax: number;
}) {
  const [level, setLevel] = useState(props.level);
  const [passion, setPassion] = useState(props.passion);
  const fill = (level / Math.max(props.skillMax, 1)) * 100;

  return (
    <div className="RimworldCharacterEditor__skillRow">
      <Button
        compact
        tooltip="Passion"
        onClick={() => setPassion((current) => (current + 1) % 3)}
      >
        {PASSION_MARK[passion] || '○'}
      </Button>
      <Box className="RimworldCharacterEditor__skillName">{props.name}</Box>
      <div className="RimworldCharacterEditor__skillBar">
        <div
          className="RimworldCharacterEditor__skillBarFill"
          style={{ width: `${fill}%` }}
        />
      </div>
      <Button
        compact
        disabled={level <= 0}
        onClick={() => setLevel((current) => Math.max(0, current - 1))}
      >
        −
      </Button>
      <Box width="28px" textAlign="center">
        {level}
      </Box>
      <Button
        compact
        disabled={level >= 10}
        onClick={() => setLevel((current) => Math.min(10, current + 1))}
      >
        +
      </Button>
    </div>
  );
}

function FeaturesTab() {
  const { act, data } = useBackend<RimworldCharacterEditorData>();
  const [visualChildhood, setVisualChildhood] = useState<string | null>(null);
  const [visualAdulthood, setVisualAdulthood] = useState<string | null>(null);
  const [visualTraits, setVisualTraits] = useState<string[]>([]);
  const skillById = new Map(data.skills.map((row) => [row.id, row]));
  const childhoods = [
    ...(data.childhoods || []),
    ...onlyNew(data.childhoods || [], VISUAL_CHILDHOODS),
  ];
  const adulthoods = [
    ...(data.adulthoods || []),
    ...onlyNew(data.adulthoods || [], VISUAL_ADULTHOODS),
  ];
  const traits = [
    ...(data.traitDefs || []),
    ...onlyNew(data.traitDefs || [], TRAIT_PLACEHOLDERS),
  ];
  const realChildhoods = new Set((data.childhoods || []).map((row) => row.id));
  const realAdulthoods = new Set((data.adulthoods || []).map((row) => row.id));
  const realTraits = new Set((data.traitDefs || []).map((row) => row.id));
  const realSkillNames = new Set((data.skillDefs || []).map((row) => row.name));
  const orderedSkills = [
    ...(data.skillDefs || []).map((skill) => ({
      id: skill.id,
      name: skill.name,
      level: 0,
      passion: 0,
      sortOrder:
        skill.sortOrder ??
        (skill.id === 'ranged' || skill.name === 'Shooting' ? 1 : 100),
      real: skill,
    })),
    ...VISUAL_SKILLS.filter((skill) => !realSkillNames.has(skill.name)).map(
      (skill) => ({
        ...skill,
        real: undefined as RwSkillDef | undefined,
      }),
    ),
  ].sort((a, b) => a.sortOrder - b.sortOrder);

  const childhoodId = visualChildhood || data.childhood;
  const adulthoodId = visualAdulthood || data.adulthood;
  const childhood = childhoods.find((story) => story.id === childhoodId);
  const adulthood = adulthoods.find((story) => story.id === adulthoodId);

  return (
    <div className="RimworldCharacterEditor__featureBoard">
      <div className="RimworldCharacterEditor__featureLeft">
        <Box className="RimworldCharacterEditor__sectionTitle">Childhood</Box>
        <Dropdown
          width="100%"
          menuWidth={22}
          selected={childhoodId}
          displayText={childhood?.name || 'Select'}
          options={childhoods.map((story) => ({
            value: story.id,
            displayText: (
              <StoryOption
                name={story.name}
                desc={story.desc}
                grants={storyGrants(story)}
              />
            ),
          }))}
          onSelected={(value) => {
            const id = String(value);
            if (realChildhoods.has(id)) {
              setVisualChildhood(null);
              act('set_childhood', { id });
              return;
            }
            setVisualChildhood(id);
          }}
        />
        <div className="RimworldCharacterEditor__storySummary">
          {!!childhood?.desc && (
            <Box className="RimworldCharacterEditor__storyBlurb">
              {childhood.desc}
            </Box>
          )}
          <StoryGrants grants={storyGrants(childhood)} />
        </div>
        <Box className="RimworldCharacterEditor__sectionTitle" mt={1}>
          Adulthood
        </Box>
        <Dropdown
          width="100%"
          menuWidth={22}
          selected={adulthoodId}
          displayText={adulthood?.name || 'Select'}
          options={adulthoods.map((story) => ({
            value: story.id,
            displayText: (
              <StoryOption
                name={story.name}
                desc={story.desc}
                grants={storyGrants(story)}
              />
            ),
          }))}
          onSelected={(value) => {
            const id = String(value);
            if (realAdulthoods.has(id)) {
              setVisualAdulthood(null);
              act('set_adulthood', { id });
              return;
            }
            setVisualAdulthood(id);
          }}
        />
        <div className="RimworldCharacterEditor__storySummary">
          {!!adulthood?.desc && (
            <Box className="RimworldCharacterEditor__storyBlurb">
              {adulthood.desc}
            </Box>
          )}
          <StoryGrants grants={storyGrants(adulthood)} />
        </div>
        <Box className="RimworldCharacterEditor__sectionTitle" mt={1}>
          Traits
        </Box>
        <div className="RimworldCharacterEditor__featureTraits">
          <div className="RimworldCharacterEditor__choiceList">
            {traits.map((trait) => {
              const selected = realTraits.has(trait.id)
                ? data.traits.includes(trait.id)
                : visualTraits.includes(trait.id);
              return (
                <ChoiceCard
                  key={trait.id}
                  name={trait.name}
                  desc={trait.desc}
                  cost={trait.cost}
                  positive={trait.positive}
                  selected={selected}
                  onClick={() => {
                    if (realTraits.has(trait.id)) {
                      act('toggle_trait', { id: trait.id });
                      return;
                    }
                    setVisualTraits((current) =>
                      current.includes(trait.id)
                        ? current.filter((id) => id !== trait.id)
                        : [...current, trait.id],
                    );
                  }}
                />
              );
            })}
          </div>
        </div>
      </div>
      <div className="RimworldCharacterEditor__featurePane RimworldCharacterEditor__featureSkills">
        <Box className="RimworldCharacterEditor__sectionTitle">Skills</Box>
        <div className="RimworldCharacterEditor__skillList">
        {orderedSkills.map((skill) =>
          skill.real ? (
            <SkillRow
              key={skill.id}
              skill={skill.real}
              row={skillById.get(skill.id)}
            />
          ) : (
            <PreviewSkillRow
              key={skill.id}
              name={skill.name}
              level={skill.level}
              passion={skill.passion}
              skillMax={data.skillMax || 20}
            />
          ),
        )}
        </div>
      </div>
    </div>
  );
}

function PossessionsTab() {
  const { act, data } = useBackend<RimworldCharacterEditorData>();
  const [visualLoadout, setVisualLoadout] = useState<string[]>([]);
  const items = [
    ...(data.loadoutDefs || []),
    ...onlyNew(data.loadoutDefs || [], VISUAL_LOADOUT),
  ];
  const realIds = new Set((data.loadoutDefs || []).map((item) => item.id));

  return (
    <div className="RimworldCharacterEditor__loadoutBoard">
      <Box className="RimworldCharacterEditor__sectionTitle">Loadout</Box>
      <div className="RimworldCharacterEditor__loadoutGrid">
        {items.map((item) => {
          const selected = realIds.has(item.id)
            ? data.loadout.includes(item.id)
            : visualLoadout.includes(item.id);
          return (
            <ChoiceCard
              key={item.id}
              name={item.name}
              desc={item.desc}
              cost={item.cost}
              positive
              selected={selected}
              onClick={() => {
                if (realIds.has(item.id)) {
                  act('toggle_loadout', { id: item.id });
                  return;
                }
                setVisualLoadout((current) =>
                  current.includes(item.id)
                    ? current.filter((id) => id !== item.id)
                    : [...current, item.id],
                );
              }}
            />
          );
        })}
      </div>
    </div>
  );
}

function AppearancePanel() {
  const { act, data } = useBackend<RimworldCharacterEditorData>();
  const skinOptions = (data.skinTones || []).map((tone) => {
    const name = data.skinToneNames?.[tone] || tone;
    const hex = data.skinToneHex?.[tone];
    return {
      value: tone,
      displayText: (
        <Stack align="center" fill>
          {!!hex && (
            <Stack.Item>
              <Box
                style={{
                  background: hex,
                  height: '11px',
                  width: '11px',
                  boxSizing: 'content-box',
                }}
              />
            </Stack.Item>
          )}
          <Stack.Item>{name}</Stack.Item>
        </Stack>
      ),
    };
  });
  const selectedSkin = skinOptions.find(
    (option) => option.value === data.skinTone,
  );
  const hairGradients = data.hairGradients || ['None'];
  const facialGradients = data.facialGradients || ['None'];
  const screamTypes = data.screamTypes || ['Human Scream'];
  const laughTypes = data.laughTypes || ['Human Laugh'];
  const blooperOptions = (data.blooperTypes || []).map((id) => ({
    value: id,
    displayText: data.blooperNames?.[id] || id,
  }));
  const showHairGradColor = (data.hairGradient || 'None') !== 'None';
  const showFacialGradColor = (data.facialGradient || 'None') !== 'None';

  return (
    <div className="RimworldCharacterEditor__appearance">
      {data.usesSkintones ? (
        <AppearanceRow label="Skin tone">
          <Dropdown
            width="100%"
            selected={data.skinTone}
            displayText={selectedSkin?.displayText}
            options={skinOptions}
            onSelected={(value) => act('set_skin_tone', { value })}
          />
        </AppearanceRow>
      ) : (
        <>
          <AppearanceRow label="Body color">
            <ColorPick
              color={data.mutantColor}
              onClick={() => act('pick_detail_color', { id: 'mutant_color' })}
            />
          </AppearanceRow>
          <AppearanceRow label="Body color 2">
            <ColorPick
              color={data.mutantColor2 || data.mutantColor}
              onClick={() => act('pick_detail_color', { id: 'mutant_color_2' })}
            />
          </AppearanceRow>
          <AppearanceRow label="Body color 3">
            <ColorPick
              color={data.mutantColor3 || data.mutantColor}
              onClick={() => act('pick_detail_color', { id: 'mutant_color_3' })}
            />
          </AppearanceRow>
        </>
      )}
      <AppearanceRow label="Eye color">
        <ColorPick
          color={data.eyeColor || '#336699'}
          onClick={() => act('pick_detail_color', { id: 'eye_color' })}
        />
      </AppearanceRow>
      <AppearanceRow label="Hair gradient">
        <Dropdown
          width="100%"
          selected={data.hairGradient || 'None'}
          options={hairGradients}
          onSelected={(value) =>
            act('set_detail', { id: 'hair_gradient', value })
          }
        />
      </AppearanceRow>
      {showHairGradColor && (
        <AppearanceRow label="Gradient color">
          <ColorPick
            color={data.hairGradientColor || '#ffffff'}
            onClick={() =>
              act('pick_detail_color', { id: 'hair_gradient_color' })
            }
          />
        </AppearanceRow>
      )}
      <AppearanceRow label="Facial gradient">
        <Dropdown
          width="100%"
          selected={data.facialGradient || 'None'}
          options={facialGradients}
          onSelected={(value) =>
            act('set_detail', { id: 'facial_gradient', value })
          }
        />
      </AppearanceRow>
      {showFacialGradColor && (
        <AppearanceRow label="Facial color">
          <ColorPick
            color={data.facialGradientColor || '#ffffff'}
            onClick={() =>
              act('pick_detail_color', { id: 'facial_gradient_color' })
            }
          />
        </AppearanceRow>
      )}
      <AppearanceRow label="Scream">
        <Dropdown
          width="100%"
          selected={data.characterScream || 'Human Scream'}
          options={screamTypes}
          onSelected={(value) =>
            act('set_detail', { id: 'character_scream', value })
          }
        />
      </AppearanceRow>
      <AppearanceRow label="Laugh">
        <Dropdown
          width="100%"
          selected={data.characterLaugh || 'Human Laugh'}
          options={laughTypes}
          onSelected={(value) =>
            act('set_detail', { id: 'character_laugh', value })
          }
        />
      </AppearanceRow>
      <AppearanceRow label="Voice">
        <Stack fill>
          <Stack.Item grow>
            <Dropdown
              width="100%"
              selected={data.blooperChoice}
              displayText={
                data.blooperNames?.[data.blooperChoice || ''] ||
                data.blooperChoice
              }
              options={blooperOptions}
              onSelected={(value) =>
                act('set_detail', { id: 'blooper_choice', value })
              }
            />
          </Stack.Item>
          <Stack.Item>
            <Button
              icon="play"
              tooltip="Preview voice"
              disabled={!data.blooperChoice || data.blooperChoice === 'none'}
              onClick={() => act('play_blooper')}
            />
          </Stack.Item>
        </Stack>
      </AppearanceRow>
      <AppearanceRow label="Voice speed">
        <Slider
          minValue={0}
          maxValue={100}
          step={1}
          stepPixelSize={4}
          unit="%"
          value={data.blooperSpeed ?? 50}
          onChange={(_, value) =>
            act('set_detail', { id: 'blooper_speed', value })
          }
        />
      </AppearanceRow>
      <AppearanceRow label="Voice pitch">
        <Slider
          minValue={0}
          maxValue={100}
          step={1}
          stepPixelSize={4}
          unit="%"
          value={data.blooperPitch ?? 50}
          onChange={(_, value) =>
            act('set_detail', { id: 'blooper_pitch', value })
          }
        />
      </AppearanceRow>
      <AppearanceRow label="Voice range">
        <Slider
          minValue={0}
          maxValue={100}
          step={1}
          stepPixelSize={4}
          unit="%"
          value={data.blooperPitchRange ?? 30}
          onChange={(_, value) =>
            act('set_detail', { id: 'blooper_pitch_range', value })
          }
        />
      </AppearanceRow>
      <AppearanceRow label="Chat color">
        <ColorPick
          color={data.chatColor || '#b0b0b0'}
          onClick={() => act('pick_detail_color', { id: 'chat_color' })}
        />
      </AppearanceRow>
      <AppearanceRow label="Headshot">
        <DetailInput
          id="headshot"
          value={data.headshot || ''}
          maxLength={1024}
        />
      </AppearanceRow>
      <DetailText
        id="flavor_text"
        label="Flavor text"
        value={data.flavorText || ''}
      />
    </div>
  );
}

function AppearanceRow(props: { label: string; children: ReactNode }) {
  return (
    <div className="RimworldCharacterEditor__appearanceRow">
      <Box className="RimworldCharacterEditor__appearanceLabel">
        {props.label}
      </Box>
      <div className="RimworldCharacterEditor__appearanceControl">
        {props.children}
      </div>
    </div>
  );
}

function ColorPick(props: { color: string; onClick: () => void }) {
  const color = props.color?.startsWith('#')
    ? props.color
    : `#${props.color || 'ffffff'}`;
  return (
    <Button onClick={props.onClick}>
      <ColorBox color={color} />
    </Button>
  );
}

function DetailInput(props: { id: string; value: string; maxLength?: number }) {
  const { act, data } = useBackend<RimworldCharacterEditorData>();
  const [text, setText] = useState(props.value);
  useEffect(() => {
    setText(props.value);
  }, [props.value, data.activeSlot]);
  return (
    <Input
      fluid
      placeholder="https://"
      value={text}
      maxLength={props.maxLength || 1024}
      onChange={setText}
      onBlur={(value) => act('set_detail', { id: props.id, value })}
    />
  );
}

function DetailText(props: { id: string; label: string; value: string }) {
  const { act, data } = useBackend<RimworldCharacterEditorData>();
  const [text, setText] = useState(props.value);
  useEffect(() => {
    setText(props.value);
  }, [props.value, data.activeSlot]);
  return (
    <Box mt={0.6}>
      <Box className="RimworldCharacterEditor__fieldLabel">{props.label}</Box>
      <TextArea
        fluid
        height="88px"
        value={text}
        maxLength={4096}
        onChange={setText}
        onBlur={(value) => act('set_detail', { id: props.id, value })}
      />
    </Box>
  );
}

function SkillRow(props: { skill: RwSkillDef; row?: RwSkillRow }) {
  const { act, data } = useBackend<RimworldCharacterEditorData>();
  const { skill, row } = props;
  const level = row?.level || 0;
  const bought = row?.bought || 0;
  const passion = row?.passion || 0;
  const fill = (level / data.skillMax) * 100;

  return (
    <div className="RimworldCharacterEditor__skillRow">
      <Button
        compact
        disabled={!skill.editable}
        tooltip="Passion"
        onClick={() => act('cycle_passion', { id: skill.id })}
      >
        {PASSION_MARK[passion] || '○'}
      </Button>
      <Box
        className="RimworldCharacterEditor__skillName"
        color={skill.editable ? undefined : 'label'}
      >
        {skill.name}
      </Box>
      <div className="RimworldCharacterEditor__skillBar">
        <div
          className="RimworldCharacterEditor__skillBarFill"
          style={{ width: `${fill}%` }}
        />
      </div>
      <Button
        compact
        disabled={!skill.editable || bought <= 0}
        onClick={() => act('adjust_skill', { id: skill.id, delta: -1 })}
      >
        −
      </Button>
      <Box width="28px" textAlign="center">
        {level}
      </Box>
      <Button
        compact
        disabled={
          !skill.editable ||
          bought >= data.skillManualMax ||
          data.budgetRemaining < 100
        }
        onClick={() => act('adjust_skill', { id: skill.id, delta: 1 })}
      >
        +
      </Button>
    </div>
  );
}
