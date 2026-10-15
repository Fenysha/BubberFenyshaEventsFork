export const TECH_ERAS = [
  { id: 'neolithic', label: 'Neolithic' },
  { id: 'medieval', label: 'Medieval' },
  { id: 'industrial', label: 'Industrial' },
  { id: 'spacer', label: 'Spacer' },
  { id: 'ultratech', label: 'Ultratech' },
] as const;

export type TechEra = (typeof TECH_ERAS)[number]['id'];

export const ERA_COLORS: Record<string, string> = {
  neolithic: '#e74c3c',
  medieval: '#f1c40f',
  industrial: '#2ecc71',
  spacer: '#3498db',
  ultratech: '#9b59b6',
};

export const ERA_COLORS_DIM: Record<string, string> = {
  neolithic: 'rgba(231, 76, 60, 0.18)',
  medieval: 'rgba(241, 196, 15, 0.14)',
  industrial: 'rgba(46, 204, 113, 0.14)',
  spacer: 'rgba(52, 152, 219, 0.14)',
  ultratech: 'rgba(155, 89, 182, 0.18)',
};

export const ERA_COLORS_GLOW: Record<string, string> = {
  neolithic: 'rgba(231, 76, 60, 0.45)',
  medieval: 'rgba(241, 196, 15, 0.4)',
  industrial: 'rgba(46, 204, 113, 0.4)',
  spacer: 'rgba(52, 152, 219, 0.45)',
  ultratech: 'rgba(155, 89, 182, 0.5)',
};

export const STATUS_COLOR = {
  researched: 'good',
  current: 'blue',
  queued: 'purple',
  available: 'default',
  locked: 'grey',
} as const;

export const STATUS_ICON = {
  researched: 'check',
  current: 'spinner',
  queued: 'clock',
  available: 'circle',
  locked: 'lock',
} as const;

export const STATUS_LABEL = {
  researched: 'Researched',
  current: 'In progress',
  queued: 'Queued',
  available: 'Available',
  locked: 'Locked',
} as const;

export type Status = keyof typeof STATUS_COLOR;

/** Soft background tints for node cards by status */
export const STATUS_BG: Record<Status, string> = {
  researched: 'rgba(39, 174, 96, 0.22)',
  current: 'rgba(52, 152, 219, 0.28)',
  queued: 'rgba(142, 68, 173, 0.22)',
  available: 'rgba(255, 255, 255, 0.06)',
  locked: 'rgba(0, 0, 0, 0.35)',
};

export const STATUS_BORDER: Record<Status, string> = {
  researched: 'rgba(46, 204, 113, 0.7)',
  current: 'rgba(52, 152, 219, 0.9)',
  queued: 'rgba(155, 89, 182, 0.7)',
  available: 'rgba(255, 255, 255, 0.18)',
  locked: 'rgba(100, 100, 100, 0.35)',
};
