import { useBackend } from 'tgui/backend';
import {
  Box,
  Button,
  NumberInput,
  ProgressBar,
  Section,
  Stack,
} from 'tgui-core/components';
import { Window } from 'tgui/layouts';

type SkillRow = {
  id: string;
  name: string;
  desc: string;
  sortOrder: number;
  editable: boolean;
  level: number;
  title: string;
  points: number;
  pointsIntoLevel: number;
  pointsToNextLevel: number;
  currentLevelRequired: number;
  nextLevelRequired: number;
  progress: number;
  progressPercent: number;
  maxLevel: number;
  maxed: boolean;
};

type Data = {
  targetName: string;
  targetType: string;
  isAdmin: boolean;
  maxLevel: number;
  skills: SkillRow[];
};

export const SkillPanel = () => {
  const { act, data } = useBackend<Data>();

  return (
    <Window
      title={`Skills — ${data.targetName}`}
      width={820}
      height={720}
      theme="tartarus"
    >
      <Window.Content scrollable>
        <Section
          title={data.targetName}
          buttons={
            <Box color="label" fontSize="12px">
              {data.targetType}
              {data.isAdmin ? ' · ADMIN EDIT' : ' · VIEW ONLY'}
            </Box>
          }
        >
          <Box color="label">
            Skill titles run from <b>Unskilled</b> to{' '}
            <b>Planetary Master</b>.
          </Box>
        </Section>

        <Stack vertical fill>
          {data.skills.map((skill) => (
            <Stack.Item key={skill.id}>
              <SkillCard skill={skill} isAdmin={data.isAdmin} act={act} />
            </Stack.Item>
          ))}
        </Stack>
      </Window.Content>
    </Window>
  );
};

function SkillCard(props: {
  skill: SkillRow;
  isAdmin: boolean;
  act: (action: string, params?: Record<string, unknown>) => void;
}) {
  const { skill, isAdmin, act } = props;

  return (
    <Section
      title={
        <Stack align="center">
          <Stack.Item grow>
            <span>{skill.name}</span>{' '}
            <Box inline color="label">
              — {skill.title}
            </Box>
          </Stack.Item>
          <Stack.Item>
            <Box bold>
              {skill.level}/{skill.maxLevel}
            </Box>
          </Stack.Item>
        </Stack>
      }
    >
      <Box color="label" mb={0.6}>
        {skill.desc}
      </Box>

      <ProgressBar value={skill.progress} maxValue={1}>
        {skill.maxed
          ? `${skill.points} XP · MAXIMUM`
          : `${skill.pointsIntoLevel} / ${
              skill.nextLevelRequired - skill.currentLevelRequired
            } XP · ${Math.round(skill.progressPercent)}%`}
      </ProgressBar>

      <Box mt={0.6} color="label">
        {skill.maxed
          ? `${skill.points} total XP`
          : `${skill.pointsToNextLevel} XP to ${skill.level + 1} (${skill.nextLevelRequired} total XP)`}
      </Box>

      {isAdmin && (
        <Stack mt={1} align="center">
          <Stack.Item>
            <Button
              icon="minus"
              tooltip="Decrease level"
              disabled={skill.level <= 0}
              onClick={() =>
                act('adjust_level', { id: skill.id, delta: -1 })
              }
            />
          </Stack.Item>

          <Stack.Item>
            <NumberInput
              width="52px"
              value={skill.level}
              minValue={0}
              maxValue={skill.maxLevel}
              step={1}
              onChange={(value) =>
                act('set_level', { id: skill.id, value })
              }
            />
          </Stack.Item>

          <Stack.Item>
            <Button
              icon="plus"
              tooltip="Increase level"
              disabled={skill.level >= skill.maxLevel}
              onClick={() =>
                act('adjust_level', { id: skill.id, delta: 1 })
              }
            />
          </Stack.Item>

          <Stack.Item>
            <Button
              content="+1 XP"
              onClick={() =>
                act('add_points', { id: skill.id, amount: 1 })
              }
            />
          </Stack.Item>

          <Stack.Item>
            <Button
              content="+10 XP"
              onClick={() =>
                act('add_points', { id: skill.id, amount: 10 })
              }
            />
          </Stack.Item>

          <Stack.Item>
            <Button
              content="+100 XP"
              onClick={() =>
                act('add_points', { id: skill.id, amount: 100 })
              }
            />
          </Stack.Item>

          <Stack.Item>
            <Button
              content="+1000 XP"
              onClick={() =>
                act('add_points', { id: skill.id, amount: 1000 })
              }
            />
          </Stack.Item>

          <Stack.Item>
            <Button
              content="Max"
              color="good"
              disabled={skill.maxed}
              onClick={() => act('max_skill', { id: skill.id })}
            />
          </Stack.Item>

          <Stack.Item>
            <Button
              content="Reset"
              color="bad"
              disabled={skill.level <= 0 && skill.points <= 0}
              onClick={() => act('reset_skill', { id: skill.id })}
            />
          </Stack.Item>
        </Stack>
      )}
    </Section>
  );
};
