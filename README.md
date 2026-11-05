# No-Art-FPS

A bright, low-poly, sixty-second FPS score attack. Godot 4.7.2 + Blender 5.2.2 LTS.

Playable local prototype. One yard, one automatic rifle, two enemy movement variants, a full 60-second round, and instant retries.

![Godot in-engine visual review](artifacts/showcase-ground.png)

This is an actual engine render. Enemy placement and the HUD values in this showcase are staged for visual comparison; the full-round automated test captures are separate.

## Play

On this Mac, double-click **Play No-Art-FPS.command**, or run:

```sh
./tools/run.sh
```

Alternatively, import `project.godot` in Godot 4.7.2 and press F6/F5 as appropriate. The main scene is `scenes/main.tscn`. The launcher uses the locally installed Godot executable; this is not yet a separately exported, signed application.

- Enter / Play: start. Three-second countdown, then 60 seconds of combat.
- WASD: move. Mouse: look. Left mouse: automatic fire. Space: jump.
- R: reload. Empty magazines reload automatically; reserve ammunition is unlimited.
- Escape: pause / resume. Losing focus also pauses.
- Enter on results or pause: retry. Escape on results: title.
- Pause menu: use Resume/Restart, the sensitivity slider, and the camera-motion toggle. `-` / `+` and M remain available as shortcuts.
- Results: Retry and Menu are clickable; Enter and Escape still work.

Head hits kill a normal target in one shot; body hits take three. Every kill is worth one. Three armor hits cause a one-second respawn while the round clock keeps running. Armor regenerates after avoiding damage. The local best and settings are stored in Godot's `user://record.cfg`; QA runs do not overwrite them.

## Build the original assets

```sh
blender --background --python tools/build_assets.py
python3 tools/build_audio.py
godot --headless --path . --editor --import
```

`art_source/no_art_kit.blend` is an editable asset library with the models laid out separately. Its source script makes ten GLBs, including four container colors, a rifle with hands, the enemy, forklift, barrel, tree and cloud. Audio consists of eight original synthesized effects. No third-party art pack or generated image is required.

The yard is assembled in `scripts/arena.gd`; static collisions also supply the runtime navigation bake. Repeated box scenery and fence lattice are batched by material. The reference recording and extracted reference frames stay local and are Git-ignored.

## Verify

```sh
godot --headless --path . --script tests/rules_test.gd
godot --path . -- --qa --check
godot --path . -- --qa
godot --path . -- --qa --benchmark
```

The first command tests score and timer boundaries. `--check` exercises normal collision movement on both ramps, live head/body raycasts, wall blocking, pause, reload, respawn, and ten restarts. `--qa` runs a real-time full-minute automatic aiming session, with scripted viewpoint changes. The short benchmark runs ten enemies with VSync disabled. These flags are development-only test helpers, not normal gameplay modes.

Results and screenshots: [implementation and validation notes](docs/implementation.md). Design background: [initial playbox plan](docs/design/No-Art-FPS-playbox-plan.md).

## Local workflow

Each completed implementation stage is committed locally. No remote is configured by this task.

Keep the original Blender sources and reproducible asset scripts alongside the Godot project. Validate rendered output after material, lighting or geometry changes.
