import { execFileSync } from 'node:child_process';
import { copyFile, mkdir, readFile, writeFile } from 'node:fs/promises';
import { join, resolve } from 'node:path';

// Ports one authored Godot map into a ForgeAX data module.
// Usage: node scripts/port-map.mjs --map ginza_station

const gameRoot = resolve(import.meta.dirname, '..');
const repoRoot = resolve(gameRoot, '..');

const MAPS = {
  sandgate: {
    title: 'SANDGATE',
    models: [
      'ground', 'a_long', 'mid', 'b_court', 'b_tunnel', 'skyline',
      'a_stall_south', 'a_stall_north', 'a_cross_wall', 'a_platform_box',
      'a_ramp_box', 'pit_box', 'short_box', 'mid_gate_box', 'mid_return_box',
      'b_stall', 'b_crate_wall', 'b_crate_low', 'b_platform_box', 'b_window_box',
      'tunnel_box',
    ],
    shared: ['enemy', 'rifle', 'cloud'],
  },
  ginza_station: {
    title: 'GINZA STATION',
    models: [
      'alarm_lamps', 'bench', 'bridges', 'ceiling', 'coin_lockers',
      'express_train', 'fluorescent_tubes', 'ginza_train', 'hoarding',
      'island_platform', 'kiosk', 'recycle_bins', 'side_passages',
      'station_shell', 'vending_machine', 'vending_machine_white',
    ],
    shared: [],
  },
  bb_office: {
    title: 'BB OFFICE',
    models: [
      'architecture', 'building_services', 'camp_cot', 'chair', 'city',
      'copy_station', 'executive', 'huddle_table', 'locker', 'manager_door',
      'meeting_table', 'pantry_counter', 'partition', 'partition_low',
      'partition_storage', 'phone_booth', 'planter', 'programmer',
      'programmer_lunch', 'project_manager', 'project_manager_lunch',
      'reception', 'rooms', 'shade_leaf', 'snack_rack', 'water_cooler',
    ],
    shared: [],
  },
};

const mapId = (() => {
  const index = process.argv.indexOf('--map');
  const value = index >= 0 ? process.argv[index + 1] : undefined;
  if (value === undefined || !(value in MAPS)) {
    throw new Error(`--map must be one of ${Object.keys(MAPS).join(', ')}`);
  }
  return value;
})();
const manifest = MAPS[mapId];

const tscnPath = join(repoRoot, 'scenes/maps', `${mapId}.tscn`);
const sourceModels = join(repoRoot, 'assets/models');
const targetModels = join(gameRoot, 'assets/models');

await mkdir(join(targetModels, mapId), { recursive: true });
for (const name of manifest.models) {
  await copyFile(join(sourceModels, mapId, `${name}.glb`), join(targetModels, mapId, `${name}.glb`));
}
for (const name of manifest.shared) {
  await copyFile(join(sourceModels, `${name}.glb`), join(targetModels, `${name}.glb`));
}

const forgeax = join(gameRoot, 'node_modules/.bin/forgeax');
const imports = [
  ...manifest.models.map((name) => `assets/models/${mapId}/${name}.glb`),
  ...manifest.shared.map((name) => `assets/models/${name}.glb`),
];
for (const path of imports) {
  execFileSync(forgeax, ['asset', 'import', path, '--root', gameRoot, '--json'], {
    cwd: gameRoot,
    env: { ...process.env, PATH: `${join(repoRoot, '.tools/pnpm/bin')}:${process.env.PATH ?? ''}` },
    stdio: 'ignore',
  });
}

const text = await readFile(tscnPath, 'utf8');
const lines = text.split('\n');
const resources = new Map();
for (const line of lines) {
  const match = /^\[ext_resource type="PackedScene" path="res:\/\/([^"]+)" id="([^"]+)"\]/.exec(line);
  if (match) resources.set(match[2], match[1]);
}

const shapes = new Map();
for (let index = 0; index < lines.length; index += 1) {
  const match = /^\[sub_resource type="BoxShape3D" id="([^"]+)"\]/.exec(lines[index]);
  if (!match) continue;
  for (const line of lines.slice(index + 1, index + 7)) {
    const size = /^size = Vector3\(([^)]+)\)/.exec(line);
    if (!size) continue;
    shapes.set(match[1], size[1].split(',').map(Number));
    break;
  }
}

