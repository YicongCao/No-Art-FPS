"""Read GLB triangle/material-surface budgets without importing or changing models."""
import argparse
import json
from pathlib import Path
import struct


def inspect(path):
    raw = path.read_bytes()
    magic, version, size = struct.unpack_from('<III', raw)
    assert magic == 0x46546C67 and version == 2 and size == len(raw), path
    length, kind = struct.unpack_from('<II', raw, 12)
    assert kind == 0x4E4F534A, path
    doc = json.loads(raw[20:20+length])
    triangles = surfaces = vertices = 0
    for mesh in doc.get('meshes', []):
        for primitive in mesh['primitives']:
            assert primitive.get('mode', 4) == 4, path
            count = doc['accessors'][primitive['attributes']['POSITION']]['count']
            vertices += count
            triangles += (doc['accessors'][primitive['indices']]['count']
                          if 'indices' in primitive else count) // 3
            surfaces += 1
    return dict(file=path.name, bytes=len(raw), triangles=triangles,
                vertices=vertices, surfaces=surfaces)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('directory', type=Path)
    args = parser.parse_args()
    models = [inspect(p) for p in sorted(args.directory.glob('*.glb'))]
    print(json.dumps({'models': models, 'total': {
        key: sum(m[key] for m in models)
        for key in ('bytes', 'triangles', 'vertices', 'surfaces')
    }}, indent=2))
