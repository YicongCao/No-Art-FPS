# No-Art-FPS score

- `sixty.mid` and `sixty.ogg` contain the 45-second, 160 BPM combat cue.
- `destroy.mid` and `destroy.ogg` contain the 15-second, 192 BPM DESTROY ALL cue.
- `park_twilight` and `park_last_ride` are the sunset park's 45- and 15-second cues at 128 BPM, with editable MIDI and rendered Ogg files.

Run `blender --background --python tools/build_music.py` for the original cues or `blender --background --python tools/build_park_music.py` for the park. Both scripts render the MIDI parts with original synthesis and use ffmpeg to encode Ogg.
