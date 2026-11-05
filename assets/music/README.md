# SIXTY

Original No-Art-FPS composition: 144 BPM, E minor, 4/4, 36 bars / 60 seconds.

- `sixty.mid`: Standard MIDI format 1. Conductor, pulse bass, arpeggio, pad and GM percussion tracks. Fully editable in a MIDI sequencer.
- `sixty.wav`: stereo 32 kHz PCM rendering of the same note events using original oscillator/noise synthesis. This is the runtime soundtrack; no MIDI decoder or external soundfont is required.
- `tools/build_music.py`: deterministic score and synthesizer source. Run with Blender's bundled NumPy.

Bass eighths and syncopated kick/snare establish urgency. Hi-hats become sixteenths at bar 25; the final six bars (ten seconds) double the arpeggio density and raise the final phrase. A short decay finishes precisely with the round. Music starts with live play, pauses with the game and stops at results. Pause includes a volume slider.

All notes and sounds were composed/generated for this project. No sampled recording or third-party soundfont is included. Listening balance remains a playtest decision; the runtime default keeps gun and hit feedback in front of the music.
