export type TreatOption = {
  type: string;
  name: string;
  iconSrc?: string | null;
};

export type InjuryData = {
  id: string;
  name: string;
  undiagnosed_name?: string;
  severity: number;
  severity_text: string;
  desc?: string;
  examine_desc?: string;
  bleed_rate: number;
  pain: number;
  disabling: boolean;
  can_treat?: boolean;
  series?: string;
  treatment_quality?: number;
  treatment_effectiveness?: number;
  healing_progress?: number;
  treated?: boolean;
  treat_options?: TreatOption[];
};

export type BodypartData = {
  zone: string;
  name: string;
  present: boolean;

  structural_damage: number;
  skin_damage: number;
  structural_integrity: number;
  skin_integrity: number;

  max_damage: number;
  disabled: boolean;
  bleed_rate: number;
  icon?: string | null;

  iconState?: string | null;
  iconSrc?: string | null;

  sprite_id?: string;
  limb_gender?: 'm' | 'f' | string;

  injuries: InjuryData[];
};

export type OrganData = {
  present: boolean;
  health: number;
  failing: boolean;
  functional?: boolean;
  status: string;
  beating?: boolean;
  fibrillating?: boolean;
  oxygen?: number;
  perfusion?: number;
  state?: HeartState;
  rhythm?: RhythmType;
  rate?: number;
  contractility?: number;
  stroke_efficiency?: number;
  cardiac_output?: number;
  preload?: number;
  cpr?: boolean;
  ventilation?: number;
  fluid_ratio?: number;
  oxygenation?: number;
};

export type RhythmType =
  | 'normal'
  | 'bradycardia'
  | 'tachycardia'
  | 'arrhythmia'
  | 'fibrillation'
  | 'ventricular_fibrillation'
  | 'asystole'
  | 'ventricular_tachycardia'
  | 'pvc';

export type HeartState =
  | 'missing'
  | 'beating'
  | 'failing'
  | 'stopped'
  | 'cpr'
  | 'fibrillating';

export type HeartbeatData = {
  rate: number;
  rhythm: RhythmType;
  strength: number;
  contractility: number;
  stroke_efficiency: number;
  cardiac_output: number;
  target_rate: number;
  state: HeartState;
  beating: boolean;
  fibrillating: boolean;
  cpr: boolean;
  preload: number;
};

export type CardiogramData = {
  rhythm: RhythmType | string;
  alert: string | null;
  noise?: number;
  flatline?: number;
};

export type BreathingData = {
  effective: boolean;
  oxygenation: number;
  ventilation: number;
  fluid: number;
  fluid_ratio: number;
  functional: boolean;
};

export type CirculationData = {
  blood_volume: number;
  blood_ratio: number;
  blood_pressure: number;
  perfusion: number;
  heart_output: number;
};

export type LungsData = {
  present: boolean;
  health: number;
  functional: boolean;
  ventilation: number;
  oxygenation: number;
  fluid: number;
  fluid_ratio: number;
  iconSrc?: string | null;
};

export type ViewerAccess = 0 | 1 | 2 | 3;

export type HealthPanelData = {
  parameters: {
    consciousness: number;
    pain: number;
    shock: number;
    heartbeat: HeartbeatData;
    breathing: BreathingData;
    circulation: CirculationData;
    movement: {
      can_stand: boolean;
      can_walk: boolean;
      slowdown: number;
    };
    bleed_rate: number;
  };

  cardiogram: CardiogramData;
  lungs: LungsData;

  bodyparts: Record<string, BodypartData>;

  organs: {
    brain: OrganData;
    heart: OrganData;
    lungs: OrganData;
  };

  viewer_access: ViewerAccess;
  can_see_full: boolean;
  /** False for ghosts — hide treat buttons */
  can_treat: boolean;
  is_self: boolean;
  /** Name of the person being examined */
  subject_name?: string;
};
