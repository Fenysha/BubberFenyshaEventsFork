export type InjuryData = {
  id: string;
  name: string;
  severity: number;
  severity_text: string;
  bleed_rate: number;
  pain: number;
  disabling: boolean;
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
  status: string;
  beating?: boolean;
};

// в types.ts
export type RhythmType =
  | 'normal'
  | 'bradycardia'
  | 'tachycardia'
  | 'arrhythmia'
  | 'fibrillation'
  | 'asystole'
  | 'ventricular_tachycardia'
  | 'pvc';

export type HeartbeatData = {
  rate: number;
  rhythm: RhythmType;
  strength: number;
};

export type CardiogramData = {
  rhythm: RhythmType;
  alert: string | null;
  /** Optional: 0–1, signal noise */
  noise?: number;
  /** Optional: 0–1, blend to flatline */
  flatline?: number;
};

export type LungsSideData = {
  fill_blood: number;
  fill_fluid: number;
  collapsed: boolean;
  functional: boolean;
};

export type HealthPanelData = {
  parameters: {
    consciousness: number;
    pain: number;
    shock: number;
    heartbeat: HeartbeatData;
    breathing: {
      rate: number;
      effective: boolean;
      oxygenation: number;
    };
    movement: {
      can_stand: boolean;
      can_walk: boolean;
    };
    bleed_rate: number;
  };
  cardiogram: CardiogramData;
  lungs: {
    left: LungsSideData;
    right: LungsSideData;
  };
  bodyparts: Record<string, BodypartData>;
  organs: {
    brain: OrganData;
    heart: OrganData;
    lungs: OrganData;
  };
  can_see_full: boolean;
};
