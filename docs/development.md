# Development

Run the commands below from the repository root. Use Godot 4.7.2 for the game and Python 3 for the QA runner. The browser input checks use Node.js, and the asset generators use Blender 5.2.2 LTS and Python 3.

`./tools/run.sh` and the macOS `./Play\ No-Art-FPS.command` import assets before launching. The `.godot/` directory is a generated local cache excluded from Git; pulling new assets does not create their imported audio, textures or models. If you start Godot directly after pulling, run `godot --headless --path . --editor --import` first, or open the project in the editor. Missing `res://.godot/imported/` files can cause later preload and class-member errors even when the source assets are present. Set `GODOT_BIN` to use a specific Godot executable; launcher arguments are forwarded only to the game process.

## Quick checks

```sh
godot --headless --path . --editor --import
godot --headless --path . --script tests/rules_test.gd
python3 tools/qa_run.py -- --qa --check
```

The rendered check covers movement, shooting, reload, respawn, and restarting. The runner stops on engine errors and writes `logs/latest-check.log`.

## Focused checks

Run `python3 tools/qa_run.py -- --qa` for an automated 60-second round. Append **one** of the following flags to run a focused check instead.

- Combat and scoring — `--combat`, `--dodge`, `--multikill`, `--awareness`, `--blast-range`, `--destroy`, `--finale`, `--respawn`.
- Movement and arena — `--movement`, `--population`, `--containers`, `--expansion`, `--terrace`, `--routes`, `--graffiti`.
- UI and audio — `--loading`, `--magazine`, `--reload-audio`, `--feedback`, `--results-ui`.
- Performance — `--benchmark`.
- Dust mission — add `--mission` and one of `--mission-check`, `--dust-revision`, `--floor-render`, or `--mission-route`. With `--mission-route`, use `--expanded-loop` for the longer route or `--live-patrols` for active enemies.

Pass `--headless` before the `--` separator for checks that do not need a render window, such as `--population`, `--blast-range`, or `--reload-audio`. Other standalone Godot checks are `tests/defuse_rules_test.gd`, `tests/map_scene_test.gd`, and `tests/aim_sights_check.gd` (rifle iron sights land on the shot point when aiming). For browser input, run `node tests/mobile_input_test.mjs` and `node tests/gyro_test.mjs`.

## Maps and assets

See the [map production workflow](../workflows/map-production.md) for Blender kits, navigation baking, fixed-view captures, and Web verification.

[Sandgate](../scenes/maps/sandgate.tscn) is the desert score arena. See the [concept-to-game views](art/sandgate/concepts.md) for the build source and camera references.

Edit the [yard](../scenes/maps/yard.tscn) and [Dust](../scenes/maps/dust_flavor.tscn) scenes in Godot. Rebake navigation after changing collision geometry. To preview Dust locally, press Ctrl + Shift + 9 on the title screen and select DEFUSE C4, or launch with `./tools/run.sh -- --mission`.

Editable Blender sources are in [`art_source/`](../art_source/). Asset builders are in [`tools/`](../tools/), including `build_assets.py`, `build_playbox_assets.py`, `build_leisure_assets.py`, `build_audio.py`, and `build_music.py`.

## Web build

Install the Godot 4.7.2 export templates, then build and serve the game locally.

```sh
./tools/export_web.sh
python3 -m http.server 8785 --bind 127.0.0.1 --directory builds/web
```

Open [the local preview](http://127.0.0.1:8785/). The [Web delivery notes](updates/2026-11-06-web.md) cover the export and verification. See [`docs/updates/`](updates/) for feature history.
