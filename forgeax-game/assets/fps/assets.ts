export const ENEMY_SCENE = '01a2159c-2f7e-7d7c-8502-21da074ee0e7';
export const RUSHER_SCENE = '01a2159c-4a90-7f41-948e-a631732f55c1';
export const RIFLE_SCENE = '01a2159c-3d07-7993-8c96-52a3ca162b9b';

/** Sound effects copied from the Godot project's assets/audio set. */
export const SOUND_GUIDS = {
  shot: '01a215d3-7ec4-7327-b532-ab69eb283eba',
  hit: '01a215d3-3217-7cbb-819d-9c21d6ac9f8b',
  headshot: '01a215d3-2470-7f0e-bb2c-bc8833089710',
  kill: '01a215d3-4ef0-724b-bcae-311e51743ed0',
  hurt: '01a215d3-4063-73d5-8eeb-52ee3570443a',
  end: '01a215d3-15b2-7ecb-b1e9-f9fd9bae8aec',
  tick: '01a215d3-8c90-73bd-9801-cded16c81fcc',
  reload: '01a215d3-70b9-740c-b7ba-aca67fcee356',
  magazineLatch: '01a215d3-6119-706d-9980-108c76c216d9',
  cartridgeInsert: '01a215d3-072d-7a2d-b89d-3d69ed9dc718',
} as const;

/** sixty.ogg, the 60-second combat loop. */
export const COMBAT_MUSIC = '01a215d3-9bca-771a-b2f2-4e123171290b';

/** One combat loop per ported map. */
export const MAP_MUSIC = {
  sandgate: COMBAT_MUSIC,
  bb_office: '01a215ed-2bd9-7881-8704-effe8c095fe8',
} as const;

export const HUD_CHANNEL = 'no-art-fps/hud';
export const CONTROL_CHANNEL = 'no-art-fps/control';
