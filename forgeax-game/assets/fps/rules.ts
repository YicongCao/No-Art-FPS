export const RUN_SECONDS = 60;

/** Live-enemy target copied from scripts/game.gd population_target(). */
export function populationTarget(elapsed: number): number {
  if (elapsed < 20) return 8;
  if (elapsed < 40) return 10;
  return 12;
}

/** Concurrent rushers allowed before random rusher spawns stop. */
export function rusherBudget(elapsed: number): number {
  return elapsed < 40 ? 2 : 3;
}

/** scripts/game.gd: elapsed > 8, below the rusher budget, 35% roll. */
export function wantsRusher(elapsed: number, rushers: number, roll: number): boolean {
  return elapsed > 8 && rushers < rusherBudget(elapsed) && roll < 0.35;
}
