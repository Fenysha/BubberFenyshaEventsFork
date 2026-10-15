export type Reward = {
  kind: 'blueprint' | 'recipe';
  name: string;
};

export type NodeEntry = {
  id: string;
  name: string;
  desc: string;
  cost: number;
  prereqs: string[];
  benches: string[];
  attachments: string[];
  flags: string[];
  rewards: Reward[];
  era: string;
  group?: string;
  ui_x: number;
  ui_y: number;
};

export type FactionOption = {
  id: string;
  name: string;
  color?: string;
  researched_count?: number;
  total_nodes?: number;
};

export type ResearchData = {
  nodes: NodeEntry[];
  researched: string[];
  current: string | null;
  progress: Record<string, number>;
  queue: string[];
  can_manage: boolean;
  bench_ready: boolean;
  bench_text: string;
  /** Admin-only fields */
  is_admin?: boolean;
  admin_view?: boolean;
  factions?: FactionOption[];
  current_faction_id?: string | null;
  current_faction_name?: string | null;
  current_faction_color?: string | null;
};
