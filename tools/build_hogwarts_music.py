"""Render the Hogwarts score. Run with Blender's Python and ffmpeg on PATH."""
import numpy as np

from build_music import PPQ, RATE, write_midi, write_ogg

NAME = "hogwarts"
BPM = 120
METER = 3
BARS = 40
FRENZY_BAR = 30
COUNTDOWN = 50
PARTS = (
    ("Celesta", 8, 0), ("Harp", 46, 1), ("Clarinet", 71, 2),
    ("Chamber strings", 48, 3), ("Timpani", 47, 4),
)
# Bass, harp voicing, and the answering clarinet note.
HARMONY = (
    (38, (50, 57, 64, 65), 69), (34, (53, 57, 60, 62), 65),
    (41, (53, 57, 60, 67), 69), (35, (50, 56, 62, 65), 68),
    (43, (55, 58, 62, 69), 70), (39, (51, 58, 62, 67), 67),
    (33, (52, 55, 58, 61), 73), (38, (50, 57, 64, 65), 69),
)
THEME = (
    ((0, 77, .52), (.75, 76, .21), (1.25, 81, .70), (2.5, 74, .32)),
    ((.5, 72, .33), (1, 77, .39), (2, 69, .64)),
    ((0, 76, .52), (.75, 77, .23), (1.5, 84, .82)),
    ((.25, 83, .25), (.75, 80, .33), (1.75, 77, .82)),
    ((0, 79, .50), (.75, 81, .23), (1.25, 82, .63), (2.5, 77, .31)),
    ((.5, 74, .34), (1, 79, .42), (2, 75, .57)),
    ((0, 76, .50), (.75, 82, .24), (1.5, 81, .34), (2, 73, .69)),
    ((0, 74, 1.42), (2, 69, .37), (2.5, 76, .25)),
)


def compose():
    tracks = [[] for _ in PARTS]

    for bar in range(BARS):
        at = bar * METER
        rush = bar >= FRENZY_BAR
        quiet = at + METER > COUNTDOWN * BPM / 60
        phase = (bar - FRENZY_BAR if rush else bar) % len(HARMONY)
        root, chord, answer = HARMONY[phase]

        def note(part, beat, pitch, length, velocity):
            start = round((at + beat) * PPQ)
            end = min(round((at + beat + length) * PPQ), BARS * METER * PPQ)
            tracks[part].append((start, end - start, pitch, velocity))

        for index, (beat, pitch, length) in enumerate(THEME[phase]):
            note(0, beat, pitch, length * (.72 if rush else 1), (72 if quiet else 86) - index * 4)
            if rush and not quiet and index == 0:
                note(2, beat, pitch - 12, .32, 84)

        harp = ((0, 0), (.5, 1), (1, 2), (1.5, 3), (2, 1), (2.5, 2))
        if quiet:
            harp = harp[::2]
        for index, (beat, tone) in enumerate(harp):
            note(1, beat, chord[tone], .35 if rush else .47, 65 - index * 2)

        if not rush:
            note(2, 1.5, answer, 1.24, 60)
            note(3, 0, root, 2.90, 74)
            note(3, .06, chord[3], 2.80, 45)
            if phase in (3, 6):
                note(4, 0, root, .55, 53)
            continue

        steps = (0, .5, 1, 1.5, 2, 2.5) if quiet else (0, .25, .75, 1, 1.5, 1.75, 2.25, 2.5, 2.75)
        for index, beat in enumerate(steps):
            pitch = root if index % 3 != 2 else chord[1]
            note(3, beat, pitch, .16, 77 if quiet else 100 - index % 3 * 11)
        for beat in ((0,) if quiet else (0, 1.5, 2.5)):
            note(4, beat, root, .32, 79 if quiet else 104 - round(beat * 9))
    return tracks


def voice(part, pitch, time, noise):
    phase = 2 * np.pi * 440 * 2 ** ((pitch - 69) / 12) * time
    sine = np.sin
    exp = np.exp
    if part == 0:
        strike = .21 * sine(2.76 * phase) * exp(-time * 12)
        return .31 * (sine(phase) + .18 * sine(2.002 * phase) + strike) * exp(-time * 3.8)
    if part == 1:
        pluck = sine(phase) + .32 * sine(2 * phase) * exp(-time * 8) + .20 * sine(3 * phase) * exp(-time * 12)
        return .24 * pluck * exp(-time * 5)
    if part == 2:
        reed = phase + .22 * sine(2 * np.pi * 5.3 * time) * np.clip(time * 2.5, 0, 1)
        return .18 * (sine(reed) + .34 * sine(3 * reed) + .07 * sine(5 * reed))
    if part == 3:
        bow = phase + .14 * sine(2 * np.pi * 4.8 * time)
        strings = sine(bow) + .32 * sine(2 * bow) + .21 * sine(3 * bow)
        return .22 * (strings + .32 * sine(1.004 * bow) + .10 * sine(5 * bow))
    strike = .18 * noise.uniform(-1, 1, len(time)) * exp(-time * 35)
    drum = sine(phase) + .43 * sine(1.51 * phase) * exp(-time * 5)
    return .46 * (drum + strike) * exp(-time * 5.5)


def render(tracks):
    frames = BARS * METER * RATE * 60 // BPM
    mix = np.zeros((frames, 2), dtype=np.float32)
    noise = np.random.default_rng(641)
    seconds_per_tick = 60 / (BPM * PPQ)
    for part, events in enumerate(tracks):
        pan, attack, release = (
            (.25, .004, .19), (-.37, .004, .15), (-.12, .060, .17),
            (.09, .038, .11), (-.08, .003, .19),
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
        for delay, level, channel in ((.071, .15, 0), (.109, .12, 1), (.211, .06, 0), (.263, .05, 1)):
            samples = round(delay * RATE)
            mix[samples:, channel] += stem[:-samples] * level

    # Reserve room for the timer tick and final explosion.
    time = np.arange(frames) / RATE
    mix *= (1 - .34 * np.clip((time - COUNTDOWN + .15) / .15, 0, 1))[:, None]
    mix[-RATE // 5:] *= np.linspace(1, 0, RATE // 5)[:, None]
    return np.tanh(1.47 * mix) * .88


if __name__ == "__main__":
    score = compose()
    write_midi(NAME, score, BPM, BARS, PARTS, meter=METER,
               markers=((FRENZY_BAR * METER, "Frenzy"), (COUNTDOWN * BPM / 60, "Countdown")))
    write_ogg(NAME, render(score))
