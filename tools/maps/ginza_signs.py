"""Draw Ginza Station signage as SVG paths from Glow Sans glyph outlines.

Usage: python3 tools/maps/ginza_signs.py GlowSansSC-Normal-v0.93.zip
"""
import io
import sys
from pathlib import Path
from zipfile import ZipFile

from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont

OUT = Path(__file__).resolve().parents[2]/"assets/art/arena_signs"
ORANGE, RED, SILVER, INK, CREAM, YELLOW = "#f39700", "#e60012", "#9caeb7", "#1d2433", "#fbf7ee", "#ffd200"


class Fonts:
    def __init__(self, archive):
        with ZipFile(archive) as zipped:
            self.bold = TTFont(io.BytesIO(zipped.read("GlowSansSC-Normal-Bold.otf")))
            self.medium = TTFont(io.BytesIO(zipped.read("GlowSansSC-Normal-Medium.otf")))

    def text(self, value, x, y, size, color, *, weight="bold", anchor="start", spacing=0.0):
        """Baseline at y; size is the em height in SVG units."""
        font = self.bold if weight == "bold" else self.medium
        glyphs, cmap = font.getGlyphSet(), font.getBestCmap()
        scale = size/font["head"].unitsPerEm
        advances = [glyphs[cmap[ord(char)]].width*scale+spacing*size for char in value]
        width = sum(advances)-spacing*size
        x -= {"start": 0, "middle": width/2, "end": width}[anchor]
        parts = []
        for char, advance in zip(value, advances):
            if char != " ":
                pen = SVGPathPen(glyphs)
                glyphs[cmap[ord(char)]].draw(TransformPen(pen, (scale, 0, 0, -scale, x, y)))
                parts.append(pen.getCommands())
            x += advance
        return f'<path fill="{color}" d="{"".join(parts)}"/>'


def roundel(fonts, cx, cy, r, color, letter, *, number=""):
    out = [f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="#ffffff"/>',
           f'<circle cx="{cx}" cy="{cy}" r="{r*.86}" fill="none" stroke="{color}" stroke-width="{r*.24}"/>',
           fonts.text(letter, cx, cy+(r*.2 if number else r*.36), r*(.78 if number else 1.0), INK, anchor="middle")]
    if number:
        out.append(fonts.text(number, cx, cy+r*.62, r*.42, INK, anchor="middle"))
    return "".join(out)


def arrow(x, y, s, color, direction):
    shapes = {
        "up": "M0 -1L.8 -.1H.3V1H-.3V-.1H-.8Z",
        "left": "M-1 0L-.1 -.8V-.3H1V.3H-.1V.8Z",
        "right": "M1 0L.1 -.8V-.3H-1V.3H.1V.8Z",
    }
    return f'<path fill="{color}" transform="translate({x} {y}) scale({s})" d="{shapes[direction]}"/>'


def svg(name, width, height, body):
    content = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" '
               f'viewBox="0 0 {width} {height}">'+"".join(body)+"</svg>\n")
    (OUT/f"{name}.svg").write_text(content)


