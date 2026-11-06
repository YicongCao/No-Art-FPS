# No-Art-FPS

A bright, low-poly, sixty-second FPS score attack. Godot 4.7.2 + Blender 5.2.2 LTS.

Playable local prototype. A 64×48 m yard with automatic container doors, an enterable warehouse and an upper pool terrace; one automatic rifle, ranged black guards and fast knife enemies, a full 60-second round, and instant retries.

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
- Pause menu: use Resume/Restart, the sensitivity and music-volume sliders, and the camera-motion toggle. `-` / `+` and M remain available as shortcuts.
- Results: Retry and Menu are clickable; Enter and Escape still work.

Enemy targets rise from 8 to 10 to 12 across the three 20-second phases. Two patrols occupy the warehouse and two occupy the upper deck, with reserved reinforcement slots; other enemies roam the yard. Reinforcements appear outside direct view and at least eight metres away.

Black guards walk and patrol continuously. Enemies steer around one another, their bodies collide, and occupied reinforcement positions are deferred until clear.

Ground-level container doors open automatically when you approach the entrance. The green and purple containers hold black guards who join combat after the doors open; you can walk inside. No interaction key is required.

Both stairs lead to a larger pool terrace with loungers, parasols and a loop around the shallow pool. Walk down the pool entrance and back out without jumping. Six coconut palms add ground-level landmarks.

Red-and-yellow barrels ignite when shot, warn for 0.65 seconds and explode within five metres; solid cover blocks blast damage, and nearby barrels chain. Orange enemies carry knives and rapidly approach, then raise their weapon before a close-range chop. Sidestep, back away, shoot them during windup, or use solid cover to block the slash.

Head hits kill a normal target in one shot; body hits take three. Every kill is worth one. The rifle holds 20 rounds and reloads automatically with unlimited reserves. Health is hidden; a gradual dark-red screen-edge vignette warns of danger. After five seconds without a hit, health recovers gradually. Defeat causes a one-second respawn while the round clock keeps running. A strictly higher kill count displays NEW RECORD at results. Only the highest kill count is retained as a score record. The local best and settings are stored in Godot's `user://record.cfg`; QA runs do not overwrite them.

The lower-right magazine shows twenty cartridges in one horizontal row. Each accepted shot splits and ejects the front cartridge at the right, then feeds the remaining rounds forward. Reloading restores the full row after completion; a thin bar shows reload progress. Ammo numbers and the RELOADING label have been removed. Low camera-motion mode also reduces shell travel/spin.

## Build the original assets

```sh
blender --background --python tools/build_assets.py
blender --background --python tools/build_playbox_assets.py
blender --background --python tools/build_leisure_assets.py
python3 tools/build_audio.py
blender --background --python tools/build_music.py
godot --headless --path . --editor --import
```

`art_source/no_art_kit.blend` is an editable asset library with the models laid out separately. Its source script makes fourteen GLBs, including four container colors, a rifle with hands, the enemy, forklift, barrel, tree, cloud, pallet, crate, steel bundle and traffic light. Audio includes eleven original effects and an original 60-second MIDI composition rendered for runtime playback. The HUD uses bundled SIL-OFL Rajdhani Bold; its license is in assets/fonts/. The magazine uses a bundled imagegen sprite atlas; its generation prompt and source details are in [assets/ui/README.md](assets/ui/README.md).

The yard is assembled in `scripts/arena.gd`; static collisions also supply the runtime navigation bake. Repeated box scenery and fence lattice are batched by material. The reference recording and extracted reference frames stay local and are Git-ignored.

## Verify

```sh
godot --headless --path . --script tests/rules_test.gd
godot --path . -- --qa --check
godot --path . -- --qa
godot --path . -- --qa --benchmark
godot --path . -- --qa --feedback
godot --path . -- --qa --expansion
godot --headless --path . -- --qa --population
godot --path . -- --qa --combat
godot --path . -- --qa --movement
godot --path . -- --qa --magazine
godot --path . -- --qa --containers
godot --path . -- --qa --terrace
```

The first command tests score and timer boundaries. `--check` exercises normal collision movement on both ramps, live head/body raycasts, wall blocking, pause, reload, respawn, and ten restarts. `--qa` runs a real-time full-minute automatic aiming session, with scripted viewpoint changes. `--population` checks patrol retention, regional reinforcements, population caps and safe spawn distances/visibility. The short benchmark runs twelve enemies with VSync disabled. These flags are development-only test helpers, not normal gameplay modes.

`--movement` checks that every opening outdoor black guard moves, twelve enemies can cross opposing lanes without overlapping or getting stuck, pause freezes avoidance movement, and occupied spawn slots are rechecked after their warning. `--containers` covers automatic doors, captive guards, entry and reset. `--terrace` checks poolside navigation, walking into/out of the pool, and palm collisions.

`--magazine` counts the rendered cartridge silhouettes after every shot from 20 down to zero, checks shell animation lifecycle, automatic/manual reload, pause and restart, then verifies the HUD in a 960×540 window.

Latest update: [automatic containers, knife enemies and pool terrace](docs/updates/2026-11-06-poolside-playbox.md). Earlier: [enemy movement and horizontal magazine](docs/updates/2026-11-06-movement-and-magazine.md), [explosive barrels](docs/updates/2026-11-06-explosive-combat.md), [enemy population](docs/updates/2026-11-06-enemy-population.md). MIDI: [sixty.mid](assets/music/sixty.mid).

Results and screenshots: [implementation and validation notes](docs/implementation.md). Design background: [initial playbox plan](docs/design/No-Art-FPS-playbox-plan.md).

## Local workflow

Each completed implementation stage is committed locally. Every new commit is immediately pushed to `git@github.com:YicongCao/No-Art-FPS.git`; push failures are reported while preserving local commits.

Keep the original Blender sources and reproducible asset scripts alongside the Godot project. Validate rendered output after material, lighting or geometry changes.
