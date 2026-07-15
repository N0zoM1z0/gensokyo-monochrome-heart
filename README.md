# Gensokyo: Monochrome Heart

Implementation repository for an unofficial Touhou Project fan game: a 1-bit exploration, dialogue, danmaku, and compact-fighter hybrid.

This repository is currently in the M00/VA00 foundation milestone. It intentionally contains no broad gameplay implementation yet. The first product gate is the integrated **Empty Cushion** vertical slice described in [`design/10_codex/VERTICAL_SLICE_ACCEPTANCE.md`](design/10_codex/VERTICAL_SLICE_ACCEPTANCE.md).

## Foundation constraints

- Godot `4.7.1-stable`, typed GDScript.
- 320×180 internal canvas with integer scaling and letterboxing.
- Visible runtime pixels use only black or white; transparency is binary.
- English and Japanese are authored from stable localization keys.
- Runtime networking and runtime-generated dialogue are prohibited.
- Story outcomes are data-authored and shared by every gameplay mode.
- Official or unlicensed Touhou assets are prohibited.
- Failure and accessibility assists may not permanently block narrative progress.

## Repository map

- `design/` — pinned preproduction specification; not runtime-imported.
- `content/` — synchronized and implementation-authored content sources.
- `schemas/` — synchronized machine-readable content contracts.
- `src/` — domain, application, presentation, and infrastructure code.
- `ui/` — UI themes, fonts, fixtures, and shared scenes.
- `assets/` — approved runtime art, audio, fonts, and placeholders.
- `tests/` — headless unit, integration, screenshot, and replay fixtures.
- `scripts/` — reproducible setup, synchronization, and verification commands.
- `docs/` — decisions and generated milestone evidence.

## Setup

```bash
GMH_USE_CLASH=1 ./scripts/install_godot.sh
./scripts/verify_project.sh
```

The verification gate checks the exact engine build, deterministic content/font sync, clean import, positive and negative validators, headless tests, smoke boot, release placeholder policy, and the 1× EN/JA screenshot matrix. On a display-less Linux runner, invoke it through `xvfb-run`; only explicitly diagnostic runs may set `GMH_SKIP_SCREENSHOTS=1`.

The full workflow and acceptance gates are defined by the pinned taskbooks under `design/10_codex/`.

## Fan-work notice

This is an unofficial Touhou Project fan work. Touhou Project is created by Team Shanghai Alice.
