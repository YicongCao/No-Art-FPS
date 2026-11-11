"""Render the Ginza Station score: city-pop keys, slap bass and an original departure-chime motif."""
import numpy as np

from build_music import PPQ, RATE, write_midi, write_ogg

NAME = "ginza_station"
BPM = 128
METER = 4
BARS = 32
FRENZY_BAR = 24
COUNTDOWN = 50
PARTS = (
    ("Station chime", 9, 0), ("Electric piano", 4, 1), ("Synth brass", 62, 2),
    ("Slap bass", 36, 3), ("Drum machine", 0, 9),
)
# City-pop changes in E: Amaj7, G#m7, F#m7, Bsus, then C#m7, F#m7, Dmaj7, E.
HARMONY = (
    (45, (61, 64, 68, 71)), (44, (59, 63, 66, 68)), (42, (61, 64, 66, 69)), (47, (59, 64, 66, 69)),
    (49, (59, 61, 64, 68)), (42, (61, 64, 66, 69)), (38, (61, 62, 66, 69)), (40, (59, 63, 64, 68)),
)
# Original eight-note departure-chime phrase, answered by a lower variant.
THEME = (
    ((0, 76, .3), (.5, 80, .3), (1, 83, .3), (1.5, 88, .5), (2.5, 85, .3), (3, 83, .6)),
    ((.5, 80, .3), (1, 81, .3), (1.5, 83, .9)),
    ((0, 76, .3), (.5, 80, .3), (1, 83, .3), (1.5, 88, .5), (2.5, 90, .3), (3, 88, .6)),
    ((0, 85, .5), (1, 83, .3), (1.5, 81, .3), (2, 80, 1.2)),
    ((0, 73, .3), (.5, 76, .3), (1, 80, .3), (1.5, 85, .5), (2.5, 83, .3), (3, 80, .6)),
    ((.5, 78, .3), (1, 80, .3), (1.5, 81, .9)),
    ((0, 78, .3), (.5, 81, .3), (1, 85, .5), (2, 86, .3), (2.5, 85, .3), (3, 81, .4)),
    ((0, 83, .6), (1, 80, .3), (2, 76, 1.4)),
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
        surdo = ((0, 64, 96), (1, 62, 90), (2, 64, 88), (2.5, 64, 70), (3, 62, 92))
        if rush:
            surdo += ((.75, 64, 80), (1.5, 64, 76), (3.5, 62, 70))
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
        bell = sine(phase) + .42 * sine(2.0 * phase) * exp(-time * 3) + .18 * sine(3.0 * phase) * exp(-time * 7)
        return .24 * bell * exp(-time * 2.4)
    if part == 1:
        tine = sine(phase + .9 * exp(-time * 6) * sine(phase)) + .14 * sine(7.0 * phase) * exp(-time * 40)
        return .15 * tine * exp(-time * 2.2)
    if part == 2:
        saw = sum(sine(k * phase) / k for k in range(1, 6))
        return .13 * np.tanh(1.4 * saw) * np.clip(time * 18, 0, 1) * exp(-time * 2.5)
    if part == 3:
        slap = np.tanh(2.2 * (sine(phase) + .5 * sine(2 * phase) * exp(-time * 14)))
        return .34 * slap * exp(-time * 4.2)
    hiss = noise.uniform(-1, 1, len(time))
    crisp = hiss - np.roll(hiss, 1)
    if pitch == 70:
        return .05 * crisp * exp(-time * 60)
    if pitch == 75:
        return .16 * sine(2 * np.pi * 2350 * time) * exp(-time * 70)
    if pitch == 62:
        return (.22 * hiss * exp(-time * 22) + .12 * sine(2 * np.pi * 190 * time) * exp(-time * 30))
    skin = 2 * np.pi * (52 * time + 70 * (1 - exp(-32 * time)) / 32)
    return .5 * sine(skin) * exp(-time * 13)


def render(tracks):
    frames = BARS * METER * RATE * 60 // BPM
    mix = np.zeros((frames, 2), dtype=np.float32)
    noise = np.random.default_rng(909)
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
