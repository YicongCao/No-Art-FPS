import { MAP_MUSIC } from '../assets.ts';
import type { MapCollider, MapPoint, MapVisual } from './types.ts';
import * as bbOffice from './bb_office.ts';
import * as sandgate from './sandgate.ts';

export interface MapDefinition {
  readonly id: string;
  readonly title: string;
  readonly visuals: readonly MapVisual[];
  readonly colliders: readonly MapCollider[];
  readonly start: MapPoint;
  readonly openings: readonly MapPoint[];
  readonly reinforcements: readonly MapPoint[];
  readonly respawns: readonly MapPoint[];
  readonly music: string;
}

export const MAP_ORDER = ['sandgate', 'bb_office'] as const;
export type MapId = (typeof MAP_ORDER)[number];

export const MAPS: Record<MapId, MapDefinition> = {
  sandgate: {
    id: sandgate.MAP_ID,
    title: sandgate.MAP_TITLE,
    visuals: sandgate.MAP_VISUALS,
    colliders: sandgate.MAP_COLLIDERS,
    start: sandgate.PLAYER_START,
    openings: sandgate.OPENING_POINTS,
    reinforcements: sandgate.REINFORCEMENT_POINTS,
    respawns: sandgate.RESPAWN_POINTS,
    music: MAP_MUSIC.sandgate,
  },
  bb_office: {
    id: bbOffice.MAP_ID,
    title: bbOffice.MAP_TITLE,
    visuals: bbOffice.MAP_VISUALS,
    colliders: bbOffice.MAP_COLLIDERS,
    start: bbOffice.PLAYER_START,
    openings: bbOffice.OPENING_POINTS,
    reinforcements: bbOffice.REINFORCEMENT_POINTS,
    respawns: bbOffice.RESPAWN_POINTS,
    music: MAP_MUSIC.bb_office,
  },
};
