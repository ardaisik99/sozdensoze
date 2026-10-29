"""Finish a Godot Web export using Python's standard library only."""
from pathlib import Path
import gzip
import shutil

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "builds/web"
OUT.mkdir(parents=True, exist_ok=True)
for source in ["assets/fonts/PatrickHand-Regular.ttf", "assets/fonts/DynaPuff.ttf", "assets/icon.png", "web/download.mjs"]:
    shutil.copy2(ROOT / source, OUT / Path(source).name)
shutil.copy2(ROOT / "assets/art/night-library-web.png", OUT / "night-library.png")
(OUT / "licenses").mkdir(exist_ok=True)
for source in [*(ROOT / "assets/licenses").glob("*.txt"), *(ROOT / "assets/fonts").glob("*-OFL.txt")]:
    shutil.copy2(source, OUT / "licenses" / source.name)
with (OUT / "index.wasm").open("rb") as src, (OUT / "index.wasm.gz").open("wb") as dst:
    with gzip.GzipFile(filename="", mode="wb", fileobj=dst, compresslevel=9, mtime=0) as compressed:
        shutil.copyfileobj(src, compressed)
(OUT / ".nojekyll").touch()
print("Web export ready; chunked gzip transport and notices included.")
