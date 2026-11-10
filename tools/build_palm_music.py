"""Render the Palm House score: marimba, kalimba and steel pan over a light samba groove."""
import numpy as np

from build_music import PPQ, RATE, write_midi, write_ogg

NAME = "palm_house"
BPM = 128
METER = 4
BARS = 32
FRENZY_BAR = 24
COUNTDOWN = 50
PARTS = (
    ("Marimba", 12, 0), ("Kalimba", 108, 1), ("Steel pan", 114, 2),
    ("Finger bass", 33, 3), ("Hand percussion", 0, 9),
)
# Bass root and kalimba voicing for F, Dm, Bb, C, then Gm7, C7, Am7, Dm.
HARMONY = (
    (41, (65, 69, 72, 76)), (38, (62, 65, 69, 72)), (46, (62, 65, 70, 74)), (36, (64, 67, 72, 74)),
    (43, (62, 65, 67, 70)), (36, (64, 67, 70, 72)), (45, (64, 67, 69, 72)), (38, (62, 65, 69, 74)),
)
THEME = (
    ((0, 81, .4), (.75, 79, .2), (1.5, 77, .4), (2.5, 79, .3), (3, 81, .7)),
    ((.5, 77, .3), (1, 74, .4), (2, 72, .3), (2.75, 74, .6)),
    ((0, 77, .4), (.75, 79, .2), (1.5, 82, .5), (2.5, 81, .3), (3.25, 79, .4)),
    ((0, 76, .6), (1, 72, .3), (1.75, 74, .3), (2.5, 76, .9)),
    ((0, 79, .4), (.75, 77, .2), (1.5, 74, .4), (2.5, 77, .3), (3, 79, .6)),
    ((.5, 76, .3), (1, 79, .4), (2, 82, .3), (2.75, 81, .6)),
    ((0, 84, .4), (.75, 81, .2), (1.5, 79, .4), (2.5, 76, .3), (3, 77, .5)),
    ((0, 74, .9), (1.5, 72, .3), (2.25, 74, .3), (3, 77, .7)),
)


def compose():
    tracks = [[] for _ in PARTS]
    for bar in range(BARS):
        at = bar * METER
        rush = bar >= FRENZY_BAR
        quiet = at + METER > COUNTDOWN * BPM / 60
        phase = bar % len(HARMONY)
        root, chord = HARMONY[phase]

        def note(part, beat, pitch, length, velocity):
            start = round((at + beat) * PPQ)
            end = min(round((at + beat + length) * PPQ), BARS * METER * PPQ)
            if end > start:
                tracks[part].append((start, end - start, pitch, velocity))

        for index, (beat, pitch, length) in enumerate(THEME[phase]):
            note(0, beat, pitch, length * (.7 if rush else 1), (70 if quiet else 88) - index * 3)
            if rush and not quiet:
                note(2, beat, pitch - 12, length * .8, 90 - index * 4)
                note(0, beat + .25, pitch + (5 if index % 2 else 7) - 12, .18, 62)

        arpeggio = (0, .5, 1, 1.5, 2, 2.5, 3, 3.5)
        if rush and not quiet:
            arpeggio = tuple(i * .25 for i in range(16))
        if quiet:
            arpeggio = arpeggio[::2]
        for index, beat in enumerate(arpeggio):
            note(1, beat, chord[(index * 3) % 4] + (12 if rush and index % 4 == 3 else 0), .3, 58 + (index % 4 == 0) * 10)

        for beat, offset, length in ((0, 0, .9), (1.5, 7, .35), (2, 0, .45), (3.5, 7, .4)):
            note(3, beat, root + offset, length * (.6 if rush else 1), 92 if beat == 0 else 76)
        if rush and not quiet:
            note(3, 2.75, root + 12, .2, 70)

        if quiet:
            note(4, 0, 64, .2, 90)
            note(4, 2, 63, .2, 70)
            continue
        surdo = ((0, 64, 96), (1, 63, 70), (2, 64, 88), (3, 63, 74))
        if rush:
            surdo += ((.75, 63, 72), (2.5, 62, 84), (3.5, 62, 80))
        for beat, pitch, velocity in surdo:
            note(4, beat, pitch, .2, velocity)
        spacing = .125 if rush else .25
        for j in range(round(METER / spacing)):
            note(4, j * spacing, 70, .06, 66 if j % 4 == 2 else 44)
        for beat in ((.75, 2.25, 3.25) if not rush else (.75, 1.5, 2.25, 3.25, 3.75)):
            note(4, beat, 75, .08, 74)
    return tracks


