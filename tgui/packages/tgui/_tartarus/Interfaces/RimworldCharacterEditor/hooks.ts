import { useEffect, useState } from 'react';
import { resolveAsset } from 'tgui/assets';
import { fetchRetry } from 'tgui-core/http';
import { PREF_JSON_KEY } from './constants';
import { asStringMap } from './utils';

export function usePrefCatalog() {
  const [icons, setIcons] = useState<Record<string, Record<string, string>>>(
    {},
  );
  const [choices, setChoices] = useState<Record<string, string[]>>({});

  useEffect(() => {
    fetchRetry(resolveAsset('preferences.json'))
      .then((response) => response.json())
      .then((raw) => {
        const json = raw as Record<
          string,
          { icons?: unknown; choices?: unknown }
        >;
        const nextIcons: Record<string, Record<string, string>> = {};
        const nextChoices: Record<string, string[]> = {};
        for (const [thumbsKey, jsonKey] of Object.entries(PREF_JSON_KEY)) {
          const iconsMap = asStringMap(json[jsonKey]?.icons);
          if (iconsMap) {
            nextIcons[thumbsKey] = iconsMap;
          }
          const names = json[jsonKey]?.choices;
          if (Array.isArray(names)) {
            nextChoices[thumbsKey] = names.filter(
              (name): name is string => typeof name === 'string' && !!name,
            );
          }
        }
        setIcons(nextIcons);
        setChoices(nextChoices);
      })
      .catch(() => {});
  }, []);

  return { icons, choices };
}

export type PrefCatalog = ReturnType<typeof usePrefCatalog>;
