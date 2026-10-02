import type { RwClothingChooser } from './types';

export type TabId =
  | 'biology'
  | 'features'
  | 'persona'
  | 'possessions'
  | 'ideology';

export const TABS: { id: TabId; label: string }[] = [
  { id: 'persona', label: 'Persona' },
  { id: 'features', label: 'Features' },
  { id: 'biology', label: 'Biology' },
  { id: 'possessions', label: 'Possessions' },
  { id: 'ideology', label: 'Ideology' },
];

export const MAX_TRAITS = 3;

export const CLOTHING_DEFAULTS: Record<string, string> = {
  hairstyle: 'Bald',
  facial: 'Shaved',
  underwear: 'Nude',
  undershirt: 'Nude',
  bra: 'Nude',
  socks: 'Nude',
};

export const PREF_JSON_KEY: Record<string, string> = {
  hair: 'hairstyle_name',
  facial: 'facial_style_name',
  underwear: 'underwear',
  undershirt: 'undershirt',
  bra: 'bra',
  socks: 'socks',
};

export const DEFAULT_CLOTHING: RwClothingChooser[] = [
  { id: 'hairstyle', name: 'Hairstyle', thumbs: 'hair', hasColor: true },
  { id: 'facial', name: 'Facial hair', thumbs: 'facial', hasColor: true },
  { id: 'bra', name: 'Bra', thumbs: 'bra', hasColor: true },
  {
    id: 'undershirt',
    name: 'Undershirt',
    thumbs: 'undershirt',
    hasColor: true,
  },
  { id: 'underwear', name: 'Underwear', thumbs: 'underwear', hasColor: true },
  { id: 'socks', name: 'Socks', thumbs: 'socks', hasColor: true },
];

export const GENDER_OPTIONS = [
  { value: 'male', icon: 'mars', label: 'He/Him' },
  { value: 'female', icon: 'venus', label: 'She/Her' },
  { value: 'plural', icon: 'transgender', label: 'They/Them' },
  { value: 'neuter', icon: 'neuter', label: 'It/Its' },
] as const;

export const CHOOSER_CELL = 54;

export type StoryGrant = { skill: string; amount: number };
