#!/usr/bin/env python3
"""Synchronize reviewed starter content from the pinned design package."""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "design" / "09_data"

JSON_MAPPINGS = {
    "characters.json": "content/characters/characters.json",
    "locations.json": "content/locations/locations.json",
    "events.json": "content/events/events.json",
    "sample_event_empty_cushion.json": "content/events/sample_event_empty_cushion.json",
    "dialogue_samples.json": "content/dialogue/dialogue_samples.json",
    "content_index.json": "content/indexes/design_content_index.json",
}

COPY_MAPPINGS = {
    "localization/strings.csv": "content/localization/strings.csv",
    "localization/en.csv": "content/localization/en.csv",
    "localization/ja.csv": "content/localization/ja.csv",
    "music_cues.csv": "content/music/music_cues.csv",
}


def _stable_json(data: object) -> bytes:
    return (json.dumps(data, ensure_ascii=False, indent=2) + "\n").encode("utf-8")


def _rewrite_design_paths(relative: str, data: object) -> object:
    if relative == "characters.json":
        for record in data["characters"]:
            slug = record["slug"]
            record["skills_document"] = f"res://design/04_characters/{slug}/skills.md"
    elif relative == "locations.json":
        for record in data["locations"]:
            bible_name = Path(record["bible_path"]).name
            record["bible_path"] = f"res://design/03_locations/{bible_name}"
    return data


def _sha256(payload: bytes) -> str:
    return hashlib.sha256(payload).hexdigest()


def _expected_outputs() -> dict[Path, bytes]:
    outputs: dict[Path, bytes] = {}
    manifest_entries: list[dict[str, object]] = []

    for source_relative, destination_relative in JSON_MAPPINGS.items():
        source = SOURCE / source_relative
        data = json.loads(source.read_text(encoding="utf-8-sig"))
        payload = _stable_json(_rewrite_design_paths(source_relative, data))
        destination = ROOT / destination_relative
        outputs[destination] = payload
        manifest_entries.append(
            {
                "source": f"design/09_data/{source_relative}",
                "destination": destination_relative,
                "sha256": _sha256(payload),
            }
        )

    for source_relative, destination_relative in COPY_MAPPINGS.items():
        payload = (SOURCE / source_relative).read_bytes()
        destination = ROOT / destination_relative
        outputs[destination] = payload
        manifest_entries.append(
            {
                "source": f"design/09_data/{source_relative}",
                "destination": destination_relative,
                "sha256": _sha256(payload),
            }
        )

    for schema in sorted((SOURCE / "schemas").glob("*.json")):
        payload = schema.read_bytes()
        destination_relative = f"schemas/{schema.name}"
        destination = ROOT / destination_relative
        outputs[destination] = payload
        manifest_entries.append(
            {
                "source": f"design/09_data/schemas/{schema.name}",
                "destination": destination_relative,
                "sha256": _sha256(payload),
            }
        )

    manifest = {
        "schema": "gmh-design-content-sync-v1",
        "source_revision": "2026.07.16.7",
        "files": sorted(manifest_entries, key=lambda item: str(item["destination"])),
    }
    outputs[ROOT / "content" / "indexes" / "sync_manifest.json"] = _stable_json(
        manifest
    )
    return outputs


def _write(outputs: dict[Path, bytes]) -> int:
    for path, payload in outputs.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(payload)
    print(f"Synchronized {len(outputs)} deterministic files from design/09_data")
    return 0


def _check(outputs: dict[Path, bytes]) -> int:
    errors: list[str] = []
    for path, expected in outputs.items():
        if not path.is_file():
            errors.append(f"missing: {path.relative_to(ROOT)}")
        elif path.read_bytes() != expected:
            errors.append(f"out of date: {path.relative_to(ROOT)}")
    if errors:
        for error in errors:
            print(f"ERROR {error}", file=sys.stderr)
        return 1
    print(f"Content synchronization check passed for {len(outputs)} files")
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
