// Run: pnpm exec forgeax project play scripts/playthrough.mjs --require-ui --json
// `project play` starts a temporary game, waits until input is open, runs this
// module with real browser input, then applies the runtime gate to the final
// frame. Read projections come from assets/player/player.ts
// (`no-art-fps.player`) and assets/fps/fps.ts (`no-art-fps.run`).

const RUN = 'no-art-fps.run';
const PLAYER = 'no-art-fps.player';
const LOOK_SENSITIVITY = 0.0022;
const CENTER = [0.5, 0.5];

/** @param {import('@forgeax/engine/devkit').PlayContext} play */
export default async function playthrough(play) {
  const start = await play.step('spawn', async () => {
    await play.screenshot('spawn');
    return play.state(RUN);
  });

  await play.step('lock', async () => {
    await play.mouse.click(CENTER);
    return play.waitFor((state) => state.phase === 'running', { read: RUN, timeoutMs: 20_000 });
  });

  let origin;
  const walked = await play.step('walk', async () => {
    origin = await play.state(PLAYER);
    const moved = await play.keyboard.hold(
      'KeyW',
      (state) => Math.hypot(
        state.position[0] - origin.position[0],
        state.position[2] - origin.position[2],
      ) > 0.5,
      { read: PLAYER },
    );
    if (!moved) throw new Error('player did not move');
    return moved;
  });

  const size = play.page.viewportSize() ?? { width: 1280, height: 720 };
  let cursor = [size.width / 2, size.height / 2];
  const look = async (dx, dy) => {
    const x = Math.min(size.width - 2, Math.max(2, cursor[0] + dx));
    const y = Math.min(size.height - 2, Math.max(2, cursor[1] + dy));
    if (x === cursor[0] && y === cursor[1]) return;
    cursor = [x, y];
    await play.page.mouse.move(x, y);
  };

  const aimAtNearest = async () => {
    for (let attempt = 0; attempt < 80; attempt += 1) {
      const run = await play.state(RUN);
      const player = await play.state(PLAYER);
      if (!run.aim) return null;
      const dYaw = run.aim.yaw - player.camera.yaw;
      const dPitch = run.aim.pitch - player.camera.pitch;
      if (Math.abs(dYaw) < 0.01 && Math.abs(dPitch) < 0.01) return run.aim;
      await look(
        Math.max(-110, Math.min(110, dYaw / LOOK_SENSITIVITY)),
        Math.max(-110, Math.min(110, dPitch / LOOK_SENSITIVITY)),
      );
      await play.wait(30);
    }
    throw new Error('could not align the crosshair with the nearest enemy');
  };

  const shot = await play.step('shoot', async () => {
    for (let burst = 0; burst < 6; burst += 1) {
      await aimAtNearest();
      await play.page.mouse.down();
      const after = await play.advance(0.8, { read: RUN });
      await play.page.mouse.up();
      if (after.kills > 0) return after;
    }
    throw new Error('firing did not score a kill');
  });

  await play.step('results', async () => {
    const ended = await play.advance(59.5, { read: RUN });
    if (ended.phase === 'results') return ended;
    return play.waitFor((state) => state.phase === 'results', { read: RUN, timeoutMs: 20_000 });
  });
  await play.screenshot('results');

  await play.step('restart', async () => {
    const target = await play.page.evaluate(() => {
      const find = (root) => {
        for (const element of root.querySelectorAll('*')) {
          const shadow = element.shadowRoot;
          if (!shadow) continue;
          const button = shadow.querySelector('[data-ui-part="restart"]');
          if (button && !button.hidden) {
            const box = button.getBoundingClientRect();
            return { x: box.left + box.width / 2, y: box.top + box.height / 2 };
          }
          const nested = find(shadow);
          if (nested) return nested;
        }
        return null;
      };
      const canvas = document.querySelector('canvas');
      const point = find(document);
      if (!canvas || !point) return null;
      const box = canvas.getBoundingClientRect();
      return { x: (point.x - box.left) / box.width, y: (point.y - box.top) / box.height };
    });
    if (!target) throw new Error('restart button is not reachable');
    await play.mouse.click([target.x, target.y]);
    return play.waitFor((state) => state.phase === 'ready', { read: RUN, timeoutMs: 10_000 });
  });
  await play.screenshot('restarted');

  return {
    startPhase: start.phase,
    travelled: Number(Math.hypot(
      walked.position[0] - origin.position[0],
      walked.position[2] - origin.position[2],
    ).toFixed(2)),
    kills: shot.kills,
    enemies: shot.enemies,
    ammo: shot.ammo,
  };
}
