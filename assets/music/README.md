# No-Art-FPS score

- `sixty.mid` and `sixty.ogg` contain the 45-second, 160 BPM combat cue.
- `destroy.mid` and `destroy.ogg` contain the 15-second, 192 BPM DESTROY ALL cue.
- `park_twilight` and `park_last_ride` are the sunset park's 45- and 15-second cues at 128 BPM, with editable MIDI and rendered Ogg files.
- `ferry_blue_hour` and `ferry_last_call` are the Last Ferry's 45- and 15-second cues at 128 BPM. Regenerate with `blender --background --python tools/build_ferry_music.py`.

Run `blender --background --python tools/build_music.py` for the original cues or `blender --background --python tools/build_park_music.py` for the park. Both scripts render the MIDI parts with original synthesis and use ffmpeg to encode Ogg.

The studio, Sandgate, BB Office, rain market, airport and observatory each
use a single 60-second score. Each MIDI includes markers at 45 seconds for
the frenzy variation and 50 seconds for the countdown mix. The airport
alternates kick and snare at 104 BPM from its frenzy marker.

Regenerate the six MIDI and Ogg pairs with:

```sh
blender --background --python-exit-code 1 --python tools/build_arena_music.py
```
