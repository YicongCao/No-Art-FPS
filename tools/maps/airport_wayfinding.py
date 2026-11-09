"""Draw the dock wayfinding sign from pixel glyphs and geometric symbols."""
from pathlib import Path

from airport_board import GLYPHS

# Bitmap silhouettes sampled from Ark Pixel 12px by TakWolf.
CJK = {
    "保": "000 2fc 284 484 4fc c10 410 5fe 438 454 592 410",
    "到": "000 fe2 10a 20a 44a faa 10a 10a fea 102 1e2 e0e",
    "取": "000 fc0 4be 7a2 4a2 4a2 7a2 494 494 5c8 e94 0a2",
    "受": "000 01c 7e0 244 128 ffe 802 bfa 208 110 0e0 f1e",
    "台": "000 080 100 208 404 ffa 002 7fc 404 404 404 7fc",
    "安": "000 040 ffe 802 080 080 ffe 108 208 110 0e0 f1e",
    "手": "000 03c 7c0 040 040 7fc 040 040 ffe 040 040 1c0",
    "李": "000 040 ffe 150 248 c46 3f8 010 060 ffe 040 1c0",
    "柜": "000 27e 240 f40 27e 242 642 742 a7e 240 240 27e",
    "査": "000 040 ffe 150 248 ffe 208 3f8 208 3f8 208 ffe",
    "检": "000 210 228 f44 282 27c 600 6a2 b54 254 208 2fe",
    "検": "000 210 228 f44 2ba 210 6fe 792 afe 210 228 2c6",
    "物": "000 240 a40 f7e aaa 22a 32a e4a 252 292 222 24c",
    "盘": "000 040 3fc 244 224 ffe 244 42c 000 7fc 4a4 ffe",
    "着": "000 110 ffe 080 7fc 100 ffe 204 604 bfc 204 3fc",
    "荷": "000 110 ffe 110 000 2fe 204 4f4 c94 494 4f4 40c",
    "行": "000 27c 400 800 2fe 408 c08 408 408 408 408 438",
    "转": "000 210 f7c 410 a10 afe f20 27c 304 e28 210 208",
    "达": "000 810 410 010 1fe c10 428 428 444 482 a00 9fe",
}

LABELS = [
    ("ARRIVALS", "到达", "到着", "#ffcb67", "M6 1h3v7l9 4v3l-9-2v6l3 2v2l-5-1-5 1v-2l3-2v-6l-9 2v-3l10-4z"),
    ("BAGGAGE CLAIM", "行李转盘", "手荷物受取", "#75dcf3", "M2 5h5V1h8v4h5v16H2zM9 5h4V3H9zM5 8v10h2V8zm10 0v10h2V8z"),
    ("SECURITY CHECK", "安检柜台", "保安検査", "#ffcb67", "M2 2h20v21h-4V6H6v17H2zM8 9h8v3H8zM9 16h6v3H9z"),
]


def lettering(text, x, y, unit, color, cjk=False):
    parts = []
    width = 12 if cjk else 5
    for char in text:
        if char != " ":
            if cjk:
                rows = [f"{int(row,16):012b}" for row in CJK[char].split()]
            else:
                rows = GLYPHS[char].split()
            for row, pixels in enumerate(rows):
                for col, lit in enumerate(pixels):
                    if lit == "1":
                        parts.append(f"M{x+col*unit:g} {y+row*unit:g}h{unit:g}v{unit:g}h-{unit:g}z")
        x += (width+1)*unit
    return f'<path fill="{color}" d="{"".join(parts)}"/>'


def write_wayfinding():
    width, height = 804, 96
    svg = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}" shape-rendering="crispEdges" fill-rule="evenodd">',
           '<path fill="#121d31" d="M0 0h804v96H0z"/><path fill="#466281" d="M5 4h794v3H5zM5 89h794v3H5zM266 7h2v82h-2zM534 7h2v82h-2z"/>']
    for i, (en,zh,ja,tint,symbol) in enumerate(LABELS):
        x = i*268
        svg.append(f'<path fill="{tint}" transform="translate({x+26} 20) scale(1.12)" d="{symbol}"/>')
        arrow = "M15 61l12-11 12 11h-8v13h-8V61z" if i<2 else "M15 64l12-11v7h12v8H27v7z"
        svg.append(f'<path fill="{tint}" transform="translate({x+5} 0)" d="{arrow}"/>')
        svg.append(lettering(en,x+58,12,2.43,"#fff6dc"))
        svg.append(lettering(zh,x+58,33,2.05,"#fff6dc",True))
        svg.append(lettering(ja,x+58,62,2.05,"#dbe7ee",True))
    svg.append("</svg>")
    out = Path(__file__).resolve().parents[2]/"assets/art/arena_signs/airport-wayfinding.svg"
    out.write_text("\n".join(svg)+"\n")
