import { definePack, definePackageId } from '@forgeax/engine/pack/source';
import { ok } from '@forgeax/engine/types';
export { default as player } from './player.ts';

export default definePack({
  schemaVersion: '2.0.0', plugins: true,
  packageId: definePackageId('019fb7ce-3b00-7000-8000-000000000000'),
  build: () => ok({
    'plugin/player': {
      kind: 'plugin',
      module: { specifier: './player.pack.ts', export: 'player' },
      config: {
        speed: 7,
        jumpSpeed: 6.25,
        gravity: 20,
      },
    },
  }),
});
