"""Run after a Web export: python3 tools/check_web.py."""
import json
import re
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlsplit

root = Path(__file__).resolve().parents[1] / "web"


class Links(HTMLParser):
    def handle_starttag(self, tag, attrs):
        for key, value in attrs:
            if key not in ("src", "href") or not value:
                continue
            url = urlsplit(value)
            if url.scheme or url.netloc or not url.path:
                continue
            target = (self.page.parent / url.path).resolve()
            assert target.is_relative_to(root.resolve()), target
            assert target.exists(), f"Missing {value} in {self.page}"


for page in root.rglob("*.html"):
    html = page.read_text()
    assert "$GODOT_" not in html, "Unexpanded export template"
    parser = Links()
    parser.page = page
    parser.feed(html)

html = (root / "play/index.html").read_text()
config = json.loads(re.search(r"const config = (\{[^\n]+\});", html)[1])
for name, size in config["fileSizes"].items():
    assert (root / "play" / name).stat().st_size == size, f"Stale export: {name}"
assert (root / "play/index.wasm").read_bytes()[:4] == b"\0asm"
assert (root / "play/index.pck").read_bytes()[:4] == b"GDPC"
assert "threads: false" in html, "Pages requires the single-threaded build"
assert 'href="mailto:cwen@hust.edu.cn"' in (root / "index.html").read_text()
print("WEB_CHECK_PASS local links, export sizes, WASM/PCK headers, single thread, contact")
