#!/usr/bin/env python3
"""Generate Kiri8 and synchronize the approved DotGothic16 font inputs."""

from __future__ import annotations

import argparse
import binascii
import hashlib
import json
import math
import re
import struct
import sys
import zlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
VISUAL_SOURCE = ROOT / "design" / "06_art" / "visual_system_v2"
PIXEL_CORE = VISUAL_SOURCE / "source" / "pixel_core.js"
FONT_SOURCE = VISUAL_SOURCE / "assets" / "fonts"
FONT_DESTINATION = ROOT / "ui" / "fonts"
LICENSE_DESTINATION = ROOT / "LICENSES" / "DotGothic16-OFL-1.1.txt"

FIRST_CODEPOINT = 32
LAST_CODEPOINT = 126
ATLAS_COLUMNS = 16
CELL_WIDTH = 6
CELL_HEIGHT = 8
GLYPH_WIDTH = 5
GLYPH_HEIGHT = 7


def _sha256(payload: bytes) -> str:
    return hashlib.sha256(payload).hexdigest()


def _stable_json(data: object) -> bytes:
    return (json.dumps(data, ensure_ascii=False, indent=2) + "\n").encode()


def _parse_kiri8_source() -> dict[str, tuple[str, ...]]:
    source = PIXEL_CORE.read_text(encoding="utf-8")
    start = source.index("const FONT_5X7 = {")
    end = source.index("\n};", start)
    glyphs: dict[str, tuple[str, ...]] = {}
    line_pattern = re.compile(r"^\s*(?:'([^']*)'|\"([^\"]*)\"):\s*\[(.*)\],\s*$")
    for line in source[start:end].splitlines()[1:]:
        match = line_pattern.match(line)
        if match is None:
            continue
        key = match.group(1) if match.group(1) is not None else match.group(2)
        rows = tuple(re.findall(r"['\"]([01]{5})['\"]", match.group(3)))
        if len(key) != 1 or len(rows) != GLYPH_HEIGHT:
            raise ValueError(f"invalid Kiri8 glyph source line: {line}")
        glyphs[key] = rows
    required = set(" ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789?")
    missing = sorted(required.difference(glyphs))
    if missing:
        raise ValueError(f"Kiri8 source lacks required glyphs: {missing}")
    return glyphs


def _png_chunk(name: bytes, payload: bytes) -> bytes:
    checksum = binascii.crc32(name)
    checksum = binascii.crc32(payload, checksum) & 0xFFFFFFFF
    return (
        struct.pack(">I", len(payload)) + name + payload + struct.pack(">I", checksum)
    )


def _encode_rgba_png(width: int, height: int, pixels: bytearray) -> bytes:
    row_size = width * 4
    scanlines = b"".join(
        b"\x00" + bytes(pixels[y * row_size : (y + 1) * row_size])
        for y in range(height)
    )
    header = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    return b"".join(
        (
            b"\x89PNG\r\n\x1a\n",
            _png_chunk(b"IHDR", header),
            _png_chunk(b"IDAT", zlib.compress(scanlines, level=9)),
            _png_chunk(b"IEND", b""),
        )
    )


def _glyph_for(character: str, glyphs: dict[str, tuple[str, ...]]) -> tuple[str, ...]:
    normalized = character.upper() if character.isascii() else character
    return glyphs.get(normalized, glyphs["?"])


def _build_kiri8() -> bytes:
    glyphs = _parse_kiri8_source()
    character_count = LAST_CODEPOINT - FIRST_CODEPOINT + 1
    rows = math.ceil(character_count / ATLAS_COLUMNS)
    width = ATLAS_COLUMNS * CELL_WIDTH
    height = rows * CELL_HEIGHT
    pixels = bytearray(width * height * 4)
    for index, codepoint in enumerate(range(FIRST_CODEPOINT, LAST_CODEPOINT + 1)):
        cell_x = index % ATLAS_COLUMNS * CELL_WIDTH
        cell_y = index // ATLAS_COLUMNS * CELL_HEIGHT
        for glyph_y, row in enumerate(_glyph_for(chr(codepoint), glyphs)):
            for glyph_x, bit in enumerate(row):
                if bit == "0":
                    continue
                offset = ((cell_y + glyph_y) * width + cell_x + glyph_x) * 4
                pixels[offset : offset + 4] = b"\xff\xff\xff\xff"
    return _encode_rgba_png(width, height, pixels)


def _expected_outputs() -> dict[Path, bytes]:
    kiri_png = _build_kiri8()
    outputs = {
        FONT_DESTINATION / "kiri8_latin.png": kiri_png,
    }
    copied_names = [
        "DotGothic16-Japanese.woff2",
        "DotGothic16-Latin.woff2",
        "DotGothic16-LICENSE.txt",
    ]
    for name in copied_names:
        outputs[FONT_DESTINATION / name] = (FONT_SOURCE / name).read_bytes()
    outputs[LICENSE_DESTINATION] = outputs[FONT_DESTINATION / "DotGothic16-LICENSE.txt"]

    manifest_files = []
    for path, payload in sorted(outputs.items()):
        manifest_files.append(
            {
                "path": path.relative_to(ROOT).as_posix(),
                "sha256": _sha256(payload),
                "bytes": len(payload),
            }
        )
    manifest = {
        "schema": "gmh-font-sync-v1",
        "source_revision": "2026.07.14.1",
        "kiri8_source": PIXEL_CORE.relative_to(ROOT).as_posix(),
        "kiri8_contract": {
            "glyph": [GLYPH_WIDTH, GLYPH_HEIGHT],
            "cell": [CELL_WIDTH, CELL_HEIGHT],
            "codepoints": [FIRST_CODEPOINT, LAST_CODEPOINT],
            "fallback": "?",
            "lowercase_rendering": "uppercase prototype glyph",
        },
        "files": manifest_files,
    }
    outputs[FONT_DESTINATION / "font_manifest.json"] = _stable_json(manifest)
    return outputs


def _write(outputs: dict[Path, bytes]) -> int:
    for path, payload in outputs.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(payload)
    print(f"Synchronized {len(outputs)} deterministic font files")
    return 0


def _check(outputs: dict[Path, bytes]) -> int:
    errors: list[str] = []
    for path, expected in outputs.items():
        if not path.is_file():
            errors.append(f"missing: {path.relative_to(ROOT)}")
        elif path.read_bytes() != expected:
            errors.append(f"out of date: {path.relative_to(ROOT)}")
    for error in errors:
        print(f"ERROR {error}", file=sys.stderr)
    if errors:
        return 1
    print(f"Font synchronization check passed for {len(outputs)} files")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--write", action="store_true", help="write synchronized outputs")
    mode.add_argument("--check", action="store_true", help="verify outputs are current")
    args = parser.parse_args()
    outputs = _expected_outputs()
    return _write(outputs) if args.write else _check(outputs)


if __name__ == "__main__":
    raise SystemExit(main())
