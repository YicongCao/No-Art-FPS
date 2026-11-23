// Exercise production exports through the same controls a player uses.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { chromium } = require(process.env.PLAYWRIGHT_MODULE || 'playwright');

const roster = ['amusement_park', 'last_ferry', 'night_studio', 'sandgate', 'bb_office',
  'hogwarts', 'snowline', 'palm_house', 'ginza_station'];

function latestFrame({ map, after, position }) {
  if (document.body.dataset.game !== 'RUNNING') return false;
  const report = document.getElementById('frame-diagnostics');
  const sample = JSON.parse(report?.textContent || '{}').engine?.at(-1);
  if (sample?.map !== map || sample.elapsed < after || !sample.draws || sample.actors < 1) return false;
  if (position) {
    const coordinates = text => text.slice(1, -1).split(',').map(Number);
    const [x, , z] = coordinates(sample.player);
    const [oldX, , oldZ] = coordinates(position);
    if (Math.hypot(x - oldX, z - oldZ) < 0.25) return false;
  }
  return sample;
}

async function play(browser, address, map, mode, out) {
  const touch = mode === 'touch';
  const viewport = touch ? { width: 844, height: 390 } : { width: 1280, height: 720 };
  const url = new URL(address);
  url.searchParams.set('perf', '1');
  const context = await browser.newContext({ viewport, hasTouch: touch, isMobile: touch });
  const errors = [];
  try {
    // Restore an existing selection, then start through the visible title screen.
    await context.addInitScript(({ id, origin }) => {
      if (window === window.top && location.origin === origin)
        localStorage.setItem('no-art-fps.title.v1', JSON.stringify({ id }));
    }, { id: map, origin: url.origin });
    const page = await context.newPage();
    page.on('pageerror', error => errors.push(String(error)));
    page.on('console', message => {
      const text = message.text();
      if (message.type() === 'error' || /SCRIPT ERROR|ERROR:|GL_INVALID_|CONTEXT_LOST/.test(text)) errors.push(text);
    });
    const phase = (states, timeout = 30_000) => page.waitForFunction(
      allowed => allowed.includes(document.body.dataset.game), states, { timeout });
    const clickAt = (x, y) => touch ? page.touchscreen.tap(x, y) : page.mouse.click(x, y);
    const sample = async (options = {}) => (await page.waitForFunction(latestFrame,
      { map, after: 1, ...options }, { polling: 150, timeout: 20_000 })).jsonValue();
    await page.goto(url.href, { waitUntil: 'domcontentloaded', timeout: 90_000 });
    await page.locator('#loading').waitFor({ state: 'hidden', timeout: 120_000 });
    await phase(['TITLE']);
    if (touch && await page.locator('#gyro-panel').isVisible())
      await page.locator('[data-gyro-touch]:visible').first().tap();
    if (await page.locator('#toolbar-tip').isVisible()) await page.locator('#toolbar-tip-ignore').click();
    assert.equal(await page.evaluate(() => window.noArtMobile), touch);
    if (out) await page.screenshot({ path: path.join(out, `${map}-${mode}-title.png`) });
    // FIRE is drawn in the canvas; calculate its center from the title safe area.
    const fire = await page.locator('#title-safe-area').evaluate((node, mobile) => {
      const safe = node.getBoundingClientRect();
      const scale = mobile ? Math.min(innerWidth / 960, innerHeight / 540)
        : Math.min(innerWidth / 1440, innerHeight / 810);
      return { x: safe.left + scale * (mobile ? 130 : 150),
        y: safe.bottom - scale * (mobile ? 50 : 56) };
    }, touch);
    await clickAt(fire.x, fire.y);
    await phase(touch ? ['RUNNING'] : ['CAPTURING', 'RUNNING']);
    if (!touch && await page.evaluate(() => document.body.dataset.game === 'CAPTURING'))
      await page.mouse.click(viewport.width / 2, viewport.height / 2);
    await phase(['RUNNING']);
    const before = await sample();
    if (touch) {
      const aim = page.locator('#aim');
      await aim.tap();
      await aim.and(page.locator('[aria-pressed="true"]')).waitFor();
      const cdp = await context.newCDPSession(page);
      const stick = await page.locator('#stick').boundingBox();
      const trigger = await page.locator('#fire').boundingBox();
      const center = (box, id) => ({ x: box.x + box.width / 2, y: box.y + box.height / 2, id });
      const start = center(stick, 1);
      const finger = center(trigger, 2);
      const send = (type, touchPoints) => cdp.send('Input.dispatchTouchEvent', { type, touchPoints });
      await send('touchStart', [start, finger]);
      await send('touchMove', [{ x: start.x + 16, y: start.y - 46, id: 1 }, finger]);
      await page.waitForTimeout(450);
      await send('touchEnd', []);
    } else {
      assert(await page.evaluate(() => document.pointerLockElement?.id === 'canvas'));
      await page.keyboard.down('KeyW');
      await page.mouse.down();
      await page.waitForTimeout(450);
      await page.mouse.up();
      await page.keyboard.up('KeyW');
    }
    const after = await sample({ after: before.elapsed + 0.5, position: before.player });
    if (out) await page.screenshot({ path: path.join(out, `${map}-${mode}-game.png`) });
    assert.deepEqual(errors, []);
    console.log(JSON.stringify({ map, mode, state: 'RUNNING', actors: after.actors,
      from: before.player, to: after.player, renderSize: after.render_size }));
  } catch (error) {
    if (errors.length) console.error(errors.join('\n'));
    throw new Error(`${map} (${mode}): ${error.message}`, { cause: error });
  } finally {
    await context.close();
  }
}

async function main() {
  const [address, out] = process.argv.slice(2);
  assert(address, 'Usage: node tools/browser/check_web_roster.cjs <web-url> [screenshot-dir]');
  const maps = process.env.MAP_ID ? [process.env.MAP_ID] : roster;
  const modes = process.env.WEB_MODE ? [process.env.WEB_MODE] : ['desktop', 'touch'];
  assert(maps.every(id => roster.includes(id)), 'Unknown MAP_ID');
  assert(modes.every(mode => ['desktop', 'touch'].includes(mode)), 'WEB_MODE must be desktop or touch');
  if (out) fs.mkdirSync(out, { recursive: true });
  const browser = await chromium.launch({ executablePath: process.env.CHROME_BIN, headless: true });
  try {
    for (const mode of modes) for (const id of maps) await play(browser, address, id, mode, out);
    console.log(`WEB_RELEASE_ROSTER_PASS: ${maps.length} maps, ${modes.join(' and ')}, Chrome ${browser.version()}`);
  } finally {
    await browser.close();
  }
}

main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
