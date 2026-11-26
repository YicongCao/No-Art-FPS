import { describe, expect, it } from 'vitest';
import { MAP_ORDER, MAPS } from '../maps/index.ts';

const GUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;

describe.each(MAP_ORDER)('ported map data: %s', (id) => {
  const map = MAPS[id];

  it('imports every authored visual with a resolvable GUID and rigid transform', () => {
    expect(map.visuals.length).toBeGreaterThan(0);
    for (const visual of map.visuals) {
      expect(visual.guid, visual.name).toMatch(GUID);
      expect(visual.pos.every(Number.isFinite), visual.name).toBe(true);
      expect(visual.scale.every((value) => value > 0), visual.name).toBe(true);
      expect(Math.abs(Math.hypot(...visual.quat) - 1), visual.name).toBeLessThan(1e-3);
    }
  });

  it('translates every authored static body into a positive-half-extent box', () => {
    expect(map.colliders.length).toBeGreaterThan(0);
    for (const box of map.colliders) {
      expect(box.half.some((value) => !(value > 0)), box.name).toBe(false);
      expect(box.pos.every(Number.isFinite), box.name).toBe(true);
      expect(Math.abs(Math.hypot(...box.quat) - 1), box.name).toBeLessThan(1e-3);
    }
  });

  it('stands the player on a collider at the authored start', () => {
    const [x, y, z] = map.start;
    expect([x, y, z].every(Number.isFinite)).toBe(true);
    const support = map.colliders.filter(
      (box) =>
        Math.abs(x - box.pos[0]) <= box.half[0] &&
        Math.abs(z - box.pos[2]) <= box.half[2] &&
        box.pos[1] - box.half[1] <= y &&
        y <= box.pos[1] + box.half[1] + 0.35,
    );
    expect(support.length).toBeGreaterThan(0);
  });

  it('keeps away-from-player spawn points for openings, reinforcements and respawns', () => {
    const spawns = [...map.openings, ...map.reinforcements];
    expect(map.openings.length).toBeGreaterThan(0);
    expect(map.reinforcements.length).toBeGreaterThan(0);
    expect(map.respawns.length).toBeGreaterThan(0);
    const reachable = spawns.filter(([x, , z]) => Math.hypot(x - map.start[0], z - map.start[2]) >= 8);
    expect(reachable.length).toBeGreaterThanOrEqual(spawns.length / 2);
  });

  it('names the map and its combat loop', () => {
    expect(map.title.length).toBeGreaterThan(0);
    expect(map.music).toMatch(GUID);
  });

  it('ports the authored environment colour and ambient energy', () => {
    const { background, ambient, ambientEnergy } = map.environment;
    expect(background.every((value) => value >= 0 && value <= 1)).toBe(true);
    expect(ambient.every((value) => value >= 0 && value <= 1)).toBe(true);
    expect(ambientEnergy).toBeGreaterThan(0);
    expect(ambientEnergy).toBeLessThanOrEqual(4);
  });
});
