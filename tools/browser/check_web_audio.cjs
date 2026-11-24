// Exercise the production export in Chromium with a mobile Safari UA, not an iPhone simulation of its audio stack.
const assert = require('node:assert/strict');
const { chromium } = require(process.env.PLAYWRIGHT_MODULE || 'playwright');

async function main() {
  const [address, screenshot] = process.argv.slice(2);
  assert(address, 'Usage: node tools/browser/check_web_audio.cjs <web-url> [results.png]');
  const url = new URL(address);
  url.searchParams.set('perf', '1');
  const browser = await chromium.launch({ executablePath: process.env.CHROME_BIN, headless: true });
  try {
    const context = await browser.newContext({ viewport: { width: 844, height: 390 }, hasTouch: true, isMobile: true,
      userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Mobile/15E148 Safari/604.1' });
    await context.addInitScript(origin => {
      if (location.origin !== origin) return;
      localStorage.setItem('no-art-fps.title.v1', JSON.stringify({ id: 'last_ferry' }));
      // Retain the real contexts so we can deliberately interrupt them. No runtime patch in the export.
      window.testAudioContexts = {};
      const Audio = window.AudioContext;
      window.AudioContext = class extends Audio {
        constructor(options) {
          super(options);
          window.testAudioContexts[options?.latencyHint === 'interactive' ? 'shot' : 'mixer'] = this;
        }
      };
    }, url.origin);
    const page = await context.newPage();
    const errors = [];
    page.on('pageerror', e => errors.push(String(e)));
    page.on('console', msg => {
      if (msg.type() === 'error' || /SCRIPT ERROR|ERROR:|GL_INVALID_|CONTEXT_LOST/.test(msg.text())) errors.push(msg.text());
    });
    const state = value => page.waitForFunction(value => document.body.dataset.game === value, value, { timeout: 120_000 });
    const frame = async ({ elapsed = 0, before = 1000, seeks = 0, started = 0 } = {}) => (await page.waitForFunction(args => {
      const sample = JSON.parse(document.querySelector('#frame-diagnostics')?.textContent || '{}').engine?.at(-1);
      if (sample?.elapsed >= args.elapsed && sample.elapsed < args.before &&
          sample.music?.seeks >= args.seeks && sample.audio?.started >= args.started) return sample;
    }, { elapsed, before, seeks, started }, { polling: 150, timeout: elapsed >= 45 ? 90_000 : 30_000 })).jsonValue();
    const audio = () => page.evaluate(() => window.noArtAudio.snapshot());
    await page.goto(url.href, { waitUntil: 'domcontentloaded', timeout: 90_000 });
    await page.locator('#loading').waitFor({ state: 'hidden', timeout: 120_000 });
    await state('TITLE');
    if (await page.locator('#gyro-panel').isVisible()) await page.locator('[data-gyro-touch]:visible').first().tap();
    if (await page.locator('#toolbar-tip').isVisible()) await page.locator('#toolbar-tip-ignore').tap();
    assert(await page.evaluate(() => window.noArtMobile && window.noArtMobileAudio));
    const fire = await page.locator('#title-safe-area').evaluate(node => {
      const safe = node.getBoundingClientRect(), scale = Math.min(innerWidth / 960, innerHeight / 540);
      return { x: safe.left + 130 * scale, y: safe.bottom - 50 * scale };
    });
    await page.touchscreen.tap(fire.x, fire.y);
    await state('RUNNING');
    const start = await frame({ elapsed: 1 });
    assert.equal(start.map, 'last_ferry');
    assert.equal(start.audio.state, 'running');
    const cdp = await context.newCDPSession(page);
    async function fireFor(ms) {
      const box = await page.locator('#fire').boundingBox();
      await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [
        { x: box.x + box.width / 2, y: box.y + box.height / 2 } ] });
      await page.waitForTimeout(ms);
      await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
    }
    await fireFor(450);
    await frame({ started: 2 });
    await page.evaluate(() => window.testAudioContexts.mixer.suspend());
    await frame({ elapsed: start.elapsed + 2.5 });
    await page.evaluate(() => window.testAudioContexts.mixer.resume());
    const corrected = await frame({ seeks: 1 });
    assert.equal(corrected.music.origin, 0);
    const settled = await frame({ elapsed: corrected.elapsed + 6 });
    assert.ok(Math.abs(settled.music.driftMs) < 250, 'The original cue returns within the drift threshold');
    assert.equal(settled.music.seeks, 1, 'The interruption needed only one correction');
    const frenzy = await frame({ elapsed: 46 });
    assert.ok(Math.abs(frenzy.music.origin - 45) < .05, 'Phase change establishes a new music origin');
    await state('RESULTS');
    if (screenshot) await page.screenshot({ path: screenshot });
    const results = await audio();
    assert.equal(results.active, 0);
    // Automated Chromium keeps tabs visible. Inject the lifecycle events into
    // the real page; the Web Audio context and touch input are not mocked.
    async function visibility(hidden) {
      await page.evaluate(hidden => {
        Object.defineProperty(document, 'hidden', { configurable: true, value: hidden });
        window.dispatchEvent(new Event(hidden ? 'blur' : 'focus'));
        document.dispatchEvent(new Event('visibilitychange'));
      }, hidden);
    }
    for (let i = 0; i < 2; i++) {
      await visibility(true);
      await page.evaluate(() => window.testAudioContexts.shot.suspend());
      await page.waitForTimeout(350);
      await visibility(false);
      assert.equal(await page.evaluate(() => document.body.dataset.game), 'RESULTS');
    }
    await page.evaluate(() => { delete document.hidden; });
    const returned = await audio();
    assert.ok(returned.clears > results.clears, 'Visibility/blur events clear the old nodes');
    assert.equal(returned.started, results.started, 'No stale shots replay on foreground');
    // Simulate a context that needs a gesture, even if Chromium resumes on its own on tab return.
    await page.evaluate(() => window.testAudioContexts.shot.suspend());
    const scale = 390 / 540;
    await page.touchscreen.tap(844 / 2 - 94 * scale, 390 / 2 + 174 * scale);
    await state('RUNNING');
    await cdp.send('Emulation.setCPUThrottlingRate', { rate: 3 });
    const retry = await frame({ elapsed: 1, before: 8 });
    assert.equal(retry.audio.state, 'running', 'The Retry tap resumes the gunshot context');
    await fireFor(650);
    const fired = await frame({ elapsed: retry.elapsed + 1, started: returned.started + 2 });
    await cdp.send('Emulation.setCPUThrottlingRate', { rate: 1 });
    assert.equal(fired.audio.fallback, results.fallback);
    assert.deepEqual(errors, []);
    console.log(JSON.stringify({ corrected: corrected.music, frenzy: frenzy.music, results, returned, retried: fired.audio, version: browser.version() }));
    console.log('WEB_AUDIO_BROWSER_PASS: rendered phase change, drift recovery, results, background, Retry and CPU throttle');
  } finally {
    await browser.close();
  }
}

main().catch(e => { console.error(e); process.exitCode = 1; });
