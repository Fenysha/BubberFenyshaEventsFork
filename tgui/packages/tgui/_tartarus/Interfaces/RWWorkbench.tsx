import { useMemo, useState } from 'react';
import { useBackend } from 'tgui/backend';
import { Window } from 'tgui/layouts';
import {
  Box,
  Button,
  Input,
  NoticeBox,
  ProgressBar,
  Section,
  Stack,
  Tooltip,
} from 'tgui-core/components';

// Keep in sync with RW_JOB_* in rw_research.dm
const JOB_COLLECTING = 0;
const JOB_READY = 1;
const JOB_WORKPIECE = 2;

const TYPE_WORKPIECE = 'workpiece';

type SkillInfo = {
  id?: string;
  name: string;
  min: number;
  ideal?: number;
  user: number;
  ok: boolean;
};

type Requirement = {
  path: string;
  name: string;
  amount: number;
  carried: number;
  delivered?: number;
};

type Recipe = {
  id: string;
  name: string;
  desc: string;
  category: string;
  craft_type: string;
  crafting_time: number;
  steps: number;
  result_name: string;
  result_path: string;
  result_amount: number;
  requirements: Requirement[];
  skill: SkillInfo;
};

type Job = {
  uid: number;
  recipe_id: string;
  name: string;
  desc: string;
  craft_type: string;
  state: number;
  steps: number;
  steps_done: number;
  working: boolean;
  filled: boolean;
  result_name: string;
  result_path: string;
  result_amount: number;
  requirements: Requirement[];
  skill: SkillInfo;
};

type WorkbenchData = {
  bench_name: string;
  has_faction: boolean;
  can_craft: boolean;
  busy: boolean;
  message: string;
  max_queue: number;
  icons: Record<string, string | null>;
  recipes: Recipe[];
  queue: Job[];
};

const COLOR_OK = '#8fe08f';
const COLOR_BAD = '#ff8c8c';

const toSrc = (src?: string | null) =>
  src ? `data:image/png;base64,${src}` : undefined;

function ItemIcon(props: { src?: string | null; size?: number }) {
  const { src, size = 32 } = props;
  const url = toSrc(src);
  if (!url) {
    return <Box inline width={`${size}px`} height={`${size}px`} />;
  }
  return (
    <img
      src={url}
      width={size}
      height={size}
      style={{ imageRendering: 'pixelated', verticalAlign: 'middle' }}
    />
  );
}

function SkillBadge(props: { skill: SkillInfo }) {
  const { skill } = props;
  if (skill.min <= 0) {
    return (
      <Box as="span" color="#999999">
        {skill.name}
      </Box>
    );
  }
  return (
    <Tooltip content={`You have ${skill.name} ${skill.user}`}>
      <Box as="span" color={skill.ok ? COLOR_OK : COLOR_BAD}>
        {skill.name} {skill.min}+
      </Box>
    </Tooltip>
  );
}

/** One ingredient tile. `have` is what is on the bench (selected recipe) or carried (list). */
function Ingredient(props: {
  icons: Record<string, string | null>;
  req: Requirement;
  mode: 'bench' | 'carried';
}) {
  const { icons, req, mode } = props;
  const have = mode === 'bench' ? req.delivered || 0 : req.carried;
  const ok = have >= req.amount;
  const tooltip =
    mode === 'bench'
      ? `${req.name}: ${have}/${req.amount} on the bench (you carry ${req.carried})`
      : `${req.name}: need ${req.amount}, you carry ${req.carried}`;
  return (
    <Tooltip content={tooltip}>
      <Box
        inline
        mr={1}
        mb={1}
        px={0.75}
        py={0.5}
        style={{
          border: `1px solid ${ok ? '#3f7a3f' : '#8a3a3a'}`,
          borderRadius: '4px',
          backgroundColor: ok ? '#243324' : '#3a2424',
          textAlign: 'center',
          minWidth: '52px',
        }}
      >
        <ItemIcon src={icons[req.path]} size={32} />
        <Box bold fontSize="12px" color={ok ? COLOR_OK : COLOR_BAD}>
          {have}/{req.amount}
        </Box>
      </Box>
    </Tooltip>
  );
}

function stateText(job: Job): string {
  if (job.working) return 'Working…';
  if (job.state === JOB_COLLECTING) return 'Waiting for ingredients';
  if (job.state === JOB_READY) return 'Ready to craft';
  if (job.state === JOB_WORKPIECE) return 'Workpiece on the bench';
  return '';
}

