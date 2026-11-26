import { FixedTime, FixedUpdate, Time, Update, type EntityHandle } from '@forgeax/engine/ecs';
import { AudioSource } from '@forgeax/engine/audio';
import { INPUT_SNAPSHOT_RESOURCE_KEY, type InputSnapshot } from '@forgeax/engine/input';
import { quat, vec3 } from '@forgeax/engine/math';
import {
  CharacterController,
  Collider,
  ColliderShapeValue,
  RigidBody,
  RigidBodyTypeValue,
  type PhysicsWorld,
} from '@forgeax/engine/physics';
import type { Plugin } from '@forgeax/engine/plugin';
import { ChildOf, Name, Transform, worldDespawnScene } from '@forgeax/engine/scene';
import type { AssetHandle } from '@forgeax/engine/types';
import type {} from '@forgeax/engine/app';
import { resolveGameEntity } from '../shared/scene-refs.ts';
import { EYE_HEIGHT, type Game3dPlayerService } from '../player/player.ts';
import { AIM_DISTANCE, AIM_FILTER_MASK, aimRay } from './aim.ts';
import {
  CONTROL_CHANNEL,
  COMBAT_MUSIC,
  ENEMY_SCENE,
  HUD_CHANNEL,
  RIFLE_SCENE,
  RUSHER_SCENE,
  SOUND_GUIDS,
} from './assets.ts';
import {
  MAP_COLLIDERS,
  MAP_VISUALS,
  OPENING_POINTS,
  PLAYER_START,
  REINFORCEMENT_POINTS,
} from './map-data.ts';

type Phase = 'ready' | 'countdown' | 'running' | 'paused' | 'results';

interface EnemyState {
  readonly entity: EntityHandle;
  readonly visual: EntityHandle;
  readonly speed: number;
  health: number;
  verticalVelocity: number;
  attackCooldown: number;
}

const PLAYER_CENTER_HEIGHT = 0.93;
const ENEMY_CENTER_HEIGHT = 0.93;
const MAX_ENEMIES = 8;
const RUN_SECONDS = 60;
const COUNTDOWN_SECONDS = 3;
const MAGAZINE_SIZE = 20;
const FIRE_INTERVAL = 0.09;
const RELOAD_SECONDS = 0.9;
const MAX_HEALTH = 3;
const MAX_VOICES = 14;
const VOICE_SECONDS = 1.5;
const MUSIC_VOLUME = 0.5;

/** Linear volumes converted from the Godot project's decibel values. */
const SOUNDS = {
  shot: { guid: SOUND_GUIDS.shot, volume: 0.32 },
  hit: { guid: SOUND_GUIDS.hit, volume: 0.2 },
  headshot: { guid: SOUND_GUIDS.headshot, volume: 0.45 },
  kill: { guid: SOUND_GUIDS.kill, volume: 0.45 },
  hurt: { guid: SOUND_GUIDS.hurt, volume: 0.28 },
  end: { guid: SOUND_GUIDS.end, volume: 0.45 },
  tick: { guid: SOUND_GUIDS.tick, volume: 0.25 },
  reload: { guid: SOUND_GUIDS.reload, volume: 0.4 },
  magazineLatch: { guid: SOUND_GUIDS.magazineLatch, volume: 0.35 },
} as const;

type SoundId = keyof typeof SOUNDS;

