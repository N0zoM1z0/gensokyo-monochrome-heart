# Gensokyo: Monochrome Heart
## Complete Preproduction Package for a Touhou Project Fan Game

**Working Japanese title:** 幻想郷モノクローム・ハート  
**Format:** retro 1-bit exploration / dialogue / danmaku / fighting hybrid  
**Languages:** English and Japanese  
**Recommended engine:** Godot 4.7 stable, GDScript, desktop-first  
**Internal resolution:** 320 × 180, pixel-perfect upscale  
**Content target:** all-ages / PG-13 romantic comedy with optional ensemble romance

This package translates a long-form romance-comedy conversation archive into a buildable game plan. **It is a preproduction package, not a completed executable game.** It is not a transcript dump. The source material has been indexed, filtered, and rewritten into systems, character rules, route beats, event hooks, and implementation tasks.

## The one-sentence pitch

A human from the Outside World returns to a monochrome Gensokyo where memories have become physical “spots”; by exploring them with the inhabitants, the player restores relationships, resolves comic incidents, and discovers why the border remembers a life that may have been only a dream.

## What makes the game coherent

Exploration, romance, danmaku, and fighting are not separate modes selected from a menu. They are outcomes of the same **Spot Event**:

1. Enter a place.
2. Notice a social or supernatural contradiction.
3. Investigate through side-view exploration.
4. Make a tone-based dialogue choice.
5. Resolve the event through a location-specific minigame, danmaku pattern, or compact duel.
6. Return to a quiet character beat.
7. Record a new shared memory in the Monochrome Journal.

The recurring emotional rhythm is:

> **comic escalation → mechanical climax → quiet sincere afterbeat**

## Package map

- `00_project/` — vision, boundaries, source policy, legal/fanwork notes
- `01_game_design/` — full GDD and all core systems
- `02_narrative/` — campaign, route structure, event catalog, scripts, localization
- `03_locations/` — location bibles and spot-level mechanics
- `04_characters/` — one `skills.md` agent specification per character
- `05_ui_ux/` — UI architecture, wireframes, controls, accessibility
- `06_art/` — 1-bit art direction, sprite standards, mockups
- `07_audio/` — legal-safe cue sheet and sound design
- `08_technical/` — Godot architecture, schemas, save/localization/testing plans
- `09_data/` — machine-readable starter data and examples
- `10_codex/` — master taskbook, staged prompts, backlog, definition of done
- `11_research/` — source notes and canon/fanon confidence register
- `12_production/` — milestones, risks, staffing, release checklist
- `tools/` — package validation utility

## Recommended production scope

### Vertical slice
- Hakurei Shrine
- Reimu and Marisa
- one exploration event
- one minigame
- one danmaku scene
- one duel
- bilingual dialogue
- save/load and journal

### Early Access / v0.8
- five headline locations
- twelve deep romance routes
- ten playable danmaku characters
- eight playable fighters
- fifty authored spot events

### Full v1.0
- seventeen location regions
- seventy-one character agent profiles
- twelve deep routes plus ensemble ending
- one hundred or more spot events
- postgame seasonal episodes
- authoring tools and mod-friendly data

## First files to read

1. `00_project/vision.md`
2. `01_game_design/game_design_document.md`
3. `02_narrative/narrative_bible.md`
4. `04_characters/README.md`
5. `10_codex/CODEX_MASTER_TASKBOOK.md`

## Rights and asset policy

This is a fan-work preproduction package. It contains no ripped official sprites, music, dialogue, endings, fonts, or game data. All production art, code, text, sound effects, and arrangements must be created or licensed for the project. Review the current official Touhou fan-work guidelines before release and again before every storefront submission.
