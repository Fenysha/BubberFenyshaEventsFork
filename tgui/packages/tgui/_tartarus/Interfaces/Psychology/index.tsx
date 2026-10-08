import { useState } from 'react';
import { useBackend } from 'tgui/backend';
import { Window } from 'tgui/layouts';
import {
  Box,
  Icon,
  ProgressBar,
  Section,
  Stack,
  Tabs,
  Tooltip,
} from 'tgui-core/components';
// @ts-expect-error
import '../../Styles/Psychology.scss';

type NeedRow = {
  id: string;
  name: string;
  description: string;
  value: number;
  max: number;
  label: string;
  moodContribution: number;
  lowThreshold: number;
  mediumThreshold: number;
  criticalThreshold: number;
};

type FactorRow = {
  id: string;
  description: string;
  moodChange: number;
  permanent: boolean;
};

type SkillRow = {
  id: string;
  name: string;
  desc: string;
  level: number;
  title: string;
  points: number;
  pointsIntoLevel: number;
  pointsToNextLevel: number;
  progress: number;
  maxed: boolean;
  passion: number;
};

type PsychologyData = {
  pawnName: string;
  speciesName: string;
  mood: number;
  moodScaleMin: number;
  moodScaleMax: number;
  moodLabel: string;
  breakSeverity: number;
  inBreak: boolean;
  breakEndsIn: number;
  breakName?: string;
  thresholds: {
    minor: number;
    major: number;
    extreme: number;
  };
  needs: NeedRow[];
  factors: FactorRow[];
  childhoodName: string;
  adulthoodName: string;
  traitNames: string[];
  persona?: {
    skillData?: SkillRow[];
  };
};

type TabId = 'character' | 'needs';

const MOOD_COLOR: Record<string, string> = {
  ecstatic: 'good',
  happy: 'good',
  content: 'good',
  neutral: 'average',
  stressed: 'average',
  miserable: 'bad',
  catatonic: 'bad',
};

const BREAK_LABELS: Record<number, string> = {
  1: 'Minor break risk',
  2: 'Major break risk',
  3: 'Extreme break risk',
};

const NEED_COLORS: Record<string, string> = {
  satisfied: 'good',
  ok: 'good',
  low: 'average',
  critical: 'bad',
  desperate: 'bad',
};

