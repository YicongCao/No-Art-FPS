// Run against local Web exports with the perfbench feature. Do not publish those exports.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const { chromium } = require(process.env.PLAYWRIGHT_MODULE || 'playwright');

async function main() {
  const [address, output, mode = 'desktop', screenshot] = process.argv.slice(2);
  assert(address && output && ['desktop', 'touch'].includes(mode),
    'Usage: node tools/browser/benchmark_web.cjs <local-url> <output.json> [desktop|touch] [screenshot.png]');
  const url = new URL(address);
  assert(url.protocol === 'http:' && url.hostname === '127.0.0.1',
    'Use a local Web export served over http://127.0.0.1');
  const map = process.env.MAP_ID || 'bb_office';
  const throttle = Number(process.env.CPU_THROTTLE || 1);
  assert(Number.isFinite(throttle) && throttle >= 1, 'CPU_THROTTLE must be at least 1');
  const touch = mode === 'touch';
  const viewport = touch ? { width: 844, height: 390 } : { width: 1920, height: 1080 };
  url.searchParams.set('perf', '1');
  url.searchParams.set('map', map);
  if (touch) {
    url.searchParams.set('touch', '1');
    url.searchParams.set('bench_dpr', '3');
  }

  const browser = await chromium.launch({ executablePath: process.env.CHROME_BIN, headless: true });
  try {
    const context = await browser.newContext({ viewport, deviceScaleFactor: 1, hasTouch: touch, isMobile: touch });
    await context.addInitScript(id => {
      if (location.hostname === '127.0.0.1') localStorage.setItem('no-art-fps.title.v1', JSON.stringify({ id }));
    }, map);
    const page = await context.newPage();
    const errors = [];
    page.on('pageerror', error => errors.push(String(error)));
    page.on('console', message => {
      const text = message.text();
      if (message.type() === 'error' || /SCRIPT ERROR|ERROR:|GL_INVALID_|CONTEXT_LOST/.test(text)) errors.push(text);
    });
    const start = performance.now();
    await page.goto(url.href, { waitUntil: 'domcontentloaded', timeout: 90_000 });
    await page.locator('#loading').waitFor({ state: 'hidden', timeout: 120_000 });
    const loadMs = Math.round(performance.now() - start);
    if (touch && await page.locator('#gyro-panel').isVisible()) {
      await page.locator('[data-gyro-touch]:visible').first().tap();
    }
    if (await page.locator('#toolbar-tip').isVisible()) await page.locator('#toolbar-tip-ignore').click();
    await page.waitForFunction(() => document.body.dataset.game === 'RUNNING', null, { timeout: 90_000 });
    if (throttle > 1) {
      const cdp = await context.newCDPSession(page);
      await cdp.send('Emulation.setCPUThrottlingRate', { rate: throttle });
    }
    if (screenshot) {
      await page.waitForFunction(() => JSON.parse(document.getElementById('frame-diagnostics').textContent || '{}')
        .engine?.at(-1)?.elapsed >= 2, null, { polling: 400, timeout: 30_000 });
      await page.screenshot({ path: screenshot });
    }
    await page.waitForFunction(() => document.body.dataset.game === 'RESULTS', null, { polling: 700, timeout: 180_000 });
    const diagnostics = JSON.parse(await page.locator('#frame-diagnostics').textContent());
    assert(diagnostics.engine.length && diagnostics.engine.every(sample => sample.map === map),
      `Missing frames for ${map}; is this a perfbench export?`);
    const gpu = await page.evaluate(() => {
      const gl = document.createElement('canvas').getContext('webgl2');
      const debug = gl?.getExtension('WEBGL_debug_renderer_info');
      return debug && gl.getParameter(debug.UNMASKED_RENDERER_WEBGL);
    });
    const summary = Object.fromEntries(['normal', 'frenzy'].map(phase => {
      const samples = diagnostics.engine.filter(sample => sample.phase === phase &&
        (phase === 'normal' ? sample.elapsed > 4 && sample.elapsed < 44.5 : sample.elapsed >= 46 && sample.elapsed < 59.5));
      assert(samples.length > 0, `No samples in ${phase}`);
      const intervals = samples.flatMap(sample => sample.intervals).sort((a, b) => a - b);
      return [phase, {
        frames: intervals.length,
        fps: intervals.length * 1000 / intervals.reduce((sum, ms) => sum + ms, 0),
        p95Ms: intervals[Math.floor(intervals.length * 0.95)],
        p99Ms: intervals[Math.floor(intervals.length * 0.99)],
        longFrames: intervals.filter(ms => ms > 33.334).length,
        medianDraws: median(samples.map(sample => sample.draws)),
        medianProcessMs: median(samples.map(sample => sample.cpu)),
        renderSizes: [...new Set(samples.map(sample => sample.render_size))],
      }];
    }));
    fs.writeFileSync(output, JSON.stringify({ map, mode, throttle, chrome: browser.version(), gpu, loadMs,
      summary, ...diagnostics, errors }, null, 2) + '\n');
    console.log(JSON.stringify({ map, mode, throttle, gpu, summary }));
    assert.deepEqual(errors, []);
  } finally {
    await browser.close();
  }
}

function median(samples) {
  return samples.sort((a, b) => a - b)[Math.floor(samples.length / 2)];
}

main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
