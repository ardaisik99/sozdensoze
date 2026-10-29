"""Local Godot preview with HTTP Range support: python scripts/preview_web.py."""
from pathlib import Path
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import re

ROOT = Path(__file__).resolve().parents[1] / "builds/web"


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def do_GET(self):
        match = re.fullmatch(r"bytes=(\d+)-(\d+)", self.headers.get("Range", ""))
        path = Path(self.translate_path(self.path))
        if not match or not path.is_file():
            return super().do_GET()
        size = path.stat().st_size
        start, end = int(match[1]), min(int(match[2]), size - 1)
        if start > end:
            self.send_error(416)
            return
        self.send_response(206)
        self.send_header("Content-Type", self.guess_type(str(path)))
        self.send_header("Accept-Ranges", "bytes")
        self.send_header("Content-Range", f"bytes {start}-{end}/{size}")
        self.send_header("Content-Length", str(end - start + 1))
        self.end_headers()
        with path.open("rb") as file:
            file.seek(start)
            self.wfile.write(file.read(end - start + 1))


if __name__ == "__main__":
    print("Sözden Söze: http://127.0.0.1:8074", flush=True)
    ThreadingHTTPServer(("127.0.0.1", 8074), Handler).serve_forever()
