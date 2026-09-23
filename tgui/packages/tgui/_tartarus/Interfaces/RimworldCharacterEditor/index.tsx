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
    <Window title="Prepare Colonist" width={1080} height={760} theme="tartarus">
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
  const { act, data } = useBackend<RimworldCharacterEditorData>();
  const currentSpecies = (data.speciesDefs || []).find(
    (species) => species.path === data.speciesPath,
  );

  return (
    <Stack fill>
      <Stack.Item grow>
        <Box className="RimworldCharacterEditor__sectionTitle">Race</Box>
        {(data.speciesDefs || []).map((species) => (
          <Button
            key={species.path}
            fluid
            selected={species.path === data.speciesPath}
            onClick={() => act('set_species', { value: species.path })}
          >
            {species.name}
          </Button>
        ))}
      </Stack.Item>
      <Stack.Item grow>
        <Box className="RimworldCharacterEditor__sectionTitle">Xenogenes</Box>
        {data.xenogeneDefs.map((gene) => {
          const supported =
            !gene.supportedSpecies.length ||
            gene.supportedSpecies.includes(currentSpecies?.id || '');
          const selected = data.xenogenes.includes(gene.id);
          return (
            <Button
              key={gene.id}
              fluid
              disabled={!supported}
              selected={selected}
              tooltip={gene.desc}
              onClick={() => act('toggle_xenogene', { id: gene.id })}
            >
              {gene.name}
            </Button>
          );
        })}
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

function FeaturesTab() {
  const { act, data } = useBackend<RimworldCharacterEditorData>();
  const skillById = new Map(data.skills.map((row) => [row.id, row]));

  return (
    <Stack fill className="RimworldCharacterEditor__persona">
      <Stack.Item basis="240px" className="RimworldCharacterEditor__scrollPane">
        <Box className="RimworldCharacterEditor__sectionTitle">Childhood</Box>
        {data.childhoods.map((story) => (
          <Button
            key={story.id}
            fluid
            selected={story.id === data.childhood}
            tooltip={story.desc}
            onClick={() => act('set_childhood', { id: story.id })}
          >
            {story.name}
          </Button>
        ))}
        <Box className="RimworldCharacterEditor__sectionTitle" mt={1}>
          Adulthood
        </Box>
        {data.adulthoods.map((story) => (
          <Button
            key={story.id}
            fluid
            selected={story.id === data.adulthood}
            tooltip={story.desc}
            onClick={() => act('set_adulthood', { id: story.id })}
          >
            {story.name}
          </Button>
        ))}
        <Box className="RimworldCharacterEditor__sectionTitle" mt={1}>
          Traits
        </Box>
        {data.traitDefs.map((trait) => (
          <Button
            key={trait.id}
            fluid
            selected={data.traits.includes(trait.id)}
            tooltip={`${trait.desc} (${trait.cost})`}
            onClick={() => act('toggle_trait', { id: trait.id })}
          >
            {trait.name} ({trait.cost})
          </Button>
        ))}
      </Stack.Item>
      <Stack.Item grow className="RimworldCharacterEditor__scrollPane">
        <Box className="RimworldCharacterEditor__sectionTitle">Skills</Box>
        {data.skillDefs.map((skill) => (
          <SkillRow
            key={skill.id}
            skill={skill}
            row={skillById.get(skill.id)}
          />
        ))}
      </Stack.Item>
    </Stack>
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
      <Box width="110px" color={skill.editable ? undefined : 'label'}>
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

function PossessionsTab() {
  const { act, data } = useBackend<RimworldCharacterEditorData>();
  return (
    <>
      <Box className="RimworldCharacterEditor__sectionTitle">Loadout</Box>
      {data.loadoutDefs.map((item) => (
        <Button
          key={item.id}
          fluid
          selected={data.loadout.includes(item.id)}
          tooltip={item.desc}
          onClick={() => act('toggle_loadout', { id: item.id })}
        >
          {item.name} ({item.cost})
        </Button>
      ))}
    </>
  );
}
