"""Render the original combat and destruction cues to MIDI and Ogg Vorbis.

Run with Blender's bundled NumPy and ffmpeg on PATH.
"""
from pathlib import Path
from tempfile import TemporaryDirectory
import math
import struct
import subprocess
import wave

import numpy as np

OUT = Path(__file__).resolve().parents[1] / "assets/music"
PPQ = 480
RATE = 32000
PARTS = (("Drive bass", 38, 0), ("Brass stabs", 62, 1),
         ("Pressure drone", 89, 2), ("Industrial drums", 0, 9))


def compose(bars, frantic):
    tracks = [[], [], [], []]

    def note(track, beat, pitch, length, velocity):
        tracks[track].append((round(beat * PPQ), round(length * PPQ), pitch, velocity))

    for bar in range(bars):
        root = [38, 38, 34, 37, 38, 38, 41, 37][bar % 8]
        start = bar * 4
        bass_steps = (0, 2, 3, 5, 6, 8, 9, 11, 12, 14, 15) if frantic else (0, 3, 6, 8, 11, 14)
        for step in bass_steps:
            pitch = root + (12 if step in (11, 15) else 0)
            note(0, start + step / 4, pitch, .20 if frantic else .36, 114 if step % 4 == 0 else 90)
        for beat in ((0, 1.5, 2.75, 3.5) if frantic else (.75, 2.5)):
            if frantic or bar % 4 in (0, 2, 3):
                for interval in (12, 19, 24):
                    note(1, start + beat, root + interval, .14 if frantic else .26, 88)
        note(2, start, root - 12, 3.92, 71)
        kick = (0, .75, 1.5, 2, 2.5, 3.25, 3.75) if frantic else (0, .75, 1.5, 2.5, 3.25)
        for beat in kick:
            note(3, start + beat, 36, .20, 118 if beat in (0, 2) else 99)
        for beat in (1, 3):
            note(3, start + beat, 38, .19, 109)
        for step in range(16):
            if frantic or step % 2 == 0 or bar % 4 == 3:
                note(3, start + step / 4, 42, .07, 67 if step % 4 == 0 else 42)
        if bar % 4 == 3:
            for step in range(4 if frantic else 2):
                note(3, start + 3.25 + step * (.167 if frantic else .25), 45 - step, .15, 99)
    return tracks


def vlq(value):
    data = [value & 127]
    value >>= 7
    while value:
        data.insert(0, (value & 127) | 128)
        value >>= 7
    return bytes(data)


def meta(kind, data):
    return bytes([255, kind]) + vlq(len(data)) + data


def chunk(data):
    return b"MTrk" + struct.pack(">I", len(data)) + data


def write_midi(name, tracks, bpm, bars, parts=PARTS, *, meter=4, markers=()):
    end = bars * meter * PPQ
    tempo = round(60000000 / bpm)
    conductor = b"\x00" + meta(3, name.encode())
    conductor += b"\x00" + meta(0x51, tempo.to_bytes(3, "big"))
    conductor += b"\x00" + meta(0x58, bytes([meter, 2, 24, 8]))
    last_marker = 0
    for beat, label in markers:
        at = round(beat * PPQ)
        conductor += vlq(at - last_marker) + meta(6, label.encode())
        last_marker = at
    conductor += vlq(end - last_marker) + meta(0x2f, b"")
    midi = b"MThd" + struct.pack(">IHHH", 6, 1, len(parts) + 1, PPQ) + chunk(conductor)
    for events, (part_name, program, channel) in zip(tracks, parts, strict=True):
        data = b"\x00" + meta(3, part_name.encode())
        if channel != 9:
            data += bytes([0, 0xc0 | channel, program])
        ordered = []
        for start, length, pitch, velocity in events:
            ordered.append((start, bytes([0x90 | channel, pitch, velocity])))
            ordered.append((start + length, bytes([0x80 | channel, pitch, 0])))
        last = 0
        for at, event in sorted(ordered):
            data += vlq(at - last) + event
            last = at
        midi += chunk(data + vlq(max(0, end - last)) + meta(0x2f, b""))
    (OUT / f"{name}.mid").write_bytes(midi)


def synthesize(index, pitch, time, rng):
    phase = 2 * np.pi * 440 * 2 ** ((pitch - 69) / 12) * time
    if index == 0:
        wave = np.sin(phase) + .36 * np.sin(phase * 2.012) + .2 * np.sin(phase * 3)
        return np.tanh(wave * 1.9) * np.exp(-time * 6) * .37
    if index == 1:
        wave = np.sin(phase) + .55 * np.sin(phase * 2.006) + .35 * np.sin(phase * 3)
        return np.tanh(wave * 2) * np.exp(-time * 15) * .17
    if index == 2:
        return (np.sin(phase) + .35 * np.sin(phase * 2)) * .11
    if pitch == 36:
        kick_phase = 2 * np.pi * (49 * time + 125 * (1 - np.exp(-time * 36)) / 36)
        return np.tanh(1.9 * np.sin(kick_phase)) * np.exp(-time * 18) * .64
    noise = rng.uniform(-1, 1, len(time))
    if pitch == 38:
        return (noise * .78 + np.sin(2 * np.pi * 165 * time) * .36) * np.exp(-time * 23) * .44
    if pitch == 42:
        return (noise - np.roll(noise, 1)) * np.exp(-time * 77) * .15
    return np.sin(2 * np.pi * (94 * time + 14 * (1 - np.exp(-time * 25)) / 25)) * np.exp(-time * 18) * .40


def render(name, tracks, bpm, bars):
    beat_seconds = 60 / bpm
    length = round(bars * 4 * beat_seconds * RATE)
    audio = np.zeros((length, 2), dtype=np.float32)
    rng = np.random.default_rng(61105)
    for index, events in enumerate(tracks):
        pan = (0, -.24, .23, 0)[index]
        for start, ticks, pitch, velocity in events:
            offset = round(start * beat_seconds / PPQ * RATE)
            duration = ticks * beat_seconds / PPQ
            count = min(round((duration + .065) * RATE), length - offset)
            time = np.arange(count) / RATE
            attack = .05 if index == 2 else .002
            envelope = np.minimum(time / attack, 1)
            envelope *= np.clip((duration + .065 - time) / .065, 0, 1)
            signal = synthesize(index, pitch, time, rng) * envelope * velocity / 127
            audio[offset:offset + count, 0] += signal * math.sqrt((1 - pan) / 2)
            audio[offset:offset + count, 1] += signal * math.sqrt((1 + pan) / 2)
    audio = np.tanh(audio * 1.3) * .92
    fade = round(.038 * RATE)
    audio[-fade:] *= np.linspace(1, 0, fade)[:, None]
    write_ogg(name, audio)
    print(f"MUSIC_OK {name}: {bpm} BPM, {length / RATE:g}s, peak {np.abs(audio).max():.2f}")


def write_ogg(name, audio):
    with TemporaryDirectory() as tmp:
        pcm = Path(tmp) / "cue.wav"
        with wave.open(str(pcm), "wb") as output:
            output.setparams((2, 2, RATE, 0, "NONE", "not compressed"))
            output.writeframes((audio * 32767).astype("<i2").tobytes())
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(pcm),
                        "-c:a", "vorbis", "-strict", "experimental", "-q:a", "4",
                        str(OUT / f"{name}.ogg")], check=True)


if __name__ == "__main__":
    for name, bpm, bars, frantic in (("sixty", 160, 30, False), ("destroy", 192, 12, True)):
        score = compose(bars, frantic)
        write_midi(name, score, bpm, bars)
        render(name, score, bpm, bars)
