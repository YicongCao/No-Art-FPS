#!/usr/bin/env python3
"""Export the isolated trial using explicit roots, then audit the actual PCK."""
from pathlib import Path
import subprocess, json, shutil, struct, hashlib, os, re, argparse
ROOT=Path(__file__).resolve().parents[1]
GODOT=os.environ.get('GODOT_BIN','/Applications/Godot.app/Contents/MacOS/Godot')
parser=argparse.ArgumentParser();parser.add_argument('--review',choices=['a','b','c'],default='c');args=parser.parse_args()
REVIEW=ROOT/('docs/art/space/review-'+args.review)
OUT=ROOT/'builds/moonbase'; OUT.mkdir(parents=True,exist_ok=True)
# Godot's selected-resource export does not discover every GDScript preload.
# Build an explicit transitive source manifest, including lazy core resources.
files={'scenes/moonbase.tscn','scripts/game.gd','scripts/maps/moonbase.gd','data/sessions/moonbase_trial.tres'}
for folder, pattern in [('assets/audio','*.wav'),('assets/models/toy','*.glb'),('assets/models/space','*.glb'),('assets/fonts','*')]:
 files.update(str(p.relative_to(ROOT)) for p in (ROOT/folder).glob(pattern) if p.is_file() and p.suffix not in ['.import','.txt'])
queue=list(files);visited=set()
while queue:
 name=queue.pop()
 if name in visited:continue
 visited.add(name)
 if Path(name).suffix not in ['.gd','.tres','.tscn']:continue
 for dep in re.findall(r'res://([^"\\\n]+)',(ROOT/name).read_text()):
  if not dep.startswith(('assets/','scripts/','data/','scenes/')):continue
  if dep.startswith('data/sessions/') and dep!='data/sessions/moonbase_trial.tres':continue
  if (ROOT/dep).is_file() and dep not in files:files.add(dep);queue.append(dep)
preset=ROOT/'export_presets.cfg'
text=preset.read_text();before,trial=text.split('[preset.3]',1)
trial=re.sub(r'export_files=PackedStringArray\([^\n]*\)', 'export_files=PackedStringArray('+', '.join(json.dumps('res://'+p) for p in sorted(files))+')',trial)
preset.write_text(before+'[preset.3]'+trial)

# Project settings feature override selects the trial only for this preset.
subprocess.run([GODOT,'--headless','--path',str(ROOT),'--editor','--import'],check=True)
subprocess.run([GODOT,'--headless','--path',str(ROOT),'--export-release','Moonbase Web',str(OUT/'index.html')],check=True)
for name in ['icon.svg','locale.js','gyro.js','gyro-setup.js','title-background.webp','Rajdhani-Bold.woff2','GlowSansSC-UI.woff2','GODOT-LICENSE.txt','GODOT-COPYRIGHT.txt']:
 shutil.copy2(ROOT/'web'/name,OUT/name)
for name in ['frag-grenade.svg','stink-bomb.svg','roach-bomb.svg']:
 shutil.copy2(ROOT/'assets/ui'/name,OUT/name)
for name in ['comedy.svg','roach.svg']:shutil.copy2(ROOT/'assets/ui/settings'/name,OUT/name)
for src,dst in [('assets/fonts/OFL.txt','FONT-LICENSE.txt'),('assets/fonts/GlowSans-OFL.txt','GlowSans-LICENSE.txt')]:shutil.copy2(ROOT/src,OUT/dst)
# Use the trial's native frame during loading; no old-map preview or saved map selection.
opening=REVIEW/'title-background.webp'
if opening.exists():shutil.copy2(opening,OUT/'title-background.webp')
html=(OUT/'index.html').read_text().replace('<title>NO ART FPS</title>','<title>Moonbase Trial</title>')
html=html.replace('<body','<body class="moonbase"',1)
html=html.replace('no-art-fps.title.v1','moonbase-trial.title.v1')
(OUT/'index.html').write_text(html)
for name in ['index.png','index.png.import','icon.svg.import']:(OUT/name).unlink(missing_ok=True)
data=(OUT/'index.pck').read_bytes(); header=struct.unpack_from('<6I2Q',data)
assert header[0]==0x43504447 and header[1] in [3,4]
directory=header[-1];count,=struct.unpack_from('<I',data,directory);offset=directory+4;paths=[]
for _ in range(count):
 length,=struct.unpack_from('<I',data,offset);offset+=4
 paths.append(data[offset:offset+length].rstrip(b'\0').decode());offset+=length+36
sessions=[p for p in paths if 'data/sessions/' in p]
maps=[p for p in paths if 'scenes/maps/' in p]
assert sessions and all('moonbase_trial' in p for p in sessions),sessions
assert maps and all('moonbase_trial' in p for p in maps),maps
for p in paths:
 assert not any(x in p for x in ['docs/','art_source/','tests/','artifacts/','.blend']),p
 for old in ['sandgate','park','ferry','studio','bb_office','hogwarts','snowline','palm_house','ginza_station','rain_market','baggage_below']:
  assert 'assets/models/'+old+'/' not in p,p
report={'pck_bytes':len(data),'packed_resources':len(paths),'sessions':sessions,'maps':maps,'note':'Common legacy character/UI/FX dependencies remain until replacement; no original map geometry or sessions.'}
(REVIEW/'package-audit.json').write_text(json.dumps(report,indent=2)+'\n')
manifest={p.name:{'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in OUT.iterdir() if p.is_file() and p.name!='manifest.json'}
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('MOONBASE_EXPORT_PASS',json.dumps(report))
