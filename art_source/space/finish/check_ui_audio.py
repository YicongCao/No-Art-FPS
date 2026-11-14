from pathlib import Path
from fontTools.ttLib import TTFont
import json,wave,numpy as np
ROOT=Path(__file__).resolve().parents[3]
fonts=[TTFont(ROOT/'assets/fonts/space'/name) for name in ['Oxanium.ttf','NotoSansSC.otf']]
coverage=set().union(*(set(f.getBestCmap()) for f in fonts))
text=(ROOT/'data/ui_text.csv').read_text()+'月球基地氧气发生器服务站过载LUNAR OUTPOST0123456789:/ '
missing=sorted({c for c in text if ord(c)>32 and ord(c) not in coverage})
assert not missing,missing
font=fonts[0];cmap=font.getBestCmap();widths=[font['hmtx'][cmap[ord(d)]][0] for d in '0123456789'];assert len(set(widths))==1
sounds={}
for p in sorted((ROOT/'assets/audio/space').glob('*.wav')):
 with wave.open(str(p),'rb') as w:
  samples=np.frombuffer(w.readframes(w.getnframes()),dtype='<i2')
  peak=int(np.abs(samples.astype(np.int32)).max());duration=w.getnframes()/w.getframerate()
  assert peak<32767 and duration>0
  sounds[p.name]={'duration_s':duration,'sample_rate':w.getframerate(),'peak_pcm':peak}
assert sounds['lunar-round.wav']['duration_s']==60
report={'font_missing_characters':missing,'digit_advance_widths':widths,'audio':sounds,'note':'Glyph coverage and file integrity, not a listening or physical-device test.'}
(ROOT/'docs/art/space/review-d/ui-audio-check.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
print('SPACE_UI_AUDIO_CHECK_PASS')
