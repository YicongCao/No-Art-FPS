# Rajdhani Bold

Indian Type Foundry, SIL Open Font License 1.1. The unmodified font and license are bundled here.

Source: https://github.com/google/fonts/tree/main/ofl/rajdhani

Chosen for condensed, squared numerals and clean arcade typography. Used for the HUD and menus; the compact number shapes leave space for timer pulses and score bursts.

The Web loading title uses an ASCII WOFF2 subset of this font. Regenerate with `uvx --from fonttools --with brotli pyftsubset assets/fonts/Rajdhani-Bold.ttf --unicodes=U+0020-007E --flavor=woff2 --output-file=web/Rajdhani-Bold.woff2`.

# Wêlai Glow Sans SC

Godot and the browser use Glow Sans SC Normal Medium for Chinese UI. The Godot frenzy notice uses Normal Bold.

The [upstream v0.93 SC Normal release](https://github.com/welai/glow-sans/releases/tag/v0.93) is covered by the bundled GlowSans-OFL.txt. Regenerate the three subsets after editing the translation catalog or browser UI.

```sh
uv run --with fonttools --with brotli python tools/subset_glow_fonts.py GlowSansSC-Normal-v0.93.zip
```
