import { CLOTHING_DEFAULTS, DEFAULT_CLOTHING } from './constants';
import type {
  RimworldCharacterEditorData,
  RwClothingChooser,
  RwXenogeneDef,
} from './types';

export function asStringMap(
  value: unknown,
): Record<string, string> | undefined {
  if (!value || typeof value !== 'object') {
    return undefined;
  }
  const result: Record<string, string> = {};
  if (Array.isArray(value)) {
    for (const entry of value) {
      if (Array.isArray(entry) && entry[0] && entry[1]) {
        result[String(entry[0])] = String(entry[1]);
      }
    }
  } else {
    for (const [key, mapped] of Object.entries(
      value as Record<string, unknown>,
    )) {
      if (typeof mapped === 'string' && mapped.length) {
        result[key] = mapped;
      }
    }
  }
  return Object.keys(result).length ? result : undefined;
}

export function isPortraitPng(value: unknown): value is string {
  return (
    typeof value === 'string' &&
    value.length > 32 &&
    value !== 'error' &&
    !value.startsWith('{')
  );
}

export function splitColonistName(profile: {
  firstName?: string;
  lastName?: string;
  name?: string;
}) {
  if (profile.firstName || profile.lastName) {
    return {
      first: profile.firstName || '',
      last: profile.lastName || '',
    };
  }
  const parts = (profile.name || '').trim().split(/\s+/).filter(Boolean);
  if (parts.length <= 1) {
    return { first: parts[0] || '', last: '' };
  }
  return {
    first: parts.slice(0, -1).join(' '),
    last: parts[parts.length - 1] || '',
  };
}

export function slotDisplayName(profile: {
  firstName?: string;
  lastName?: string;
  name: string;
}) {
  const { first, last } = splitColonistName(profile);
  return [first, last].filter(Boolean).join(' ') || profile.name;
}

export function mergeChoosers(fromServer?: RwClothingChooser[]) {
  const byId = new Map(
    DEFAULT_CLOTHING.map((chooser) => [chooser.id, chooser]),
  );
  for (const chooser of fromServer || []) {
    byId.set(chooser.id, { ...byId.get(chooser.id), ...chooser });
  }
  const ids = DEFAULT_CLOTHING.map((chooser) => chooser.id);
  for (const chooser of fromServer || []) {
    if (!ids.includes(chooser.id)) {
      ids.push(chooser.id);
    }
  }
  return ids
    .filter((id) => id !== 'backpack' && id !== 'jumpsuit')
    .map((id) => byId.get(id)!);
}

export function clothingIconsFor(
  data: RimworldCharacterEditorData,
  thumbsKey: string,
  prefIcons: Record<string, Record<string, string>>,
) {
  return (
    asStringMap(data.clothingIcons?.[thumbsKey]) ||
    prefIcons[thumbsKey] ||
    (thumbsKey === 'hair' ? asStringMap(data.hairIcons) : undefined) ||
    (thumbsKey === 'underwear' ? asStringMap(data.underwearIcons) : undefined)
  );
}

export function selectedClothing(
  data: RimworldCharacterEditorData,
  id: string,
) {
  return (
    data.clothing?.[id] ||
    (typeof (data as Record<string, unknown>)[id] === 'string'
      ? ((data as Record<string, unknown>)[id] as string)
      : undefined) ||
    CLOTHING_DEFAULTS[id] ||
    ''
  );
}

export function selectedClothingColor(
  data: RimworldCharacterEditorData,
  id: string,
) {
  return (
    data.clothingColors?.[id] ||
    (id === 'hairstyle' ? data.hairColor : undefined) ||
    (id === 'facial' ? data.facialHairColor : undefined) ||
    (id === 'underwear' ? data.underwearColor : undefined) ||
    (id === 'undershirt' ? data.undershirtColor : undefined) ||
    (id === 'bra' ? data.braColor : undefined) ||
    (id === 'socks' ? data.socksColor : undefined)
  );
}

export function geneById(defs: RwXenogeneDef[], id: string) {
  return defs.find((gene) => gene.id === id);
}

export function genesFromIds(defs: RwXenogeneDef[], ids: string[]) {
  return ids
    .map((id) => geneById(defs, id))
    .filter((gene): gene is RwXenogeneDef => !!gene);
}

export function sumGeneStats(genes: RwXenogeneDef[]) {
  let complexity = 0;
  let metabolic = 0;
  for (const gene of genes) {
    complexity += gene.complexity ?? 1;
    metabolic += gene.metabolicEfficiency ?? 0;
  }
  return { complexity, metabolic };
}

export function hungerRate(metabolic: number) {
  return Math.max(45, Math.round((1 - metabolic * 0.1) * 100));
}

export function formatMetabolic(value: number) {
  if (value > 0) {
    return `+${value}`;
  }
  return `${value}`;
}

export function geneConflicts(gene: RwXenogeneDef, other: RwXenogeneDef) {
  if (gene.id === other.id) {
    return false;
  }
  if ((gene.incompatibleWith || []).includes(other.id)) {
    return true;
  }
  if ((other.incompatibleWith || []).includes(gene.id)) {
    return true;
  }
  return !!(
    gene.incompatibilityGroup &&
    gene.incompatibilityGroup === other.incompatibilityGroup
  );
}

export function conflictingGeneIds(
  gene: RwXenogeneDef,
  ownedIds: string[],
  defs: RwXenogeneDef[],
) {
  return ownedIds.filter((id) => {
    const other = geneById(defs, id);
    return !!other && geneConflicts(gene, other);
  });
}

export function geneValueLabel(
  gene: RwXenogeneDef,
  values?: Record<string, unknown>,
) {
  const raw = values?.[gene.id];
  if (gene.option?.kind === 'tricolor' && Array.isArray(raw)) {
    return raw.map((piece) => String(piece)).join(' ');
  }
  if (raw === undefined || raw === null || raw === '') {
    return '';
  }
  return String(raw);
}

export function toPngSrc(value: string) {
  if (value.startsWith('data:')) {
    return value;
  }
  return `data:image/png;base64,${value}`;
}
