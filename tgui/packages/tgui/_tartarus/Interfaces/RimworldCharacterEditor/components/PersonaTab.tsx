import { useBackend } from 'tgui/backend';
import { Box, Button, Dropdown, Slider, Stack } from 'tgui-core/components';
import type { RimworldCharacterEditorData } from '../types';
import { AppearanceRow, ColorPick, DetailInput, DetailText } from './shared';

export function PersonaTab() {
  return (
    <Stack fill className="RimworldCharacterEditor__persona">
      <Stack.Item grow className="RimworldCharacterEditor__scrollPane">
        <AppearancePanel />
      </Stack.Item>
    </Stack>
  );
}

export function AppearancePanel() {
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
