"""Compose and render the sunset park score. Requires NumPy and ffmpeg."""
from pathlib import Path
import sys

import numpy as np

# Blender executes scripts without necessarily adding their directory to sys.path.
sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_music import PPQ, RATE, write_midi, write_ogg

BPM = 128
PARTS = (
    ("Round bass", 33, 0),
    ("Tremolo electric piano", 4, 1),
    ("Bell lead", 10, 2),
    ("Carousel organ", 16, 3),
    ("Pocket drums", 0, 9),
)
# Bbm9, Eb13, Abmaj9, Dbmaj9#11, Gm7b5, C7b9, Fm9, F7#9.
HARMONY = (
    (46, 7, (53, 56, 60, 61, 65)),
    (39, 7, (55, 61, 65, 70, 72)),
    (44, 7, (55, 60, 63, 67, 70)),
    (37, 7, (53, 60, 63, 67, 68)),
    (43, 6, (53, 58, 61, 65, 69)),
    (36, 7, (52, 58, 61, 64, 67)),
    (41, 7, (55, 56, 60, 63, 65)),
    (41, 7, (57, 63, 68, 72)),
)
# Each tuple holds the beat, note and duration for a phrase across one chord.
THEME = (
    ((.58, 72, .61), (1.58, 68, .42), (2.29, 65, 1.12), (3.58, 70, .25)),
    ((0, 67, .82), (1.58, 65, .39), (2.58, 63, .81)),
    ((.58, 67, .44), (1.29, 70, .44), (2.0, 75, 1.20), (3.58, 72, .27)),
    ((.29, 67, .63), (1.58, 65, .41), (2.29, 63, 1.22)),
    ((.58, 70, .64), (1.58, 73, .40), (2.29, 77, .85)),
    ((.29, 76, .56), (1.58, 73, .40), (2.58, 70, .56), (3.58, 67, .25)),
    ((0, 68, .88), (1.58, 72, .51), (2.58, 75, .86)),
    ((0, 72, .65), (1.29, 68, .37), (2.0, 69, .64), (3.29, 65, .46)),
)


def compose(bars, rush):
    tracks = [[] for _ in PARTS]

    def note(part, beat, pitch, length, velocity):
        tracks[part].append((round((bar * 4 + beat) * PPQ),
                             round(length * PPQ), pitch, velocity))

    for bar in range(bars):
        index = bar % len(HARMONY)
        root, fifth, chord = HARMONY[index]
        next_root = HARMONY[(index + 1) % len(HARMONY)][0]
        approach = next_root + (1 if next_root < root else -1)

        bass = [(0, root, .78, 94), (1.58, root + fifth, .38, 76),
                (2.29, root + (12 if index % 2 == 0 else 0), .61, 83),
                (3.58, approach, .32, 68)]
        if rush:
            bass.extend(((1, root + 12, .23, 86), (3, root + fifth, .27, 80)))
        for beat, pitch, length, velocity in bass:
            note(0, beat, pitch, length, velocity)

        hits = ((0, 2.14, 72), (2.58, 1.24, 65))
        if rush:
            hits = ((0, .91, 81), (1.58, .51, 71), (2.58, .62, 74), (3.58, .29, 64))
        for beat, length, velocity in hits:
            for voice, pitch in enumerate(chord):
                note(1, beat + voice * .009, pitch, length, velocity - (len(chord) - voice - 1) * 2)

        for phrase_note, (beat, pitch, length) in enumerate(THEME[index]):
            # The second circuit answers the hook an octave lower on alternating bars.
            if not rush and 8 <= bar < 16 and index % 2:
                pitch -= 12
            note(2, beat, pitch, length, (81 if rush else 76) - phrase_note * 4)
            if rush and phrase_note == 0 and index % 2 == 0:
                note(3, beat + .03, pitch - 12, length, 61)
        if index in (1, 3, 5, 7):
            note(3, .31, chord[-1], 2.4 if rush else 3.15, 62 if rush else 55)

        kick = (0, 1.29, 2.29, 3.0) if rush else (0, 2.29)
        for beat in kick:
            note(4, beat, 36, .23, 98 if beat == 0 else 80)
        for beat in (1, 3):
            note(4, beat + .02, 37, .16, 86 if rush else 74)
        hats = (0, .58, 1, 1.58, 2, 2.58, 3, 3.58)
        if rush:
            hats += (.29, 1.29, 2.29, 3.29, 3.80)
        for step, beat in enumerate(hats):
            note(4, beat, 46 if rush and beat == 3.58 else 42, .09, 66 if step % 2 else 51)
        if index == 7:
            note(4, 3.28, 37, .10, 59)
            note(4, 3.76, 37, .10, 65)
    return tracks


