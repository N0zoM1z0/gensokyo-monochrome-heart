# Asset Naming and Export Matrix

## 1. Naming convention

```text
<domain>_<entity>_<context>_<action>_<variant>_<frame>.<ext>
```

Examples:
```text
chr_reimu_explore_walk_e_03.png
chr_reimu_portrait_private_tired_01.png
chr_marisa_danmaku_broom_recoil_04.png
loc_shrine_veranda_rain_fg_02.png
vfx_sakuya_knife_spawn_a_00.png
ui_journal_thread_knot_open.png
```

Use lowercase ASCII snake_case. Japanese display names live in data, not filenames.

## 2. Domains

- `chr` character;
- `loc` location;
- `prop` prop;
- `vfx` effect;
- `bul` bullet;
- `ui` interface;
- `ico` icon/stamp;
- `prt` particle;
- `cut` cutscene illustration;
- `dbg` debug only.

## 3. Character contexts

`map`, `explore`, `portrait`, `danmaku`, `fighter`, `minigame`, `cutscene`, `journal`.

## 4. Export metadata

Each animation has a sidecar JSON or imported Godot resource:

```json
{
  "fps": 10,
  "loop": true,
  "anchor": [12, 31],
  "events": {"3": ["footstep_wood"]},
  "polarity": "both",
  "outline_safe": true
}
```

## 5. Repository policy

- source art and exports are separate;
- generated atlases are reproducible;
- never hand-edit a generated atlas;
- hash exported assets in build manifests;
- placeholders use `ph_` prefix and fail release validation;
- every third-party asset has a license record;
- official Touhou assets are never imported, even as hidden placeholders.
