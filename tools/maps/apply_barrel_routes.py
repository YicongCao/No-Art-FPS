"""Apply reviewed route suggestions to barrel transforms and rebake only navigation."""
from pathlib import Path
import json, re, subprocess
root = Path(__file__).resolve().parents[2]
scene = root / 'scenes/maps/yard.tscn'
report = json.loads((root / 'artifacts/barrel-route-analysis.json').read_text())
text = scene.read_text()
for barrel in report['barrels']:
    parent, name = barrel['path'].rsplit('/', 1)
    pattern = r'(\[node name="' + re.escape(name) + r'"[^\n]*parent="' + re.escape(parent) + r'"[^\n]*\]\n)(.*?)(?=\n\[|\Z)'
    match = re.search(pattern, text, re.S)
    assert match, barrel['path']
    body = match[2]
    coords = ', '.join(f'{value:.6f}'.rstrip('0').rstrip('.') if value else '0' for value in barrel['to'])
    body, count = re.subn(r'transform = Transform3D\([^\n]+\)', 'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, ' + coords + ')', body, count=1)
    assert count == 1
    text = text[:match.start(2)] + body + text[match.end(2):]
scene.write_text(text)
result = subprocess.run(['godot','--headless','--path',str(root),'--script','tools/maps/rebake_yard.gd'],capture_output=True,text=True,timeout=90)
assert result.returncode==0 and 'ERROR:' not in result.stdout+result.stderr, result.stdout+result.stderr
nav = Path('/tmp/no-art-yard-navigation.tres').read_text().split('[resource]\n',1)[1].rstrip()
text, count = re.subn(r'(\[sub_resource type="NavigationMesh"[^\n]*\]\n).*?(?=\n\[)',lambda m:m[1]+nav+'\n',scene.read_text(),count=1,flags=re.S)
assert count == 1
scene.write_text(text)
print(result.stdout.strip())
print('Updated barrel transforms and navigation; other scene nodes preserved.')
