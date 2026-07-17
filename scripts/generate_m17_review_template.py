#!/usr/bin/env python3
"""Generate, but never approve, the M17 human editorial review manifest."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
EVENTS = ROOT / "content" / "events"
DEFAULT_OUTPUT = ROOT / "content" / "reviews" / "m17_human_reviews.template.json"
PASS_NAMES = (
    "canon",
    "relationship",
    "fanon",
    "autonomy",
    "boundaries",
    "humor",
    "en_voice",
    "ja_register",
    "width_kinsoku",
    "comfort",
    "terminology",
)


def graph_ids() -> list[str]:
    result: list[str] = []
    for path in sorted(EVENTS.glob("*.json")):
        raw = json.loads(path.read_text(encoding="utf-8"))
        event_id = str(raw.get("id", ""))
        if event_id.startswith("evt.") and isinstance(raw.get("nodes"), dict):
            result.append(event_id)
    return sorted(result)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--check", action="store_true", help="fail if the checked-in pending template is stale")
    options = parser.parse_args()
    events = [
        {
            "event_id": event_id,
            "reviewers": {"character": "", "en": "", "ja": ""},
            "passes": {name: "pending" for name in PASS_NAMES},
            "notes": "",
        }
        for event_id in graph_ids()
    ]
    payload = {
        "schema": "gmh-m17-human-review-v1",
        "status": "template_only_not_approved",
        "instructions": (
            "Copy this file to content/reviews/m17_human_reviews.json only after "
            "named human reviewers have completed every pass for every event. "
            "Do not replace pending with approved without the corresponding review."
        ),
        "events": events,
    }
    encoded = json.dumps(payload, ensure_ascii=False, indent=2) + "\n"
    if options.check:
        if not options.output.is_file() or options.output.read_text(encoding="utf-8") != encoded:
            print(f"M17 review template is stale: {options.output}")
            return 1
        print(f"M17 review template is current: {options.output} ({len(events)} events)")
        return 0
    options.output.parent.mkdir(parents=True, exist_ok=True)
    options.output.write_text(encoded, encoding="utf-8")
    print(f"Generated pending M17 review template: {options.output} ({len(events)} events)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
