# M11 Debug Workbench

The workbench gives designers and QA one stable-ID registry for playable mode fixtures, reviewed data definitions, the fighter hitbox viewer, save migration fixtures, and generated legal test tones. It reuses production loaders and presentation scenes instead of maintaining tool-only simulations.

## Discover targets

```bash
GODOT_BIN="$HOME/.local/bin/godot" scripts/authoring_workbench.sh --action=list
GODOT_BIN="$HOME/.local/bin/godot" scripts/authoring_workbench.sh --action=list --category=fighter
```

The catalog reports each target's kind, category, state, and authoritative resource. Current categories cover exploration, tea minigame, danmaku, fighter, vertical slice, migration, and music.

## Inspect or smoke a target

```bash
GODOT_BIN="$HOME/.local/bin/godot" scripts/authoring_workbench.sh \
  --action=inspect --target=save.v1_route_affinity

GODOT_BIN="$HOME/.local/bin/godot" scripts/authoring_workbench.sh \
  --action=smoke --target=scene.danmaku.phase1
```

Inspection validates the registered scene and its definition. Danmaku and fighter targets load their reviewed JSON through the production definition loaders. The v1 save target runs through the production migration, codec, typed validation, and state inspector. `smoke` instantiates a scene headlessly, allows four process frames, and fails on Godot script errors in project verification.

## Launch an interactive fixture

```bash
GODOT_BIN="$HOME/.local/bin/godot" scripts/authoring_workbench.sh \
  --action=launch --target=scene.fighter.hitbox
```

Useful targets include:

- `scene.tea.tutorial`, `scene.tea.active`, and `scene.tea.assist`;
- `scene.danmaku.live`, `scene.danmaku.phase1`, `scene.danmaku.focus`, and `scene.danmaku.stress`;
- `scene.fighter.live`, `scene.fighter.hitbox`, `scene.fighter.training`, and `scene.fighter.stress`.

The live targets are playable. Review fixtures intentionally freeze or prepare a deterministic state.

## Capture a registered scene

```bash
DISPLAY=:0 GODOT_BIN="$HOME/.local/bin/godot" scripts/authoring_workbench.sh \
  --action=screenshot \
  --target=scene.fighter.hitbox \
  --output=/tmp/fighter-hitbox.png \
  --profile=A --locale=en --ui-scale=100
```

The workbench delegates capture to `tests/ui/screenshot_runner.gd`, including the exact 320×180 viewport, one-bit post-process, synchronized rendering, and palette validation. An X display is required for OpenGL screenshot capture.

## Audition legal test tones

```bash
GODOT_BIN="$HOME/.local/bin/godot" scripts/authoring_workbench.sh \
  --action=launch --target=tone.shrine_day
```

All tone targets use `AdaptiveTestTonePlayer`. They generate original low-volume sine/harmonic loops at runtime and contain no downloaded, official, or copyrighted recording. Headless `smoke` proves state selection and transition behavior without audio hardware.

This registry is the shared entrypoint; the underlying fixture scenes, definitions, migration rules, screenshot runner, and audio generator remain their respective authoritative implementations.