export function Psychology() {
  const { data } = useBackend<PsychologyData>();
  const [tab, setTab] = useState<TabId>('character');

  return (
    <Window
      title="Psychological profile"
      width={820}
      height={600}
      theme="tartarus"
    >
      <Window.Content className="Psychology" altDrag={false}>
        <Stack fill vertical className="Psychology__layout">
          <Stack.Item className="Psychology__header">
            <Stack align="center">
              <Stack.Item grow>
                <Box className="Psychology__eyebrow">COLONIST DOSSIER</Box>
                <Box className="Psychology__pawnName" bold>
                  {data.pawnName || 'Unknown colonist'}
                </Box>
                <Box className="Psychology__species">
                  {data.speciesName || 'Unknown species'}
                </Box>
              </Stack.Item>
              <Stack.Item>
                <MoodSummary data={data} />
              </Stack.Item>
            </Stack>
          </Stack.Item>
          <Stack.Item className="Psychology__tabs">
            <Tabs>
              <Tabs.Tab
                selected={tab === 'character'}
                onClick={() => setTab('character')}
              >
                Character
              </Tabs.Tab>
              <Tabs.Tab
                selected={tab === 'needs'}
                onClick={() => setTab('needs')}
              >
                Needs &amp; State
              </Tabs.Tab>
            </Tabs>
          </Stack.Item>
          <Stack.Item grow className="Psychology__content">
            {tab === 'character' ? (
              <CharacterTab data={data} />
            ) : (
              <NeedsTab data={data} />
            )}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
}

function MoodSummary({ data }: { data: PsychologyData }) {
  const moodColor = MOOD_COLOR[data.moodLabel] || 'average';
  const breakRisk = getBreakRisk(data.mood, data.thresholds);

  return (
    <div className="Psychology__moodSummary">
      <Box className="Psychology__eyebrow">CURRENT MOOD</Box>
      <Stack align="center" justify="space-between">
        <Stack.Item>
          <Box color={moodColor} bold className="Psychology__moodLabel">
            {data.moodLabel || 'unknown'}
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Box color={moodColor} bold className="Psychology__moodValue">
            {data.mood > 0 ? '+' : ''}
            {Math.round(data.mood || 0)}
          </Box>
        </Stack.Item>
      </Stack>
      {data.inBreak ? (
        <Box color="bad" className="Psychology__breakState">
          <Icon name="exclamation-triangle" />{' '}
          {data.breakName || 'Mental break'}
          {data.breakEndsIn > 0 && ` · ${Math.ceil(data.breakEndsIn)}s`}
        </Box>
      ) : breakRisk > 0 ? (
        <Box color="average" className="Psychology__breakState">
          {BREAK_LABELS[breakRisk] || 'Break risk'}
        </Box>
      ) : (
        <Box color="label" className="Psychology__breakState">
          No mental break risk
        </Box>
      )}
    </div>
  );
}

function getBreakRisk(mood: number, thresholds: PsychologyData['thresholds']) {
  if (mood <= thresholds.extreme) {
    return 3;
  }
  if (mood <= thresholds.major) {
    return 2;
  }
  if (mood <= thresholds.minor) {
    return 1;
  }
  return 0;
}

function CharacterTab({ data }: { data: PsychologyData }) {
  const skills = data.persona?.skillData || [];
  const traits = data.traitNames || [];

  return (
    <Stack fill className="Psychology__columns">
      <Stack.Item basis="43%" grow className="Psychology__leftColumn">
        <Stack vertical fill>
          <Stack.Item>
            <Section title="Life story" className="Psychology__section">
              <StoryCard label="CHILDHOOD" name={data.childhoodName} />
              <StoryCard label="ADULTHOOD" name={data.adulthoodName} />
            </Section>
          </Stack.Item>
          <Stack.Item grow>
            <Section title="Traits" fill className="Psychology__section">
              {traits.length ? (
                <div className="Psychology__traitList">
                  {traits.map((trait, index) => (
                    <div
                      className="Psychology__trait"
                      key={`${trait}-${index}`}
                    >
                      <Icon name="circle" size={0.65} />
                      <span>{trait}</span>
                    </div>
                  ))}
                </div>
              ) : (
                <Box color="label">No recorded traits</Box>
              )}
            </Section>
          </Stack.Item>
        </Stack>
      </Stack.Item>
      <Stack.Item basis="57%" grow>
        <Section title="Skills" fill scrollable className="Psychology__section">
          {skills.length ? (
            <div className="Psychology__skillList">
              {skills.map((skill) => (
                <SkillRowView key={skill.id} skill={skill} />
              ))}
            </div>
          ) : (
            <Box color="label">No skill data available</Box>
          )}
        </Section>
      </Stack.Item>
    </Stack>
  );
}

function StoryCard({ label, name }: { label: string; name: string }) {
  return (
    <div className="Psychology__story">
      <Box className="Psychology__eyebrow">{label}</Box>
      <Box bold>{name || 'Unknown'}</Box>
    </div>
  );
}

function SkillRowView({ skill }: { skill: SkillRow }) {
  const passionCount = Math.max(0, Math.min(2, skill.passion || 0));
  const progress = Math.max(0, Math.min(1, skill.progress || 0));

  return (
    <div className="Psychology__skill">
      <Stack align="center">
        <Stack.Item grow>
          <Box bold>{skill.name}</Box>
          <Box color="label" className="Psychology__skillTitle">
            {skill.title}
          </Box>
        </Stack.Item>
        <Stack.Item className="Psychology__passions">
          {passionCount ? (
            Array.from({ length: passionCount }, (_, index) => (
              <Icon key={index} name="fire" color="average" />
            ))
          ) : (
            <span className="Psychology__noPassion">—</span>
          )}
        </Stack.Item>
        <Stack.Item className="Psychology__skillLevel">
          <Box textAlign="right" bold>
            {skill.level}
          </Box>
        </Stack.Item>
      </Stack>
      <div className="Psychology__skillProgress">
        <ProgressBar value={progress} maxValue={1}>
          {skill.maxed
            ? 'MAX LEVEL'
            : `${skill.pointsIntoLevel} / ${skill.pointsIntoLevel + skill.pointsToNextLevel} XP`}
        </ProgressBar>
      </div>
      {skill.desc && (
        <Box color="label" className="Psychology__skillDesc">
          {skill.desc}
        </Box>
      )}
    </div>
  );
}

function NeedsTab({ data }: { data: PsychologyData }) {
  const needs = [...(data.needs || [])].sort(
    (a, b) => b.value / (b.max || 100) - a.value / (a.max || 100),
  );
  const factors = data.factors || [];

  return (
    <Stack fill className="Psychology__columns">
      <Stack.Item basis="56%" grow>
        <Section title="Needs" fill scrollable className="Psychology__section">
          {needs.length ? (
            <div className="Psychology__needList">
              {needs.map((need) => (
                <NeedRowView key={need.id} need={need} />
              ))}
            </div>
          ) : (
            <Box color="label">No need data available</Box>
          )}
        </Section>
      </Stack.Item>
      <Stack.Item basis="44%" grow>
        <Section
          title="Psychological effects"
          fill
          scrollable
          className="Psychology__section"
        >
          <NeedsTabMoodNote data={data} />
          {factors.length ? (
            <div className="Psychology__factorList">
              {factors.map((factor) => (
                <div className="Psychology__factor" key={factor.id}>
                  <Stack align="center">
                    <Stack.Item grow>
                      <Box bold>{factor.id}</Box>
                      <Box color="label" className="Psychology__factorDesc">
                        {factor.description}
                      </Box>
                    </Stack.Item>
                    <Stack.Item>
                      <Box color={factor.moodChange >= 0 ? 'good' : 'bad'} bold>
                        {factor.moodChange >= 0 ? '+' : ''}
                        {factor.moodChange}
                      </Box>
                    </Stack.Item>
                  </Stack>
                  {factor.permanent && (
                    <Box className="Psychology__permanent">PERMANENT</Box>
                  )}
                </div>
              ))}
            </div>
          ) : (
            <Box color="label">No active psychological effects</Box>
          )}
        </Section>
      </Stack.Item>
    </Stack>
  );
}

function NeedRowView({ need }: { need: NeedRow }) {
  const max = need.max || 100;
  const value = Math.max(0, Math.min(max, need.value || 0));
  const color = NEED_COLORS[need.label] || 'average';
  const tooltip = `${need.description} Mood thresholds: low ${need.lowThreshold}, moderate ${need.mediumThreshold}, critical ${need.criticalThreshold}.`;

  return (
    <div className="Psychology__need">
      <Stack align="center">
        <Stack.Item grow>
          <Tooltip content={tooltip}>
            <Box bold>{need.name}</Box>
          </Tooltip>
          <Box color={color} className="Psychology__needLabel">
            {need.label}
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Box color={need.moodContribution >= 0 ? 'good' : 'bad'} bold>
            {need.moodContribution >= 0 ? '+' : ''}
            {need.moodContribution.toFixed(1)} mood
          </Box>
        </Stack.Item>
      </Stack>
      <div className="Psychology__needBar">
        <ProgressBar value={value / max} maxValue={1}>
          {Math.round(value)} / {max}
        </ProgressBar>
      </div>
    </div>
  );
}

function NeedsTabMoodNote({ data }: { data: PsychologyData }) {
  const moodColor = MOOD_COLOR[data.moodLabel] || 'average';
  const moodScaleMin = data.moodScaleMin;
  const moodScaleMax = data.moodScaleMax;
  const moodRange = Math.max(moodScaleMax - moodScaleMin, 1);
  const moodScaleValue = Math.max(
    moodScaleMin,
    Math.min(moodScaleMax, data.mood || 0),
  );
  const neutralPosition = `${((0 - moodScaleMin) / moodRange) * 100}%`;

  return (
    <div className="Psychology__moodNote">
      <Box className="Psychology__eyebrow">MOOD BALANCE</Box>
      <Box color={moodColor} bold>
        {data.mood > 0 ? '+' : ''}
        {Math.round(data.mood || 0)} · {data.moodLabel}
      </Box>
      <Box color="label" className="Psychology__moodHint">
        Mood combines current needs and psychological effects.
      </Box>
      <div className="Psychology__moodScale" title="Current overall mood">
        <ProgressBar
          value={(moodScaleValue - moodScaleMin) / moodRange}
          maxValue={1}
          color={moodColor}
        >
          {data.mood > 0 ? '+' : ''}
          {Math.round(data.mood || 0)}
        </ProgressBar>
        <div className="Psychology__moodScaleLabels">
          <span>Severe distress</span>
          <span style={{ left: neutralPosition }}>Neutral</span>
          <span>Positive</span>
        </div>
      </div>
    </div>
  );
}
