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
def rifle_shot():
    low = mid = 0.0

    def sample(t):
        nonlocal low, mid
        noise = random.uniform(-1, 1)
        low += .055 * (noise - low)
        mid += .27 * (noise - mid)
        crack = 1.05 * (noise - mid) * math.exp(-t * 210)
        pressure = (1.2 * mid + .65 * low) * math.exp(-t * 49)
        thump = .64 * math.sin(math.tau * (145 * t - 360 * t * t)) * math.exp(-t * 55)
        air = .18 * (mid - low) * math.exp(-t * 24)
        reflections = sum(
            gain * (mid + .32 * noise) * math.exp(-(t - delay) * 100)
            for delay, gain in ((.022, .32), (.048, .15)) if t >= delay
        )
        action_time = t - .029
        action = 0.0
        if action_time >= 0:
            action = .08 * math.sin(math.tau * 1850 * action_time) * math.exp(-action_time * 190)
        edge = min(1.0, t / .00025, (.16 - t) / .01)
        return edge * math.tanh(1.35 * (crack + pressure + thump + air + reflections + action))

    return sample


def magazine_latch(t):
    noise = random.uniform(-1, 1)
    slide = .19 * noise * math.exp(-t * 170)
    snap_time = t - .013
    if snap_time < 0:
        return slide
    snap = (.46 * noise + .4 * math.sin(math.tau * 540 * snap_time)) * math.exp(-snap_time * 135)
    ring = .19 * math.sin(math.tau * 2350 * snap_time) * math.exp(-snap_time * 105)
    return slide + snap + ring


write('shot',.16,rifle_shot())
write('hit',.07,lambda t:(math.sin(2*math.pi*850*t)*.5+random.uniform(-1,1)*.2)*math.exp(-t*55))
write('kill',.20,lambda t:math.sin(2*math.pi*(850*t+1800*t*t))*.4*math.exp(-t*18))
write('headshot',.27,lambda t:(math.sin(2*math.pi*1380*t)+math.sin(2*math.pi*2070*t))*.22*math.exp(-t*14))
write('reload',.3,lambda t:random.uniform(-1,1)*.35*(math.exp(-t*80)+.7*math.exp(-abs(t-.19)*95)))
write('hurt',.18,lambda t:math.sin(2*math.pi*(160*t-150*t*t))*.45*math.exp(-t*22))
write('tick',.10,lambda t:math.sin(2*math.pi*650*t)*.22*math.exp(-t*40))
write('end',.7,lambda t:(math.sin(2*math.pi*440*t)+math.sin(2*math.pi*660*t))*.2*math.exp(-t*5))
write('fuse',.65,lambda t:math.sin(2*math.pi*(600*t+450*t*t))*.22*(.25+.75*max(0,math.sin(t*55))))
write('explosion',.7,lambda t:(random.uniform(-1,1)*.65+math.sin(2*math.pi*(65*t-30*t*t))*.5)*math.exp(-t*7))
write('charge',.75,lambda t:(math.sin(2*math.pi*(220*t+400*t*t))*.3+math.sin(2*math.pi*660*t)*.08)*min(1,t*30)*math.exp(-t*1.8))
write('cartridge_insert',.032,lambda t:(random.uniform(-1,1)*.42+math.sin(2*math.pi*1600*t)*.28+math.sin(2*math.pi*3100*t)*.12)*math.exp(-t*180))
write('magazine_latch',.105,magazine_latch)
print('Thirteen original WAV effects generated')
