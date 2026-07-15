# Save System

## 1. Requirements

- three manual slots;
- rolling autosaves at day start, before mode transitions, and event completion;
- event checkpoint for scenes longer than ten minutes;
- settings stored separately from story saves;
- atomic writes and backup recovery;
- explicit schema version and migration chain;
- deterministic combat seed preservation;
- locale-independent data;
- no Node paths or resource instances serialized.

## 2. File layout

```text
user://profiles/<profile_id>/
  profile.json
  manual_01.save
  manual_02.save
  manual_03.save
  auto_day.save
  auto_event.save
  auto_mode.save
  backup/
  screenshots/
user://settings.json
```

## 3. Envelope

```json
{
  "format":"gmh_save",
  "schema_version":4,
  "game_version":"0.3.0",
  "profile_id":"p01",
  "created_utc":"...",
  "saved_utc":"...",
  "checksum":"sha256:...",
  "payload":{ }
}
```

Compressing is optional. Obfuscation is not security and should not replace validation.

## 4. Atomic write

1. Serialize payload to memory.
2. Validate against runtime invariants.
3. Write `slot.tmp`.
4. Flush and close.
5. Read back and verify checksum.
6. Move previous file to backup.
7. Rename temp to final.
8. Prune backups by policy.

If any step fails, preserve the old save and report a recoverable error.

## 5. Migration

Migrations are pure functions:

```gdscript
func migrate_v3_to_v4(data: Dictionary) -> Dictionary:
    # Rename old route affinity to five facets and preserve intent.
    return data
```

Rules:
- never mutate the source file;
- write a migrated copy only after validation;
- keep fixtures from every public schema version;
- unknown future version opens read-only diagnostic, not destructive downgrade;
- deprecated IDs map through a checked migration table.

## 6. Save boundaries

Safe:
- day desk;
- exploration idle;
- dialogue node boundary;
- pre-mode and post-mode;
- fighter round boundary;
- danmaku phase boundary.

Unsafe:
- halfway through applying node effects;
- inside collision callbacks;
- while an asynchronous content load is incomplete;
- during locale resource rebuild.

## 7. Metadata card

Separate lightweight metadata is generated for slot display:
- chapter and day;
- location/time;
- visible active characters;
- play time;
- route-completion stamps;
- accessibility preset;
- screenshot path;
- save/game version.

## 8. Tests

- power-loss simulation at every atomic step;
- corrupted checksum;
- truncated JSON;
- missing optional field;
- all migrations in sequence and direct from each version;
- locale switch after load;
- content ID renamed through migration;
- replay seed reproduction;
- disk full / permission failure behavior.
