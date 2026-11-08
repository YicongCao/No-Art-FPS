"""Write six continuous arena scores, with editable MIDI and synthesized Ogg audio."""
from dataclasses import dataclass
from pathlib import Path
import sys

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_music import PPQ, RATE, write_midi, write_ogg

ROUND = 60
FRENZY = 45
COUNTDOWN = 50


@dataclass(frozen=True)
class Arrangement:
    name: str
    bpm: int
    voices: tuple
    harmony: tuple
    melody: tuple
    bass: tuple
    chords: tuple
    drums: tuple
    texture: tuple
    meter: int = 4


# Harmony entries carry the bass root and independent chord voicings. Melodies
# use four-beat phrases even at the airport, where a phrase spans two bars.
SCORES = (
    Arrangement(
        "night_studio", 128, ("Finger bass", "Electric piano", "News brass", "Fader click"),
        ((43, (55, 58, 62, 65, 69)), (41, (53, 57, 60, 63, 67)),
         (39, (55, 58, 62, 65)), (38, (54, 60, 63, 69))),
        (((0, 74, .19), (.50, 77, .19), (1.25, 81, .58), (3, 79, .19)),
         ((.50, 77, .20), (1.5, 72, .35), (2.75, 75, .42)),
         ((0, 74, .19), (.50, 77, .19), (1.25, 82, .68), (3.25, 77, .2)),
         ((.75, 76, .31), (2, 75, .24), (3, 69, .42))),
        (0, .75, 1.5, 2.5, 3.25), (.50, 2.75), ((0, 1.5, 2.75), (1, 3.25)),
        (.75, 3.75),
    ),
    Arrangement(
        "sandgate", 144, ("Warm drone bass", "Plucked strings", "Oud-like lead", "Frame drum"),
        ((38, (50, 57, 62, 65)), (38, (50, 57, 63, 65)),
         (34, (53, 58, 62, 65)), (33, (52, 55, 58, 64))),
        (((0, 62, .55), (.75, 63, .2), (1.25, 66, .42), (2.75, 65, .45)),
         ((.5, 62, .35), (1.75, 60, .45), (3, 57, .6)),
         ((0, 62, .55), (.75, 63, .2), (1.25, 66, .42), (2.75, 69, .38)),
         ((0, 67, .27), (.5, 66, .32), (1.75, 63, .46), (3, 57, .61))),
        (0, 1.5, 3), (.75, 2.25, 3.5), ((0, 1.5, 3), (.75, 2.25, 3.5)),
        (0, 1.5, 3, 3.75),
    ),
    Arrangement(
        "bb_office", 112, ("Muted bass", "Desktop keys", "Square pulse", "Keyboard and printer"),
        ((45, (57, 60, 64, 67)), (45, (55, 59, 64, 67)),
         (41, (53, 57, 60, 64)), (43, (55, 59, 62, 69))),
        (((.5, 76, .19), (.75, 76, .19), (1.5, 79, .31), (3, 72, .4)),
         ((.75, 71, .17), (1, 76, .25), (2.5, 79, .35)),
         ((.5, 76, .19), (.75, 76, .19), (1.5, 81, .35), (3, 77, .4)),
         ((0, 74, .25), (1.25, 69, .32), (2.75, 71, .57))),
        (0, 1.25, 2, 3.5), (.25, 1.5, 2.75), ((0, 2.5), (1, 3)),
        (.25, .5, 1.75, 2.25, 2.5, 3.75),
    ),
    Arrangement(
        "rain_market", 128, ("Slap bass", "FM city keys", "Minibus bell and brass", "Roof and trolley"),
        ((42, (54, 57, 61, 64, 68)), (47, (54, 57, 61, 64, 69)),
         (40, (56, 59, 63, 66, 68)), (37, (53, 56, 59, 63, 69))),
        (((.25, 73, .35), (.75, 78, .52), (1.75, 81, .51), (3, 80, .3)),
         ((.25, 71, .35), (.75, 76, .52), (2.25, 73, .69)),
         ((.25, 73, .35), (.75, 78, .52), (2, 83, .43), (3.25, 80, .4)),
         ((0, 77, .42), (.75, 73, .49), (2.25, 71, .35), (3.25, 68, .35))),
        (0, .75, 1.25, 2, 2.75, 3.5), (.5, 1.75, 3.25), ((0, .75, 2.5), (1, 3)),
        (.5, 1.25, 1.75, 2.5, 3.25, 3.75),
    ),
    Arrangement(
        "baggage_below", 104, ("Conveyor bass", "Terminal pad", "Boarding chime", "Split-flap relays"),
        ((40, (55, 59, 62, 66)), (43, (55, 59, 62, 64)),
         (36, (55, 59, 60, 67)), (38, (54, 57, 60, 64))),
        (((0, 76, .3), (.5, 79, .28), (1, 83, .7)),
         ((1, 81, .43), (2, 79, .58), (3.25, 74, .36)),
         ((0, 76, .3), (.5, 79, .28), (1, 83, .7)),
         ((.75, 78, .38), (1.75, 76, .35), (3.25, 74, .44))),
        (0, .75, 1.5, 2.25, 3), (0, 2), ((0, 2), (1.5, 3)),
        (.25, .5, 1.25, 1.5, 2.25, 3.25, 3.5), 2,
    ),
    Arrangement(
        "snowline", 96, ("Low pressure pulse", "Wind pad", "Glass observatory bells", "Instrument relay"),
        ((38, (50, 57, 64, 65, 69)), (34, (53, 57, 60, 65)),
         (41, (53, 57, 60, 64, 67)), (36, (55, 60, 62, 67))),
        (((0, 81, .83), (1.5, 76, .67), (2.75, 77, .8)),
         ((.5, 72, .74), (2.5, 74, .82)),
         ((0, 81, .83), (1.5, 76, .67), (2.75, 84, .82)),
         ((.75, 79, .54), (2.5, 74, .81))),
        (0, 2.5), (0,), ((0, 2.5), (2,)), (1.75, 3.75),
    ),
)