def instrument(part, pitch, t, rng):
    phase = 2 * np.pi * 440 * 2 ** ((pitch - 69) / 12) * t
    if part == 0:
        body = np.sin(phase) + .24 * np.sin(phase * 2) + .11 * np.sin(phase * 3)
        return .43 * np.tanh(1.26 * body) * (.75 + .25 * np.exp(-4 * t))
    if part == 1:
        tine = np.sin(phase + 1.18 * np.exp(-6.4 * t) * np.sin(phase * 2.006))
        tremolo = .87 + .13 * np.cos(2 * np.pi * 4.5 * t + pitch * .16)
        return .27 * tremolo * (tine + .19 * np.sin(phase * 1.003)) * np.exp(-1.42 * t)
    if part == 2:
        drift = .30 * np.sin(2 * np.pi * 5.2 * t)
        tone = np.sin(phase + drift + .8 * np.exp(-8 * t) * np.sin(phase * 2.012))
        return .28 * (tone + .27 * np.sin(phase * 1.006 - drift)) * np.exp(-1.15 * t)
    if part == 3:
        organ = np.sin(phase) + .38 * np.sin(phase * 2.008) + .13 * np.sin(phase * 3)
        return .105 * organ * (.82 + .18 * np.sin(2 * np.pi * 3.2 * t))
    if pitch == 36:
        kick = 2 * np.pi * (47 * t + 55 * (1 - np.exp(-t * 39)) / 39)
        return .62 * np.sin(kick) * np.exp(-17 * t)
    noise = rng.uniform(-1, 1, len(t))
    crisp = noise - np.roll(noise, 1)
    if pitch == 37:
        rim = np.sin(2 * np.pi * 820 * t) + .44 * np.sin(2 * np.pi * 1228 * t)
        return .20 * rim * np.exp(-43 * t) + .115 * crisp * np.exp(-34 * t)
    return .062 * crisp * np.exp((-32 if pitch == 46 else -78) * t)


def render(name, tracks, bars, synth=instrument):
    beat = 60 / BPM
    frames = round(bars * 4 * beat * RATE)
    mix = np.zeros((frames, 2), dtype=np.float32)
    rng = np.random.default_rng(7814)
    for part, events in enumerate(tracks):
        stem = np.zeros(frames, dtype=np.float32)
        attack = (.009, .007, .024, .067, .0015)[part]
        release = (.075, .14, .19, .21, .046)[part]
        for start, ticks, pitch, velocity in events:
            offset = round(start * beat * RATE / PPQ)
            duration = ticks * beat / PPQ
            t = np.arange(round((duration + release) * RATE)) / RATE
            envelope = np.minimum(t / attack, 1) * np.clip((duration + release - t) / release, 0, 1)
            signal = synth(part, pitch, t, rng) * envelope * velocity / 127
            # Wrap the final tails into the next downbeat for seamless looping.
            head = min(len(signal), frames - offset)
            stem[offset:offset + head] += signal[:head]
            stem[:len(signal) - head] += signal[head:]

        pan = (0, -.16, .19, -.24, .04)[part]
        mix[:, 0] += stem * np.sqrt((1 - pan) / 2)
        mix[:, 1] += stem * np.sqrt((1 + pan) / 2)
        if part in (1, 2, 3):
            mix[:, 0] += np.roll(stem, round(.75 * beat * RATE)) * .10
            mix[:, 1] += np.roll(stem, round(.375 * beat * RATE)) * .13

    audio = np.tanh(mix * 1.38) * .72
    write_ogg(name, audio)
    print(f"MUSIC_OK {name}: {BPM} BPM, {frames / RATE:g}s, peak {np.abs(audio).max():.2f}")


if __name__ == "__main__":
    for name, bars, rush in (("park_twilight", 24, False), ("park_last_ride", 8, True)):
        score = compose(bars, rush)
        write_midi(name, score, BPM, bars, PARTS)
        render(name, score, bars)
