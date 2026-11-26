import { definePack, definePackageId } from '@forgeax/engine/pack/source';
import { ok } from '@forgeax/engine/types';
export { fps } from './fps.ts';

export default definePack({
  schemaVersion: '2.0.0',
  plugins: true,
  packageId: definePackageId('019fb7ce-3f00-7000-8000-000000000000'),
  build: () => ok({
    'plugin/fps': {
      kind: 'plugin',
      module: { specifier: './fps.pack.ts', export: 'fps' },
    },
  }),
});
