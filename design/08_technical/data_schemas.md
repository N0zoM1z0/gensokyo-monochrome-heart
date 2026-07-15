# Data Schemas and Content Contracts

Machine-readable JSON Schemas and examples are in `09_data/`.

## 1. Stable identifiers

Format:
```text
<domain>.<region_or_group>.<name>
```

Examples:
- `char.reimu_hakurei`
- `loc.hakurei_shrine.veranda`
- `evt.hkr.empty_cushion`
- `dlg.hkr.empty_cushion.reimu.003`
- `item.keepsake.unpaired_cup`
- `mus.reimu.private`

IDs are never localized and never reused after public release. Deprecated IDs map through migration tables.

## 2. Character data

```json
{
  "id": "char.reimu_hakurei",
  "display_name_key": "char.reimu.name",
  "faction_ids": ["faction.hakurei"],
  "skills_document": "reimu_hakurei/skills.md",
  "route_depth": "deep",
  "companion_skill_id": "skill.intuitive_float",
  "danmaku_loadout_id": "dload.reimu.story",
  "fighter_loadout_id": "fload.reimu.base",
  "portrait_set_id": "portrait.reimu.base",
  "tags": ["human", "shrine_maiden", "launch"]
}
```

Behavioral prose remains in `skills.md`; runtime data stores references and validated gameplay values.

## 3. Event graph

An event is a directed graph of typed nodes.

Core node types:
- `line`;
- `choice`;
- `condition`;
- `set_flag`;
- `adjust_relationship`;
- `exploration_objective`;
- `start_minigame`;
- `start_danmaku`;
- `start_duel`;
- `give_item`;
- `journal_entry`;
- `music_state`;
- `wait`;
- `end_event`.

Every graph must have:
- one entry node;
- at least one end node;
- no unreachable nodes;
- no unbounded cycle unless explicitly marked repeatable;
- deterministic condition priority;
- localized keys for all player-visible text.

## 4. Dialogue beat

```json
{
  "id": "beat.hkr.empty_cushion.003",
  "speaker_id": "char.reimu_hakurei",
  "text_key": "dlg.hkr.empty_cushion.reimu.003",
  "portrait": "private_neutral",
  "nonverbal_key": "cue.reimu.slide_cup",
  "voice_policy": "none",
  "advance_policy": "input",
  "memory_tag": "shrine.second_cup"
}
```

## 5. Choice

A choice stores intent, not relationship math in UI text.

```json
{
  "id": "choice.hkr.empty_cushion.01",
  "options": [
    {
      "tone": "patient",
      "text_key": "choice.hkr.empty_cushion.patient",
      "next": "node.after_patient",
      "effects": [
        {"op":"relationship", "character_id":"char.reimu_hakurei", "facet":"ease", "delta":1}
      ]
    }
  ]
}
```

## 6. Relationship conditions

Never compare raw values in content files. Use semantic predicates:

```json
{"predicate":"relationship_band", "character_id":"char.reimu_hakurei", "facet":"trust", "at_least":"open"}
```

Band thresholds are centralized and migratable.

## 7. Spot data

A spot declares:
- region and scene;
- time/weather availability;
- active character pool;
- event priorities;
- traversal tags;
- ambience/music state;
- companion skill interactions;
- screenshot anchor;
- estimated duration and comfort tags.

## 8. Combat pattern data

Pattern data specifies emitters, curves, phases, telegraphs, density tiers, and deterministic seed use. Arbitrary GDScript in content data is prohibited. Complex patterns reference audited script components by ID.

## 9. Minigame definition

```json
{
  "id":"mini.shrine.leaf_graze",
  "scene":"res://src/presentation/minigames/leaf_graze/LeafGraze.tscn",
  "duration_seconds":45,
  "controls":["move","focus"],
  "assists":["speed_scale","hazard_density","wide_collect"],
  "result_bands":{"clear":600,"excellent":900}
}
```

## 10. Validation pipeline

1. JSON Schema validation.
2. Stable-ID uniqueness.
3. Reference resolution.
4. localization-key existence.
5. graph reachability/cycle analysis.
6. asset-path import existence.
7. comfort-tag review.
8. deterministic fixture execution.
9. screenshot generation.
