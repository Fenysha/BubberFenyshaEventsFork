import { useBackend } from 'tgui/backend';
import { Window } from 'tgui/layouts';
import { Box, Button, NoticeBox, Section, Stack } from 'tgui-core/components';

type RecipeRequirement = {
  path: string;
  name: string;
  amount: number;
  have: number;
  iconSrc: string | null;
};

type CraftingRecipe = {
  id: string;
  name: string;
  desc: string;
  category: string;
  crafting_time: number;
  result_name: string;
  result_amount: number;
  resultIconSrc: string | null;
  requirements: RecipeRequirement[];
  canCraft: boolean;
};

type WorkbenchData = {
  bench_name: string;
  has_faction: boolean;
  can_craft: boolean;
  busy: boolean;
  message: string;
  recipes: CraftingRecipe[];
};

function toPngSrc(value: string | null | undefined) {
  if (!value) return '';
  if (value.startsWith('data:')) return value;
  return `data:image/png;base64,${value}`;
}

const ItemIcon = (props: {
  iconSrc: string | null | undefined;
  name: string;
  size?: number;
}) => {
  const { iconSrc, name, size = 24 } = props;

  if (!iconSrc) {
    return (
      <Box
        inline
        textAlign="center"
        width={`${size}px`}
        height={`${size}px`}
        style={{
          lineHeight: `${size}px`,
          backgroundColor: 'rgba(128, 128, 128, 0.2)',
          borderRadius: '2px',
        }}
      >
        ?
      </Box>
    );
  }

  return (
    <img
      src={toPngSrc(iconSrc)}
      alt={name}
      width={size}
      height={size}
      draggable={false}
      style={{ imageRendering: 'pixelated' }}
    />
  );
};

export const RWWorkbench = () => {
  const { act, data } = useBackend<WorkbenchData>();
  const {
    bench_name = 'Crafting Station',
    can_craft,
    busy,
    message,
    recipes = [],
  } = data;

  return (
    <Window title={bench_name} width={880} height={720}>
      <Window.Content scrollable>
        <Stack fill vertical>
          {!!message && (
            <Stack.Item>
              <NoticeBox>{message}</NoticeBox>
            </Stack.Item>
          )}

          {!recipes.length && !message && (
            <Stack.Item>
              <NoticeBox>
                No researched recipes are available at this workbench.
              </NoticeBox>
            </Stack.Item>
          )}

          {recipes.map((recipe) => (
            <Stack.Item key={recipe.id}>
              <Section
                title={recipe.name}
                buttons={
                  <Button
                    icon="hammer"
                    color={recipe.canCraft ? 'good' : undefined}
                    disabled={!can_craft || busy || !recipe.canCraft}
                    tooltip={
                      !can_craft
                        ? 'Workbench unavailable'
                        : busy
                          ? 'Already crafting'
                          : !recipe.canCraft
                            ? 'Missing materials'
                            : 'Craft this item'
                    }
                    onClick={() => act('craft', { id: recipe.id })}
                  >
                    Craft
                  </Button>
                }
              >
                <Stack vertical>
                  {/* Result */}
                  <Stack.Item>
                    <Stack align="center">
                      <Stack.Item>
                        <ItemIcon
                          iconSrc={recipe.resultIconSrc}
                          name={recipe.result_name}
                          size={36}
                        />
                      </Stack.Item>
                      <Stack.Item grow>
                        <Box bold>{recipe.result_name}</Box>
                        <Box color="label">
                          {recipe.category} · Output: {recipe.result_amount} ·{' '}
                          {recipe.crafting_time}s
                        </Box>
                      </Stack.Item>
                    </Stack>
                  </Stack.Item>

                  {/* Description */}
                  {!!recipe.desc && (
                    <Stack.Item>
                      <Box>{recipe.desc}</Box>
                    </Stack.Item>
                  )}

                  {/* Requirements */}
                  <Stack.Item>
                    <Box color="label" mb={0.5}>
                      Required resources
                    </Box>

                    {recipe.requirements.length ? (
                      <Stack wrap>
                        {recipe.requirements.map((requirement) => {
                          const enough = requirement.have >= requirement.amount;

                          return (
                            <Stack.Item key={requirement.path}>
                              <Box
                                inline
                                backgroundColor={
                                  enough
                                    ? 'rgba(0, 180, 0, 0.12)'
                                    : 'rgba(180, 0, 0, 0.12)'
                                }
                                p={0.75}
                                style={{ borderRadius: '3px' }}
                              >
                                <Stack align="center">
                                  <Stack.Item>
                                    <ItemIcon
                                      iconSrc={requirement.iconSrc}
                                      name={requirement.name}
                                      size={24}
                                    />
                                  </Stack.Item>
                                  <Stack.Item>
                                    <Box>
                                      {requirement.amount}× {requirement.name}
                                    </Box>
                                    <Box
                                      color={enough ? 'good' : 'bad'}
                                      fontSize="0.9em"
                                    >
                                      Have: {requirement.have}
                                    </Box>
                                  </Stack.Item>
                                </Stack>
                              </Box>
                            </Stack.Item>
                          );
                        })}
                      </Stack>
                    ) : (
                      <Box color="label">No material requirements.</Box>
                    )}
                  </Stack.Item>
                </Stack>
              </Section>
            </Stack.Item>
          ))}
        </Stack>
      </Window.Content>
    </Window>
  );
};
