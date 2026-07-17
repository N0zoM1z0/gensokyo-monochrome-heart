#!/usr/bin/env python3
"""Validate M16 runtime provenance and generate deterministic asset credits."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LEDGER_PATH = ROOT / "assets" / "asset_ledger.json"
CREDITS_PATH = ROOT / "CREDITS.generated.md"
ALLOWED_RIGHTS = {"project_original", "commissioned", "licensed"}
APPROVED = "approved_for_release"


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _load() -> dict:
    raw = json.loads(LEDGER_PATH.read_text(encoding="utf-8"))
    if not isinstance(raw, dict):
        raise ValueError("asset ledger root must be an object")
    return raw


def _discover(ledger: dict) -> set[str]:
    extensions = {f".{value.lower()}" for value in ledger["tracked_extensions"]}
    excluded = set(ledger["excluded_directories"])
    discovered: set[str] = set()
    for root_name in ledger["release_roots"]:
        root = ROOT / root_name
        for path in root.rglob("*"):
            relative = path.relative_to(ROOT)
            if not path.is_file() or path.suffix.lower() not in extensions:
                continue
            if any(part in excluded for part in relative.parts):
                continue
            discovered.add(relative.as_posix())
    return discovered


def validate(ledger: dict) -> list[str]:
    errors: list[str] = []
    if ledger.get("schema") != "gmh-runtime-asset-ledger-v1":
        errors.append("unsupported or missing asset ledger schema")
    required_lists = (
        "release_roots",
        "excluded_directories",
        "tracked_extensions",
        "records",
    )
    for key in required_lists:
        if not isinstance(ledger.get(key), list) or not ledger[key]:
            errors.append(f"{key} must be a non-empty array")
    if errors:
        return errors

    ids: set[str] = set()
    paths: set[str] = set()
    records_by_id: dict[str, dict] = {}
    required_fields = (
        "id",
        "path",
        "kind",
        "creator",
        "rights_basis",
        "license_id",
        "source_paths",
        "sha256",
        "approval_status",
        "approval_basis",
        "approved_by",
        "approved_at",
        "approval_evidence_path",
        "accessibility_pair",
    )
    for index, record in enumerate(ledger["records"]):
        label = f"records[{index}]"
        if not isinstance(record, dict):
            errors.append(f"{label} must be an object")
            continue
        for field in required_fields:
            if field not in record:
                errors.append(f"{label} lacks {field}")
        if any(field not in record for field in required_fields):
            continue
        asset_id = record["id"]
        relative_path = record["path"]
        if not isinstance(asset_id, str) or not asset_id.startswith("asset."):
            errors.append(f"{label} has invalid asset id: {asset_id!r}")
        elif asset_id in ids:
            errors.append(f"duplicate asset id: {asset_id}")
        else:
            ids.add(asset_id)
            records_by_id[asset_id] = record
        if not isinstance(relative_path, str) or relative_path.startswith(("/", "../")):
            errors.append(f"{label} has unsafe path: {relative_path!r}")
            continue
        if relative_path in paths:
            errors.append(f"duplicate asset path: {relative_path}")
        paths.add(relative_path)
        runtime_path = ROOT / relative_path
        if not runtime_path.is_file():
            errors.append(f"registered asset is missing: {relative_path}")
        elif record["sha256"] != _sha256(runtime_path):
            errors.append(f"asset hash mismatch: {relative_path}")
        if record["rights_basis"] not in ALLOWED_RIGHTS:
            errors.append(f"unsupported rights basis for {asset_id}: {record['rights_basis']}")
        if record["approval_status"] != APPROVED:
            errors.append(f"asset is not release-approved: {asset_id}")
        if not isinstance(record["approval_basis"], str) or not record["approval_basis"].strip():
            errors.append(f"asset approval lacks an evidence note: {asset_id}")
        if not isinstance(record["approved_by"], str) or not record["approved_by"].strip():
            errors.append(f"asset approval lacks a reviewer: {asset_id}")
        if not isinstance(record["approved_at"], str) or re.fullmatch(
            r"\d{4}-\d{2}-\d{2}", record["approved_at"]
        ) is None:
            errors.append(f"asset approval has an invalid date: {asset_id}")
        evidence_path = record["approval_evidence_path"]
        if not isinstance(evidence_path, str) or not (ROOT / evidence_path).is_file():
            errors.append(f"asset approval evidence is missing: {asset_id}")
        if not isinstance(record["source_paths"], list) or not record["source_paths"]:
            errors.append(f"asset lacks source provenance: {asset_id}")
        else:
            for source in record["source_paths"]:
                if not isinstance(source, str) or not (ROOT / source).is_file():
                    errors.append(f"asset source is missing for {asset_id}: {source}")
        if record["rights_basis"] == "licensed":
            license_path = record.get("license_path", "")
            if not license_path or not (ROOT / license_path).is_file():
                errors.append(f"licensed asset lacks its license file: {asset_id}")

    for record in ledger["records"]:
        if not isinstance(record, dict):
            continue
        pair_id = record.get("accessibility_pair", "")
        if pair_id and pair_id not in records_by_id:
            errors.append(f"accessibility pair is unknown for {record.get('id')}: {pair_id}")
        elif pair_id and records_by_id[pair_id].get("accessibility_pair") != record.get("id"):
            errors.append(f"accessibility pair is not reciprocal: {record.get('id')} / {pair_id}")

    discovered = _discover(ledger)
    for path in sorted(discovered - paths):
        errors.append(f"runtime art/audio/font is absent from the asset ledger: {path}")
    for path in sorted(paths - discovered):
        errors.append(f"ledger path is outside tracked release assets: {path}")
    return errors


def _credits(ledger: dict) -> str:
    records = sorted(ledger["records"], key=lambda item: (item["kind"], item["path"]))
    kinds = Counter(record["kind"] for record in records)
    lines = [
        "# Runtime Asset Credits",
        "",
        "Generated from `assets/asset_ledger.json`; do not edit this file by hand.",
        "",
        "This is an unofficial Touhou Project fan work. Touhou Project is created by Team Shanghai Alice.",
        "",
        f"Ledger policy: `{ledger['policy_revision']}`. Registered runtime assets: {len(records)}.",
        "",
        "## Inventory",
        "",
    ]
    for kind, count in sorted(kinds.items()):
        lines.append(f"- {kind}: {count}")
    lines.extend(("", "## Asset records", ""))
    for record in records:
        license_note = record["license_id"]
        if record.get("license_path"):
            license_note += f" (`{record['license_path']}`)"
        lines.extend(
            (
                f"### {record['id']}",
                "",
                f"- File: `{record['path']}`",
                f"- Creator: {record['creator']}",
                f"- Rights: {record['rights_basis']} / {license_note}",
                f"- Approval: {record['approval_status']} — {record['approval_basis']}",
                f"- Reviewed by: {record['approved_by']} on {record['approved_at']}",
                f"- Evidence: `{record['approval_evidence_path']}`",
                f"- SHA-256: `{record['sha256']}`",
                "",
            )
        )
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--check", action="store_true")
    mode.add_argument("--write-credits", action="store_true")
    args = parser.parse_args()
    try:
        ledger = _load()
        errors = validate(ledger)
    except (OSError, ValueError, KeyError, json.JSONDecodeError) as error:
        print(f"ERROR asset ledger could not be validated: {error}", file=sys.stderr)
        return 1
    for error in errors:
        print(f"ERROR {error}", file=sys.stderr)
    if errors:
        return 1
    expected = _credits(ledger)
    if args.write_credits:
        CREDITS_PATH.write_text(expected, encoding="utf-8")
    elif not CREDITS_PATH.is_file() or CREDITS_PATH.read_text(encoding="utf-8") != expected:
        print("ERROR CREDITS.generated.md is missing or out of date", file=sys.stderr)
        return 1
    print(
        f"Asset ledger passed: records={len(ledger['records'])} "
        f"tracked_files={len(_discover(ledger))} credits=current"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