def build(fonts):
    t = fonts.text
    svg("ginza-station-name", 1024, 256, [
        f'<rect width="1024" height="256" fill="{CREAM}"/>',
        f'<rect y="206" width="1024" height="50" fill="{ORANGE}"/>',
        f'<rect y="0" width="1024" height="10" fill="{INK}"/>',
        roundel(fonts, 330, 112, 38, ORANGE, "G", number="09"),
        t("ぎんざ", 512, 52, 30, INK, weight="medium", anchor="middle", spacing=.3),
        t("銀座", 512, 152, 96, INK, anchor="middle", spacing=.18),
        t("Ginza", 512, 194, 32, INK, weight="medium", anchor="middle"),
        arrow(48, 126, 22, INK, "left"),
        t("京橋", 84, 140, 46, INK),
        t("Kyobashi  G10", 84, 176, 22, INK, weight="medium"),
        arrow(976, 126, 22, INK, "right"),
        t("新橋", 940, 140, 46, INK, anchor="end"),
        t("Shimbashi  G08", 940, 176, 22, INK, weight="medium", anchor="end"),
    ])
    svg("ginza-exit", 512, 128, [
        f'<rect width="512" height="128" rx="8" fill="{YELLOW}"/>',
        t("出口", 32, 84, 64, INK, spacing=.08),
        f'<rect x="184" y="28" width="92" height="72" rx="8" fill="{INK}"/>',
        t("A2", 230, 86, 52, YELLOW, anchor="middle"),
        t("Exit", 300, 84, 46, INK),
        arrow(452, 64, 34, INK, "up"),
    ])
    svg("ginza-marunouchi", 512, 128, [
        f'<rect width="512" height="128" rx="8" fill="#ffffff"/>',
        f'<rect y="112" width="512" height="16" fill="{RED}"/>',
        roundel(fonts, 64, 58, 40, RED, "M"),
        t("丸ノ内線", 120, 66, 46, INK),
        t("Marunouchi Line", 122, 98, 22, INK, weight="medium"),
        arrow(458, 58, 30, INK, "right"),
    ])
    svg("ginza-hibiya", 512, 128, [
        f'<rect width="512" height="128" rx="8" fill="#ffffff"/>',
        f'<rect y="112" width="512" height="16" fill="{SILVER}"/>',
        roundel(fonts, 64, 58, 40, SILVER, "H"),
        t("日比谷線", 120, 66, 46, INK),
        t("Hibiya Line", 122, 98, 22, INK, weight="medium"),
        arrow(458, 58, 30, INK, "up"),
    ])
    amber, dim = "#ffb21e", "#3b2a10"
    rows = [("渋谷", "21:37", "1"), ("浅草", "21:42", "2")]
    body = [f'<rect width="1024" height="256" fill="#0d0f14"/>', f'<rect x="8" y="8" width="1008" height="240" fill="#16191f"/>']
    for i, (dest, time, track) in enumerate(rows):
        y = 104+i*104
        body += [roundel(fonts, 64, y-30, 30, ORANGE, "G"),
                 t("各停", 120, y, 54, "#7be06b"), t(dest, 290, y, 64, amber, spacing=.1),
                 t("行", 450, y, 44, amber), t(time, 600, y, 64, amber), t(f"{track}番線", 820, y, 50, amber)]
    svg("ginza-departures", 1024, 256, body+[f'<path stroke="{dim}" stroke-width="2" d="M8 128H1016"/>'])
    svg("ginza-passing", 1024, 256, [
        f'<rect width="1024" height="256" fill="#0d0f14"/>', f'<rect x="8" y="8" width="1008" height="240" fill="#1a0c0e"/>',
        t("通過列車", 512, 120, 92, "#ff3b3b", anchor="middle", spacing=.12),
        t("ご注意下さい", 512, 210, 64, "#ff8a3b", anchor="middle", spacing=.08),
    ])
    stripes = "".join(f'<path fill="{INK}" d="M{x} 0h28l-56 96h-28z"/>' for x in range(0, 560, 56))
    svg("ginza-construction", 512, 384, [
        '<rect width="512" height="384" fill="#ffffff"/>',
        f'<svg y="24" width="512" height="96" viewBox="0 0 512 96"><rect width="512" height="96" fill="{YELLOW}"/>{stripes}</svg>',
        t("工事中", 256, 236, 108, INK, anchor="middle", spacing=.08),
        t("ご迷惑をおかけします", 256, 296, 38, INK, weight="medium", anchor="middle"),
        t("東京メトロ", 256, 348, 30, ORANGE, anchor="middle"),
    ])
    svg("ginza-office", 512, 128, [
        f'<rect width="512" height="128" fill="{CREAM}"/>', f'<rect y="104" width="512" height="24" fill="{ORANGE}"/>',
        t("駅事務室", 256, 70, 56, INK, anchor="middle", spacing=.1),
        t("Station Office", 256, 98, 22, INK, weight="medium", anchor="middle"),
    ])
    for name, track, dest, latin, side in (("ginza-track-1", "1", "渋谷方面", "for Shibuya", "left"),
                                           ("ginza-track-2", "2", "浅草方面", "for Asakusa", "right")):
        svg(name, 512, 128, [
            f'<rect width="512" height="128" fill="{INK}"/>',
            f'<circle cx="64" cy="64" r="44" fill="{CREAM}"/>', t(track, 64, 90, 72, INK, anchor="middle"),
            t("番線", 120, 66, 34, CREAM), t(dest, 214, 66, 44, CREAM), t(latin, 214, 102, 24, CREAM, weight="medium"),
            arrow(466, 64, 28, ORANGE, side),
        ])
    svg("ginza-roundel", 128, 128, [roundel(fonts, 64, 64, 60, ORANGE, "G")])
    svg("ginza-roundel-m", 128, 128, [roundel(fonts, 64, 64, 60, RED, "M")])
    lines = [(ORANGE, "M40 180C160 180 200 90 320 90S460 150 600 150 760 70 980 70"),
             (RED, "M40 70C200 70 260 160 420 160S700 220 980 200"),
             (SILVER, "M80 230C240 220 360 40 560 40S860 120 980 130"),
             ("#00a7db", "M60 120H980"), ("#9c5e31", "M200 240C320 120 600 260 900 30")]
    body = ['<rect width="1024" height="256" fill="#ffffff"/>']
    for color, d in lines:
        body.append(f'<path d="{d}" fill="none" stroke="{color}" stroke-width="12" stroke-linecap="round"/>')
    for x, y in ((320, 90), (420, 160), (560, 40), (600, 150), (760, 120), (180, 120), (900, 70)):
        body.append(f'<circle cx="{x}" cy="{y}" r="13" fill="#ffffff" stroke="{INK}" stroke-width="5"/>')
    svg("ginza-fare-map", 1024, 256, body)
    palettes = [("#ffcf3d", "#f39700", "#fff3c4"), ("#7cc6f0", "#2b6fd6", "#e8f6ff"), ("#ffb3c8", "#e2457a", "#fff0f4")]
    for i, (a, b, c) in enumerate(palettes):
        svg(f"ginza-ad-{i+1}", 512, 288, [
            f'<rect width="512" height="288" fill="{c}"/>',
            f'<circle cx="{360-i*80}" cy="{150+i*20}" r="150" fill="{a}"/>',
            f'<path fill="{b}" d="M0 288L{200+i*60} {60+i*30}L512 288Z"/>',
            f'<rect x="32" y="{36+i*12}" width="{150+i*40}" height="22" rx="11" fill="#ffffff" fill-opacity=".85"/>',
        ])


if __name__ == "__main__":
    build(Fonts(sys.argv[1]))
    print("GINZA_SIGNS_READY")
