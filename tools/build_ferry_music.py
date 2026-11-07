"""Compose the Last Ferry soundtrack and export editable MIDI and Ogg."""
from pathlib import Path
import sys

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_music import PPQ, write_midi
from build_park_music import BPM, instrument, render

PARTS = (("Fingered bass", 33, 0), ("Night synth", 5, 1),
         ("Boarding chime", 10, 2), ("Harbor pads", 89, 3), ("Breakbeat", 0, 9))
CHORDS = (
    (40, (55,59,62,66)),
    (36, (55,59,62,64)),
    (45, (55,61,64,66)),
    (47, (57,60,63,66)),
)
CHIME = (
    ((.29,76),(.86,79),(1.56,83)),
    ((1.78,74),(2.54,71)),
    ((.29,73),(.86,76),(1.56,81)),
    ((1.56,78),(2.54,75),(3.37,71)),
)


def compose(bars, rush):
    tracks = [[] for _ in PARTS]

    def note(part, beat, pitch, length, velocity):
        tracks[part].append((round((bar * 4 + beat) * PPQ), round(length * PPQ), pitch, velocity))

    for bar in range(bars):
        section = bar % len(CHORDS)
        root, chord = CHORDS[section]
        next_root = CHORDS[(section+1) % len(CHORDS)][0]
        for beat, pitch, length, velocity in (
            (0,root,.54,96),(.78,root+12,.19,76),(1.28,root+7,.32,86),
            (2,root,.49,94),(2.78,root+12,.20,79),(3.55,next_root-1,.32,76),
        ):
            note(0,beat,pitch,length,velocity)
        if rush:
            note(0,1.76,root,.17,83)
            note(0,3.07,root+7,.19,88)
        for beat in ((.52,1.54,2.52,3.54) if rush else (.52,2.52)):
            for voice, pitch in enumerate(chord):
                note(1,beat+voice*.007,pitch,.21 if rush else .57,68+voice*2)
        if section%2==0:
            note(3,0,chord[1],3.78,47)
        octave = 12 if rush else 0
        for index, (beat, pitch) in enumerate(CHIME[section]):
            note(2,beat,pitch+octave,.38,80-index*6)
        for beat in ((0,.77,1.54,2.3,2.78,3.32) if rush else (0,1.52,2.29)):
            note(4,beat,36,.18,100 if beat==0 else 79)
        for beat in ((1,1.76,3,3.51) if rush else (1,3)):
            note(4,beat,37,.13,89 if beat in (1,3) else 64)
        for step in range(16 if rush else 8):
            division = 4 if rush else 2
            beat = step/division + (.035 if step%2 else 0)
            note(4,beat,46 if step in (3,7) else 42,.10,65 if step%2 else 45)
    return tracks


def ferry_instrument(part, pitch, t, rng):
    phase = 2 * np.pi * 440 * 2 ** ((pitch - 69) / 12) * t
    if part == 0:
        bass = np.sin(phase) + .33*np.sin(phase*2) + .21*np.sin(phase*3)*np.exp(-6*t)
        return .46*np.tanh(bass*1.2)*(.68+.32*np.exp(-3*t))
    if part == 1:
        chord = np.sin(phase) + .25*np.sin(phase*2.004) + .19*np.sin(phase*3.005)
        return .24*chord*np.exp(-3.2*t)
    if part == 2:
        bell = np.sin(phase) + .32*np.sin(phase*2.74)*np.exp(-8*t)
        bell += .12*np.sin(phase*4.07)*np.exp(-13*t)
        return .25*bell*np.exp(-3.5*t)
    return instrument(part,pitch,t,rng)


if __name__ == "__main__":
    for name, bars, rush in (("ferry_blue_hour",24,False),("ferry_last_call",8,True)):
        score = compose(bars,rush)
        write_midi(name,score,BPM,bars,PARTS)
        render(name,score,bars,ferry_instrument)
