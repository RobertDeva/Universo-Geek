#!/usr/bin/env python3
"""Dependency-free smoke checks for Universo Geek static pages."""
from html.parser import HTMLParser
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
ERRORS = []

class PageParser(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.ids = set()
        self.refs = []
    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if attrs.get("id"):
            if attrs["id"] in self.ids:
                ERRORS.append(f"ID duplicado: {attrs['id']}")
            self.ids.add(attrs["id"])
        for attr in ("href", "src"):
            value = attrs.get(attr, "").strip()
            if value:
                self.refs.append((tag, attr, value))

pages = sorted(ROOT.glob("*.html"))
if not pages:
    ERRORS.append("No se encontraron páginas HTML en la raíz.")

parsed = {}
for page in pages:
    parser = PageParser()
    try:
        parser.feed(page.read_text(encoding="utf-8"))
        parser.close()
    except Exception as exc:
        ERRORS.append(f"{page.name}: HTML no se pudo analizar: {exc}")
    parsed[page] = parser

for page, parser in parsed.items():
    for tag, attr, raw in parser.refs:
        if raw.startswith(("#", "https://", "http://", "//", "mailto:", "tel:", "data:", "javascript:")):
            if raw.startswith("#") and raw[1:] and raw[1:] not in parser.ids:
                ERRORS.append(f"{page.name}: ancla inexistente {raw}")
            continue
        target_part, _, fragment = raw.partition("#")
        target_part = target_part.split("?", 1)[0]
        if not target_part:
            continue
        target = (page.parent / target_part).resolve()
        if not target.is_file():
            ERRORS.append(f"{page.name}: {attr} local inexistente: {raw}")
            continue
        if fragment and target.suffix.lower() == ".html":
            target_page = next((p for p in parsed if p.resolve() == target), None)
            if target_page and fragment not in parsed[target_page].ids:
                ERRORS.append(f"{page.name}: ancla inexistente en {target.name}: #{fragment}")

css_files = list((ROOT / "assets" / "css").glob("*.css"))
for css in css_files:
    content = css.read_text(encoding="utf-8")
    if content.count("{") != content.count("}"):
        ERRORS.append(f"{css.relative_to(ROOT)}: llaves CSS desbalanceadas")

app = ROOT / "assets" / "js" / "app.js"
if app.exists():
    content = app.read_text(encoding="utf-8")
    for marker in ('data-theme-toggle', 'data-section-search', 'event.key === "Escape"', 'prefers-reduced-motion'):
        candidate = content if marker != 'prefers-reduced-motion' else "\n".join(p.read_text(encoding="utf-8") for p in css_files)
        if marker not in candidate:
            ERRORS.append(f"Falta comprobación de funcionalidad: {marker}")

if ERRORS:
    print("SMOKE TEST: FALLÓ")
    for error in ERRORS:
        print(" - " + error)
    sys.exit(1)

print(f"SMOKE TEST: OK — {len(pages)} páginas HTML, {len(css_files)} hojas CSS y referencias locales verificadas.")
