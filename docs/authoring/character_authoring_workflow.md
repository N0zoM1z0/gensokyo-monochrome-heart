# Character Skills and Agent Output Workflow

This M11 tool exposes the reviewed character-writing contracts and validates structured character-agent output before it can enter an event draft. It reads the synchronized runtime character index, so the browser and the game agree on character IDs and skills documents.

## Browse the complete roster

```bash
GODOT_BIN="$HOME/.local/bin/godot" scripts/character_authoring.sh --action=list
```

The deterministic table contains all 71 character IDs, bilingual names, route depth, document path, and readiness. `READY` means the file exists, its title matches the character index, and all ten required contract sections are present.

## Read one character contract

```bash
GODOT_BIN="$HOME/.local/bin/godot" scripts/character_authoring.sh \
  --action=show \
  --character-id=char.reimu_hakurei
```

Read the full contract before drafting output. In particular, respect the canon anchors, voice model, mischaracterization guardrails, romance boundaries, runtime inputs, and `Never do` rules. Sample lines establish cadence and must not become repeated catchphrases.

## Validate agent output

Create a JSON object matching `schemas/character_agent_output.schema.json`, then run:

```bash
GODOT_BIN="$HOME/.local/bin/godot" scripts/character_authoring.sh \
  --action=validate-output \
  --character-id=char.reimu_hakurei \
  --input=path/to/agent-output.json
```

Validation checks:

- the selected character exists in the reviewed catalog;
- JSON syntax and the complete agent-output schema;
- nonblank intent and nonverbal cue;
- spoken output supplies both English and Japanese, or intentionally leaves both empty;
- relationship deltas remain in the schema range of `-1..1`;
- at most one of Trust, Ease, Respect, Spark, and Strain changes in one beat.

A valid result reports the changed facet and memory tag. Validation proves structural and state-contract safety; it does not replace human canon, tone, romance-boundary, or localization review against the displayed skills document.

The checked-in [valid Reimu fixture](../../tests/fixtures/authoring/valid_reimu_agent_output.json) is a minimal reference shape, not reusable dialogue copy.
