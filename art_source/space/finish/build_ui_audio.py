from pathlib import Path
import json,hashlib,shutil,wave
import numpy as np
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont
from fontTools import subset
ROOT=Path(__file__).resolve().parents[3];OUT=ROOT/'assets/fonts/space';OUT.mkdir(exist_ok=True)
text=''.join(p.read_text() for folder in ['scripts','web','data'] for p in (ROOT/folder).rglob('*') if p.suffix in ['.gd','.js','.csv'])+'LUNAR OUTPOST O2 0123456789 :/ 过载 月球基地 氧气发生器 服务站'
chars=set(map(ord,text));manifest={}
for name,source,license in [('Oxanium','Oxanium.ttf','Oxanium-OFL.txt'),('NotoSansSC','NotoSansCJKsc-Medium.otf','NotoSansCJK-OFL.txt')]:
 font=TTFont(ROOT/'artifacts/local/moonbase-plan'/source)
 if 'fvar' in font:font=instantiateVariableFont(font,{'wght':700},inplace=True)
 opts=subset.Options();opts.layout_features=['*'];sub=subset.Subsetter(opts);sub.populate(unicodes=chars);sub.subset(font)
 cmap=font.getBestCmap();suffix='.otf' if name=='NotoSansSC' else '.ttf';font.save(OUT/(name+suffix));font.flavor='woff2';font.save(OUT/(name+'.woff2'))
 shutil.copy2(ROOT/'docs/design/moonbase-plan-2026-11-13/fonts'/license,OUT/license)
 manifest[name]={'glyphs':len(cmap),'sha256':hashlib.sha256((OUT/(name+suffix)).read_bytes()).hexdigest()}
 if name=='Oxanium':assert len({font['hmtx'][cmap[ord(d)]][0] for d in '0123456789'})==1
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
# Original synthesized mechanical/ion sounds; no downloaded samples.
audio=ROOT/'assets/audio/space';audio.mkdir(exist_ok=True);sr=22050;rng=np.random.default_rng(71114)
def save(name,s):
 s=np.tanh(s);s*=.82/max(.82,float(np.max(np.abs(s))))
 with wave.open(str(audio/(name+'.wav')),'wb') as f:f.setnchannels(1);f.setsampwidth(2);f.setframerate(sr);f.writeframes((s*32767).astype('<i2').tobytes())
for name,duration,pitch in [('moon_step',.18,90),('shot',.22,150),('enemy_raise',.32,680),('charge',.4,410),('reload',.35,240),('cartridge_insert',.08,900),('magazine_latch',.12,350),('headshot',.28,1250),('hit',.10,760),('prop_metal',.24,950),('explosion',.8,55),('tick',.08,1200)]:
 t=np.arange(int(duration*sr))/sr;noise=rng.normal(size=t.size);tone=np.sin(2*np.pi*(pitch*t+pitch*.7*t*t))
 if name=='shot':s=.55*noise*np.exp(-t*75)+.5*np.sin(2*np.pi*(180*t-160*t*t))*np.exp(-t*22)+.12*np.sin(2*np.pi*2200*t)*np.exp(-t*35)
 elif name=='explosion':s=noise*np.exp(-t*6)*.4+np.sin(2*np.pi*55*t)*np.exp(-t*8)*.6
 else:s=.22*tone*np.exp(-t*9/duration)+.18*noise*np.exp(-t*18/duration)
 s*=np.minimum(t/.002,1)*np.minimum((duration-t)/.01,1);save(name,s)
t=np.arange(sr*60)/sr;s=np.zeros_like(t)
for freq in [55,82.4069,110,164.8138]:s+=.015*np.sin(2*np.pi*freq*t+.15*np.sin(t*.4))
for beat in np.arange(0,60,.6):
 i=int(beat*sr);n=min(int(.25*sr),len(s)-i);u=np.arange(n)/sr;gain=.11 if beat<45 else .18
 s[i:i+n]+=gain*np.sin(2*np.pi*(62*u-30*u*u))*np.exp(-u*25)
 if beat>=45:s[i:i+n]+=.035*rng.normal(size=n)*np.exp(-u*40)
s*=np.minimum(t/2,1)*np.minimum((60-t)/.6,1);save('lunar-round',s)
(audio/'SOURCE.txt').write_text('Original deterministic synthesis by art_source/space/finish/build_ui_audio.py. No external samples. 22050 Hz mono PCM.\n')
print('SPACE_UI_AUDIO_PASS',manifest)
