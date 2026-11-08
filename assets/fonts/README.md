# Rajdhani Bold

Indian Type Foundry, SIL Open Font License 1.1. The unmodified font and license are bundled here.

Source: https://github.com/google/fonts/tree/main/ofl/rajdhani

Chosen for condensed, squared numerals and clean arcade typography. Used for the HUD and menus; the compact number shapes leave space for timer pulses and score bursts.

The Web loading title uses an ASCII WOFF2 subset of this font. Regenerate with `uvx --from fonttools --with brotli pyftsubset assets/fonts/Rajdhani-Bold.ttf --unicodes=U+0020-007E --flavor=woff2 --output-file=web/Rajdhani-Bold.woff2`.

The Godot HUD uses a subset of Noto Sans CJK SC Bold for Chinese glyphs. The [upstream font](https://github.com/notofonts/noto-cjk/tree/main/Sans/OTF/SimplifiedChinese) is distributed under the bundled NotoSansCJK-OFL.txt. After editing data/ui_text.csv, regenerate with `uvx --from fonttools pyftsubset NotoSansCJKsc-Bold.otf --text-file=data/ui_text.csv --name-IDs='*' --output-file=assets/fonts/NotoSansSC-UI.otf`.
