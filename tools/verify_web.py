#!/usr/bin/env python3
"""Validate a distributable Web export and write its public integrity manifest."""
import hashlib
import json
import struct
from pathlib import Path

root = Path(__file__).resolve().parents[1]
bundle = root / 'builds' / 'web'
required = ['index.html', 'index.js', 'index.wasm', 'index.pck', 'icon.svg', 'comedy.svg', 'roach.svg', 'locale.js', 'gyro.js', 'gyro-setup.js', 'title-background.webp', 'Rajdhani-Bold.woff2', 'FONT-LICENSE.txt', 'Noto-CJK-LICENSE.txt', 'GODOT-LICENSE.txt', 'GODOT-COPYRIGHT.txt', 'DUST-LICENSE.txt']
required += ['frag-grenade.svg', 'stink-bomb.svg', 'roach-bomb.svg']
for name in required:
    assert (bundle / name).is_file(), f'Missing export: {name}'
html = (bundle / 'index.html').read_text()
assert '$GODOT_' not in html, 'Unresolved template token'
assert '"ensureCrossOriginIsolationHeaders":false' in html, 'Unexpected isolation requirement'
assert '"serviceWorker"' not in html, 'PWA must stay disabled'
assert (bundle / 'Rajdhani-Bold.woff2').read_bytes()[:4] == b'wOF2', 'Invalid title font'
assert (bundle / 'title-background.webp').read_bytes()[8:12] == b'WEBP', 'Invalid opening frame'
assert (bundle / 'index.wasm').read_bytes()[:4] == b'\x00asm', 'Invalid WebAssembly'
# PCK path table contains public runtime resources only. Nothing from the
# reference, source-art, screenshots, design or QA folders may be published.
data = (bundle / 'index.pck').read_bytes()
magic, version, major, minor, patch, flags, file_base, directory = struct.unpack_from('<6I2Q', data)
assert magic == 0x43504447 and version in (3, 4) and not flags & 1, 'Unsupported PCK layout'
count, = struct.unpack_from('<I', data, directory)
offset = directory + 4
paths = []
for _ in range(count):
    length, = struct.unpack_from('<I', data, offset)
    offset += 4
    path = data[offset:offset + length].rstrip(b'\x00').decode('utf-8')
    paths.append(path)
    offset += length + 36
for path in paths:
    assert not any(part in path for part in ['docs/', 'art_source/', 'artifacts/', 'tests/', '.mov', '.blend']), f'Non-runtime content in pack: {path}'
assert not list(bundle.glob('*worker*')), 'Unexpected service worker export'
assert not list(bundle.glob('*.import')), 'Editor import metadata must not ship'
allowed = set(required + ['index.audio.worklet.js', 'index.audio.position.worklet.js', 'manifest.json'])
assert {p.name for p in bundle.iterdir()} <= allowed, 'Unexpected file in public bundle'
manifest = {p.name: {'bytes': p.stat().st_size, 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}
            for p in sorted(bundle.iterdir()) if p.is_file() and p.name != 'manifest.json'}
(bundle / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
print(json.dumps({'files': len(manifest), 'packed_resources': len(paths), 'bytes': sum(f['bytes'] for f in manifest.values()), 'manifest': str(bundle / 'manifest.json')}, indent=2))
