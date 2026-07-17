#!/usr/bin/env python3
"""Enforce exact M16 visual/audio deliverable coverage independently of generators."""

from __future__ import annotations

import hashlib
import json
import sys
import wave
from collections import Counter, defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
VISUAL_PATH = ROOT / "assets" / "art" / "production" / "production_manifest.json"
AUDIO_PATH = ROOT / "assets" / "audio" / "production" / "production_manifest.json"

CHARACTERS = {
    "aya_shameimaru",
    "marisa_kirisame",
    "reimu_hakurei",
    "remilia_scarlet",
    "sakuya_izayoi",
    "sanae_kochiya",
    "tenshi_hinanawi",
    "youmu_konpaku",
}
REGIONS = {
    "eientei_bamboo_forest",
    "hakugyokurou",
    "hakurei_shrine",
    "scarlet_devil_mansion",
    "youkai_mountain",
}
AUDIO_REGIONS = {
    "eientei_bamboo",
    "hakugyokurou",
    "hakurei_shrine",
    "scarlet_devil_mansion",
    "youkai_mountain",
}
FIGHTER_ACTIONS = {
    "idle", "crouch", "walk_forward", "walk_back", "jump", "air_dash",
    "ground_dash", "guard_high", "guard_low", "throw", "normal_1",
    "normal_2", "normal_3", "normal_4", "normal_5", "command_normal_1",
    "command_normal_2", "special_1", "special_2", "special_3", "special_4",
    "spell_1", "spell_2", "hit", "down", "win", "surrender",
    "focus_cancel", "spell_declaration",
}
PORTRAITS = {
    "work_neutral", "social_neutral", "amused", "irritated", "focused",
    "startled", "tired_private", "sincere_restrained", "route_vulnerable",
}
BULLETS = {
    "amulet", "needle", "orb", "star", "knife", "butterfly", "leaf",
    "arrow", "shard", "plate", "spirit", "keystone_chip",
}
SFX_IDS = {
    "sfx.ambience.region_bed",
    "sfx.bullet.group_loop",
    "sfx.bullet.transient",
    "sfx.combat.impact",
    "sfx.danmaku.graze",
    "sfx.player.damage",
    "sfx.save.begin",
    "sfx.save.end",
    "sfx.ui.cancel",
    "sfx.ui.confirm",
    "sfx.ui.focus",
    "sfx.warning.threat",
}
EXPECTED_DIMENSIONS = {
    "model_m_sheet": [384, 32],
    "model_l_sheet": [928, 48],
    "portrait_pack": [720, 104],
    "region_tileset": [128, 128],
    "bullet_library": [96, 32],
    "vfx_accessibility": [64, 128],
    "ui_export": [256, 128],
}


def _load(path: Path) -> dict:
    raw = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(raw, dict):
        raise ValueError(f"manifest root is not an object: {path.relative_to(ROOT)}")
    return raw


def _file_errors(record: dict) -> list[str]:
    errors: list[str] = []
    path = ROOT / str(record.get("path", "")).removeprefix("res://")
    if not path.is_file():
        return [f"production asset is missing: {path.relative_to(ROOT)}"]
    payload = path.read_bytes()
    if hashlib.sha256(payload).hexdigest() != record.get("sha256"):
        errors.append(f"production hash mismatch: {path.relative_to(ROOT)}")
    if len(payload) != record.get("bytes"):
        errors.append(f"production byte-size mismatch: {path.relative_to(ROOT)}")
    if record.get("rights_basis") != "project_original":
        errors.append(f"production asset is not clean-source original: {path.relative_to(ROOT)}")
    if record.get("approval_status") != "candidate_for_review":
        errors.append(f"generator tried to self-approve production asset: {path.relative_to(ROOT)}")
    return errors


