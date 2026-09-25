export type RwProfile = {
  slot: number;
  name: string;
  firstName?: string;
  lastName?: string;
  nickname?: string;
  empty: boolean;
  role?: string;
  portrait?: string | null;
};

export type RwSpeciesPerk = {
  type: string;
  name: string;
  desc: string;
};

export type RwSpeciesDef = {
  id: string;
  name: string;
  label?: string;
  subtitle?: string;
  path: string;
  usesSkintones: boolean;
  desc?: string;
  lore?: string;
  innateXenogenes?: string[];
  perks?: RwSpeciesPerk[];
};

export type RwSkillDef = {
  id: string;
  name: string;
  desc: string;
  editable: boolean;
};

export type RwSkillRow = {
  id: string;
  bought: number;
  bonus: number;
  level: number;
  passion: number;
};

export type RwXenogeneOption = {
  kind: 'accessory' | 'choiced' | 'numeric' | 'tricolor';
  choices?: string[];
  min?: number;
  max?: number;
  step?: number;
  defaultOption?: unknown;
};

export type RwXenogeneDef = {
  id: string;
  name: string;
  desc: string;
  category: string;
  supportedSpecies: string[];
  effects?: string[];
  partKey?: string | null;
  partName?: string | null;
  complexity?: number;
  metabolicEfficiency?: number;
  icon?: string | null;
  iconState?: string | null;
  iconBg?: string | null;
  iconSrc?: string | null;
  iconBgSrc?: string | null;
  negative?: boolean;
  pointCost?: number;
  inheritableCost?: number;
  incompatibleWith?: string[];
  incompatibilityGroup?: string | null;
  option?: RwXenogeneOption | null;
};

export type RwNamedDef = {
  id: string;
  name: string;
  desc: string;
};

export type RwPricedDef = {
  id: string;
  name: string;
  desc: string;
  cost: number;
  positive?: boolean;
};

export type PrefFieldKind =
  | 'choiced'
  | 'color'
  | 'tricolor'
  | 'tri_color'
  | 'toggle'
  | 'numeric'
  | 'text';

export type PrefField = {
  key: string;
  name: string;
  kind: PrefFieldKind;
  value: unknown;
  choices?: string[];
  displayNames?: Record<string, string>;
  min?: number;
  max?: number;
  step?: number;
};

export type RwClothingChooser = {
  id: string;
  name: string;
  thumbs: string;
  hasColor?: boolean;
  choices?: string[];
};

export type RimworldCharacterEditorData = {
  characterPreviewView?: string | null;
  budgetMax: number;
  skillManualMax: number;
  skillMax: number;
  hairstyles: string[];
  hairIcons?: Record<string, string> | [string, string][];
  underwearIcons?: Record<string, string> | [string, string][];
  clothingDefs?: RwClothingChooser[];
  clothingIcons?: Record<
    string,
    Record<string, string> | [string, string][]
  >;
  clothing?: Record<string, string>;
  clothingColors?: Record<string, string>;
  skinTones: string[];
  skinToneNames: Record<string, string>;
  skinToneHex?: Record<string, string>;
  screamTypes?: string[];
  laughTypes?: string[];
  blooperTypes?: string[];
  blooperNames?: Record<string, string>;
  tattoos: string[];
  hairGradients?: string[];
  facialGradients?: string[];
  bodySizeMin?: number;
  bodySizeMax?: number;
  speciesDefs: RwSpeciesDef[];
  skillDefs: RwSkillDef[];
  xenogeneDefs: RwXenogeneDef[];
  childhoods: RwNamedDef[];
  adulthoods: RwNamedDef[];
  traitDefs: RwPricedDef[];
  loadoutDefs: RwPricedDef[];
  character_preferences?: {
    species?: PrefField[];
  };
  profiles: RwProfile[];
  activeSlot: number;
  active_slot?: number;
  firstName?: string;
  nickname?: string;
  lastName?: string;
  biologicalAge?: number;
  chronologicalAge?: number;
  realName: string;
  gender: string;
  bodyType?: string;
  speciesPath: string;
  hairstyle: string;
  hairColor: string;
  facial?: string;
  facials?: string[];
  facialHairColor?: string;
  underwear?: string;
  underwearColor?: string;
  undershirt?: string;
  undershirtColor?: string;
  bra?: string;
  braColor?: string;
  socks?: string;
  socksColor?: string;
  jumpsuit?: string;
  backpack?: string;
  skinTone: string;
  mutantColor: string;
  mutantColor2?: string;
  mutantColor3?: string;
  eyeColor?: string;
  eyeColorRight?: string;
  hairGradient?: string;
  hairGradientColor?: string;
  facialGradient?: string;
  facialGradientColor?: string;
  bodySize?: number;
  customSpecies?: string;
  customSpeciesLore?: string;
  flavorText?: string;
  flavorTextNsfw?: string;
  oocNotes?: string;
  headshot?: string;
  characterScream?: string;
  characterLaugh?: string;
  chatColor?: string;
  blooperChoice?: string;
  blooperSpeed?: number;
  blooperPitch?: number;
  blooperPitchRange?: number;
  customTaste?: string;
  customSmell?: string;
  generalRecord?: string;
  medicalRecord?: string;
  securityRecord?: string;
  exploitableInfo?: string;
  backgroundInfo?: string;
  tattoo: string;
  xenogenes: string[];
  xenogeneValues?: Record<string, unknown>;
  xenogeneInheritable?: string[];
  innateXenogenes?: string[];
  childhood: string;
  adulthood: string;
  traits: string[];
  loadout: string[];
  usesSkintones: boolean;
  budgetSpent: number;
  budgetRemaining: number;
  skills: RwSkillRow[];
};
