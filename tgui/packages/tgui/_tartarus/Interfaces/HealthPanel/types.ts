export type InjuryData = {
  id: string;
  name: string;
  severity: number;
  severity_text: string;
  desc?: string;
  bleed_rate: number;
  pain: number;
  disabling: boolean;
  can_treat?: boolean;
};

export type BodypartData = {
  zone: string;
  name: string;
  present: boolean;
  brute: number;
  burn: number;
  max_damage: number;
  disabled: boolean;
  bleed_rate: number;
  injuries: InjuryData[];
};

export type OrganData = {
  present: boolean;
  health: number;
  failing: boolean;
  functional?: boolean;
  status: string;
  beating?: boolean;
  oxygen?: number;
  perfusion?: number;
  state?: HeartState;
  rhythm?: RhythmType;
  rate?: number;
  contractility?: number;
  stroke_efficiency?: number;
  cardiac_output?: number;
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
  | 'asystole'
  | 'ventricular_tachycardia'
  | 'pvc';

export type HeartState = 'missing' | 'beating' | 'failing' | 'stopped' | 'cpr';

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
  cpr: boolean;
};

export type CardiogramData = {
  rhythm: RhythmType;
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
};

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
  can_see_full: boolean;
};
