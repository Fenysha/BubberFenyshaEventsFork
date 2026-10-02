import { useEffect, useState } from 'react';
import { useBackend } from 'tgui/backend';
import { Box, Button, ProgressBar, Stack } from 'tgui-core/components';
import { Window } from '../../../layouts';
// @ts-expect-error
import '../../Styles/RimworldCharacterEditor.scss';
import { BiologyTab } from './components/BiologyTab';
import { ColonyList } from './components/ColonyList';
import { FeaturesTab } from './components/FeaturesTab';
import { PawnIdentity } from './components/PawnIdentity';
import { PersonaTab } from './components/PersonaTab';
import { PossessionsTab } from './components/PossessionsTab';
import { TABS, type TabId } from './constants';
import { usePrefCatalog } from './hooks';
import type { RimworldCharacterEditorData } from './types';

export const RimworldCharacterEditor = () => {
  const { data } = useBackend<RimworldCharacterEditorData>();
  const [tab, setTab] = useState<TabId>('persona');
  const prefCatalog = usePrefCatalog();

  useEffect(() => {
    if (!data.slotLost) {
      return;
    }
    const blockKeys = (event: KeyboardEvent) => {
      const target = event.target instanceof HTMLElement ? event.target : null;
      const inLockedPane = !!target?.closest(
        '.RimworldCharacterEditor__lockPane',
      );
      if (event.key === 'Tab' || inLockedPane) {
        event.preventDefault();
        event.stopPropagation();
        if (inLockedPane) {
          target?.blur();
        }
      }
    };
    const blurLocked = () => {
      const active = document.activeElement;
      if (
        active instanceof HTMLElement &&
        active.closest('.RimworldCharacterEditor__lockPane')
      ) {
        active.blur();
      }
    };
    document.addEventListener('keydown', blockKeys, true);
    document.addEventListener('keyup', blockKeys, true);
    blurLocked();
    const timer = window.setInterval(blurLocked, 200);
    return () => {
      document.removeEventListener('keydown', blockKeys, true);
      document.removeEventListener('keyup', blockKeys, true);
      window.clearInterval(timer);
    };
  }, [data.slotLost]);

  return (
    <Window title="Prepare Colonist" width={1320} height={760} theme="tartarus">
      <Window.Content className="RimworldCharacterEditor" altDrag={false}>
        <div className="RimworldCharacterEditor__frame">
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
              {!!data.slotLost && (
                <div className="RimworldCharacterEditor__lost">
                  <div className="RimworldCharacterEditor__lostWord">
                    Deceased
                  </div>
                  <div className="RimworldCharacterEditor__lostLine">
                    Персонаж утерян и будет недоступен до конца текущего раунда.
                  </div>
                </div>
              )}
              <Stack fill>
                <Stack.Item className="RimworldCharacterEditor__colony">
                  <ColonyList />
                </Stack.Item>
                <Stack.Item className="RimworldCharacterEditor__preview">
                  <div
                    className="RimworldCharacterEditor__lockPane"
                    inert={!!data.slotLost}
                  >
                    <PawnIdentity prefCatalog={prefCatalog} />
                  </div>
                </Stack.Item>
                <Stack.Item grow className="RimworldCharacterEditor__tabBody">
                  <div
                    className="RimworldCharacterEditor__lockPane"
                    inert={!!data.slotLost}
                  >
                    {tab === 'biology' && <BiologyTab />}
                    {tab === 'persona' && <PersonaTab />}
                    {tab === 'features' && <FeaturesTab />}
                    {tab === 'possessions' && <PossessionsTab />}
                    {tab === 'ideology' && (
                      <Box color="label" p={2}>
                        Ideology is not implemented yet.
                      </Box>
                    )}
                  </div>
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
                    value={Math.max(0, data.budgetRemaining)}
                    maxValue={data.budgetMax}
                    ranges={{
                      good: [data.budgetMax * 0.4, Infinity],
                      average: [data.budgetMax * 0.15, data.budgetMax * 0.4],
                      bad: [-Infinity, data.budgetMax * 0.15],
                    }}
                  >
                    {data.budgetRemaining < 0 ? (
                      <Box color="bad">
                        OVER BUDGET: {data.budgetRemaining} / {data.budgetMax}
                      </Box>
                    ) : (
                      `${data.budgetRemaining} / ${data.budgetMax}`
                    )}
                  </ProgressBar>
                </Stack.Item>
              </Stack>
            </Stack.Item>
          </Stack>
        </div>
      </Window.Content>
    </Window>
  );
};