const nodes = [];
for (let index = 0; index < lines.length;) {
  const match = /^\[node name="([^"]+)"(?: type="([^"]+)")?(?: parent="([^"]*)")?([^\]]*)\]/.exec(lines[index]);
  if (!match) {
    index += 1;
    continue;
  }
  const [, name, type, parent = '', rest] = match;
  let transform = [1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0];
  let instance;
  let shape;
  const lineInstance = /instance=ExtResource\("([^"]+)"\)/.exec(rest);
  if (lineInstance) instance = lineInstance[1];
  let cursor = index + 1;
  while (cursor < lines.length && !lines[cursor].startsWith('[node')) {
    const line = lines[cursor];
    if (line.startsWith('transform = Transform3D(')) {
      transform = line.slice(line.indexOf('(') + 1, line.indexOf(')')).split(',').map(Number);
    }
    const childInstance = /instance=ExtResource\("([^"]+)"\)/.exec(line);
    if (childInstance) instance = childInstance[1];
    const childShape = /shape = SubResource\("([^"]+)"\)/.exec(line);
    if (childShape) shape = childShape[1];
    cursor += 1;
  }
  nodes.push({
    name,
    type,
    parent,
    path: parent === '' || parent === '.' ? name : `${parent}/${name}`,
    transform,
    instance,
    shape,
  });
  index = cursor;
}

const byPath = new Map(nodes.map((node) => [node.path, node]));
const transformMatrix = (value) => {
  const [xx, xy, xz, yx, yy, yz, zx, zy, zz, ox, oy, oz] = value;
  return [
    [xx, yx, zx, ox],
    [xy, yy, zy, oy],
    [xz, yz, zz, oz],
    [0, 0, 0, 1],
  ];
};
const multiply = (a, b) => Array.from({ length: 4 }, (_, row) =>
  Array.from({ length: 4 }, (_, column) =>
    a[row][0] * b[0][column] + a[row][1] * b[1][column] + a[row][2] * b[2][column] + a[row][3] * b[3][column]));
const worldMatrix = (node) => {
  let matrix = transformMatrix(node.transform);
  let parent = node.parent;
  while (parent && parent !== '.') {
    const nodeParent = byPath.get(parent);
    if (!nodeParent) break;
    matrix = multiply(transformMatrix(nodeParent.transform), matrix);
    parent = nodeParent.parent;
  }
  return matrix;
};
const quatScale = (matrix) => {
  const sx = Math.hypot(matrix[0][0], matrix[1][0], matrix[2][0]);
  const sy = Math.hypot(matrix[0][1], matrix[1][1], matrix[2][1]);
  const sz = Math.hypot(matrix[0][2], matrix[1][2], matrix[2][2]);
  const r = [
    [matrix[0][0] / sx, matrix[0][1] / sy, matrix[0][2] / sz],
    [matrix[1][0] / sx, matrix[1][1] / sy, matrix[1][2] / sz],
    [matrix[2][0] / sx, matrix[2][1] / sy, matrix[2][2] / sz],
  ];
  const trace = r[0][0] + r[1][1] + r[2][2];
  let x;
  let y;
  let z;
  let w;
  if (trace > 0) {
    const s = Math.sqrt(trace + 1) * 2;
    w = 0.25 * s;
    x = (r[2][1] - r[1][2]) / s;
    y = (r[0][2] - r[2][0]) / s;
    z = (r[1][0] - r[0][1]) / s;
  } else if (r[0][0] > r[1][1] && r[0][0] > r[2][2]) {
    const s = Math.sqrt(1 + r[0][0] - r[1][1] - r[2][2]) * 2;
    w = (r[2][1] - r[1][2]) / s;
    x = 0.25 * s;
    y = (r[0][1] + r[1][0]) / s;
    z = (r[0][2] + r[2][0]) / s;
  } else if (r[1][1] > r[2][2]) {
    const s = Math.sqrt(1 + r[1][1] - r[0][0] - r[2][2]) * 2;
    w = (r[0][2] - r[2][0]) / s;
    x = (r[0][1] + r[1][0]) / s;
    y = 0.25 * s;
    z = (r[1][2] + r[2][1]) / s;
  } else {
    const s = Math.sqrt(1 + r[2][2] - r[0][0] - r[1][1]) * 2;
    w = (r[1][0] - r[0][1]) / s;
    x = (r[0][2] + r[2][0]) / s;
    y = (r[1][2] + r[2][1]) / s;
    z = 0.25 * s;
  }
  return { quat: [x, y, z, w].map((value) => Number(value.toFixed(6))), scale: [sx, sy, sz].map((value) => Number(value.toFixed(4))) };
};
const round = (value) => Number(value.toFixed(5));
const sceneGuid = async (glb) => {
  const relative = glb.replace('assets/models/', '');
  const meta = JSON.parse(await readFile(join(targetModels, relative) + '.meta.json', 'utf8'));
  const scene = meta.subAssets.find((asset) => asset.kind === 'scene');
  if (!scene) throw new Error(`No scene output for ${glb}`);
  return scene.guid;
};

