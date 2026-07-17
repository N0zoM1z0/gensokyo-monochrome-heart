#!/usr/bin/env python3
"""Reject malformed localization CSV before Godot's translation importer sees it."""

from __future__ import annotations

import csv
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LOCALIZATION_DIR = ROOT / "content" / "localization"
MUSIC_PATH = ROOT / "content" / "music" / "music_cues.csv"
SCHEMAS = {
    "en.csv": ["key", "en"],
    "ja.csv": ["key", "ja"],
}
DEFAULT_HEADER = ["key", "_context", "_speaker", "en", "ja", "_max_width_px", "_origin"]
MUSIC_HEADER = [
    "cue_id",
    "_section",
    "_scene_or_system",
    "_mood_function",
    "_touhou_reference_en",
    "_touhou_reference_ja",
    "_source_work",
    "_arrangement_brief",
    "_loop",
    "_priority",
]


def main() -> int:
    errors: list[str] = []
    checked = 0
    for path in sorted(LOCALIZATION_DIR.glob("*.csv")):
        expected_header = SCHEMAS.get(path.name, DEFAULT_HEADER)
        with path.open(encoding="utf-8-sig", newline="") as source:
            rows = list(csv.reader(source))
        checked += 1
        if not rows:
            errors.append(f"{path.relative_to(ROOT)}: empty CSV")
            continue
        if rows[0] != expected_header:
            errors.append(
                f"{path.relative_to(ROOT)}: expected header {expected_header!r}, found {rows[0]!r}"
            )
        for line_number, row in enumerate(rows[1:], start=2):
            if not any(row):
                continue
            if len(row) != len(expected_header):
                errors.append(
                    f"{path.relative_to(ROOT)}:{line_number}: expected {len(expected_header)} columns, found {len(row)}"
                )
    with MUSIC_PATH.open(encoding="utf-8-sig", newline="") as source:
        music_rows = list(csv.reader(source))
    checked += 1
    if not music_rows or music_rows[0] != MUSIC_HEADER:
        actual_header = music_rows[0] if music_rows else []
        errors.append(
            f"{MUSIC_PATH.relative_to(ROOT)}: expected header {MUSIC_HEADER!r}, found {actual_header!r}"
        )
    for line_number, row in enumerate(music_rows[1:], start=2):
        if any(row) and len(row) != len(MUSIC_HEADER):
            errors.append(
                f"{MUSIC_PATH.relative_to(ROOT)}:{line_number}: expected {len(MUSIC_HEADER)} columns, found {len(row)}"
            )
    if errors:
        print("Localization CSV validation failed:", file=sys.stderr)
        print("\n".join(errors), file=sys.stderr)
        return 1
    print(f"Localization CSV validation: PASS ({checked} files)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
