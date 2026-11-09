"""Extract repeatable pixel detail from the ImageGen park material atlas."""
from pathlib import Path

from PIL import Image, ImageOps, ImageStat

ROOT = Path(__file__).resolve().parents[2]
ATLAS = ROOT / "docs/art/park-texture-experiment/imagegen-atlas.png"
DESTINATION = ROOT / "assets/textures/park_experiment"
CELLS = (
    ("pavers", 2.9), ("gravel", 1.65), ("brick", 2.1),
    ("concrete", 2.35), ("wood", 2.15), ("metal", 2.05),
    ("canvas", 2.25), ("enamel", 2.15), ("ceramic", 2.4),
)


def build():
    atlas = Image.open(ATLAS).convert("RGB")
    DESTINATION.mkdir(parents=True, exist_ok=True)
    for index, (name, gain) in enumerate(CELLS):
        row, column = divmod(index, 3)
        x0, x1 = round(column * atlas.width / 3), round((column + 1) * atlas.width / 3)
        y0, y1 = round(row * atlas.height / 3), round((row + 1) * atlas.height / 3)
        cell = atlas.crop((x0+3, y0+3, x1-3, y1-3))
        pixels = ImageOps.grayscale(cell).resize((48, 48), Image.Resampling.BOX)
        mean = ImageStat.Stat(pixels).mean[0]
        detail = pixels.point([round(max(0, min(255, 128 + (i-mean)*gain))) for i in range(256)])
        tile = Image.new("L", (96, 96))
        tile.paste(detail, (0, 0))
        tile.paste(ImageOps.mirror(detail), (48, 0))
        tile.paste(ImageOps.flip(detail), (0, 48))
        tile.paste(ImageOps.flip(ImageOps.mirror(detail)), (48, 48))
        tile.save(DESTINATION / f"{name}.png", optimize=True)


if __name__ == "__main__":
    build()
