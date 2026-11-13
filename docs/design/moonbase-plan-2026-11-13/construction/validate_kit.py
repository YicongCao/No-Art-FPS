"""Check drawing coverage, dimensions, references, embedded resources and type coverage."""
from pathlib import Path
from html.parser import HTMLParser
from collections import Counter
from math import isfinite
from xml.etree import ElementTree as ET
import json,re,hashlib
from build_kit import PARTS,ASSEMBLIES,VIEWS,bounds,dot,unit
OUT=Path(__file__).resolve().parent
class Page(HTMLParser):
 def __init__(self):super().__init__();self.ids=[];self.links=[];self.resources=[];self.text=[];self.skip=0
 def handle_starttag(self,t,aa):
  a=dict(aa)
  if 'id'in a:self.ids.append(a['id'])
  if t=='a':self.links.append(a.get('href',''))
  if t in ('style','script'):self.skip+=1
  if 'src'in a:self.resources.append(a['src'])
 def handle_endtag(self,t):
  if t in ('style','script'):self.skip-=1
 def handle_data(self,d):
  if not self.skip:self.text.append(d)
page=(OUT/'index.html').read_text();a=Page();a.feed(page)
assert len(a.ids)==len(set(a.ids))
assert not [l for l in a.links if l.startswith('#') and l[1:] not in a.ids]
assert all(x.startswith('data:') for x in a.resources)
assert not re.search(r'url\((?!data:|#)',page)
assert (OUT/'../index.html').resolve().exists()
assert len(PARTS)==43 and len(ASSEMBLIES)==12 and len(VIEWS)==5
assert VIEWS[4][2]==(0,0,-1)
ids={p['id'] for p in PARTS}
for p in PARTS:
 assert 'part-'+p['id'] in a.ids
 assert all(isfinite(c) for f,col in p['mesh'] for v in f for c in v)
 mn,mx=bounds(p['mesh']);assert all(mx[k]>mn[k] for k in range(3))
 assert [round(mx[k]-mn[k],4) for k in range(3)]==p['bounds_size']
 src=(OUT/'sheets'/(p['id']+'.svg')).read_text();root=ET.fromstring(src)
 for name,*_ in VIEWS:assert src.count(name)==1
 for forbidden in ('nan','Infinity','href="http'):assert forbidden not in src
 assert root.attrib['viewBox']=='0 0 1440 1050'
for m in ASSEMBLIES:
 assert m['id'] in a.ids
 assert all(row['part'] in ids for row in m['bom'])
 ET.parse(OUT/'assemblies'/(m['id']+'.svg'))
ET.parse(OUT/'layout-v1.1.svg')
# Validate the proposed centre line with a 1.75 m clearance against key rectangular proxies.
from build_layout import route
obstacles=[(-18.5,-8,-6.5,6),(-3,-15,0,-7),(3.5,-15,6.5,-7),(-3.5,-2.4,-.5,-1.6),(2.6,3.5,3.4,6.5),(-5.5,8.6,-2.5,9.4),(-12,13.25,-6,16.75),(6.75,13,13.25,17)]
def distance_to_box(x,z,b):return max(b[0]-x,0,x-b[2])**2+max(b[1]-z,0,z-b[3])**2
min_clear=999
for (x0,z0),(x1,z1) in zip(route,route[1:]):
 for j in range(1001):
  t=j/1000;x=x0+(x1-x0)*t;z=z0+(z1-z0)*t
  min_clear=min(min_clear,*(distance_to_box(x,z,b)**.5 for b in obstacles))
assert min_clear>=1.75-1e-6,min_clear
# CJK visible HTML coverage. SVGs use platform text fallback in standalone image documents.
from fontTools.ttLib import TTFont
font=TTFont(OUT/'NotoKit.woff2');cmap=font.getBestCmap()
missing=sorted({c for c in ''.join(a.text) if '\u4e00'<=c<='\u9fff' and ord(c) not in cmap});assert not missing,missing
report={'date':'2026-11-13','parts':43,'orthographic_views':215,'assembly_drawings':12,'site_plans':1,'svg_files_parsed':56,'internal_links_broken':0,'external_runtime_resources':0,'visible_html_han_missing':0,'route_half_width_clearance_to_selected_proxies_m':round(min_clear,3),'route_validation':'2D rectangular proposal only; not navigation, exact art envelopes or jump validation','html_sha256':hashlib.sha256(page.encode()).hexdigest(),'html_bytes':len(page.encode())}
(OUT/'static-validation.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n');print(json.dumps(report,ensure_ascii=False))
