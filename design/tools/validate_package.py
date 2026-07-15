#!/usr/bin/env python3
"""Validate the design package without requiring Godot."""
from __future__ import annotations
from pathlib import Path
import csv, json, re, sys

ROOT = Path(__file__).resolve().parents[1]
ERRORS: list[str] = []
WARNINGS: list[str] = []


def error(msg: str) -> None:
    ERRORS.append(msg)


def warning(msg: str) -> None:
    WARNINGS.append(msg)


def load_json(path: Path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        error(f"JSON parse failed: {path.relative_to(ROOT)}: {exc}")
        return None


def main() -> int:
    files = [p for p in ROOT.rglob("*") if p.is_file()]
    if not files:
        error("Package contains no files")
    for path in files:
        if path.stat().st_size == 0:
            error(f"Empty file: {path.relative_to(ROOT)}")

    expected_dirs = [f"{i:02d}_{name}" for i, name in [
        (0,"project"),(1,"game_design"),(2,"narrative"),(3,"locations"),
        (4,"characters"),(5,"ui_ux"),(6,"art"),(7,"audio"),
        (8,"technical"),(9,"data"),(10,"codex"),(11,"research"),(12,"production")]]
    for d in expected_dirs:
        if not (ROOT/d).is_dir():
            error(f"Missing directory: {d}")

    skill_files = sorted((ROOT/"04_characters").glob("*/skills.md"))
    required_sections = [
        "## 1. Canon identity anchors", "## 2. Portrayal contract",
        "## 3. Voice model", "## 4. Relationship anchors",
        "## 5. Canon / fanon / original control", "## 6. Romance and trust progression",
        "## 7. Gameplay expression", "## 8. Agent runtime contract",
        "## 9. Original sample lines", "## 10. Source notes"]
    if len(skill_files) < 70:
        error(f"Expected at least 70 character skills files, found {len(skill_files)}")
    slugs = set()
    for path in skill_files:
        text = path.read_text(encoding="utf-8")
        slugs.add(path.parent.name)
        for section in required_sections:
            if section not in text:
                error(f"{path.relative_to(ROOT)} missing section: {section}")
        if "generate explicit sexual content" not in text and "explicit sexual content" not in text:
            warning(f"{path.relative_to(ROOT)} has no explicit-content guardrail phrase")

    roster = load_json(ROOT/"04_characters/roster.json")
    if roster:
        roster_slugs = {c["id"] for c in roster.get("characters", [])}
        if roster_slugs != slugs:
            error(f"Roster/skills slug mismatch: only roster={sorted(roster_slugs-slugs)}, only skills={sorted(slugs-roster_slugs)}")

    data_chars = load_json(ROOT/"09_data/characters.json")
    if data_chars and len(data_chars.get("characters", [])) != len(skill_files):
        error("09_data/characters.json count does not match skills files")

    for path in ROOT.rglob("*.json"):
        load_json(path)

    loc = load_json(ROOT/"09_data/locations.json")
    evt = load_json(ROOT/"09_data/events.json")
    if loc and len(loc.get("locations", [])) != 19:
        warning(f"Expected 19 location records, found {len(loc.get('locations', []))}")
    if evt and len(evt.get("events", [])) < 28:
        warning(f"Expected at least 28 event records, found {len(evt.get('events', []))}")

    csv_path = ROOT/"07_audio/music_cue_sheet.csv"
    try:
        with csv_path.open(encoding="utf-8-sig", newline="") as f:
            rows = list(csv.DictReader(f))
        if len(rows) < 80:
            warning(f"Music cue sheet has only {len(rows)} rows")
        cue_ids = [r["cue_id"] for r in rows]
        if len(cue_ids) != len(set(cue_ids)):
            error("Duplicate music cue IDs")
    except Exception as exc:
        error(f"Music cue CSV failed: {exc}")

    local_path = ROOT/"09_data/localization/strings.csv"
    try:
        with local_path.open(encoding="utf-8-sig", newline="") as f:
            rows = list(csv.DictReader(f))
        for row in rows:
            if not row.get("key") or not row.get("en") or not row.get("ja"):
                error(f"Incomplete localization row: {row}")
    except Exception as exc:
        error(f"Localization CSV failed: {exc}")

    mockups = list((ROOT/"06_art/mockups").glob("*.png"))
    if len(mockups) < 7:
        warning(f"Expected at least 7 PNG mockups, found {len(mockups)}")

    print(f"Files: {len(files)}")
    print(f"Character skills: {len(skill_files)}")
    print(f"Errors: {len(ERRORS)}")
    for msg in ERRORS:
        print(f"ERROR: {msg}")
    print(f"Warnings: {len(WARNINGS)}")
    for msg in WARNINGS:
        print(f"WARN: {msg}")
    return 1 if ERRORS else 0


if __name__ == "__main__":
    raise SystemExit(main())
