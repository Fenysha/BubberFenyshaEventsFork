export type StorytellerProfile = {
  id: string;
  name: string;
  desc: string;
  ooc_desc: string;
  ooc_difficulty: string;
  portrait_asset?: string;
  logo_asset?: string;
};

export type StorytellerCell = {
  id: string;
  name: string;
  x: number;
  y: number;
  loaded: boolean;
};

export type StorytellerEvent = {
  id: string;
  name: string;
  description: string;
  category: string;
};

export type StorytellerPlanEntry = StorytellerEvent & {
  id: number;
  event_id: string;
  fire_day: number;
  days_until: number;
  manual: boolean;
};

export type StorytellerAdminData = {
  storytellers: StorytellerProfile[];
  active_id?: string;
  active_name: string;
  active_desc: string;
  active_ooc_desc: string;
  difficulty_multiplier: number;
  current_day: number;
  event_count: number;
  vote_active: boolean;
  cells: StorytellerCell[];
  selected_cell_id?: string;
  selected_cell?: {
    id: string;
    name: string;
    x: number;
    y: number;
    loaded: boolean;
    biome: string;
    weather: string;
    interval_override_days: number;
    has_colony: boolean;
    colonists: number;
    colony_age_days: number;
    threat_points: number;
    upcoming: StorytellerPlanEntry[];
  } | null;
  available_events: StorytellerEvent[];
};

export type DifficultyLevel = {
  value: number;
  label: string;
  tooltip: string;
  min_players: number;
};

export type StorytellerVoteStatic = {
  storytellers: StorytellerProfile[];
  difficulty_levels: DifficultyLevel[];
  min_difficulty: number;
  max_difficulty: number;
};

export type StorytellerTally = {
  id: string;
  name: string;
  count: number;
  difficulty: number;
};

export type StorytellerVoteData = StorytellerVoteStatic & {
  personal_selection?: string;
  personal_difficulty: number;
  is_open: boolean;
  can_vote: boolean;
  admin_mode: boolean;
  debug_mode: boolean;
  current_storyteller?: string;
  time_left: number;
  total_voters: number;
  voted_count: number;
  top_tallies: StorytellerTally[];
  winner_id?: string | null;
  winner_difficulty?: number | null;
};