export const fps: Plugin = {
  name: 'no-art-fps/combat',
  inject: ['world', 'assets', 'physics', 'gameHost', 'gameScene', 'game3dPlayer'],
  async apply(ctx) {
    const world = ctx.world;
    const assets = ctx.assets;
    const host = ctx.gameHost;
    if (!assets) throw new Error('no-art-fps/combat requires assets');
    if (!host) throw new Error('no-art-fps/combat requires the App-owned GameHost');
    const playerService = ctx.game3dPlayer as Game3dPlayerService | undefined;
    if (!playerService) throw new Error('no-art-fps/combat requires the player service');
    const player = playerService.entity;
    const camera = resolveGameEntity(world, ctx.gameScene, 'camera');

    let phase: Phase = 'ready';
    let resumePhase: Phase = 'running';
    let time = RUN_SECONDS;
    let countdown = COUNTDOWN_SECONDS;
    let kills = 0;
    let best = 0;
    let ammo = MAGAZINE_SIZE;
    let reload = 0;
    let fireCooldown = 0;
    let health = MAX_HEALTH;
    let hurtCooldown = 0;
    let spawnTimer = 0;
    let hudTimer = 0;
    let restartRequested = false;
    let spawnCursor = 0;
    const enemies = new Map<EntityHandle, EnemyState>();

    await ctx.effect(async function* () {
      const enemyLoaded = await assets.load(ENEMY_SCENE, 'scene');
      if (!enemyLoaded.ok) throw enemyLoaded.error;
      const enemyHandle = enemyLoaded.value;
      yield () => assets.release(enemyHandle).unwrap();
      const rusherLoaded = await assets.load(RUSHER_SCENE, 'scene');
      if (!rusherLoaded.ok) throw rusherLoaded.error;
      const rusherHandle = rusherLoaded.value;
      yield () => assets.release(rusherHandle).unwrap();
      const rifleLoaded = await assets.load(RIFLE_SCENE, 'scene');
      if (!rifleLoaded.ok) throw rifleLoaded.error;
      const rifleHandle = rifleLoaded.value;
      yield () => assets.release(rifleHandle).unwrap();

      const clips = new Map<SoundId, AssetHandle<'audio'>>();
      for (const id of Object.keys(SOUNDS) as SoundId[]) {
        const loaded = await assets.load(SOUNDS[id].guid, 'audio');
        if (!loaded.ok) throw loaded.error;
        clips.set(id, loaded.value);
        yield () => assets.release(loaded.value).unwrap();
      }

      const voices: { entity: EntityHandle; remaining: number }[] = [];
      const playSound = (id: SoundId, rate = 1) => {
        const clip = clips.get(id);
        if (clip === undefined) return;
        if (voices.length >= MAX_VOICES) {
          const oldest = voices.shift();
          if (oldest !== undefined) world.despawn(oldest.entity).unwrap();
        }
        const entity = world.spawn({
          component: AudioSource,
          data: {
            clip,
            playing: true,
            volume: SOUNDS[id].volume,
            playbackRate: rate,
            spatialBlend: 0,
          },
        }).unwrap();
        voices.push({ entity, remaining: VOICE_SECONDS });
      };
      yield () => {
        for (const voice of voices.splice(0)) world.despawn(voice.entity).unwrap();
      };

      const musicLoaded = await assets.load(COMBAT_MUSIC, 'audio');
      if (!musicLoaded.ok) throw musicLoaded.error;
      const music = world.spawn({
        component: AudioSource,
        data: {
          clip: musicLoaded.value,
          playing: false,
          loop: true,
          volume: MUSIC_VOLUME,
          spatialBlend: 0,
        },
      }).unwrap();
      yield () => {
        world.despawn(music).unwrap();
        assets.release(musicLoaded.value).unwrap();
      };
      const playMusic = (on: boolean) => world.set(music, AudioSource, { playing: on }).unwrap();

      const mapRoots: EntityHandle[] = [];
      for (const visual of MAP_VISUALS) {
        const loaded = await assets.load(visual.guid, 'scene');
        if (!loaded.ok) throw loaded.error;
        const root = assets.instantiate(loaded.value, world).unwrap();
        assets.release(loaded.value).unwrap();
        place(world, root, visual.pos, visual.quat, visual.scale);
        mapRoots.push(root);
      }
      yield () => {
        for (const root of mapRoots.reverse()) worldDespawnScene(world, root).unwrap();
      };

      const colliders: EntityHandle[] = [];
      for (const box of MAP_COLLIDERS) {
        if (box.half.some((value) => value <= 0)) continue;
        colliders.push(world.spawn(
          { component: Transform, data: { pos: box.pos, quat: box.quat } },
          { component: RigidBody, data: { type: RigidBodyTypeValue.static } },
          {
            component: Collider,
            data: {
              shape: ColliderShapeValue.cuboid,
              halfExtents: box.half,
              friction: 0.86,
              restitution: 0,
            },
          },
        ).unwrap());
      }
      yield () => {
        for (const entity of colliders.reverse()) world.despawn(entity).unwrap();
      };

      const weapon = assets.instantiate(rifleHandle, world).unwrap();
      world.addComponent(weapon, { component: ChildOf, data: { parent: camera } }).unwrap();
      place(world, weapon, [0.25, -0.32, -0.66], [0, 0, 0, 1], [0.7, 0.7, 0.7]);
      yield () => worldDespawnScene(world, weapon).unwrap();

      const removeEnemy = (entity: EntityHandle) => {
        const state = enemies.get(entity);
        if (!state) return;
        enemies.delete(entity);
        worldDespawnScene(world, state.visual).unwrap();
        world.despawn(entity).unwrap();
      };
      const clearEnemies = () => {
        for (const entity of [...enemies.keys()]) removeEnemy(entity);
      };
      yield clearEnemies;

      const spawnEnemy = (fast = false) => {
        if (enemies.size >= MAX_ENEMIES) return;
        const position = nextSpawnPoint();
        const entity = world.spawn(
          { component: Transform, data: { pos: [position[0], position[1] + ENEMY_CENTER_HEIGHT, position[2]] } },
          { component: RigidBody, data: { type: RigidBodyTypeValue.kinematic } },
          {
            component: Collider,
            data: {
              shape: ColliderShapeValue.capsule,
              radius: 0.28,
              halfHeight: 0.65,
              friction: 0.7,
              restitution: 0,
            },
          },
          { component: CharacterController, data: {} },
        ).unwrap();
        const visual = assets.instantiate(fast ? rusherHandle : enemyHandle, world).unwrap();
        world.addComponent(visual, { component: ChildOf, data: { parent: entity } }).unwrap();
        place(world, visual, [0, -ENEMY_CENTER_HEIGHT, 0], [0, 0, 0, 1], [1, 1, 1]);
        enemies.set(entity, {
          entity,
          visual,
          speed: fast ? 3.6 : 2.4,
          health: 3,
          verticalVelocity: 0,
          attackCooldown: 0.7,
        });
      };

      const resetRun = () => {
        clearEnemies();
        phase = 'ready';
        playMusic(false);
        time = RUN_SECONDS;
        countdown = COUNTDOWN_SECONDS;
        kills = 0;
        ammo = MAGAZINE_SIZE;
        reload = 0;
        fireCooldown = 0;
        health = MAX_HEALTH;
        hurtCooldown = 0;
        spawnTimer = 0;
        spawnCursor = 0;
        const position = vec3.create(PLAYER_START[0], PLAYER_START[1] + PLAYER_CENTER_HEIGHT, PLAYER_START[2]);
        world.set(player, Transform, { pos: [position[0], position[1], position[2]], quat: [0, 0, 0, 1] }).unwrap();
        const physics = world.getResource<PhysicsWorld>('PhysicsWorld');
        physics.teleport(player, position);
        playerService.updateRig({ yaw: -0.045, pitch: 0 });
        for (let index = 0; index < 4; index += 1) spawnEnemy(index === 3);
        host.setPointerLockAllowed?.(true);
        publishHud();
      };

      const nextSpawnPoint = () => {
        const points = [...OPENING_POINTS, ...REINFORCEMENT_POINTS];
        const playerPosition = world.get(player, Transform).unwrap().pos;
        for (let attempt = 0; attempt < points.length; attempt += 1) {
          const point = points[(spawnCursor + attempt) % points.length];
          if (!point) continue;
          const distance = Math.hypot(point[0] - (playerPosition[0] ?? 0), point[2] - (playerPosition[2] ?? 0));
          if (distance < 8) continue;
          spawnCursor = (spawnCursor + attempt + 1) % points.length;
          return point;
        }
        spawnCursor = (spawnCursor + 1) % points.length;
        return points[spawnCursor] ?? PLAYER_START;
      };

      const publishHud = () => {
        host.port?.postMessage({
          channel: HUD_CHANNEL,
          state: {
            phase,
            time: Math.max(0, time),
            countdown: Math.max(0, countdown),
            kills,
            best: Math.max(best, kills),
            ammo,
            reloading: reload > 0,
            health,
          },
        });
      };

      const receive = (event: MessageEvent) => {
        const data = event.data as { channel?: string; kind?: string } | undefined;
        if (data?.channel === CONTROL_CHANNEL && data.kind === 'restart') restartRequested = true;
      };
      host.port?.addEventListener('message', receive);
      host.port?.start();
      yield () => host.port?.removeEventListener('message', receive);
      yield () => host.setPointerLockAllowed?.(false);
      host.setPointerLockAllowed?.(true);

      for (let index = 0; index < 4; index += 1) spawnEnemy(index === 3);

      const fire = () => {
        const rig = playerService.readRig();
        const position = world.get(player, Transform).unwrap().pos;
        const { origin, direction } = aimRay(position, rig.yaw, rig.pitch, EYE_HEIGHT);
        const physics = world.getResource<PhysicsWorld>('PhysicsWorld');
        const hit = physics.raycast(origin, direction, AIM_DISTANCE, AIM_FILTER_MASK);
        ammo -= 1;
        fireCooldown = FIRE_INTERVAL;
        playSound('shot', 0.94 + Math.random() * 0.11);
        if (!hit) return;
        const enemy = enemies.get(hit.entity as EntityHandle);
        if (!enemy) return;
        const body = world.get(enemy.entity, Transform).unwrap();
        const headshot = (hit.point[1] ?? 0) > (body.pos[1] ?? 0) + 0.55;
        enemy.health -= headshot ? 3 : 1;
        if (enemy.health > 0) {
          if (!headshot) playSound('hit');
          return;
        }
        removeEnemy(enemy.entity);
        kills += 1;
        spawnTimer = 0.2;
        playSound(headshot ? 'headshot' : 'kill', 0.96 + Math.random() * 0.08);
      };

      world.addSystem(FixedUpdate, {
        name: 'no-art-fps-enemies',
        queries: [],
        fn: () => {
          if (phase !== 'running') return;
          const physicsWorld = world.getResource<PhysicsWorld>('PhysicsWorld');
          const dt = world.getResource(FixedTime).delta;
          const playerPosition = world.get(player, Transform).unwrap().pos;
          for (const enemy of enemies.values()) {
            if (!physicsWorld.hasBody(enemy.entity)) continue;
            const transform = world.get(enemy.entity, Transform);
            const controller = world.get(enemy.entity, CharacterController);
            if (!transform.ok || !controller.ok) continue;
            const dx = (playerPosition[0] ?? 0) - (transform.value.pos[0] ?? 0);
            const dz = (playerPosition[2] ?? 0) - (transform.value.pos[2] ?? 0);
            const distance = Math.hypot(dx, dz);
            enemy.verticalVelocity = controller.value.grounded ? 0 : enemy.verticalVelocity - 20 * dt;
            if (distance > 0.8) {
              const step = enemy.speed * dt;
              physicsWorld.moveAndSlide(
                enemy.entity,
                vec3.create(
                  (dx / distance) * step,
                  enemy.verticalVelocity * dt,
                  (dz / distance) * step,
                ),
              );
              const facing = quat.eulerY(Math.atan2(-dx, -dz));
              world.set(enemy.entity, Transform, {
                quat: [facing[0] ?? 0, facing[1] ?? 0, facing[2] ?? 0, facing[3] ?? 1],
              }).unwrap();
            }
            enemy.attackCooldown -= dt;
            if (distance < 1.15 && enemy.attackCooldown <= 0 && hurtCooldown <= 0) {
              enemy.attackCooldown = 0.9;
              health = Math.max(0, health - 1);
              hurtCooldown = 0.7;
              playSound('hurt');
              if (health === 0) {
                const spawn = vec3.create(PLAYER_START[0], PLAYER_START[1] + PLAYER_CENTER_HEIGHT, PLAYER_START[2]);
                world.set(player, Transform, { pos: [spawn[0], spawn[1], spawn[2]] }).unwrap();
                physicsWorld.teleport(player, spawn);
                health = MAX_HEALTH;
                hurtCooldown = 2;
              }
            }
          }
        },
      }).unwrap();
      yield () => world.removeSystem(FixedUpdate, 'no-art-fps-enemies').unwrap();

      world.addSystem(Update, {
        name: 'no-art-fps-game',
        queries: [],
        fn: () => {
          const dt = world.getResource(Time).delta;
          const input = world.getResource<InputSnapshot>(INPUT_SNAPSHOT_RESOURCE_KEY);
          if (restartRequested) {
            restartRequested = false;
            resetRun();
          }
          fireCooldown = Math.max(0, fireCooldown - dt);
          hurtCooldown = Math.max(0, hurtCooldown - dt);
          for (let index = voices.length - 1; index >= 0; index -= 1) {
            const voice = voices[index];
            if (voice === undefined) continue;
            voice.remaining -= dt;
            if (voice.remaining > 0) continue;
            voices.splice(index, 1);
            world.despawn(voice.entity).unwrap();
          }
          if (reload > 0) {
            reload -= dt;
            if (reload <= 0) {
              reload = 0;
              ammo = MAGAZINE_SIZE;
              playSound('magazineLatch');
            }
          }
          const locked = input.mouse.pointerLocked;
          if (phase === 'ready' && locked) {
            phase = 'countdown';
            countdown = COUNTDOWN_SECONDS;
            playMusic(true);
            playSound('tick');
          } else if (phase === 'countdown') {
            if (!locked) {
              resumePhase = 'countdown';
              phase = 'paused';
            } else {
              const previousSecond = Math.ceil(countdown);
              countdown -= dt;
              if (countdown > 0 && Math.ceil(countdown) !== previousSecond) playSound('tick');
              if (countdown <= 0) {
                phase = 'running';
                countdown = 0;
              }
            }
          } else if (phase === 'running') {
            if (!locked) {
              resumePhase = 'running';
              phase = 'paused';
            } else {
              time = Math.max(0, time - dt);
              spawnTimer -= dt;
              if (spawnTimer <= 0 && enemies.size < MAX_ENEMIES) {
                spawnEnemy(enemies.size >= 5);
                spawnTimer = 1.15;
              }
              if (time <= 0) {
                phase = 'results';
                best = Math.max(best, kills);
                host.setPointerLockAllowed?.(false);
                playMusic(false);
                playSound('end');
              }
            }
          } else if (phase === 'paused' && locked) {
            phase = resumePhase;
          }

          if (phase === 'running' && locked) {
            if ((input.mouse.button(0) || input.mouse.justPressed(0)) && fireCooldown <= 0 && ammo > 0) fire();
            if (input.keyboard.justPressedCode('KeyR') && reload <= 0 && ammo < MAGAZINE_SIZE) {
              reload = RELOAD_SECONDS;
              playSound('reload');
            }
            if (ammo <= 0 && reload <= 0) {
              reload = RELOAD_SECONDS;
              playSound('reload');
            }
          }

          hudTimer -= dt;
          if (hudTimer <= 0) {
            hudTimer = 0.08;
            publishHud();
          }
        },
      }).unwrap();
      yield () => world.removeSystem(Update, 'no-art-fps-game').unwrap();

      const nearestAim = () => {
        const position = world.get(player, Transform).unwrap().pos;
        const eyeY = (position[1] ?? 0) + EYE_HEIGHT;
        let best: { yaw: number; pitch: number; distance: number } | null = null;
        for (const enemy of enemies.values()) {
          const transform = world.get(enemy.entity, Transform).unwrap();
          const dx = (transform.pos[0] ?? 0) - (position[0] ?? 0);
          const dy = (transform.pos[1] ?? 0) - eyeY;
          const dz = (transform.pos[2] ?? 0) - (position[2] ?? 0);
          const distance = Math.hypot(dx, dy, dz);
          if (best !== null && best.distance <= distance) continue;
          best = {
            yaw: Math.atan2(dx, -dz),
            pitch: -Math.atan2(dy, Math.hypot(dx, dz)),
            distance,
          };
        }
        return best;
      };

      const unregisterRead = host.gameProjection?.registerRead({
        id: 'no-art-fps.run',
        title: 'No-Art-FPS run state',
        description: 'Phase, remaining time, score, ammunition, health, live enemies and the nearest aim point.',
        read: () => ({
          phase,
          time,
          kills,
          best: Math.max(best, kills),
          ammo,
          reloading: reload > 0,
          health,
          enemies: enemies.size,
          aim: nearestAim(),
        }),
      });
      if (unregisterRead !== undefined) yield unregisterRead;

      publishHud();
    }, 'no-art-fps/combat');
  },
};

function place(
  world: import('@forgeax/engine/ecs').World,
  entity: EntityHandle,
  pos: readonly [number, number, number],
  rotation: readonly [number, number, number, number],
  scale: readonly [number, number, number],
): void {
  if (world.get(entity, Transform).ok) {
    world.set(entity, Transform, { pos, quat: rotation, scale }).unwrap();
  } else {
    world.addComponent(entity, { component: Transform, data: { pos, quat: rotation, scale } }).unwrap();
  }
}
