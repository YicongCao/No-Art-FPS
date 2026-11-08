"""Build the bundled Glow Sans subsets from the upstream SC Normal release zip."""

import csv
import io
import sys
from pathlib import Path
from zipfile import ZipFile

from fontTools import subset

ROOT = Path(__file__).resolve().parents[1]


def save_subset(archive, weight, text, path, flavor=None):
    source = f"GlowSansSC-Normal-{weight}.otf"
    options = subset.Options()
    options.name_IDs = ["*"]
    font = subset.load_font(io.BytesIO(archive.read(source)), options)
    codepoints = {ord(char) for char in text if ord(char) > 127 and not char.isspace()}
    missing = codepoints - font.getBestCmap().keys()
    if missing:
        raise ValueError(f"{source} is missing {''.join(map(chr, sorted(missing)))}")
    selection = subset.Subsetter(options=options)
    selection.populate(unicodes=codepoints)
    selection.subset(font)
    # CID glyphs use FDArray's private dictionaries. Glow Sans also ships a
    # redundant top-level dictionary with thousands of unused subroutines.
    top = font["CFF "].cff.topDictIndex[0]
    if hasattr(top, "FDArray") and hasattr(top, "ROS"):
        top.rawDict.pop("Private", None)
        if hasattr(top, "Private"):
            del top.Private
    options.flavor = flavor
    subset.save_font(font, ROOT / path, options)


if __name__ == "__main__":
    with (ROOT / "data/ui_text.csv").open(encoding="utf-8") as catalog:
        translations = {row["keys"]: row["zh"] for row in csv.DictReader(catalog)}
    web_text = "".join(
        (ROOT / "web" / name).read_text(encoding="utf-8")
        for name in ("shell.html", "locale.js", "gyro.js", "gyro-setup.js")
    )
    with ZipFile(sys.argv[1]) as archive:
        save_subset(archive, "Medium", "".join(translations) + "".join(translations.values()), "assets/fonts/GlowSansSC-UI.otf")
        save_subset(archive, "Bold", translations["DESTROY ALL"], "assets/fonts/GlowSansSC-Frenzy.otf")
        save_subset(archive, "Medium", web_text, "web/GlowSansSC-UI.woff2", "woff2")
