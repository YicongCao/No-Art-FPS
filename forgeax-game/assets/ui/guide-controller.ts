import type { GameHost } from '@forgeax/engine/app';
import { mountUi, type UiAsset, type UiInstance } from '@forgeax/engine/ui';
import { CONTROL_CHANNEL, HUD_CHANNEL } from '../fps/assets.ts';

interface HudState {
  readonly phase: 'ready' | 'countdown' | 'running' | 'paused' | 'results';
  readonly map: string;
  readonly time: number;
  readonly countdown: number;
  readonly kills: number;
  readonly best: number;
  readonly ammo: number;
  readonly reloading: boolean;
  readonly health: number;
}

const PHASES = ['ready', 'countdown', 'running', 'paused', 'results'] as const;
const BEST_PREFIX = 'no-art-fps.best.';

function readStoredBest(map: string): number {
  try {
    const raw = globalThis.localStorage?.getItem(BEST_PREFIX + map);
    const value = raw ? Math.floor(Number(raw)) : 0;
    return Number.isFinite(value) && value > 0 ? value : 0;
  } catch {
    return 0;
  }
}

function writeStoredBest(map: string, value: number): void {
  try {
    globalThis.localStorage?.setItem(BEST_PREFIX + map, String(Math.floor(value)));
  } catch {
    // Storage can be unavailable in a private or embedded context.
  }
}

export async function createGuideUi(
  asset: UiAsset,
  host: Pick<GameHost, 'uiRoot' | 'port' | 'presentationPort'>,
): Promise<UiInstance> {
  const root = host.uiRoot;
  if (!root) throw new Error('No-Art-FPS UI requires GameHost.uiRoot');
  const mounted = mountUi(asset, { root, layer: 50 });
  if (!mounted.ok) throw mounted.error;
  const ui = mounted.value;
  const shadow = ui.host.shadowRoot;
  if (!shadow) {
    ui.dispose();
    throw new Error('No-Art-FPS UI requires a shadow root');
  }
  const query = <T extends HTMLElement>(part: string): T => {
    const node = shadow.querySelector<T>(`[data-ui-part="${part}"]`);
    if (!node) throw new Error(`No-Art-FPS UI is missing ${part}`);
    return node;
  };
  const time = query('time');
  const kills = query('kills');
  const countdown = query('countdown');
  const ammo = query('ammo');
  const resultKills = query('result-kills');
  const resultBest = query('result-best');
  const restart = query<HTMLButtonElement>('restart');
  const mapButtons: Record<string, HTMLButtonElement> = {
    sandgate: query<HTMLButtonElement>('map-sandgate'),
    bb_office: query<HTMLButtonElement>('map-bb_office'),
  };
  const port = host.presentationPort ?? host.port;
  let disposed = false;
  let bestMap = '';
  let storedBest = 0;

  const announceBest = (map: string, value: number) => {
    port?.postMessage({ channel: CONTROL_CHANNEL, kind: 'best', map, value });
  };

  const update = (state: HudState) => {
    for (const phase of PHASES) ui.host.classList.toggle(phase, state.phase === phase);
    ui.host.classList.toggle('low-health', state.health <= 1);
    ui.host.classList.toggle('show-ammo', state.reloading || state.ammo < 20);
    if (state.phase === 'results' && state.best > storedBest) {
      storedBest = state.best;
      writeStoredBest(state.map, storedBest);
      announceBest(state.map, storedBest);
    }
    for (const [id, button] of Object.entries(mapButtons)) {
      button.classList.toggle('selected', id === state.map);
    }
    time.textContent = String(Math.ceil(state.time));
    kills.textContent = String(state.kills);
    countdown.textContent = String(Math.max(1, Math.ceil(state.countdown)));
    resultKills.textContent = String(state.kills);
    resultBest.textContent = `BEST ${Math.max(state.best, storedBest)}`;
    ammo.textContent = state.reloading ? 'RELOAD' : String(state.ammo);
    ammo.classList.toggle('reloading', state.reloading);
    restart.hidden = state.phase !== 'results';
  };
  const receive = (event: MessageEvent) => {
    const data = event.data as { channel?: string; state?: HudState } | undefined;
    if (data?.channel !== HUD_CHANNEL || !data.state) return;
    const state = data.state;
    if (state.map !== bestMap) {
      bestMap = state.map;
      storedBest = readStoredBest(state.map);
      announceBest(state.map, storedBest);
    }
    update(state);
  };
  const restartRun = () => {
    if (restart.hidden) return;
    port?.postMessage({ channel: CONTROL_CHANNEL, kind: 'restart' });
  };
  const chooseMap = (map: string) => {
    port?.postMessage({ channel: CONTROL_CHANNEL, kind: 'map', value: map });
  };
  const chooseSandgate = () => chooseMap('sandgate');
  const chooseOffice = () => chooseMap('bb_office');

  ui.host.classList.add('ready');
  ui.host.classList.remove('low-health', 'show-ammo');
  restart.addEventListener('click', restartRun);
  mapButtons.sandgate?.addEventListener('click', chooseSandgate);
  mapButtons.bb_office?.addEventListener('click', chooseOffice);
  port?.addEventListener('message', receive);
  port?.start();

  let closed = false;
  const dispose = () => {
    if (closed) return;
    closed = true;
    disposed = true;
    restart.removeEventListener('click', restartRun);
    mapButtons.sandgate?.removeEventListener('click', chooseSandgate);
    mapButtons.bb_office?.removeEventListener('click', chooseOffice);
    port?.removeEventListener('message', receive);
    ui.dispose();
  };
  return { host: ui.host, signal: ui.signal, resourceUrl: ui.resourceUrl, dispose };
}
