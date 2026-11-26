import { Collider, ColliderShapeValue, RigidBody, RigidBodyTypeValue, CharacterController, type PhysicsWorld } from '@forgeax/engine/physics';
import physics3d from '@forgeax/engine/physics-rapier3d';
import { Transform } from '@forgeax/engine/scene';
import { describe, expect, it } from 'vitest';
import { EYE_HEIGHT } from '../../player/player.ts';
import { sceneWorldFixture } from '../../shared/__tests__/plugin-fixture.ts';
import { AIM_DISTANCE, AIM_FILTER_MASK, aimRay, PLAYER_COLLISION_GROUPS } from '../aim.ts';

async function aimFixture() {
  const { world, ctx } = await sceneWorldFixture();
  await ctx.plugin(physics3d);
  const player = world.spawn(
    { component: Transform, data: { pos: [0, 0.93, 0] } },
    { component: RigidBody, data: { type: RigidBodyTypeValue.kinematic } },
    {
      component: Collider,
      data: {
        shape: ColliderShapeValue.capsule,
        radius: 0.38,
        halfHeight: 0.55,
        collisionGroups: PLAYER_COLLISION_GROUPS,
      },
    },
    { component: CharacterController, data: {} },
  ).unwrap();
  const wall = world.spawn(
    { component: Transform, data: { pos: [0, 2, -10] } },
    { component: RigidBody, data: { type: RigidBodyTypeValue.static } },
    {
      component: Collider,
      data: { shape: ColliderShapeValue.cuboid, halfExtents: [4, 4, 0.2] },
    },
  ).unwrap();
  for (let step = 0; step < 8; step += 1) world.update(1 / 60).unwrap();
  const physics = world.getResource<PhysicsWorld>('PhysicsWorld');
  return { world, ctx, physics, player, wall };
}

describe('first-person aim ray', () => {
  it('starts at eye height inside the player capsule and looks down -Z from yaw 0', () => {
    const ray = aimRay([2, 0.93, 3], 0, 0, EYE_HEIGHT);
    expect(ray.origin[0]).toBeCloseTo(2);
    expect(ray.origin[1]).toBeCloseTo(0.93 + EYE_HEIGHT);
    expect(ray.origin[2]).toBeCloseTo(3);
    expect(ray.direction[0]).toBeCloseTo(0);
    expect(ray.direction[1]).toBeCloseTo(0);
    expect(ray.direction[2]).toBeCloseTo(-1);
    const up = aimRay([0, 0, 0], 0, Math.PI / 4, EYE_HEIGHT);
    expect(up.direction[1]).toBeCloseTo(-Math.SQRT1_2);
    expect(up.direction[2]).toBeCloseTo(-Math.SQRT1_2);
  });

  it('ignores the shooter body but still hits the wall down the sight line', async () => {
    const { ctx, physics, player, wall } = await aimFixture();
    try {
      const ray = aimRay([0, 0.93, 0], 0, 0, EYE_HEIGHT);
      const selfHit = physics.raycast(ray.origin, ray.direction, AIM_DISTANCE, 0xffffffff);
      expect(selfHit?.entity).toBe(player);
      const hit = physics.raycast(ray.origin, ray.direction, AIM_DISTANCE, AIM_FILTER_MASK);
      expect(hit?.entity).toBe(wall);
      expect(hit?.timeOfImpact).toBeCloseTo(9.8, 1);
    } finally {
      await ctx.fiber.dispose();
    }
  });

  it('still hits enemies behind the sight line', async () => {
    const { world, ctx, physics } = await aimFixture();
    try {
      const enemy = world.spawn(
        { component: Transform, data: { pos: [0, 0.93, -6] } },
        { component: RigidBody, data: { type: RigidBodyTypeValue.kinematic } },
        {
          component: Collider,
          data: { shape: ColliderShapeValue.capsule, radius: 0.28, halfHeight: 0.65 },
        },
      ).unwrap();
      for (let step = 0; step < 8; step += 1) world.update(1 / 60).unwrap();
      const ray = aimRay([0, 0.93, 0], 0, 0, EYE_HEIGHT);
      const hit = physics.raycast(ray.origin, ray.direction, AIM_DISTANCE, AIM_FILTER_MASK);
      expect(hit?.entity).toBe(enemy);
      expect(hit?.timeOfImpact).toBeLessThan(6);
    } finally {
      await ctx.fiber.dispose();
    }
  });
});
