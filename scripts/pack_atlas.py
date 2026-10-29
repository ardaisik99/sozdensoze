"""Pack generated PNG artwork at native resolution; palette-optimize web copies.

Optional authoring tool: python scripts/pack_atlas.py (requires Pillow).
The prebuilt PNG is committed, so Godot/CI does not depend on Python.
"""
from pathlib import Path
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/source_art"
OUTPUT = ROOT / "assets/atlases"
WIDTH, LIMIT, PAD = 2048, 4096, 4


def contains(a, b):
    return a[0] <= b[0] and a[1] <= b[1] and a[0]+a[2] >= b[0]+b[2] and a[1]+a[3] >= b[1]+b[3]


def split(free, used):
    x, y, w, h = free
    ux, uy, uw, uh = used
    if ux >= x+w or ux+uw <= x or uy >= y+h or uy+uh <= y:
        return [free]
    out = []
    if uy > y:
        out.append((x, y, w, uy-y))
    if uy+uh < y+h:
        out.append((x, uy+uh, w, y+h-uy-uh))
    if ux > x:
        out.append((x, y, ux-x, h))
    if ux+uw < x+w:
        out.append((ux+uw, y, x+w-ux-uw, h))
    return out


def main():
    metadata = json.loads((SOURCE / "source-regions.json").read_text())
    originals = {name: Image.open(SOURCE / (name+".png")).convert("RGBA") for name in metadata}
    sprites = []
    for group, regions in metadata.items():
        for i, (x, y, w, h) in enumerate(regions):
            sprites.append((group, i, originals[group].crop((x, y, x+w, y+h))))
    sprites.sort(key=lambda item: max(item[2].size), reverse=True)
    free = [(0, 0, WIDTH, LIMIT)]
    placed = []
    for group, index, image in sprites:
        w, h = image.width+PAD*2, image.height+PAD*2
        candidates = [r for r in free if r[2] >= w and r[3] >= h]
        if not candidates:
            raise RuntimeError("Atlas overflow; increase WIDTH or LIMIT deliberately")
        box = min(candidates, key=lambda r: (min(r[2]-w, r[3]-h), max(r[2]-w, r[3]-h)))
        used = (box[0], box[1], w, h)
        pieces = list(set(p for r in free for p in split(r, used)))
        free = [r for i, r in enumerate(pieces) if not any(j != i and contains(other, r) for j, other in enumerate(pieces))]
        placed.append((group, index, image, box[0]+PAD, box[1]+PAD))
    height = ((max(y+im.height+PAD for _, _, im, _, y in placed)+63)//64)*64
    canvas = Image.new("RGBA", (WIDTH, height))
    output = {group: [None]*len(regions) for group, regions in metadata.items()}
    for group, index, image, x, y in placed:
        canvas.paste(image, (x, y))
        output[group][index] = [x, y, image.width, image.height]
    OUTPUT.mkdir(exist_ok=True)
    # Keep the full RGBA master. Indexed PNG reduces paper-grain entropy without
    # resizing the ink, UI corners or glyphs (text remains separate MSDF fonts).
    canvas.save(SOURCE / "game-atlas-master.png", optimize=True)
    canvas.quantize(colors=256, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE).save(OUTPUT / "game-atlas.png", optimize=True)
    background = Image.open(ROOT / "assets/art/night-library.png").convert("RGBA")
    background.quantize(colors=256, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE).save(ROOT / "assets/art/night-library-web.png", optimize=True)
    (OUTPUT / "regions.json").write_text(json.dumps(output, indent=2)+"\n")
    print(f"{len(placed)} PNG sprites -> {WIDTH}x{height}; native resolution, 256-color web palette")


if __name__ == "__main__":
    main()
