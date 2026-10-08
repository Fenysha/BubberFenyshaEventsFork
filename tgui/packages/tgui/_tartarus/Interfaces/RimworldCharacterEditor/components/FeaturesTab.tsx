import { useBackend } from 'tgui/backend';
import { Box, Button } from 'tgui-core/components';
import { MAX_TRAITS } from '../constants';
import type { RimworldCharacterEditorData } from '../types';
import {
  ChoiceCard,
  SearchDropdown,
  SkillRow,
  StoryOption,
  storyChoice,
  storyGrants,
} from './shared';

export function FeaturesTab() {
  const { act, data } = useBackend<RimworldCharacterEditorData>();
  const skillById = new Map(data.skills.map((row) => [row.id, row]));
  const childhoods = data.childhoods || [];
  const adulthoods = data.adulthoods || [];
  const traits = data.traitDefs || [];
  const forcedTraits = data.forcedTraits || [];
  const pickedTraits = traits.filter(
    (trait) =>
      data.traits.includes(trait.id) || forcedTraits.includes(trait.id),
  );
  const openTraits = traits.filter((trait) => {
    if (pickedTraits.some((picked) => picked.id === trait.id)) {
      return false;
    }
    if ((trait.cost || 0) > 0 && data.budgetRemaining < trait.cost) {
      return false;
    }
    return true;
  });

  const addTrait = (id: string) => {
    if (pickedTraits.length >= MAX_TRAITS || forcedTraits.includes(id)) {
      return;
    }
    const trait = traits.find((t) => t.id === id);
    if (trait && (trait.cost || 0) > 0 && data.budgetRemaining < trait.cost) {
      return;
    }
    act('toggle_trait', { id });
  };

  const removeTrait = (id: string) => {
    act('toggle_trait', { id });
  };

  const orderedSkills = [...(data.skillDefs || [])]
    .map((skill) => ({
      id: skill.id,
      name: skill.name,
      sortOrder:
        skill.sortOrder ??
        (skill.id === 'ranged' || skill.name === 'Shooting' ? 1 : 100),
      real: skill,
    }))
    .sort((a, b) => a.sortOrder - b.sortOrder);

  const childhood = childhoods.find((story) => story.id === data.childhood);
  const adulthood = adulthoods.find((story) => story.id === data.adulthood);

  return (
    <div className="RimworldCharacterEditor__featureBoard">
      <div className="RimworldCharacterEditor__featureLeft">
        <Box className="RimworldCharacterEditor__sectionTitle">Childhood</Box>
        <SearchDropdown
          label={childhood?.name || 'Select'}
          options={childhoods.map(storyChoice)}
          onSelected={(id) => act('set_childhood', { id })}
        />
        <div className="RimworldCharacterEditor__storySummary">
          {!!childhood && (
            <StoryOption
              name={childhood.name}
              desc={childhood.desc}
              textGood={childhood.textGood}
              textBad={childhood.textBad}
              grants={storyGrants(childhood)}
            />
          )}
        </div>
        <Box className="RimworldCharacterEditor__sectionTitle" mt={1}>
          Adulthood
        </Box>
        <SearchDropdown
          label={adulthood?.name || 'Select'}
          options={adulthoods.map(storyChoice)}
          onSelected={(id) => act('set_adulthood', { id })}
        />
        <div className="RimworldCharacterEditor__storySummary">
          {!!adulthood && (
            <StoryOption
              name={adulthood.name}
              desc={adulthood.desc}
              textGood={adulthood.textGood}
              textBad={adulthood.textBad}
              grants={storyGrants(adulthood)}
            />
          )}
        </div>
        <Box className="RimworldCharacterEditor__sectionTitle" mt={1}>
          Traits
        </Box>
        <div className="RimworldCharacterEditor__featureTraits">
          <div className="RimworldCharacterEditor__choiceList">
            {pickedTraits.map((trait) => (
              <div
                key={trait.id}
                className={
                  forcedTraits.includes(trait.id)
                    ? 'RimworldCharacterEditor__traitPicked RimworldCharacterEditor__traitForced'
                    : 'RimworldCharacterEditor__traitPicked'
                }
              >
                <ChoiceCard
                  name={trait.name}
                  desc={trait.desc}
                  textGood={trait.textGood}
                  textBad={trait.textBad}
                  cost={trait.cost}
                  positive={trait.positive}
                  selected
                  onClick={() => {
                    if (!forcedTraits.includes(trait.id)) {
                      removeTrait(trait.id);
                    }
                  }}
                />
                {!forcedTraits.includes(trait.id) && (
                  <Button
                    compact
                    icon="times"
                    tooltip="Remove"
                    onClick={() => removeTrait(trait.id)}
                  />
                )}
              </div>
            ))}
            {pickedTraits.length < MAX_TRAITS && (
              <SearchDropdown
                label="+ Add trait"
                options={openTraits.map((trait) => ({
                  value: trait.id,
                  name: trait.name,
                  desc: `${trait.desc} (${
                    trait.cost > 0 ? `+${trait.cost}` : trait.cost
                  })`,
                  textGood: trait.textGood,
                  textBad: trait.textBad,
                  grants: [],
                }))}
                onSelected={addTrait}
              />
            )}
          </div>
        </div>
      </div>
      <div className="RimworldCharacterEditor__featurePane RimworldCharacterEditor__featureSkills">
        <Box className="RimworldCharacterEditor__sectionTitle">Skills</Box>
        <div className="RimworldCharacterEditor__skillList">
          {orderedSkills.map((skill) => (
            <SkillRow
              key={skill.id}
              skill={skill.real}
              row={skillById.get(skill.id)}
            />
          ))}
        </div>
      </div>
    </div>
  );
}
