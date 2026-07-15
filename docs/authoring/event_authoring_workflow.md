# Event Authoring Workflow

This M11 workflow lets a writer duplicate the reviewed **Empty Cushion** event, edit an isolated data bundle, validate it with the same schemas and graph rules as the game, and preview every branch in English or Japanese. No GDScript changes are required.

The workflow creates a draft only. It does not publish content into the runtime indexes, so experiments cannot change the playable build accidentally.

## 1. Duplicate the reviewed template

Run from the repository root:

```bash
GODOT_BIN="$HOME/.local/bin/godot" scripts/author_event.sh \
  --action=duplicate \
  --event-id=evt.hkr.my_event \
  --output=authoring/drafts/my_event
```

Choose a stable lowercase ID beginning with `evt.` and containing at least two namespace components after it. The command refuses to overwrite an existing directory.

The new directory contains:

- `manifest.json` — bundle identity, source template, and required file list.
- `event.json` — event nodes, objects, choices, mode result branches, effects, rewards, and outcome.
- `dialogue.json` — only the dialogue beats referenced by this event.
- `strings.csv` — only the English and Japanese strings used by this event.

Event-private identifiers are remapped to the new namespace. Shared character, location, spot, music, minigame, item, and prop identifiers remain references to the project-wide content catalog.

## 2. Edit data, not scripts

Use a text or spreadsheet editor. The most common changes are:

- Text: edit the `en` and `ja` columns in `strings.csv`. Keep both locales non-empty and preserve the `key` column.
- Objects: edit `interactable_ids` on an `exploration_objective` node in `event.json`.
- Results: edit `result_branches` on a minigame, danmaku, or duel node. Every target must name an existing node.
- Ending: edit the `outcome` on an `end_event` node.
- Dialogue: edit speaker, portrait, nonverbal cue, or memory tag in `dialogue.json`; edit spoken text in `strings.csv`.

Keep stable IDs lowercase and namespaced. Do not reuse an ID for a different meaning after content has shipped.

## 3. Validate before previewing

```bash
GODOT_BIN="$HOME/.local/bin/godot" scripts/author_event.sh \
  --action=validate \
  --bundle=authoring/drafts/my_event
```

A valid result ends with `errors=0`. Validation checks:

- the bundle manifest and required files;
- event and dialogue JSON Schemas;
- supported node shapes, complete four-tone choices, graph reachability, missing targets, and unbounded cycles;
- event-to-dialogue and dialogue-to-localization references;
- duplicate IDs and localization keys;
- non-empty English/Japanese text and positive width budgets.

Failures name the file, node, beat, or string that needs attention. Preview commands also validate first and refuse to emit a misleading preview from invalid data.

## 4. Preview both locales

```bash
GODOT_BIN="$HOME/.local/bin/godot" scripts/author_event.sh \
  --action=preview \
  --bundle=authoring/drafts/my_event \
  --locale=en \
  --output=authoring/drafts/my_event/preview-en.md

GODOT_BIN="$HOME/.local/bin/godot" scripts/author_event.sh \
  --action=preview \
  --bundle=authoring/drafts/my_event \
  --locale=ja \
  --output=authoring/drafts/my_event/preview-ja.md
```

The deterministic Markdown preview follows every reachable branch once and shows dialogue, choice text, objects, effects, mode results, rewards, journals, and final outcomes. Use `--output=-` to print the preview in the terminal.

## 5. Inspect dependencies

```bash
GODOT_BIN="$HOME/.local/bin/godot" scripts/author_event.sh \
  --action=dependencies \
  --bundle=authoring/drafts/my_event \
  --output=authoring/drafts/my_event/dependencies.md
```

The dependency report lists deterministic, typed edges from the event to its nodes and shared content, from nodes to graph targets and gameplay content, and from dialogue beats and choices to localized text. Search the target column before renaming or removing a stable ID.

## 6. Check localization widths

Generate all four required locale/scale reports:

```bash
for locale in en ja; do
  for scale in 100 150; do
    GODOT_BIN="$HOME/.local/bin/godot" scripts/author_event.sh \
      --action=width-report \
      --bundle=authoring/drafts/my_event \
      --locale="$locale" \
      --ui-scale="$scale" \
      --output="authoring/drafts/my_event/width-${locale}-${scale}.md"
  done
done
```

The report uses the approved project fonts and the same English word wrapping and Japanese kinsoku rules as the game. `Raw px` is the unwrapped measurement, `Budget px` is the authored width budget at the requested scale, `Lines` and `Max line px` describe the actual wrapped result, and `OVERFLOW` identifies a line that cannot fit even after wrapping. `WRAP` is expected for dialogue and other multiline copy.

## Current boundary

The current M11 increments prove the duplicate/edit/validate/bilingual-preview acceptance path and provide draft dependency and localization width diagnostics. Publishing drafts into reviewed runtime content remains a deliberate review step. The wider M11 workbench—mode fixture launchers, Bullet Pattern Lab, fighter frame viewer, migration harness, and screenshot matrix UI—remains separate work so draft authoring does not bypass its future checks.
