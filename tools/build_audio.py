"""Generate small original procedural effects; no external sound assets."""
from pathlib import Path
import math, random, struct, wave
root=Path(__file__).resolve().parents[1]/'assets/audio'
root.mkdir(parents=True,exist_ok=True)
random.seed(42)
rate=22050
def write(name,duration,fn):
    with wave.open(str(root/(name+'.wav')),'wb') as f:
        f.setparams((1,2,rate,0,'NONE','not compressed'))
        f.writeframes(b''.join(struct.pack('<h',int(max(-1,min(1,fn(i/rate)))*24000)) for i in range(int(duration*rate))))
write('shot',.16,lambda t:(random.uniform(-1,1)*.55+math.sin(2*math.pi*(95*t-160*t*t))*.5)*math.exp(-t*34))
write('hit',.07,lambda t:(math.sin(2*math.pi*850*t)*.5+random.uniform(-1,1)*.2)*math.exp(-t*55))
write('kill',.20,lambda t:math.sin(2*math.pi*(850*t+1800*t*t))*.4*math.exp(-t*18))
write('headshot',.27,lambda t:(math.sin(2*math.pi*1380*t)+math.sin(2*math.pi*2070*t))*.22*math.exp(-t*14))
write('reload',.3,lambda t:random.uniform(-1,1)*.35*(math.exp(-t*80)+.7*math.exp(-abs(t-.19)*95)))
write('hurt',.18,lambda t:math.sin(2*math.pi*(160*t-150*t*t))*.45*math.exp(-t*22))
write('tick',.10,lambda t:math.sin(2*math.pi*650*t)*.22*math.exp(-t*40))
write('end',.7,lambda t:(math.sin(2*math.pi*440*t)+math.sin(2*math.pi*660*t))*.2*math.exp(-t*5))
print('Eight original WAV effects generated')
