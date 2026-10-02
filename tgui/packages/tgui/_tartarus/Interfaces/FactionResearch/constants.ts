export const TECH_ERAS = [
  { id: 'neolithic', label: 'Neolithic' },
  { id: 'medieval', label: 'Medieval' },
  { id: 'industrial', label: 'Industrial' },
  { id: 'spacer', label: 'Spacer' },
  { id: 'ultratech', label: 'Ultratech' },
] as const;

export type TechEra = (typeof TECH_ERAS)[number]['id'];

export const ERA_COLORS: Record<string, string> = {
  neolithic: '#c0392b',
  medieval: '#f1c40f',
  industrial: '#27ae60',
  spacer: '#3498db',
  ultratech: '#9b59b6',
};

export const ERA_COLORS_DIM: Record<string, string> = {
  neolithic: 'rgba(192, 57, 43, 0.15)',
  medieval: 'rgba(241, 196, 15, 0.12)',
  industrial: 'rgba(39, 174, 96, 0.12)',
  spacer: 'rgba(52, 152, 219, 0.12)',
  ultratech: 'rgba(155, 89, 182, 0.15)',
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
