import { definePack, definePackageId } from '@forgeax/engine/pack/source';
import { ok } from '@forgeax/engine/types';
import { FixedUpdate, Update } from '@forgeax/engine/ecs';
import { quat } from '@forgeax/engine/math';
import type { Plugin } from '@forgeax/engine/plugin';
import { PROPAGATE_TRANSFORMS_SYSTEM, Transform } from '@forgeax/engine/scene';
import type { Game3dPlayerService } from '../player/player.ts';
import { EYE_HEIGHT } from '../player/player.ts';
import { MAX_CAMERA_PITCH, MIN_CAMERA_PITCH, integratePointerLook } from './third-person.ts';
import { resolveGameEntity } from '../shared/scene-refs.ts';

const MIN_PITCH = MIN_CAMERA_PITCH;
const MAX_PITCH = MAX_CAMERA_PITCH;

export const camera: Plugin = {
  name: 'no-art-fps/camera',
  inject: ['world', 'game3dPlayer', 'gameScene'],
  apply(ctx) {
    const world = ctx.world;
    const playerService = ctx.game3dPlayer as Game3dPlayerService | undefined;
    if (playerService === undefined) throw new Error('no-art-fps/camera requires the player service');
    const player = playerService.entity;
    const camera = resolveGameEntity(world, ctx.gameScene, 'camera');
    ctx.effect(function* () {
      world
        .addSystem(Update, {
          name: 'no-art-fps-camera',
          after: [FixedUpdate, 'no-art-fps-player-input'],
          before: [PROPAGATE_TRANSFORMS_SYSTEM],
          queries: [],
          fn: () => {
            const input = playerService.readInput();
            const rig = playerService.readRig();
            const look = integratePointerLook(rig.yaw, rig.pitch, input.lookX, input.lookY);
            const yaw = look.yaw;
            const pitch = Math.max(MIN_PITCH, Math.min(MAX_PITCH, look.pitch));
            const position = world.get(player, Transform).unwrap().pos;
            const eye = [
              position[0] ?? 0,
              (position[1] ?? 0) + EYE_HEIGHT,
              position[2] ?? 0,
            ] as const;
            const direction = [
              Math.sin(yaw) * Math.cos(pitch),
              -Math.sin(pitch),
              -Math.cos(yaw) * Math.cos(pitch),
            ] as const;
            const target = [eye[0] + direction[0], eye[1] + direction[1], eye[2] + direction[2]] as const;
            const rotation = quat.fromLookAt(quat.create(), eye, target, [0, 1, 0]);
            world
              .set(camera, Transform, {
                pos: eye,
                quat: [rotation[0] ?? 0, rotation[1] ?? 0, rotation[2] ?? 0, rotation[3] ?? 1],
              })
              .unwrap();
            playerService.updateRig({ yaw, pitch });
          },
        })
        .unwrap();
      yield () => world.removeSystem(Update, 'no-art-fps-camera').unwrap();
    }, 'no-art-fps/camera');
  },
};

export default definePack({
  schemaVersion: '2.0.0',
  plugins: true,
  packageId: definePackageId('019fb7ce-3c00-7000-8000-000000000000'),
  build: () => ok({
    'plugin/camera': {
      kind: 'plugin',
      module: { specifier: './camera.pack.ts', export: 'camera' },
    },
  }),
});
