import { useBackend } from 'tgui/backend';
import { Section } from 'tgui-core/components';
import { classes } from 'tgui-core/react';
import type { RimworldCharacterEditorData } from '../types';
import { isPortraitPng, slotDisplayName, splitColonistName } from '../utils';
import { SlotPortrait } from './shared';

export function ColonyList() {
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
            profile.lost && 'RimworldCharacterEditor__slot--lost',
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
