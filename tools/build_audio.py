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


def magazine_latch():
    rng = random.Random(815)
    smooth_noise = 0.0

    def sample(t):
        nonlocal smooth_noise
        noise = rng.uniform(-1, 1)
        smooth_noise += .24 * (noise - smooth_noise)
        # A short guide scrape, the body seating, then the spring catch.
        scrape = .30 * (noise - smooth_noise) * math.sin(math.pi * t / .021) if t < .021 else 0.0
        seat_time = t - .023
        seat = 0.0
        if seat_time >= 0:
            body = .69 * math.sin(math.tau * 289 * seat_time) + .24 * math.sin(math.tau * 683 * seat_time)
            seat = (body + .26 * smooth_noise) * math.exp(-seat_time * 163)
        catch_time = t - .038
        catch = 0.0
        if catch_time >= 0:
            modes = sum(
                gain * math.sin(math.tau * frequency * catch_time) * math.exp(-decay * catch_time)
                for frequency, gain, decay in ((911, .44, 157), (1763, .32, 205), (3227, .23, 273), (5101, .17, 350))
            )
            catch = modes + .65 * (noise - smooth_noise) * math.exp(-catch_time * 520)
        return math.tanh(1.45 * (scrape + seat + catch))

    return sample


def comedy_plop():
    rng = random.Random(302)
    filtered = 0.0

    def sample(t):
        nonlocal filtered
        filtered += .22 * (rng.uniform(-1, 1) - filtered)
        body = .72 * math.sin(math.tau * (220 * t - 425 * t * t)) * math.exp(-t * 22)
        splash = .72 * filtered * math.exp(-t * 35)
        bubble = max(0.0, t - .063)
        tail = .26 * math.sin(math.tau * (470 * bubble - 1250 * bubble * bubble)) * math.exp(-bubble * 47)
        return min(1.0, t * 650) * (body + splash + tail)

    return sample


def roach_buzz(t):
    flap = math.sin(math.tau * (51 * t - 72 * t * t))
    buzz = math.sin(math.tau * (405 * t - 650 * t * t) + flap * 1.6)
    pop = math.sin(math.tau * (205 * t - 215 * t * t)) * math.exp(-t * 52)
    return min(1.0, t * 260) * (.48 * buzz * math.exp(-t * 24) + .5 * pop)


def water_shot(t):
    jet = math.sin(math.tau * (980*t - 2100*t*t) + .7*math.sin(math.tau*76*t))
    pump = math.sin(math.tau * (220*t - 490*t*t))
    return min(1.0, t*530) * (.36*jet*math.exp(-t*31) + .47*pump*math.exp(-t*50))


def slipper_shot(t):
    slap = math.sin(math.tau*268*t) + .42*math.sin(math.tau*870*t)
    return min(1.0, t*720) * .56*slap*math.exp(-t*54)


def roach_grenade():
    rng = random.Random(403)
    smoothed = 0.0

    def sample(t):
        nonlocal smoothed
        noise = rng.uniform(-1, 1)
        smoothed += .22 * (noise - smoothed)
        pressure = .45 * math.sin(math.tau * (134 * t - 220 * t * t)) * math.exp(-t * 27)
        cracks = 0.0
        for delay, weight in ((0.0, .80), (.049, .62)):
            age = t - delay
            if age >= 0:
                snap = (noise - smoothed) + .36 * math.sin(math.tau * 1250 * age)
                cracks += weight * snap * math.exp(-age * 108) * min(1.0, age * 2400)
        return math.tanh(pressure + cracks)

    return sample


def enemy_raise():
    rng = random.Random(116)

    def sample(t):
        noise = rng.uniform(-1, 1)
        sound = 0.0
        for delay, pitch, weight in ((0, 1640, .40), (.066, 2430, .73)):
            age = t - delay
            if age >= 0:
                metal = math.sin(math.tau * pitch * age) + .38 * math.sin(math.tau * pitch * 1.83 * age)
                sound += weight * (metal + .42 * noise) * math.exp(-age * 140) * min(1.0, age * 2400)
        return math.tanh(sound)

    return sample


def heartbeat(t):
    sound = 0.0
    for offset, strength, frequency in ((0.0, 1.0, 83), (.145, .67, 105)):
        age = t - offset
        if age < 0:
            continue
        phase = math.tau * (frequency * age - 74 * age * age)
        pulse = math.sin(phase) + .34 * math.sin(2 * phase) + .12 * math.sin(3 * phase)
        attack = min(1.0, age / .013)
        sound += strength * pulse * attack * math.exp(-age * 31)
    tail = min(1.0, (.34 - t) / .028)
    return math.tanh(sound * 1.35) * tail


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
write('magazine_latch',.125,magazine_latch())
write('comedy_plop',.18,comedy_plop())
write('roach_buzz',.16,roach_buzz)
write('water_shot',.13,water_shot)
write('slipper_shot',.11,slipper_shot)
write('roach_grenade',.24,roach_grenade())
write('enemy_raise',.17,enemy_raise())
write('heartbeat',.34,heartbeat)
print('Twenty original WAV effects generated')
