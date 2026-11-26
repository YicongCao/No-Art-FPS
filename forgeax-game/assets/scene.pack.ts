import { definePack, definePackageId } from '@forgeax/engine/pack/source';
import {
  CharacterController,
  Collider,
  ColliderShapeValue,
  RigidBody,
  RigidBodyTypeValue,
} from '@forgeax/engine/physics';
import {
  ANTIALIAS_FXAA,
  Camera,
  DirectionalLight,
  perspective,
  SKYBOX_MODE_CUBEMAP,
  SkyboxBackground,
  Skylight,
  TONEMAP_ACES_FILMIC,
} from '@forgeax/engine/render';
import { Name, Transform } from '@forgeax/engine/scene';
import type { SceneAsset } from '@forgeax/engine/types';
import { ok } from '@forgeax/engine/types';
import { assetGuid, guidText, PACKAGE_IDS, SUN_OUTGOING_DIRECTION } from './shared/asset-refs.ts';
import { PLAYER_COLLISION_GROUPS } from './fps/aim.ts';

const PLAYER_START = [15.73, 0.98, 17.48] as const;
const CAMERA_START = [15.73, 1.7, 17.48] as const;

function sandgateScene(): SceneAsset {
  return {
    kind: 'scene',
    entities: {
      player: {
        components: {
          Name: { value: 'Player' },
          Transform: { pos: PLAYER_START },
          RigidBody: { type: RigidBodyTypeValue.kinematic },
          Collider: {
            shape: ColliderShapeValue.capsule,
            radius: 0.38,
            halfHeight: 0.55,
            friction: 0.7,
            restitution: 0,
            collisionGroups: PLAYER_COLLISION_GROUPS,
          },
          CharacterController: {
            offset: 0.03,
            maxSlopeClimbDeg: 48,
            minSlopeSlideDeg: 55,
            autoStepMaxHeight: 0.32,
            autoStepMinWidth: 0.15,
            snapToGroundDist: 0.24,
          },
        },
      },
      camera: {
        components: {
          Name: { value: 'Main Camera' },
          Transform: { pos: CAMERA_START },
          Camera: {
            ...perspective({ fov: (63 * Math.PI) / 180, aspect: 16 / 9, near: 0.035, far: 250 }),
            tonemap: TONEMAP_ACES_FILMIC,
            antialias: ANTIALIAS_FXAA,
            clearColor: [0.32, 0.49, 0.78, 1],
          },
        },
      },
      sun: {
        components: {
          Name: { value: 'Sun' },
          DirectionalLight: {
            direction: SUN_OUTGOING_DIRECTION,
            color: [1, 0.95, 0.86],
            intensity: 2.6,
            castShadow: true,
            shadowDistance: 56,
          },
        },
      },
      skylight: {
        components: {
          Name: { value: 'Skylight' },
          Skylight: {
            equirect: guidText(assetGuid(PACKAGE_IDS.environment, 'environment/daylight')),
            color: [1, 1, 1],
            intensity: 0.58,
          },
        },
      },
      'sky-background': {
        components: {
          Name: { value: 'Sky Background' },
          SkyboxBackground: {
            equirect: guidText(assetGuid(PACKAGE_IDS.environment, 'environment/daylight')),
            mode: SKYBOX_MODE_CUBEMAP,
          },
        },
      },
    },
  };
}

export default definePack({
  schemaVersion: '2.0.0',
  packageId: definePackageId('019fb7ce-3400-7000-8000-000000000000'),
  name: 'No Art FPS / Sandgate Scene',
  sceneComponents: [
    Camera,
    CharacterController,
    Collider,
    DirectionalLight,
    Name,
    RigidBody,
    SkyboxBackground,
    Skylight,
    Transform,
  ],
  build: () => ok({ 'scene/showcase': sandgateScene() }),
});