const visuals = [];
for (const node of nodes) {
  if (!node.instance) continue;
  const glb = resources.get(node.instance);
  if (!glb?.startsWith('assets/models/')) continue;
  const isArchitecture = node.parent === 'Architecture';
  const isPropModel = node.name === 'Model' && node.parent.startsWith('Props/');
  const isCloud = node.name.startsWith('Cloud');
  if (!isArchitecture && !isPropModel && !isCloud) continue;
  const matrix = worldMatrix(node);
  const { quat, scale } = quatScale(matrix);
  visuals.push({
    name: node.path,
    guid: await sceneGuid(glb),
    pos: [round(matrix[0][3]), round(matrix[1][3]), round(matrix[2][3])],
    quat,
    scale,
  });
}

const shapeChildren = new Map();
for (const node of nodes) {
  if (node.type !== 'CollisionShape3D' || !node.shape) continue;
  const list = shapeChildren.get(node.parent) ?? [];
  list.push(node);
  shapeChildren.set(node.parent, list);
}
const colliders = [];
let skippedShapes = 0;
for (const node of nodes) {
  if (node.type !== 'StaticBody3D') continue;
  const parent = node.parent;
  const owner = parent === 'Collision' || parent === 'Architecture' || parent === '.' || parent.startsWith('Props/');
  if (!owner) continue;
  for (const shapeNode of shapeChildren.get(node.path) ?? []) {
    const size = shapes.get(shapeNode.shape);
    if (!size) {
      skippedShapes += 1;
      continue;
    }
    const matrix = worldMatrix(shapeNode);
    const { quat, scale } = quatScale(matrix);
    colliders.push({
      name: node.path,
      pos: [round(matrix[0][3]), round(matrix[1][3]), round(matrix[2][3])],
      quat,
      half: size.map((value, axis) => Number((value * scale[axis] / 2).toFixed(4))),
    });
  }
}

const markers = { openings: [], reinforcements: [], respawns: [] };
let start;
for (const node of nodes) {
  if (node.parent !== 'Markers') continue;
  const matrix = worldMatrix(node);
  const point = [round(matrix[0][3]), round(matrix[1][3]), round(matrix[2][3])];
  if (node.name.startsWith('PlayerStart') || node.name.startsWith('Start')) start = point;
  else if (node.name.startsWith('Opening')) markers.openings.push(point);
  else if (node.name.startsWith('Reinforcement')) markers.reinforcements.push(point);
  else if (node.name.startsWith('Respawn')) markers.respawns.push(point);
}
if (start === undefined) {
  start = [0, 0, 0];
  console.warn(`${mapId} has no Start or PlayerStart marker; falling back to the origin`);
}

const json = (value) => JSON.stringify(value, null, 2);
const color = (value) => value.split(',').map(Number);
let environment = { background: [0.32, 0.49, 0.78], ambient: [0.88, 0.91, 1], ambientEnergy: 0.55 };
for (let index = 0; index < lines.length; index += 1) {
  if (!/^\[sub_resource type="Environment"/.test(lines[index])) continue;
  for (let cursor = index + 1; cursor < lines.length && !lines[cursor].startsWith('['); cursor += 1) {
    const line = lines[cursor];
    const background = /^background_color = Color\(([^)]+)\)/.exec(line);
    if (background) environment.background = color(background[1]).slice(0, 3);
    const ambient = /^ambient_light_color = Color\(([^)]+)\)/.exec(line);
    if (ambient) environment.ambient = color(ambient[1]).slice(0, 3);
    const energy = /^ambient_light_energy = ([\d.]+)/.exec(line);
    if (energy) environment.ambientEnergy = Number(energy[1]);
  }
  break;
}
const output = `// Generated by scripts/port-map.mjs --map ${mapId} from scenes/maps/${mapId}.tscn.
// Godot authored space is reused: 1 unit = 1 m, Y up, -Z forward.

import type { MapCollider, MapVisual } from './types.ts';

export const MAP_ID = ${JSON.stringify(mapId)};
export const MAP_TITLE = ${JSON.stringify(manifest.title)};
export const ENVIRONMENT = ${json(environment)} as const;
export const PLAYER_START = ${json(start)} as const;
export const OPENING_POINTS = ${json(markers.openings)} as const;
export const REINFORCEMENT_POINTS = ${json(markers.reinforcements)} as const;
export const RESPAWN_POINTS = ${json(markers.respawns)} as const;

export const MAP_VISUALS: readonly MapVisual[] = ${json(visuals)};

export const MAP_COLLIDERS: readonly MapCollider[] = ${json(colliders)};
`;
await mkdir(join(gameRoot, 'assets/fps/maps'), { recursive: true });
await writeFile(join(gameRoot, 'assets/fps/maps', `${mapId}.ts`), output);
console.log(JSON.stringify({
  map: mapId,
  visuals: visuals.length,
  colliders: colliders.length,
  openings: markers.openings.length,
  reinforcements: markers.reinforcements.length,
  respawns: markers.respawns.length,
  skippedShapes,
  start,
}));