def voice(part, pitch, time, noise):
    phase = 2 * np.pi * 440 * 2 ** ((pitch - 69) / 12) * time
    sine = np.sin
    exp = np.exp
    if part == 0:
        bar = sine(phase) + .32 * sine(3.93 * phase) * exp(-time * 22) + .12 * sine(9.2 * phase) * exp(-time * 40)
        return .30 * bar * exp(-time * 6.5)
    if part == 1:
        tine = sine(phase) + .26 * sine(5.4 * phase) * exp(-time * 30) + .08 * sine(2.01 * phase)
        return .17 * tine * exp(-time * 4.2)
    if part == 2:
        pan = sine(phase) + .55 * sine(2.0 * phase) * exp(-time * 4) + .34 * sine(3.01 * phase) * exp(-time * 6)
        pan += .22 * sine(4.48 * phase) * exp(-time * 9)
        return .21 * pan * exp(-time * 3.1)
    if part == 3:
        pluck = np.tanh(1.6 * (sine(phase) + .22 * sine(2 * phase) * exp(-time * 9)))
        return .36 * pluck * exp(-time * 2.6)
    hiss = noise.uniform(-1, 1, len(time))
    crisp = hiss - np.roll(hiss, 1)
    if pitch == 70:
        return .05 * crisp * exp(-time * 60)
    if pitch == 75:
        return .16 * sine(2 * np.pi * 2350 * time) * exp(-time * 70)
    drop = {64: 92, 63: 128, 62: 176}[pitch]
    skin = 2 * np.pi * (drop * time + drop * .6 * (1 - exp(-30 * time)) / 30)
    return (.42 * sine(skin) + .05 * hiss * exp(-time * 40)) * exp(-time * 11)


def render(tracks):
    frames = BARS * METER * RATE * 60 // BPM
    mix = np.zeros((frames, 2), dtype=np.float32)
    noise = np.random.default_rng(2026)
    seconds_per_tick = 60 / (BPM * PPQ)
    for part, events in enumerate(tracks):
        pan, attack, release = (
            (.22, .002, .12), (-.34, .003, .16), (.36, .004, .14),
            (0, .006, .07), (-.10, .001, .04),
        )[part]
        stem = np.zeros(frames, dtype=np.float32)
        for tick, length, pitch, velocity in events:
            offset = round(tick * seconds_per_tick * RATE)
            duration = length * seconds_per_tick
            count = min(round((duration + release) * RATE), frames - offset)
            time = np.arange(count) / RATE
            envelope = np.minimum(time / attack, 1) * np.clip((duration + release - time) / release, 0, 1)
            stem[offset:offset + count] += voice(part, pitch, time, noise) * envelope * (velocity / 127)
        mix[:, 0] += stem * np.sqrt((1 - pan) * .5)
        mix[:, 1] += stem * np.sqrt((1 + pan) * .5)
        if part in (0, 1, 2):
            for delay, level, channel in ((.088, .12, 1), (.176, .07, 0), (.351, .04, 1)):
                samples = round(delay * RATE)
                mix[samples:, channel] += stem[:-samples] * level

    # Leave room for the timer tick and the final explosion.
    time = np.arange(frames) / RATE
    mix *= (1 - .30 * np.clip((time - COUNTDOWN + .15) / .15, 0, 1))[:, None]
    mix[-RATE // 5:] *= np.linspace(1, 0, RATE // 5)[:, None]
    return np.tanh(1.4 * mix) * .86


if __name__ == "__main__":
    score = compose()
    write_midi(NAME, score, BPM, BARS, PARTS, meter=METER,
               markers=((FRENZY_BAR * METER, "Frenzy"), (COUNTDOWN * BPM / 60, "Countdown")))
    audio = render(score)
    write_ogg(NAME, audio)
    print(f"MUSIC_OK {NAME}: {BPM} BPM, frenzy at bar {FRENZY_BAR}, peak {np.abs(audio).max():.2f}")
