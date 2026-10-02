import { memo, useEffect, useState } from 'react';
import { useBackend } from 'tgui/backend';
import {
  Box,
  Button,
  ByondUi,
  Dropdown,
  Floating,
  Input,
  NumberInput,
  Stack,
} from 'tgui-core/components';
import { GENDER_OPTIONS } from '../constants';
import type { RimworldCharacterEditorData } from '../types';
import {
  clothingIconsFor,
  mergeChoosers,
  selectedClothing,
  selectedClothingColor,
  splitColonistName,
} from '../utils';
import { AccessoryChooser } from './AccessoryChooser';

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

export function GenderButton(props: {
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

export function PawnIdentity(props: {
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
