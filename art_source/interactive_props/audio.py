import math,random,wave,struct
from pathlib import Path
out=Path(__file__).resolve().parents[2]/'assets/audio'
rng=random.Random(271)
for kind,freq,duration in [('ceramic',1550,.20),('glass',2700,.25),('wood',350,.14),('metal',960,.30),('paper',240,.18),('soft',100,.12),('soil',160,.16)]:
 samples=[]
 for i in range(int(22050*duration)):
  t=i/22050;env=math.exp(-t/(duration*.19));noise=rng.uniform(-1,1)
  tone=sum(math.sin(2*math.pi*freq*f*t)*a for f,a in [(1,.5),(1.59,.25),(2.71,.15)])
  if kind in ['paper','soil','soft']:tone=noise*.6+math.sin(2*math.pi*freq*t)*.2
  samples.append(int(15000*env*(tone*.65+noise*.25)))
 with wave.open(str(out/('prop_'+kind+'.wav')),'wb') as w:w.setparams((1,2,22050,0,'NONE',''));w.writeframes(struct.pack('<%dh'%len(samples),*samples))
