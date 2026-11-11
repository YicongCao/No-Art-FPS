# Office pixel posters

Four original illustrations generated with the built-in imagegen tool on 2026-11-11 for this project. No external reference images were supplied. The brief excluded existing characters, emblems, logos, titles and watermarks.

- `sky_courier.png`: orange-caped sky courier and floating gardens.
- `arena_guardians.png`: ceramic-armored spear guardian and mechanical scout.
- `citrus_racers.png`: capybara hover-buggy racer at a seaside fruit market.
- `lantern_observatory.png`: lantern traveler exploring an overgrown observatory.

The original generated PNGs are retained here. Godot imports them at a maximum edge of 1024 with mipmaps; four separate 1.125 × 2 metre wall panels give an exact 9:16 display ratio. Each illustration is placed once. They are matte printed surfaces, not emissive screens, and do not affect collision or navigation.

Placement source: `scripts/maps/office_posters.gd`; wall coordinates verified against `tools/build_bb_office.py`. There are three north corridor posters and one entrance-return poster, all on solid walls rather than doors or glass.
