#!/usr/bin/env python3
"""Reject SDM/Sakuya branching inside generic runtime boundaries."""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
GENERIC_ROOTS = [ROOT / "src/application", ROOT / "src/domain", ROOT / "src/infrastructure"]
IDENTIFIERS = re.compile(r"(?:char\.sakuya_izayoi|loc\.scarlet_devil_mansion|evt\.sdm\.)")
BEHAVIOR = re.compile(r"\b(?:if|elif|match)\b|==|!=")

errors: list[str] = []
for generic_root in GENERIC_ROOTS:
    for path in sorted(generic_root.rglob("*.gd")):
        for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if IDENTIFIERS.search(line) and BEHAVIOR.search(line):
                errors.append(f"{path.relative_to(ROOT)}:{line_number}: {line.strip()}")

print(f"M12 architecture scan: files={sum(1 for root in GENERIC_ROOTS for _ in root.rglob('*.gd'))} errors={len(errors)}")
for error in errors:
    print(f"ERROR generic character/region branch: {error}")
sys.exit(1 if errors else 0)
