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

export type RwSpeciesDef = {
  id: string;
  name: string;
  path: string;
  usesSkintones: boolean;
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

export type RwXenogeneDef = {
  id: string;
  name: string;
  desc: string;
  category: string;
  supportedSpecies: string[];
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
    basics?: Record<string, unknown>;
    visual?: Record<string, unknown>;
    identity?: Record<string, unknown>;
    [otherKey: string]: unknown;
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
  childhood: string;
  adulthood: string;
  traits: string[];
  loadout: string[];
  usesSkintones: boolean;
  budgetSpent: number;
  budgetRemaining: number;
  skills: RwSkillRow[];
};
