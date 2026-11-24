import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { runInNewContext } from 'node:vm';

const script = readFileSync(new URL('../web/audio.js', import.meta.url), 'utf8');
function harness() {
  let now = 0, gesture = false, resumeCalls = 0, context;
  const sources = [], allocations = [];
  class Node {
    connect(next) { this.next = next; return next; }
    disconnect() { this.next = null; }
  }
  class Audio extends EventTarget {
    state = 'suspended';
    destination = new Node();
    constructor() { super(); context = this; }
    setState(state) { this.state = state; this.dispatchEvent(new Event('statechange')); }
    resume() {
      resumeCalls++;
      if (!gesture) return new Promise(() => {});
      this.setState('running');
      return Promise.resolve();
    }
    createBuffer(channels, frames, rate) {
      const samples = new Float32Array(frames);
      const buffer = { channels, rate, getChannelData: () => samples };
      allocations.push(buffer);
      return buffer;
    }
    createBufferSource() {
      const source = Object.assign(new Node(), { playbackRate: {}, stopped: false,
        start(when) { this.when = when; }, stop() { this.stopped = true; } });
      sources.push(source);
      return source;
    }
    createGain() { return Object.assign(new Node(), { gain: {} }); }
  }
  const window = Object.assign(new EventTarget(), { AudioContext: Audio });
  const document = Object.assign(new EventTarget(), { hidden: false });
  runInNewContext(script, { window, document, atob, performance: { now: () => now } });
  window.noArtInstallAudio();
  const audio = window.noArtAudio;
  const send = (type, trusted = false, pointerType = 'touch', activation = trusted) => {
    gesture = activation;
    const event = new Event(type);
    Object.defineProperties(event, { isTrusted: { value: trusted }, pointerType: { value: pointerType } });
    window.dispatchEvent(event);
    gesture = false;
  };
  return { audio, sources, allocations, send,
    now: value => { now = value; }, state: value => context.setState(value), resumeCalls: () => resumeCalls,
    hide: hidden => { document.hidden = hidden; document.dispatchEvent(new Event('visibilitychange')); } };
}

const h = harness(), a = h.audio;
const pcm = Buffer.from([0, 128, 1, 0, 255, 127]).toString('base64');
a.register('shot', pcm, 22050);
assert.equal(a.shot('shot', .25, 1), false, 'Godot fallback before unlock');
h.send('pointerdown', true);
h.send('pointerup', false);
assert.equal(a.snapshot().state, 'not-created', 'Touch press and synthetic release do not unlock');
h.send('touchend', true);
assert.equal(a.snapshot().state, 'running');
assert.deepEqual(Array.from(h.allocations[0].getChannelData(0)), [-1, 1 / 32768, 32767 / 32768]);
a.register('water_shot', pcm, 22050);
a.register('slipper_shot', pcm, 22050);
assert.equal(h.allocations.length, 3, 'All samples are ready before firing');
assert.equal(a.shot('shot', .25, .95), true);
assert.equal(h.sources[0].when, 0);
assert.equal(h.sources[0].playbackRate.value, .95);
assert.equal(h.sources[0].next.gain.value, .25);
assert.equal(a.shot('shot', .25, 1), true);
assert.equal(h.sources.length, 1, 'No same-frame catch-up burst');
for (const now of [100, 200, 300, 400]) { h.now(now); a.shot('shot', .25, 1); }
assert.equal(a.snapshot().active, 4, 'Bound active nodes');
assert.equal(h.sources.length, 4);
assert(h.sources.every(source => source.buffer === h.allocations[0]), 'No shot buffer copies');
h.sources[0].onended();
assert.equal(a.snapshot().active, 3);

h.hide(true);
assert.equal(a.snapshot().active, 0);
assert(h.sources.slice(1).every(source => source.stopped && !source.next));
assert.equal(a.shot('shot', .25, 1), true, 'No Godot fallback while hidden');
h.state('interrupted');
h.hide(false);
assert.equal(a.snapshot().state, 'interrupted');
assert.equal(a.shot('shot', .25, 1), true, 'Do not enqueue a shot during interruption');
h.now(650);
assert.equal(a.shot('shot', .25, 1), true, 'No fallback burst into a potentially suspended Godot context');
const previousResumes = h.resumeCalls();
h.send('pointerup', true, 'touch', false);
assert.equal(a.snapshot().state, 'interrupted');
h.send('touchend', true);
assert(h.resumeCalls() >= previousResumes + 2, 'Pending resume and prior pointerup do not block Retry touch activation');
assert.equal(a.snapshot().state, 'running');
assert.equal(a.snapshot().started, 4, 'No backlog replay on resume');
a.shot('water_shot', .25, 1);
assert.equal(h.sources.at(-1).buffer, h.allocations[1]);
h.send('pagehide');
assert.equal(a.snapshot().active, 0);
assert.equal(a.shot('shot', .25, 1), true);
h.send('pageshow');
h.send('blur');
assert.equal(a.shot('shot', .25, 1), true);
h.send('focus');
a.shot('slipper_shot', .25, 1);
assert.equal(h.sources.at(-1).buffer, h.allocations[2]);
a.stop();
assert.equal(a.snapshot().active, 0);
h.state('closed');
assert.equal(a.shot('shot', .25, 1), false);
console.log('WEB_AUDIO_PASS: PCM, unlock, bounded voices, interruption, no replay, and fallback');
