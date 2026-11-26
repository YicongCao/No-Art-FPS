import { describe, expect, it } from 'vitest';
import {
  MAP_COLLIDERS,
  MAP_VISUALS,
  OPENING_POINTS,
  PLAYER_START,
  REINFORCEMENT_POINTS,
  RESPAWN_POINTS,
} from '../map-data.ts';

const GUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;

describe('ported sandgate map data', () => {
  it('imports every authored visual with a resolvable GUID and rigid transform', () => {
    expect(MAP_VISUALS.length).toBe(26);
    for (const visual of MAP_VISUALS) {
      expect(visual.guid, visual.name).toMatch(GUID);
      expect(visual.pos, visual.name).toHaveLength(3);
      expect(visual.quat, visual.name).toHaveLength(4);
      expect(visual.scale, visual.name).toHaveLength(3);
      expect(visual.pos.every(Number.isFinite), visual.name).toBe(true);
      expect(visual.scale.every((value) => value > 0), visual.name).toBe(true);
      expect(Math.abs(Math.hypot(...visual.quat) - 1), visual.name).toBeLessThan(1e-3);
    }
  });

  it('translates every authored static body into a positive-half-extent box', () => {
    expect(MAP_COLLIDERS.length).toBe(111);
    for (const box of MAP_COLLIDERS) {
      expect(box.half.some((value) => !(value > 0)), box.name).toBe(false);
      expect(box.pos.every(Number.isFinite), box.name).toBe(true);
      expect(Math.abs(Math.hypot(...box.quat) - 1), box.name).toBeLessThan(1e-3);
    }
  });

  it('stands the player on a collider at the authored start', () => {
    const [x, y, z] = PLAYER_START;
    expect([x, y, z].every(Number.isFinite)).toBe(true);
    const support = MAP_COLLIDERS.filter(
      (box) =>
        Math.abs(x - box.pos[0]) <= box.half[0] &&
        Math.abs(z - box.pos[2]) <= box.half[2] &&
        box.pos[1] - box.half[1] <= y &&
        y <= box.pos[1] + box.half[1] + 0.35,
    );
    expect(support.length).toBeGreaterThan(0);
  });

  it('keeps away-from-player spawn points for openings, reinforcements and respawns', () => {
    const spawns = [...OPENING_POINTS, ...REINFORCEMENT_POINTS];
    expect(OPENING_POINTS.length).toBeGreaterThan(0);
    expect(REINFORCEMENT_POINTS.length).toBeGreaterThan(0);
    expect(RESPAWN_POINTS.length).toBeGreaterThan(0);
    for (const point of [...spawns, ...RESPAWN_POINTS]) {
      expect(point).toHaveLength(3);
      expect(point.every(Number.isFinite)).toBe(true);
    }
    const reachable = spawns.filter(
      ([x, , z]) => Math.hypot(x - PLAYER_START[0], z - PLAYER_START[2]) >= 8,
    );
    expect(reachable.length).toBeGreaterThanOrEqual(spawns.length / 2);
  });
});
