import { type ReactNode, useEffect, useRef, useState } from 'react';
import { useBackend } from 'tgui/backend';
import {
  Box,
  Button,
  ColorBox,
  Floating,
  Icon,
  Input,
  TextArea,
} from 'tgui-core/components';
import { classes } from 'tgui-core/react';
import type { StoryGrant } from '../constants';
import type {
  RimworldCharacterEditorData,
  RwSkillDef,
  RwSkillRow,
} from '../types';

export function storyGrants(story?: {
  id: string;
  grants?: StoryGrant[];
}): StoryGrant[] {
  if (!story?.grants?.length) {
    return [];
  }
  return story.grants;
}

export function StoryGrants(props: { grants: StoryGrant[] }) {
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

export function StoryOption(props: {
  name: string;
  desc?: string;
  textGood?: string;
  textBad?: string;
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
      {!!props.textGood && (
        <div className="RimworldCharacterEditor__storyGood">
          {props.textGood}
        </div>
      )}
      {!!props.textBad && (
        <div className="RimworldCharacterEditor__storyBad">{props.textBad}</div>
      )}
      <StoryGrants grants={props.grants} />
    </div>
  );
}

export function ChoiceCard(props: {
  name: string;
  desc?: string;
  textGood?: string;
  textBad?: string;
  selected: boolean;
  cost?: number;
  positive?: boolean;
  disabled?: boolean;
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
      title={props.disabled ? 'Not enough budget' : props.desc}
      disabled={props.disabled}
      className={classes([
        'RimworldCharacterEditor__choiceCard',
        props.selected && 'RimworldCharacterEditor__choiceCard--on',
        props.disabled && 'RimworldCharacterEditor__choiceCard--disabled',
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
      {!!props.textGood && (
        <div className="RimworldCharacterEditor__storyGood">
          {props.textGood}
        </div>
      )}
      {!!props.textBad && (
        <div className="RimworldCharacterEditor__storyBad">{props.textBad}</div>
      )}
    </button>
  );
}

export function PassionFlames(props: {
  passion: number;
  disabled?: boolean;
  onClick: () => void;
}) {
  const count = Math.max(0, Math.min(2, props.passion));
  return (
    <Button
      compact
      className="RimworldCharacterEditor__passion"
      disabled={props.disabled}
      tooltip="Passion"
      onClick={props.onClick}
    >
      {Array.from({ length: count }, (_, index) => (
        <Icon
          key={index}
          name="fire"
          className="RimworldCharacterEditor__passionFlame"
        />
      ))}
    </Button>
  );
}

export function SearchDropdown(props: {
  label: string;
  options: Array<{
    value: string;
    name: string;
    desc?: string;
    textGood?: string;
    textBad?: string;
    grants: StoryGrant[];
  }>;
  onSelected: (value: string) => void;
}) {
  const menu = useRef<{ close: () => void } | null>(null);
  const [query, setQuery] = useState('');
  const needle = query.trim().toLowerCase();
  const visible = props.options.filter((option) => {
    if (!needle) {
      return true;
    }
    const haystack = [
      option.name,
      option.desc,
      option.textGood,
      option.textBad,
      ...option.grants.map((grant) => `${grant.amount} ${grant.skill}`),
    ]
      .filter(Boolean)
      .join(' ')
      .toLowerCase();
    return haystack.includes(needle);
  });

  return (
    <Floating
      ref={menu}
      placement="bottom-start"
      contentClasses="RimworldCharacterEditor__searchMenu"
      content={
        <div className="RimworldCharacterEditor__searchPanel">
          <Input
            autoFocus
            fluid
            alwaysUpdate
            placeholder="Search"
            value={query}
            onChange={setQuery}
          />
          <div className="RimworldCharacterEditor__searchList">
            {visible.map((option) => (
              <button
                key={option.value}
                type="button"
                className="RimworldCharacterEditor__searchEntry"
                onClick={() => {
                  props.onSelected(option.value);
                  setQuery('');
                  menu.current?.close();
                }}
              >
                <StoryOption
                  name={option.name}
                  desc={option.desc}
                  textGood={option.textGood}
                  textBad={option.textBad}
                  grants={option.grants}
                />
              </button>
            ))}
            {!visible.length && (
              <div className="RimworldCharacterEditor__searchEmpty">
                No options
              </div>
            )}
          </div>
        </div>
      }
    >
      <Button fluid>{props.label}</Button>
    </Floating>
  );
}

export function storyChoice(story: {
  id: string;
  name: string;
  desc?: string;
  textGood?: string;
  textBad?: string;
  grants?: StoryGrant[];
}) {
  return {
    value: story.id,
    name: story.name,
    desc: story.desc,
    textGood: story.textGood,
    textBad: story.textBad,
    grants: storyGrants(story),
  };
}

export function AppearanceRow(props: { label: string; children: ReactNode }) {
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

export function ColorPick(props: { color: string; onClick: () => void }) {
  const color = props.color?.startsWith('#')
    ? props.color
    : `#${props.color || 'ffffff'}`;
  return (
    <Button onClick={props.onClick}>
      <ColorBox color={color} />
    </Button>
  );
}

export function DetailInput(props: {
  id: string;
  value: string;
  maxLength?: number;
}) {
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

export function DetailText(props: {
  id: string;
  label: string;
  value: string;
}) {
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

/** Minor passion = 100 pts, major = 250 pts (matches server passion_point_cost). */
function passionCost(level: number) {
  if (level === 1) return 100;
  if (level === 2) return 250;
  return 0;
}

export function SkillRow(props: { skill: RwSkillDef; row?: RwSkillRow }) {
  const { act, data } = useBackend<RimworldCharacterEditorData>();
  const { skill, row } = props;
  const level = row?.level || 0;
  const bought = row?.bought || 0;
  const passion = row?.passion || 0;
  const fill = (level / data.skillMax) * 100;
  const nextPassion = (passion + 1) % 3;
  const passionDelta = passionCost(nextPassion) - passionCost(passion);
  const passionBlocked =
    passionDelta > 0 && data.budgetRemaining < passionDelta;

  return (
    <div className="RimworldCharacterEditor__skillRow">
      <PassionFlames
        passion={passion}
        disabled={passionBlocked}
        onClick={() => {
          if (passionBlocked) return;
          act('cycle_passion', { id: skill.id });
        }}
      />
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
          data.budgetRemaining <= 0
        }
        onClick={() => act('adjust_skill', { id: skill.id, delta: 1 })}
      >
        +
      </Button>
    </div>
  );
}

export function SlotPortrait(props: { png: string; alt: string }) {
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