PROGRAMS = (
    (33, 4, 61, 115), (43, 46, 105, 116), (34, 4, 80, 115),
    (36, 5, 14, 116), (38, 89, 10, 115), (39, 94, 14, 115),
)


def compose(score, index):
    tracks = [[] for _ in range(5)]
    bpm = score.bpm
    end = bpm
    boundary = bpm * FRENZY / 60
    quiet_from = bpm * COUNTDOWN / 60

    def note(track, beat, pitch, length, velocity):
        if beat >= end:
            return
        ticks = round(beat * PPQ)
        length = min(round(length * PPQ), end * PPQ - ticks)
        if length > 0:
            tracks[track].append((ticks, length, pitch, velocity))

    def phrase(start, stop, rush):
        for n, at in enumerate(range(int(start), stop, 4)):
            section = n % 4
            root, chord = score.harmony[section]
            quiet = at + 3 >= quiet_from
            variation = n // 4 % 3
            bass_hits = score.bass
            if rush and not quiet:
                bass_hits = tuple(sorted(set(bass_hits + (.5, 1.75, 2.75, 3.5))))
            for j, beat in enumerate(bass_hits):
                pitch = root + (7 if j % 4 == 2 else 12 if j % 4 == 3 and index in (0, 2, 3) else 0)
                note(0, at + beat, pitch, .22 if rush else .43, 94 if j == 0 else 73 + j % 3 * 5)

            keys = score.chords
            if rush:
                keys = (.25, 1.5, 2.5, 3.75) if index in (0, 2, 3) else (0, 2.5)
            for beat in keys:
                for j, pitch in enumerate(chord):
                    sustain = (3.4 if index == 5 else 1.65) if not rush and index >= 4 else .23 if rush else .43
                    note(1, at + beat + j * .012, pitch, sustain, (65 if quiet else 74) - (4 - j) * 2)

            for j, (beat, pitch, length) in enumerate(score.melody[section]):
                # In the second verse the motif answers from a different register.
                shift = -12 if (rush and index == 5) or (not rush and variation == 1 and section % 2) else 0
                offset = .125 if rush and index == 2 and j % 2 else 0
                note(2, at + beat + offset, pitch + shift, length * (.66 if rush and index < 4 else 1),
                     (78 if quiet else 92) - j * 5)
                if rush and not quiet and index in (0, 1, 2, 3) and j == 0:
                    note(2, at + beat + .28, pitch + (12 if index in (0, 3) else 0), .13, 58)

            details = score.texture if not quiet else score.texture[::2]
            if rush and not quiet and index in (1, 2, 3, 4):
                details = tuple(sorted(set(details + (.125, .375, 1.125, 2.625, 3.875))))
            for j, beat in enumerate(details):
                note(3, at + beat, 52 + 4 * (j % 4), .13, 70 if j % 3 == 0 else 53)

            kick, snare = score.drums
            if rush and index == 4:
                # One low drum on every red beat, one snare on every blue beat.
                kick, snare = (0, 2), (1, 3)
            elif rush:
                kick = tuple(sorted(set(kick + (.75, 1.75, 2.75)))) if not quiet else kick
                snare = snare + (1.75, 3.5) if not quiet else snare
            for beat in kick:
                note(4, at + beat, 36, .21, 105 if beat % 2 == 0 else 78)
            for beat in snare:
                note(4, at + beat, 38, .18, 99 if beat in (1, 2, 3) else 72)
            if not quiet:
                spacing = .25 if rush else .5
                for j in range(round(4 / spacing)):
                    swing = .045 if index in (0, 3) and j % 2 else 0
                    note(4, at + j * spacing + swing, 42, .09, 52 if j % 2 else 42)

    phrase(0, int(boundary), False)
    # Airport's 2/4 meter can end on the first half of a four-beat phrase.
    cut = round(boundary * PPQ)
    for track in tracks:
        track[:] = [(start, min(length, cut - start), pitch, velocity)
                    for start, length, pitch, velocity in track if start < cut]
    phrase(boundary, end, True)
    return tracks


