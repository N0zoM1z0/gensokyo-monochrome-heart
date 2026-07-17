#!/usr/bin/env python3
"""Audit M17 review readiness without pretending automation is an editor.

The taskbook requires human EN/JA and character/canon sign-off. This tool checks
the evidence that reviewers need: every shipped graph has origin and comfort
metadata, every spoken beat is bilingual and attributable, every visible
character resolves to a skills profile, and a graph's fanon value stays within
the most conservative visible-character ceiling. It intentionally reports, but
does not auto-approve, narrative/relationship pairs that need editorial review.
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import sys
from collections import Counter
from dataclasses import dataclass
from itertools import combinations
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
CONTENT = ROOT / "content"
EVENTS = CONTENT / "events"
DIALOGUE = CONTENT / "dialogue"
LOCALIZATION = CONTENT / "localization"
CHARACTERS = CONTENT / "characters" / "characters.json"
SKILLS_ROOT = ROOT / "design" / "04_characters"
RELATIONSHIPS = SKILLS_ROOT / "relationship_graph.json"
ORIGINS = {"Canon", "Fanon", "Original", "UI"}
ORIGIN_KEYS = {"canon", "fanon", "original"}
FANON_CEILING = re.compile(r"\*\*Maximum fanon dial:\*\*\s*([0-5])/5")
SENSITIVE_TERMS = (
    "consent", "romance", "medical", "patient", "alcohol", "intox",
    "injur", "fear", "photo", "privacy", "authority", "violence",
)


@dataclass(frozen=True)
class LocalizedRow:
    key: str
    context: str
    speaker: str
    english: str
    japanese: str
    maximum_width: int
    origin: str
    path: Path
    line: int


@dataclass(frozen=True)
class CharacterReviewProfile:
    character_id: str
    skill_path: Path
    fanon_ceiling: int


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--require-human-review",
        action="store_true",
        help="fail unless an explicit human-review manifest is present and complete",
    )
    parser.add_argument(
        "--review-manifest",
        type=Path,
        default=ROOT / "content" / "reviews" / "m17_human_reviews.json",
        help="optional human sign-off manifest; not created or auto-filled by this tool",
    )
    parser.add_argument(
        "--report",
        choices=("summary", "markdown"),
        default="summary",
        help="print compact evidence or the reviewer-facing markdown inventory",
    )
    options = parser.parse_args()

    errors: list[str] = []
    localizations = load_localizations(errors)
    profiles = load_character_profiles(errors)
    dialogues = load_dialogue_beats(errors)
    relation_pairs = load_relationship_pairs(errors)
    graphs = load_event_graphs(errors)

    event_reports: list[dict[str, Any]] = []
    for path, graph in graphs:
        report = audit_graph(path, graph, localizations, profiles, dialogues, relation_pairs, errors)
        event_reports.append(report)

    human_status = audit_human_manifest(
        options.review_manifest,
        {report["id"] for report in event_reports},
        options.require_human_review,
        errors,
    )
    if options.report == "markdown":
        print_markdown_report(event_reports, profiles, human_status)
    else:
        print_summary(event_reports, localizations, profiles, human_status)

    if errors:
        print("M17 review readiness: FAIL", file=sys.stderr)
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("M17 review readiness: PASS")
    return 0


def load_json(path: Path, errors: list[str]) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        errors.append(f"{relative(path)}: cannot read JSON ({error})")
        return None


def load_localizations(errors: list[str]) -> dict[str, LocalizedRow]:
    rows_by_key: dict[str, LocalizedRow] = {}
    for path in sorted(LOCALIZATION.glob("*.csv")):
        # These paired starter-language columns are retained as source material;
        # their synchronized `strings.csv` rows are the reviewable runtime form.
        if path.name in {"en.csv", "ja.csv"}:
            continue
        with path.open(encoding="utf-8-sig", newline="") as source:
            rows = list(csv.DictReader(source))
        # DictReader's fieldnames preserve the exact source header for this audit.
        with path.open(encoding="utf-8-sig", newline="") as source:
            reader = csv.reader(source)
            actual_header = next(reader, [])
        expected_header = ["key", "_context", "_speaker", "en", "ja", "_max_width_px", "_origin"]
        if actual_header != expected_header:
            errors.append(f"{relative(path)}: M17 expects the canonical bilingual review header")
            continue
        for index, raw in enumerate(rows, start=2):
            key = (raw.get("key") or "").strip()
            if not key:
                errors.append(f"{relative(path)}:{index}: localization key is empty")
                continue
            if key in rows_by_key:
                errors.append(
                    f"{relative(path)}:{index}: duplicate localization key {key} "
                    f"(already in {relative(rows_by_key[key].path)})"
                )
                continue
            origin = (raw.get("_origin") or "").strip()
            try:
                width = int((raw.get("_max_width_px") or "").strip())
            except ValueError:
                width = 0
            row = LocalizedRow(
                key=key,
                context=(raw.get("_context") or "").strip(),
                speaker=(raw.get("_speaker") or "").strip(),
                english=(raw.get("en") or "").strip(),
                japanese=(raw.get("ja") or "").strip(),
                maximum_width=width,
                origin=origin,
                path=path,
                line=index,
            )
            if not row.english or not row.japanese:
                errors.append(f"{relative(path)}:{index}: {key} is not bilingual")
            if row.maximum_width <= 0:
                errors.append(f"{relative(path)}:{index}: {key} has no positive review width")
            if row.origin not in ORIGINS:
                errors.append(f"{relative(path)}:{index}: {key} has unsupported origin {origin!r}")
            rows_by_key[key] = row
    if not rows_by_key:
        errors.append("no bilingual localization rows found")
    return rows_by_key


def load_character_profiles(errors: list[str]) -> dict[str, CharacterReviewProfile]:
    raw = load_json(CHARACTERS, errors)
    profiles: dict[str, CharacterReviewProfile] = {}
    for character in raw.get("characters", []) if isinstance(raw, dict) else []:
        character_id = str(character.get("id", ""))
        skills_reference = str(character.get("skills_document", ""))
        if not character_id.startswith("char."):
            errors.append(f"{relative(CHARACTERS)}: invalid character id {character_id!r}")
            continue
        skill_path = ROOT / skills_reference.removeprefix("res://")
        if not skill_path.is_file():
            errors.append(f"{character_id}: missing skills document {skills_reference}")
            continue
        match = FANON_CEILING.search(skill_path.read_text(encoding="utf-8"))
        if match is None:
            errors.append(f"{relative(skill_path)}: missing Maximum fanon dial")
            continue
        profiles[character_id] = CharacterReviewProfile(character_id, skill_path, int(match.group(1)))
    if len(profiles) != 71:
        errors.append(f"expected 71 usable character review profiles, found {len(profiles)}")
    return profiles


def load_dialogue_beats(errors: list[str]) -> dict[str, dict[str, Any]]:
    beats: dict[str, dict[str, Any]] = {}
    for path in sorted(DIALOGUE.glob("*.json")):
        raw = load_json(path, errors)
        if not isinstance(raw, dict):
            continue
        for beat in raw.get("beats", []):
            if not isinstance(beat, dict):
                continue
            beat_id = str(beat.get("id", ""))
            if not beat_id:
                errors.append(f"{relative(path)}: dialogue beat without id")
            elif beat_id in beats:
                errors.append(f"{relative(path)}: duplicate dialogue beat {beat_id}")
            else:
                beat["_source_path"] = path
                beats[beat_id] = beat
    if not beats:
        errors.append("no dialogue beats found")
    return beats


def load_relationship_pairs(errors: list[str]) -> set[frozenset[str]]:
    raw = load_json(RELATIONSHIPS, errors)
    pairs: set[frozenset[str]] = set()
    for edge in raw.get("edges", []) if isinstance(raw, dict) else []:
        left = str(edge.get("from", ""))
        right = str(edge.get("to", ""))
        if left and right:
            pairs.add(frozenset((f"char.{left}", f"char.{right}")))
    return pairs


def load_event_graphs(errors: list[str]) -> list[tuple[Path, dict[str, Any]]]:
    graphs: list[tuple[Path, dict[str, Any]]] = []
    for path in sorted(EVENTS.glob("*.json")):
        raw = load_json(path, errors)
        if not isinstance(raw, dict):
            continue
        if isinstance(raw.get("nodes"), dict) and str(raw.get("id", "")).startswith("evt."):
            graphs.append((path, raw))
    if not graphs:
        errors.append("no authored event graphs found")
    return graphs


def audit_graph(
    path: Path,
    graph: dict[str, Any],
    localizations: dict[str, LocalizedRow],
    profiles: dict[str, CharacterReviewProfile],
    beats: dict[str, dict[str, Any]],
    relation_pairs: set[frozenset[str]],
    errors: list[str],
) -> dict[str, Any]:
    event_id = str(graph.get("id", ""))
    cast = [str(value) for value in graph.get("cast", []) if str(value)]
    if not cast:
        errors.append(f"{event_id}: review packet has no visible cast")
    missing_profiles = [character_id for character_id in cast if character_id not in profiles]
    for character_id in missing_profiles:
        errors.append(f"{event_id}: visible character has no review profile: {character_id}")

    origin_tags = graph.get("origin_tags")
    fanon = -1
    if not isinstance(origin_tags, dict) or set(origin_tags) != ORIGIN_KEYS:
        errors.append(f"{event_id}: origin_tags must contain exactly canon, fanon, original")
    else:
        values: dict[str, int] = {}
        for key in sorted(ORIGIN_KEYS):
            value = origin_tags.get(key)
            if not isinstance(value, int) or value < 0:
                errors.append(f"{event_id}: origin_tags.{key} must be a non-negative integer")
                continue
            values[key] = value
        if values and sum(values.values()) <= 0:
            errors.append(f"{event_id}: origin_tags cannot all be zero")
        fanon = values.get("fanon", -1)
        ceilings = [profiles[character_id].fanon_ceiling for character_id in cast if character_id in profiles]
        if fanon >= 0 and ceilings and fanon > min(ceilings):
            errors.append(
                f"{event_id}: fanon {fanon}/5 exceeds visible-character ceiling {min(ceilings)}/5"
            )

    comfort_tags = graph.get("comfort_tags")
    if not isinstance(comfort_tags, list) or not all(isinstance(tag, str) and tag for tag in comfort_tags):
        errors.append(f"{event_id}: comfort_tags must be a non-empty string list")
    elif not comfort_tags:
        errors.append(f"{event_id}: comfort_tags cannot be empty")

    title_key = str(graph.get("title_key", ""))
    require_localization(event_id, title_key, localizations, errors, "event title")

    spoken = 0
    sensitive_tokens: set[str] = set()
    for node in graph.get("nodes", {}).values():
        if not isinstance(node, dict):
            continue
        node_type = str(node.get("type", ""))
        text_keys: list[str] = []
        if node_type == "line":
            spoken += 1
            beat_id = str(node.get("beat_id", ""))
            beat = beats.get(beat_id)
            if beat is None:
                errors.append(f"{event_id}: line references unknown dialogue beat {beat_id}")
            else:
                speaker = str(beat.get("speaker_id", ""))
                if speaker not in cast:
                    errors.append(f"{event_id}: beat {beat_id} speaker {speaker} is absent from graph cast")
                if not str(beat.get("nonverbal_key", "")).strip():
                    errors.append(f"{event_id}: beat {beat_id} lacks a nonverbal cue")
                text_keys.append(str(beat.get("text_key", "")))
        elif node_type == "choice":
            for option in node.get("options", []):
                if isinstance(option, dict):
                    text_keys.append(str(option.get("text_key", "")))
                    sensitive_tokens.update(tokens_for(str(option.get("text_key", ""))))
        elif node_type == "exploration_objective":
            text_keys.append(str(node.get("objective_key", "")))
        for key in text_keys:
            require_localization(event_id, key, localizations, errors, node_type)
            sensitive_tokens.update(tokens_for(key))

    if spoken == 0:
        errors.append(f"{event_id}: review packet has no spoken dialogue beats")
    for tag in comfort_tags if isinstance(comfort_tags, list) else []:
        sensitive_tokens.update(tokens_for(str(tag)))
    relationship_pairs = []
    for left, right in combinations(sorted(set(cast)), 2):
        if frozenset((left, right)) not in relation_pairs:
            relationship_pairs.append(f"{left} ↔ {right}")
    return {
        "id": event_id,
        "path": relative(path),
        "cast": cast,
        "fanon": fanon,
        "spoken": spoken,
        "comfort": [str(tag) for tag in comfort_tags] if isinstance(comfort_tags, list) else [],
        "sensitive": sorted(sensitive_tokens),
        "unlisted_relationship_pairs": relationship_pairs,
    }


def require_localization(
    event_id: str,
    key: str,
    localizations: dict[str, LocalizedRow],
    errors: list[str],
    source: str,
) -> None:
    if not key:
        errors.append(f"{event_id}: {source} has an empty localization key")
        return
    if key not in localizations:
        errors.append(f"{event_id}: {source} localization key is missing: {key}")


def tokens_for(value: str) -> set[str]:
    lowered = value.lower()
    return {term for term in SENSITIVE_TERMS if term in lowered}


def audit_human_manifest(
    path: Path,
    expected_events: set[str],
    required: bool,
    errors: list[str],
) -> str:
    if not path.is_file():
        if required:
            errors.append(f"missing required human-review manifest: {relative(path)}")
        return "not present"
    raw = load_json(path, errors)
    if not isinstance(raw, dict) or not isinstance(raw.get("events"), list):
        errors.append(f"{relative(path)}: expected an object with an events list")
        return "invalid"
    approved: set[str] = set()
    for entry in raw["events"]:
        if not isinstance(entry, dict):
            errors.append(f"{relative(path)}: invalid review entry")
            continue
        event_id = str(entry.get("event_id", ""))
        reviewers = entry.get("reviewers")
        statuses = entry.get("passes")
        if event_id in approved:
            errors.append(f"{relative(path)}: duplicate human review entry {event_id}")
        if not isinstance(reviewers, dict) or not all(str(reviewers.get(role, "")).strip() for role in ("character", "en", "ja")):
            errors.append(f"{relative(path)}: {event_id} lacks named character/EN/JA reviewers")
        if not isinstance(statuses, dict) or any(statuses.get(name) != "approved" for name in (
            "canon", "relationship", "fanon", "autonomy", "boundaries", "humor",
            "en_voice", "ja_register", "width_kinsoku", "comfort", "terminology",
        )):
            errors.append(f"{relative(path)}: {event_id} lacks all eleven approved M17 passes")
        approved.add(event_id)
    missing = expected_events - approved
    unknown = approved - expected_events
    if missing:
        errors.append(f"{relative(path)}: missing human review for {len(missing)} event graphs")
    if unknown:
        errors.append(f"{relative(path)}: contains {len(unknown)} unknown event reviews")
    return "complete" if not missing and not unknown else "incomplete"


def print_summary(
    reports: list[dict[str, Any]],
    localizations: dict[str, LocalizedRow],
    profiles: dict[str, CharacterReviewProfile],
    human_status: str,
) -> None:
    sensitive = Counter(token for report in reports for token in report["sensitive"])
    unlisted = sum(len(report["unlisted_relationship_pairs"]) for report in reports)
    print(
        "M17 automated evidence: "
        f"graphs={len(reports)} localized_rows={len(localizations)} "
        f"character_profiles={len(profiles)} unlisted_cast_pairs={unlisted} "
        f"sensitive_markers={dict(sorted(sensitive.items()))} human_review={human_status}"
    )


def print_markdown_report(
    reports: list[dict[str, Any]],
    profiles: dict[str, CharacterReviewProfile],
    human_status: str,
) -> None:
    print("# M17 Content Review Readiness Packet")
    print()
    print("This is an evidence inventory, not human editorial approval.")
    print(f"Human review manifest: **{human_status}**")
    print()
    print("## Character profiles")
    print()
    print(f"- Skills documents resolved: {len(profiles)}")
    print("- Fanon ceilings are applied per visible cast using the most conservative value.")
    print()
    print("## Event inventory")
    print()
    print("| Event | Cast | Fanon | Spoken beats | Sensitive review markers | Unlisted relationship pairs |")
    print("| --- | --- | ---: | ---: | --- | --- |")
    for report in reports:
        cast = ", ".join(item.removeprefix("char.") for item in report["cast"])
        markers = ", ".join(report["sensitive"]) or "—"
        pairs = "; ".join(report["unlisted_relationship_pairs"]) or "—"
        print(
            f"| `{report['id']}` | {cast} | {report['fanon']} | {report['spoken']} | "
            f"{markers} | {pairs} |"
        )
    print()
    print("Each row still requires the eleven M17 human passes: canon, relationship, fanon, autonomy, boundaries, humor, EN voice, JA register, width/kinsoku, comfort, and terminology.")


def relative(path: Path) -> str:
    try:
        return str(path.relative_to(ROOT))
    except ValueError:
        return str(path)


if __name__ == "__main__":
    raise SystemExit(main())