def _visual_errors(manifest: dict) -> list[str]:
    errors: list[str] = []
    if manifest.get("schema") != "gmh-m16-visual-production-v1":
        errors.append("visual production manifest schema mismatch")
    exact_sets = (
        ("characters", CHARACTERS),
        ("regions", REGIONS),
        ("fighter_actions", FIGHTER_ACTIONS),
        ("portrait_expressions", PORTRAITS),
        ("bullet_shapes", BULLETS),
        ("vfx_modes", {"standard", "reduced_flash"}),
    )
    for key, expected in exact_sets:
        actual = set(manifest.get(key, []))
        if actual != expected:
            errors.append(f"visual {key} coverage mismatch: {sorted(actual ^ expected)}")
    assets = manifest.get("assets", [])
    if not isinstance(assets, list):
        return errors + ["visual assets must be an array"]
    subjects: dict[str, set[str]] = defaultdict(set)
    kinds = Counter()
    for record in assets:
        if not isinstance(record, dict):
            errors.append("visual asset record is not an object")
            continue
        errors.extend(_file_errors(record))
        kind = str(record.get("kind", ""))
        kinds[kind] += 1
        subjects[kind].add(str(record.get("subject_id", "")))
        if record.get("dimensions") != EXPECTED_DIMENSIONS.get(kind):
            errors.append(f"visual dimensions mismatch for {record.get('id')}")
    expected_counts = {
        "model_m_sheet": 8,
        "model_l_sheet": 8,
        "portrait_pack": 8,
        "region_tileset": 5,
        "bullet_library": 1,
        "vfx_accessibility": 2,
        "ui_export": 1,
    }
    if kinds != Counter(expected_counts):
        errors.append(f"visual deliverable counts mismatch: {dict(kinds)}")
    for kind in ("model_m_sheet", "model_l_sheet", "portrait_pack"):
        if subjects[kind] != CHARACTERS:
            errors.append(f"visual {kind} character coverage mismatch")
    if subjects["region_tileset"] != REGIONS:
        errors.append("visual region tileset coverage mismatch")
    return errors


def _audio_errors(manifest: dict) -> list[str]:
    errors: list[str] = []
    if manifest.get("schema") != "gmh-m16-audio-production-v1":
        errors.append("audio production manifest schema mismatch")
    assets = manifest.get("assets", [])
    if not isinstance(assets, list):
        return errors + ["audio assets must be an array"]
    music_roles: dict[str, set[str]] = defaultdict(set)
    sfx_ids: set[str] = set()
    for record in assets:
        if not isinstance(record, dict):
            errors.append("audio asset record is not an object")
            continue
        errors.extend(_file_errors(record))
        path = ROOT / str(record.get("path", "")).removeprefix("res://")
        if path.is_file():
            try:
                with wave.open(str(path), "rb") as stream:
                    if stream.getnchannels() != 1 or stream.getsampwidth() != 2:
                        errors.append(f"production audio is not mono 16-bit PCM: {path.relative_to(ROOT)}")
                    if stream.getframerate() != record.get("sample_rate"):
                        errors.append(f"production audio sample-rate mismatch: {path.relative_to(ROOT)}")
                    if stream.getnframes() != record.get("loop_end_sample", stream.getnframes()):
                        errors.append(f"production audio loop endpoint mismatch: {path.relative_to(ROOT)}")
            except (wave.Error, EOFError):
                errors.append(f"production audio is not a readable PCM WAV: {path.relative_to(ROOT)}")
        kind = record.get("kind")
        if kind == "music_stem":
            parts = str(record.get("id", "")).split(".")
            if len(parts) != 4:
                errors.append(f"music stem id is malformed: {record.get('id')}")
            else:
                music_roles[parts[2]].add(parts[3])
            if record.get("meter") != "4/4" or int(record.get("bpm", 0)) <= 0:
                errors.append(f"music stem timing contract is incomplete: {record.get('id')}")
        elif kind == "sfx":
            sfx_ids.add(str(record.get("id", "")))
            if int(record.get("voice_cap", 0)) <= 0 or int(record.get("priority", 0)) <= 0:
                errors.append(f"SFX voice policy is incomplete: {record.get('id')}")
        else:
            errors.append(f"unknown production audio kind: {kind}")
    if set(music_roles) != AUDIO_REGIONS:
        errors.append(f"adaptive music region coverage mismatch: {sorted(set(music_roles) ^ AUDIO_REGIONS)}")
    for region, roles in music_roles.items():
        if roles != {"place", "person", "incident"}:
            errors.append(f"adaptive music roles incomplete for {region}: {sorted(roles)}")
    if sfx_ids != SFX_IDS:
        errors.append(f"production SFX coverage mismatch: {sorted(sfx_ids ^ SFX_IDS)}")
    return errors


def main() -> int:
    try:
        visual = _load(VISUAL_PATH)
        audio = _load(AUDIO_PATH)
        errors = _visual_errors(visual) + _audio_errors(audio)
    except (OSError, ValueError, KeyError, json.JSONDecodeError) as error:
        print(f"ERROR M16 production validation could not run: {error}", file=sys.stderr)
        return 1
    for error in errors:
        print(f"ERROR {error}", file=sys.stderr)
    if errors:
        return 1
    print(
        "M16 production coverage passed: visual=33 audio=27 "
        "fighters=8 regions=5 bullets=12 stems=15 sfx=12"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
