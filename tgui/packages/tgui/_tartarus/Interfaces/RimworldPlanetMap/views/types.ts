import type { BooleanLike } from 'tgui-core/react';
import type { PlanetCellData, PlanetMapData } from '../types';

export type PlayerSettlementInfo = {
  id: string;
  name: string;
  x: number;
  y: number;
  population: number;
  faction: string;
  icon?: string | null;
  color?: string | null;
};

export type LoadedCellInfo = {
  x: number;
  y: number;
  id?: string;
  name?: string;
};

export type SettlementViewData = {
  mode?: 'start' | 'observer';
  isLoading?: BooleanLike;
  startX?: number | null;
  startY?: number | null;
  joinSettlementId?: string | null;
  canCreate?: BooleanLike;
  canJoin?: BooleanLike;
  playerSettlements?: PlayerSettlementInfo[];
  loadedCells?: LoadedCellInfo[];
};

export type NearbyCaravanInfo = {
  id: string;
  leader: string;
  members: number;
  hasVehicle?: BooleanLike;
};

export type CaravanViewData = {
  caravanId?: string | null;
  originX?: number | null;
  originY?: number | null;
  currentX?: number | null;
  currentY?: number | null;
  destinationX?: number | null;
  destinationY?: number | null;
  canTravel?: BooleanLike;
  canEnter?: BooleanLike;
  isLeader?: BooleanLike;
  inArena?: BooleanLike;
  status?: string;
  members?: string[];
  hasVehicle?: BooleanLike;
  hasInterior?: BooleanLike;
  nearbyCaravans?: NearbyCaravanInfo[];
  pendingMerges?: string[];
  pendingAttacks?: string[];
};

export type AdminViewData = {
  roadStartX?: number | null;
  roadStartY?: number | null;
  cell?: PlanetCellData | null;
};

export type OverviewViewData = Record<string, never>;

export type SettlementMapData = PlanetMapData & {
  viewType: 'settlement';
  view?: SettlementViewData;
};

export type CaravanMapData = PlanetMapData & {
  viewType: 'caravan';
  view?: CaravanViewData;
};

export type AdminMapData = PlanetMapData & {
  viewType: 'admin';
  view?: AdminViewData;
};

export type OverviewMapData = PlanetMapData & {
  viewType: 'overview';
  view?: OverviewViewData;
};
