#!/usr/bin/env python3
"""Build or verify M15 runtime roster metadata from reviewed design sources."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CHARACTERS_PATH = ROOT / "design" / "09_data" / "characters.json"
ART_CATALOG_PATH = (
    ROOT / "design" / "06_art" / "characters" / "character_model_catalog.json"
)
SKILLS_ROOT = ROOT / "design" / "04_characters"

SUPPORT_BOSSES = {
    "byakuren_hijiri",
    "flandre_scarlet",
    "fujiwara_no_mokou",
    "hecatia_lapislazuli",
    "junko",
    "keiki_haniyasushin",
    "okina_matara",
    "reisen_udongein_inaba",
    "saki_kurokoma",
    "suika_ibuki",
    "toyostomimi_no_miko",
    "utsuho_reiuji",
    "watatsuki_no_toyohime",
    "watatsuki_no_yorihime",
    "yuugi_hoshiguma",
    "yuuka_kazami",
}


def _section(text: str, heading: str, next_heading_pattern: str) -> str:
    match = re.search(
        rf"^{re.escape(heading)}\s*$\n(.*?)(?=^{next_heading_pattern}\s*$)",
        text,
        flags=re.MULTILINE | re.DOTALL,
    )
    if match is None:
        raise ValueError(f"missing section {heading}")
    return match.group(1).strip()


def _skills_metadata(slug: str) -> dict[str, object]:
    path = SKILLS_ROOT / slug / "skills.md"
    text = path.read_text(encoding="utf-8")
    motives = _section(text, "### Active motives", r"### Scene function")
    motives = " ".join(line.strip() for line in motives.splitlines()).strip()

    gameplay = _section(text, "## 7. Gameplay expression", r"## 8\. Agent runtime contract")
    companion_match = re.search(
        r"^### Exploration companion skill\s*$\n\n`([^`]+)`:\s*(.+?)$",
        gameplay,
        flags=re.MULTILINE,
    )
    if companion_match is None:
        raise ValueError(f"{slug} is missing a parseable companion skill")
    hooks_match = re.search(
        r"^### Signature event seeds\s*$\n(.*?)(?=^### |\Z)",
        gameplay,
        flags=re.MULTILINE | re.DOTALL,
    )
    if hooks_match is None:
        raise ValueError(f"{slug} is missing signature event seeds")
    hooks = re.findall(r"^- (.+)$", hooks_match.group(1), flags=re.MULTILINE)
    if not 2 <= len(hooks) <= 4:
        raise ValueError(f"{slug} must expose 2-4 event hooks, found {len(hooks)}")
    return {
        "agency_anchor": motives,
        "event_hooks": hooks,
        "companion_skill": {
            "id": f"companion.{slug}",
            "display_name": companion_match.group(1).strip(),
            "description": companion_match.group(2).strip(),
        },
    }


def _presence_tier(production_tier: str, scope: str) -> str:
    if production_tier == "A":
        return "lead"
    if production_tier == "B":
        return "regional"
    if scope.lower().startswith("minor support"):
        return "crowd"
    return "cameo"


def _relationship_scope(route_depth: str, scope: str) -> str:
    if route_depth == "deep":
        return "deep_route"
    lowered = scope.lower()
    if "friendship only" in lowered or lowered.startswith("minor support"):
        return "friendship_only"
    non_route_terms = (
        "major support",
        "late-game",
        "antagonist",
        "antagonistic",
        "support rival",
        "final act",
        "postgame lead",
    )
    if any(term in lowered for term in non_route_terms):
        return "non_route"
    return "friendship_support"


def _expected_data() -> dict[str, object]:
    source = json.loads(CHARACTERS_PATH.read_text(encoding="utf-8"))
    art = json.loads(ART_CATALOG_PATH.read_text(encoding="utf-8"))
    art_by_slug = {record["id"]: record for record in art["characters"]}
    characters = source["characters"]
    if {record["slug"] for record in characters} != set(art_by_slug):
        raise ValueError("character data and visual production catalog do not match")

    for record in characters:
        slug = record["slug"]
        scope = record.get("route_scope_note", "").strip()
        presence_tier = _presence_tier(art_by_slug[slug]["production_tier"], scope)
        runtime = _skills_metadata(slug)
        runtime["presence_tier"] = presence_tier
        runtime["relationship_scope"] = _relationship_scope(
            record["route_depth"], scope
        )
        runtime["companion_skill"]["scope"] = (
            "regional" if presence_tier in {"lead", "regional"} else "event_only"
        )
        runtime["danmaku_role"] = (
            "launch_lead"
            if "danmaku lead" in scope.lower()
            else "support_boss"
            if slug in SUPPORT_BOSSES
            else "none"
        )
        record.update(runtime)
    return source


def _payload(data: dict[str, object]) -> str:
    return json.dumps(data, ensure_ascii=False, indent=2) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--write", action="store_true")
    mode.add_argument("--check", action="store_true")
    args = parser.parse_args()
    try:
        expected = _payload(_expected_data())
    except (OSError, ValueError, KeyError, json.JSONDecodeError) as exc:
        print(f"ERROR: M15 roster build failed: {exc}", file=sys.stderr)
        return 1
    current = CHARACTERS_PATH.read_text(encoding="utf-8")
    if args.check:
        if current != expected:
            print("ERROR: design/09_data/characters.json has stale M15 roster metadata", file=sys.stderr)
            return 1
        print("M15 roster metadata check passed for 71 characters")
        return 0
    CHARACTERS_PATH.write_text(expected, encoding="utf-8", newline="\n")
    print("Built M15 runtime roster metadata for 71 characters")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
