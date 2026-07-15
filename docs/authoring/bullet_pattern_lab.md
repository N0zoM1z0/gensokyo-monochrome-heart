# Bullet Pattern Lab

The M11 Bullet Pattern Lab lets a designer duplicate the reviewed Boundary Stain definition, edit data without GDScript, validate it through the production loader, inspect density and timing consequences, and preview the complete pattern through the production fixed-step simulation and packed renderer.

The closed component vocabulary is `lane_fan`, `offering_ring`, and `safe_lane_grid`. Arbitrary scripts and unknown component names are rejected.

## Create a draft

```bash
GODOT_BIN="$HOME/.local/bin/godot" scripts/bullet_pattern_lab.sh \
  --action=duplicate \
  --pattern-id=danmaku.lab.my_pattern \
  --output=authoring/drafts/my_pattern.json
```

The command refuses to overwrite a file. It remaps the pattern, phase, and emitter IDs into the new namespace while retaining reviewed localization keys and the 224×152 arena contract.

## Edit and validate

Edit the JSON in a text editor. Useful emitter fields include:

- `pattern`: one of the three supported components;
- `start_tick`, `interval_ticks`, and `volleys`;
- `slot_count`, origin, speed, angle, telegraph, and lifetime;
- bullet family and polarity;
- `safe_lane` for `safe_lane_grid`.

Then run:

```bash
GODOT_BIN="$HOME/.local/bin/godot" scripts/bullet_pattern_lab.sh \
  --action=validate --input=authoring/drafts/my_pattern.json

GODOT_BIN="$HOME/.local/bin/godot" scripts/bullet_pattern_lab.sh \
  --action=report --input=authoring/drafts/my_pattern.json
```

The report shows timing, speed, telegraph duration, and actual emitted slot counts at the production density tiers 55/70/85/100%.

## Run deterministic evidence

```bash
GODOT_BIN="$HOME/.local/bin/godot" scripts/bullet_pattern_lab.sh \
  --action=smoke --input=authoring/drafts/my_pattern.json \
  --density=85 --speed=70
```

This runs all three phases through `BoundaryStainSimulation`, keeps the preview observer invulnerable, and reports tick count, peak active/committed bullets, capacity, result, and canonical snapshot SHA-256. Repeated runs with the same data and settings must produce identical evidence.

## Launch the visual lab

```bash
DISPLAY=:0 GODOT_BIN="$HOME/.local/bin/godot" scripts/bullet_pattern_lab.sh \
  --action=launch --input=authoring/drafts/my_pattern.json
```

The logical canvas is 320×180 for exact pixel review; the normal desktop launch uses the project-wide 960×540 integer-scaled window.

Controls:

- `H`: open the in-lab first-use help and symbol legend;
- `R`: reload the JSON after saving external edits;
- `Space`: pause or resume;
- `.`: advance one fixed tick;
- `F`: advance 60 ticks;
- `P`: cycle and seek to a phase;
- `D`: cycle 55/70/85/100% density;
- `S`: cycle 70/80/90/100% speed;
- `E`: select an emitter and its origin marker.

The lab is a read-only preview: `D` and `S` change temporary preview assists and never write the JSON. The right rail reports phase/tick, live and solid (committed) bullets, peak occupancy, production assist settings, reload state, selected component, timing, slots, and telegraph ticks. `ASCII EN/JA` marks the compact technical telemetry as deliberately locale-neutral; localized event and dialogue authoring remain available through the bilingual event previewer. The observer is invulnerable so collision does not interrupt authoring preview; emission, lifecycle, pooling, phase transitions, and rendering remain production behavior.