def voice(index, part, pitch, t, rng, rush):
    phase = 2 * np.pi * 440 * 2 ** ((pitch - 69) / 12) * t
    if part == 0:
        overtone = (.30, .13, .11, .61, .35, .08)[index]
        return .43 * np.tanh(np.sin(phase) + overtone * np.sin(2.007 * phase)
                             + .12 * np.exp(-7 * t) * np.sin(3 * phase))
    if part == 1:
        if index in (4, 5):
            return .10 * (np.sin(phase) + .44 * np.sin(1.004 * phase)) * (.77 + .23 * np.sin(t * 11))
        modulation = (.9, .35, 1.35, 1.77)[index] * np.exp(-6 * t)
        return .19 * np.sin(phase + modulation * np.sin(2.001 * phase)) * np.exp(-2.5 * t)
    if part == 2:
        if index in (0, 3) and (index == 0 or rush):
            brass = np.sin(phase) + .49 * np.sin(2.004 * phase) + .22 * np.sin(3.02 * phase)
            return .22 * np.tanh(1.55 * brass) * np.exp(-3.2 * t)
        if index == 1:
            return .27 * (np.sin(phase) + .61 * np.sin(2 * phase) * np.exp(-8 * t)
                          + .38 * np.sin(3 * phase) * np.exp(-12 * t)) * np.exp(-4 * t)
        if index == 2:
            return .19 * (np.sin(phase) + .31 * np.sin(3.01 * phase)) * np.exp(-3 * t)
        bell = np.sin(phase) + .31 * np.sin(2.72 * phase) * np.exp(-8 * t)
        bell += .12 * np.sin(4.07 * phase) * np.exp(-13 * t)
        return .24 * bell * np.exp((-1.8 if index == 5 else -3.3) * t)
    noise = rng.uniform(-1, 1, len(t))
    crisp = noise - np.roll(noise, 1)
    if part == 3:
        rings = np.sin(phase * 1.9) + .37 * np.sin(phase * 4.6)
        if index == 1:
            return .15 * (np.sin(phase * .56) + .30 * noise) * np.exp(-t * 24)
        if index == 5:
            return .052 * (noise + np.sin(phase * 2.5)) * np.exp(-t * 22)
        if index == 2 and pitch >= 60:
            motor = np.sin(2 * np.pi * (465 * t + 1600 * t*t))
            return .11 * (motor + .24 * crisp) * np.exp(-t * 42)
        if index == 3:
            if pitch >= 60:
                return .095 * rings * np.exp(-t * 22) * (.68 + .32 * np.cos(t * 192))
            return .09 * (np.sin(phase * 3.3) + .5 * noise) * np.exp(-t * 75)
        decay = 102 if index == 2 else 84 if index == 4 else 68
        return (.065 * crisp + .067 * rings) * np.exp(-decay * t)
    if pitch == 36:
        kick = 2 * np.pi * (48 * t + 78 * (1 - np.exp(-35 * t)) / 35)
        return .55 * np.sin(kick) * np.exp(-t * (16 if rush else 20))
    if pitch == 38:
        return (.20 * noise + .11 * np.sin(2 * np.pi * 182 * t)) * np.exp(-t * 28)
    return .045 * crisp * np.exp(-t * 70)


