import { vec3, type Vec3, type Vec3Like } from '@forgeax/engine/math';

/**
 * Packed membership/filter groups. The player joins membership bit 2 and only
 * accepts interactions from group bit 1, which nothing but the aim ray uses;
 * the aim ray in turn refuses bit 2. Every other body keeps the engine default
 * (membership 1, filter all), so level geometry and enemies stay unaffected.
 */
export const PLAYER_COLLISION_GROUPS = 0x0002fffd;
export const AIM_FILTER_MASK = 0xfffffffd;
export const AIM_DISTANCE = 120;

export interface AimRay {
  readonly origin: Vec3;
  readonly direction: Vec3;
}

export function aimRay(position: Vec3Like, yaw: number, pitch: number, eyeHeight: number): AimRay {
  const cos = Math.cos(pitch);
  return {
    origin: vec3.create(position[0] ?? 0, (position[1] ?? 0) + eyeHeight, position[2] ?? 0),
    direction: vec3.create(Math.sin(yaw) * cos, -Math.sin(pitch), -Math.cos(yaw) * cos),
  };
}
