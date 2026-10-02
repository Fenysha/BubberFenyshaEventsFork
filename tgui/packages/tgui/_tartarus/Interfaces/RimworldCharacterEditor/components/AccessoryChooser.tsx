import { useState } from 'react';
import {
  Box,
  Button,
  ColorBox,
  Floating,
  Input,
  Stack,
} from 'tgui-core/components';
import { classes } from 'tgui-core/react';
import { CHOOSER_CELL } from '../constants';

export function catalogEntries(
  icons?: Record<string, string>,
  fallbackNames?: string[],
): { name: string; css: string | null }[] {
  const names = new Set<string>();
  for (const name of Object.keys(icons || {})) {
    names.add(name);
  }
  for (const name of fallbackNames || []) {
    if (typeof name === 'string' && name) {
      names.add(name);
    }
  }
  return Array.from(names).map((name) => ({
    name,
    css: icons?.[name] || null,
  }));
}

export function AccessoryArt(props: { css: string | null; name: string }) {
  if (props.css) {
    return (
      <Box
        className={classes([
          'preferences32x32',
          props.css,
          'RimworldCharacterEditor__chooserArt',
        ])}
      />
    );
  }
  return (
    <Box className="RimworldCharacterEditor__chooserLabel">{props.name}</Box>
  );
}

export function AccessoryChooser(props: {
  slot?: string;
  name: string;
  icons?: Record<string, string>;
  fallbackNames?: string[];
  selected: string;
  onSelect: (value: string) => void;
  color?: string;
  onPickColor?: () => void;
}) {
  const [searchText, setSearchText] = useState('');
  const entries = catalogEntries(props.icons, props.fallbackNames);
  const query = searchText.toLowerCase();
  const visible = query
    ? entries.filter((entry) => entry.name.toLowerCase().includes(query))
    : entries;
  const selected = entries.find((entry) => entry.name === props.selected) ||
    entries.find((entry) => entry.name === 'Nude') ||
    entries.find((entry) => entry.name === 'Jumpsuit') ||
    entries[0] || {
      name: props.name,
      css: props.icons?.[props.selected] || null,
    };

  return (
    <Floating
      stopChildPropagation
      placement="right-start"
      content={
        <Box className="RimworldCharacterEditor__chooser">
          <Stack fill vertical g={0}>
            <Stack.Item>
              <Box className="RimworldCharacterEditor__chooserHeader">
                <Box className="RimworldCharacterEditor__sectionTitle">
                  Select {props.name.toLowerCase()}
                </Box>
                {!!props.onPickColor && (
                  <Button tooltip="Color" onClick={props.onPickColor}>
                    <ColorBox color={props.color || '#ffffff'} />
                  </Button>
                )}
              </Box>
              <Input
                autoFocus
                fluid
                placeholder="Search..."
                value={searchText}
                onChange={setSearchText}
              />
            </Stack.Item>
            <Stack.Item grow>
              <Box className="RimworldCharacterEditor__chooserGrid">
                {visible.map((entry) => (
                  <Button
                    key={entry.name}
                    selected={entry.name === props.selected}
                    tooltip={entry.name}
                    tooltipPosition="right"
                    className="RimworldCharacterEditor__chooserCell"
                    onClick={() => props.onSelect(entry.name)}
                  >
                    <AccessoryArt css={entry.css} name={entry.name} />
                  </Button>
                ))}
              </Box>
            </Stack.Item>
          </Stack>
        </Box>
      }
    >
      <div>
        <Button
          className={classes([
            'RimworldCharacterEditor__chooserBtn',
            props.slot && `RimworldCharacterEditor__chooserBtn--${props.slot}`,
          ])}
          tooltip={props.name}
          tooltipPosition="right"
          position="relative"
          style={{
            height: `${CHOOSER_CELL}px`,
            width: `${CHOOSER_CELL}px`,
          }}
        >
          <AccessoryArt
            css={selected.css}
            name={selected.css ? selected.name : props.name}
          />
        </Button>
      </div>
    </Floating>
  );
}