def render(score, index, tracks):
    frames = ROUND * RATE
    mix = np.zeros((frames, 2), dtype=np.float32)
    rng = np.random.default_rng(41021 + index)
    samples_per_tick = RATE * 60 / (score.bpm * PPQ)
    for part, events in enumerate(tracks):
        stem = np.zeros(frames, dtype=np.float32)
        pan = (0, -.24, .18, .34, 0)[part]
        attack = (.010, .040 if index >= 4 else .011, .014, .003, .002)[part]
        release = (.065, .23, .21, .05, .06)[part]
        for start, length, pitch, velocity in events:
            offset = round(start * samples_per_tick)
            duration = length * samples_per_tick / RATE
            count = min(round((duration + release) * RATE), frames - offset)
            t = np.arange(count) / RATE
            envelope = np.minimum(t / attack, 1) * np.clip((duration + release - t) / release, 0, 1)
            stem[offset:offset + count] += voice(index, part, pitch, t, rng, offset >= FRENZY * RATE) * envelope * (velocity / 127)
        mix[:, 0] += stem * np.sqrt((1 - pan) * .5)
        mix[:, 1] += stem * np.sqrt((1 + pan) * .5)
        if part in (1, 2):
            delay = round(RATE * (60 / score.bpm) * .375)
            mix[delay:, part - 1] += stem[:-delay] * (.18 if index in (1, 5) else .10)

    # Preserve the last ten ticks and the zero-second explosion.
    time = np.arange(frames) / RATE
    mix *= (1 - .20 * np.clip((time - COUNTDOWN + .17) / .17, 0, 1))[:, None]
    mix[-RATE // 5:] *= np.linspace(1, 0, RATE // 5)[:, None]
    audio = np.tanh(mix * 1.32) * .78
    write_ogg(score.name, audio)
    print(f"MUSIC_OK {score.name}: {score.bpm} BPM, {score.meter}/4, 45s + 15s, peak {np.abs(audio).max():.2f}")


if __name__ == "__main__":
    for index, score in enumerate(SCORES):
        events = compose(score, index)
        parts = tuple((name, program, channel) for channel, (name, program) in enumerate(zip(score.voices, PROGRAMS[index], strict=True)))
        parts += (("Drums", 0, 9),)
        markers = ((score.bpm * FRENZY / 60, "Frenzy"), (score.bpm * COUNTDOWN / 60, "Countdown"))
        write_midi(score.name, events, score.bpm, score.bpm // score.meter, parts,
                   meter=score.meter, markers=markers)
        render(score, index, events)
