#!/usr/bin/env python3
"""Synchronize reviewed generated-production manifests into the release ledger."""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LEDGER_PATH = ROOT / "assets" / "asset_ledger.json"


@dataclass(frozen=True)
class ManifestSource:
    path: str
    schema: str
    output_prefix: str
    reviewer: str
    evidence_path: str


SOURCES = (
    ManifestSource(
        "assets/art/production/production_manifest.json",
        "gmh-m16-visual-production-v1",
        "assets/art/production/",
        "codex-m16-visual-technical-review",
        "docs/reviews/m16_production_visual_review.md",
    ),
    ManifestSource(
        "assets/audio/production/production_manifest.json",
        "gmh-m16-audio-production-v1",
        "assets/audio/production/",
        "codex-m16-audio-technical-review",
        "docs/reviews/m16_production_audio_review.md",
    ),
)


def _stable_json(value: object) -> str:
    return json.dumps(value, ensure_ascii=False, indent=2) + "\n"


def _relative(path: str) -> str:
    return path.removeprefix("res://")


def _asset_id(value: str) -> str:
    normalized = value.removeprefix("asset.")
    return f"asset.{normalized}"


def _record(raw: dict, source: ManifestSource) -> dict:
    required = (
        "id",
        "path",
        "kind",
        "creator",
        "rights_basis",
        "source_paths",
        "sha256",
        "approval_status",
        "approval_basis",
    )
    missing = [field for field in required if field not in raw]
    if missing:
        raise ValueError(f"{source.path} asset lacks fields: {', '.join(missing)}")
    path = _relative(str(raw["path"]))
    if not path.startswith(source.output_prefix):
        raise ValueError(f"{source.path} asset escapes its output root: {path}")
    if raw["rights_basis"] != "project_original":
        raise ValueError(f"generated production asset has unsupported rights: {path}")
    if raw["approval_status"] != "candidate_for_review":
        raise ValueError(f"generated manifest bypassed external review: {path}")
    return {
        "id": _asset_id(str(raw["id"])),
        "path": path,
        "kind": str(raw["kind"]),
        "creator": str(raw["creator"]),
        "rights_basis": "project_original",
        "license_id": "project-original-fanwork",
        "license_path": "",
        "source_paths": [_relative(str(item)) for item in raw["source_paths"]],
        "sha256": str(raw["sha256"]),
        "approval_status": "approved_for_release",
        "approval_basis": str(raw["approval_basis"]),
        "approved_by": source.reviewer,
        "approved_at": "2026-07-17",
        "approval_evidence_path": source.evidence_path,
        "accessibility_pair": "",
    }


def expected_ledger() -> dict:
    ledger = json.loads(LEDGER_PATH.read_text(encoding="utf-8"))
    prefixes = tuple(source.output_prefix for source in SOURCES)
    records = [
        record
        for record in ledger.get("records", [])
        if not str(record.get("path", "")).startswith(prefixes)
    ]
    for source in SOURCES:
        manifest_path = ROOT / source.path
        if not manifest_path.is_file():
            raise ValueError(f"production manifest is missing: {source.path}")
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        if manifest.get("schema") != source.schema:
            raise ValueError(f"production manifest schema mismatch: {source.path}")
        assets = manifest.get("assets", [])
        if not isinstance(assets, list) or not assets:
            raise ValueError(f"production manifest has no assets: {source.path}")
        records.extend(_record(raw, source) for raw in assets)
    ledger["records"] = sorted(records, key=lambda item: (item["kind"], item["path"]))
    return ledger


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--write", action="store_true")
    mode.add_argument("--check", action="store_true")
    args = parser.parse_args()
    try:
        expected = _stable_json(expected_ledger())
    except (OSError, ValueError, KeyError, json.JSONDecodeError) as error:
        print(f"ERROR could not synchronize production assets: {error}", file=sys.stderr)
        return 1
    if args.write:
        LEDGER_PATH.write_text(expected, encoding="utf-8")
    elif LEDGER_PATH.read_text(encoding="utf-8") != expected:
        print("ERROR assets/asset_ledger.json is out of sync with production manifests", file=sys.stderr)
        return 1
    record_count = len(json.loads(expected)["records"])
    print(f"Production asset ledger synchronization passed: records={record_count}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
