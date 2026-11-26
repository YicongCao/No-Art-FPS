import { defineComponent, FixedTime, FixedUpdate, Update, type EntityHandle } from '@forgeax/engine/ecs';
import { FRAME_START_SCAN_SYSTEM_NAME, INPUT_SNAPSHOT_RESOURCE_KEY, type InputSnapshot } from '@forgeax/engine/input';
import { quat, vec3 } from '@forgeax/engine/math';
import { CharacterController, type PhysicsWorld } from '@forgeax/engine/physics';
import type { Plugin } from '@forgeax/engine/plugin';
import { Transform } from '@forgeax/engine/scene';
import { cameraRelativeMove, facingYaw } from '../camera/third-person.ts';
import { resolveGameEntity, type GameScene } from '../shared/scene-refs.ts';
import { createPlayerInput, type PlayerInput } from './player-input.ts';

const EYE_HEIGHT = 0.72;

export const FpsPlayerRig = defineComponent(
  'NoArtFpsPlayerRig',
  {
    verticalVelocity: { type: 'f32', default: 0 },
    yaw: { type: 'f32', default: -0.045 },
    pitch: { type: 'f32', default: 0 },
  },
  { transient: true },
);

export interface Game3dPlayerService {
  readonly entity: EntityHandle;
  readonly readInput: () => PlayerInput;
  readonly readRig: () => { readonly yaw: number; readonly pitch: number };
  readonly updateRig: (patch: { readonly yaw?: number; readonly pitch?: number }) => void;
}

declare module '@forgeax/engine/plugin' {
  interface EngineContextServices {
    game3dPlayer: Game3dPlayerService;
  }
}

type SceneHost = NonNullable<import('@forgeax/engine/app').GameHost>;

interface PlayerConfig {
  readonly speed: number;
  readonly jumpSpeed: number;
  readonly gravity: number;
}

const playerPlugin: Plugin.Object<PlayerConfig> = {
  name: 'no-art-fps/player',
  provide: 'game3dPlayer',
  inject: ['world', 'physics', 'gameHost', 'gameScene'],
  async apply(ctx, config) {
    const world = ctx.world;
    const host = ctx.gameHost;
    if (host === undefined) throw new Error('no-art-fps/player requires the App-owned GameHost');
    const readDrawingBufferSize = host.drawingBufferSize?.bind(host);
    const player = resolveGameEntity(world, ctx.gameScene, 'player');
    await ctx.effect(async function* () {
      const sampleInput = createPlayerInput();
      let frameInput: PlayerInput = { horizontal: 0, vertical: 0, lookX: 0, lookY: 0, run: false };
      const receive = (event: MessageEvent) => sampleInput.receive(event.data);
      host.port?.addEventListener('message', receive);
      host.port?.start();
      yield () => {
        host.port?.removeEventListener('message', receive);
        sampleInput.reset();
      };
      const lease = world.components.register(FpsPlayerRig).unwrap();
      yield () => lease.dispose().unwrap();
      world.addComponent(player, { component: FpsPlayerRig, data: {} }).unwrap();
      yield () => world.removeComponent(player, FpsPlayerRig).unwrap();
      const playerService: Game3dPlayerService = {
        entity: player,
        readInput: () => frameInput,
        readRig: () => {
          const rig = world.get(player, FpsPlayerRig).unwrap();
          return { yaw: rig.yaw, pitch: rig.pitch };
        },
        updateRig: (patch) => {
          world.set(player, FpsPlayerRig, patch).unwrap();
        },
      };
      world.addSystem(Update, {
        name: 'no-art-fps-player-input',
        after: [FRAME_START_SCAN_SYSTEM_NAME],
        before: [FixedUpdate],
        queries: [],
        fn: () => {
          const size = readDrawingBufferSize?.();
          frameInput = sampleInput.sample(
            world.getResource<InputSnapshot>(INPUT_SNAPSHOT_RESOURCE_KEY),
            size?.width ?? 0,
            size?.height ?? 0,
          );
        },
      }).unwrap();
      yield () => world.removeSystem(Update, 'no-art-fps-player-input').unwrap();
      installMovement(world, player, config, playerService.readInput, sampleInput.takeJump);
      yield () => world.removeSystem(FixedUpdate, 'no-art-fps-player-movement').unwrap();
      const unregisterRead = host.gameProjection?.registerRead({
        id: 'no-art-fps.player',
        title: 'First-person player state',
        description: 'Resolved physics position, view angles and grounded state.',
        read: () => {
          const transform = world.get(player, Transform).unwrap();
          const rig = world.get(player, FpsPlayerRig).unwrap();
          const controller = world.get(player, CharacterController).unwrap();
          const input = world.getResource<InputSnapshot>(INPUT_SNAPSHOT_RESOURCE_KEY);
          return {
            position: Array.from(transform.pos),
            camera: { yaw: rig.yaw, pitch: rig.pitch, pointerLocked: input.mouse.pointerLocked },
            grounded: controller.grounded,
            controls: { horizontal: frameInput.horizontal, vertical: frameInput.vertical, run: frameInput.run },
            simulation: { fixedTick: world.getResource(FixedTime).tick },
          };
        },
      });
      if (unregisterRead !== undefined) yield unregisterRead;
      ctx.provide('game3dPlayer', playerService);
    }, 'no-art-fps/player');
  },
};

function installMovement(
  world: Parameters<typeof installMovementImpl>[0],
  player: EntityHandle,
  config: PlayerConfig,
  readInput: () => PlayerInput,
  takeJump: () => boolean,
): void {
  installMovementImpl(world, player, config, readInput, takeJump);
}

function installMovementImpl(
  world: import('@forgeax/engine/ecs').World,
  player: EntityHandle,
  config: PlayerConfig,
  readInput: () => PlayerInput,
  takeJump: () => boolean,
): void {
  world
    .addSystem(FixedUpdate, {
      name: 'no-art-fps-player-movement',
      queries: [],
      fn: () => {
        if (!world.hasResource('PhysicsWorld')) return;
        const physics = world.getResource<PhysicsWorld>('PhysicsWorld');
        if (!physics.hasBody(player)) return;
        const dt = world.getResource(FixedTime).delta;
        const rig = world.get(player, FpsPlayerRig).unwrap();
        const controller = world.get(player, CharacterController).unwrap();
        const { horizontal, vertical, run } = readInput();
        const jump = takeJump();
        const speed = config.speed * (run ? 1.5 : 1);
        const move = cameraRelativeMove(rig.yaw, horizontal, vertical);
        let verticalVelocity = rig.verticalVelocity;
        if (controller.grounded && jump) verticalVelocity = config.jumpSpeed;
        verticalVelocity -= config.gravity * dt;
        if (controller.grounded && verticalVelocity < 0) verticalVelocity = -config.gravity * dt;
        physics.moveAndSlide(
          player,
          vec3.create(move.x * speed * dt, verticalVelocity * dt, move.z * speed * dt),
        );
        if (world.get(player, CharacterController).unwrap().grounded && verticalVelocity < 0)
          verticalVelocity = 0;
        if (move.length > 0.001) {
          const rotation = quat.eulerY(facingYaw(move.x, move.z));
          world
            .set(player, Transform, {
              quat: [rotation[0] ?? 0, rotation[1] ?? 0, rotation[2] ?? 0, rotation[3] ?? 1],
            })
            .unwrap();
        }
        world.set(player, FpsPlayerRig, { verticalVelocity }).unwrap();
      },
    })
    .unwrap();
}

export { EYE_HEIGHT };
export default playerPlugin;