export function RWWorkbench() {
  const { act, data } = useBackend<WorkbenchData>();
  const {
    can_craft,
    message,
    max_queue = 1,
    icons = {},
    recipes = [],
    queue = [],
  } = data;

  const [search, setSearch] = useState('');
  const [category, setCategory] = useState('All');

  const categories = useMemo(
    () => ['All', ...Array.from(new Set(recipes.map((r) => r.category)))],
    [recipes],
  );

  const q = search.trim().toLowerCase();
  const shownRecipes = recipes.filter((r) => {
    if (category !== 'All' && r.category !== category) return false;
    if (!q) return true;
    return (
      r.name.toLowerCase().includes(q) || r.result_name.toLowerCase().includes(q)
    );
  });

  const active = queue[0];
  const waiting = queue.slice(1);
  const activeRecipeId = active?.recipe_id;

  return (
    <Window width={900} height={620} title={data.bench_name || 'Workbench'}>
      <Window.Content style={{ backgroundColor: '#333333' }}>
        <Stack vertical fill>
          {!!message && (
            <Stack.Item>
              <NoticeBox>{message}</NoticeBox>
            </Stack.Item>
          )}

          <Stack.Item grow>
            <Stack fill>
              {/* LEFT: the recipe currently on the bench + queue */}
              <Stack.Item basis="390px">
                <Stack vertical fill>
                  <Stack.Item grow>
                    <Section fill scrollable title="Current recipe">
                      {active ? (
                        <Stack vertical>
                          <Stack.Item>
                            <Stack align="center">
                              <Stack.Item>
                                <ItemIcon
                                  src={icons[active.result_path]}
                                  size={64}
                                />
                              </Stack.Item>
                              <Stack.Item grow ml={1}>
                                <Box bold fontSize="15px">
                                  {active.name}
                                </Box>
                                <Box color="#aaaaaa" fontSize="12px">
                                  {active.craft_type === TYPE_WORKPIECE
                                    ? `Workpiece · ${active.steps} steps`
                                    : 'Gather & craft'}
                                  {active.result_amount > 1
                                    ? ` · makes ${active.result_amount}`
                                    : ''}
                                </Box>
                                <Box fontSize="12px">
                                  <SkillBadge skill={active.skill} />
                                </Box>
                              </Stack.Item>
                            </Stack>
                          </Stack.Item>

                          {!!active.desc && (
                            <Stack.Item>
                              <Box color="#b0b0b0">{active.desc}</Box>
                            </Stack.Item>
                          )}

                          <Stack.Item>
                            <Box color="#d2d2d2" mb={0.5}>
                              Ingredients on the workbench
                            </Box>
                            <Box>
                              {active.requirements.map((req) => (
                                <Ingredient
                                  key={req.path}
                                  icons={icons}
                                  req={req}
                                  mode="bench"
                                />
                              ))}
                            </Box>
                            {active.state === JOB_COLLECTING && (
                              <Box color="#888888" fontSize="12px">
                                Drag items onto the workbench, or use them on
                                it.
                              </Box>
                            )}
                          </Stack.Item>

                          <Stack.Item>
                            <Box color="#d2d2d2" mb={0.5}>
                              {stateText(active)}
                            </Box>
                            {active.craft_type === TYPE_WORKPIECE &&
                              active.state === JOB_WORKPIECE && (
                                <ProgressBar
                                  value={active.steps_done / active.steps}
                                  ranges={{
                                    good: [0.99, Infinity],
                                    average: [0.01, 0.99],
                                    bad: [-Infinity, 0.01],
                                  }}
                                >
                                  {active.steps_done}/{active.steps} steps
                                </ProgressBar>
                              )}
                          </Stack.Item>

                          <Stack.Item>
                            <Stack>
                              {active.state === JOB_COLLECTING && (
                                <Stack.Item grow>
                                  <Button
                                    fluid
                                    icon="hand-holding"
                                    disabled={!can_craft || active.working}
                                    onClick={() => act('deliver_carried')}
                                  >
                                    Add carried items
                                  </Button>
                                </Stack.Item>
                              )}
                              {active.state === JOB_READY && (
                                <Stack.Item grow>
                                  <Button
                                    fluid
                                    icon="hammer"
                                    color="good"
                                    disabled={!can_craft || active.working}
                                    onClick={() => act('work')}
                                  >
                                    Start crafting
                                  </Button>
                                </Stack.Item>
                              )}
                              {active.state === JOB_WORKPIECE && (
                                <Stack.Item grow>
                                  <Button
                                    fluid
                                    icon="hammer"
                                    color="good"
                                    disabled={!can_craft || active.working}
                                    onClick={() => act('work')}
                                  >
                                    {active.steps_done > 0
                                      ? 'Continue working'
                                      : 'Start working'}
                                  </Button>
                                </Stack.Item>
                              )}
                              <Stack.Item>
                                <Button
                                  icon="times"
                                  color="bad"
                                  disabled={active.working}
                                  tooltip={
                                    active.steps_done > 0
                                      ? 'Cancel. Materials worked into the workpiece are lost.'
                                      : 'Cancel and get the ingredients back.'
                                  }
                                  onClick={() =>
                                    act('cancel_job', { uid: active.uid })
                                  }
                                >
                                  Cancel
                                </Button>
                              </Stack.Item>
                            </Stack>
                          </Stack.Item>
                        </Stack>
                      ) : (
                        <Box color="#aaaaaa">
                          Pick a recipe on the right, then bring the
                          ingredients to the workbench.
                        </Box>
                      )}
                    </Section>
                  </Stack.Item>

                  <Stack.Item>
                    <Section title={`Queue ${queue.length}/${max_queue}`}>
                      {waiting.length ? (
                        waiting.map((job, i) => (
                          <Stack key={job.uid} align="center" mb={0.5}>
                            <Stack.Item>
                              <ItemIcon src={icons[job.result_path]} size={24} />
                            </Stack.Item>
                            <Stack.Item grow ml={1}>
                              {i + 2}. {job.name}
                            </Stack.Item>
                            <Stack.Item>
                              <Button
                                compact
                                icon="times"
                                color="bad"
                                onClick={() =>
                                  act('cancel_job', { uid: job.uid })
                                }
                              />
                            </Stack.Item>
                          </Stack>
                        ))
                      ) : (
                        <Box color="#888888" fontSize="12px">
                          {max_queue > 1
                            ? 'Nothing is waiting.'
                            : 'This bench handles one recipe at a time.'}
                        </Box>
                      )}
                    </Section>
                  </Stack.Item>
                </Stack>
              </Stack.Item>

              {/* RIGHT: available recipes */}
              <Stack.Item grow>
                <Section
                  fill
                  title="Recipes"
                  buttons={
                    <Box inline width="160px">
                      <Input
                        fluid
                        placeholder="Search..."
                        value={search}
                        onChange={setSearch}
                      />
                    </Box>
                  }
                >
                  <Stack vertical fill>
                    <Stack.Item>
                      <Box mb={1}>
                        {categories.map((c) => (
                          <Button
                            key={c}
                            compact
                            mr={0.5}
                            color={category === c ? 'grey' : 'transparent'}
                            onClick={() => setCategory(c)}
                          >
                            {c}
                          </Button>
                        ))}
                      </Box>
                    </Stack.Item>
                    <Stack.Item grow style={{ overflowY: 'auto' }}>
                      {shownRecipes.map((r) => {
                        const isActive = activeRecipeId === r.id;
                        const canPick = can_craft && r.skill.ok;
                        return (
                          <Box
                            key={r.id}
                            mb={1}
                            p={1}
                            style={{
                              border: `1px solid ${isActive ? '#2d6a4f' : '#555555'}`,
                              borderRadius: '4px',
                              backgroundColor: isActive ? '#26352d' : '#3b3b3b',
                            }}
                          >
                            <Stack align="center">
                              <Stack.Item>
                                <ItemIcon src={icons[r.result_path]} size={40} />
                              </Stack.Item>
                              <Stack.Item grow ml={1}>
                                <Box bold>
                                  {r.name}
                                  {r.result_amount > 1 && (
                                    <Box as="span" color="#999999">
                                      {' '}
                                      ×{r.result_amount}
                                    </Box>
                                  )}
                                </Box>
                                <Box color="#999999" fontSize="11px">
                                  {r.craft_type === TYPE_WORKPIECE
                                    ? `Workpiece · ${r.steps} steps`
                                    : 'Gather & craft'}
                                  {' · '}
                                  {r.crafting_time.toFixed(1)}s
                                  {' · '}
                                  <SkillBadge skill={r.skill} />
                                </Box>
                              </Stack.Item>
                              <Stack.Item>
                                <Button
                                  icon="check"
                                  color={isActive ? 'good' : 'default'}
                                  disabled={!canPick || isActive}
                                  tooltip={
                                    !r.skill.ok
                                      ? `Needs ${r.skill.name} ${r.skill.min}`
                                      : undefined
                                  }
                                  onClick={() =>
                                    act('select_recipe', { id: r.id })
                                  }
                                >
                                  {isActive ? 'Selected' : 'Select'}
                                </Button>
                              </Stack.Item>
                            </Stack>
                            <Box mt={0.75}>
                              {r.requirements.map((req) => (
                                <Ingredient
                                  key={req.path}
                                  icons={icons}
                                  req={req}
                                  mode="carried"
                                />
                              ))}
                            </Box>
                          </Box>
                        );
                      })}
                      {!shownRecipes.length && (
                        <Box color="#888888" textAlign="center" py={4}>
                          {recipes.length
                            ? 'No recipes match.'
                            : 'No recipes available here. Research some first.'}
                        </Box>
                      )}
                    </Stack.Item>
                  </Stack>
                </Section>
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
}
