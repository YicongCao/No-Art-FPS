import { describe, expect, it } from 'vitest';
import { populationTarget, rusherBudget, wantsRusher, RUN_SECONDS } from '../rules.ts';

describe('ported round pacing', () => {
  it('keeps the sixty second run length', () => {
    expect(RUN_SECONDS).toBe(60);
  });

  it('raises the live-enemy target at twenty and forty seconds', () => {
    expect([0, 5, 19.9].map(populationTarget)).toEqual([8, 8, 8]);
    expect([20, 25, 39.9].map(populationTarget)).toEqual([10, 10, 10]);
    expect([40, 59, 60].map(populationTarget)).toEqual([12, 12, 12]);
  });

  it('allows two rushers before forty seconds and three after', () => {
    expect(rusherBudget(0)).toBe(2);
    expect(rusherBudget(39)).toBe(2);
    expect(rusherBudget(40)).toBe(3);
  });

  it('only rolls a rusher after eight seconds and below the budget', () => {
    expect(wantsRusher(8, 0, 0)).toBe(false);
    expect(wantsRusher(20, 2, 0)).toBe(false);
    expect(wantsRusher(20, 1, 0.34)).toBe(true);
    expect(wantsRusher(20, 1, 0.35)).toBe(false);
    expect(wantsRusher(45, 2, 0)).toBe(true);
    expect(wantsRusher(45, 3, 0)).toBe(false);
  });
});
