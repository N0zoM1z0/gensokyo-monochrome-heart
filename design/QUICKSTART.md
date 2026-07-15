# Quick Start

## For the project owner

1. Read `README.md` and `00_project/vision.md`.
2. Decide whether the working title and PG-13 / ensemble-romance policy are accepted.
3. Review the 12 deep-route outlines in `02_narrative/romance_route_beats.md`.
4. Open `06_art/mockups/` to compare the proposed UI and sprite scales.
5. Review the 89-row `07_audio/music_cue_sheet.csv` and mark arrangement priorities.
6. Give the repository plus this package to Codex using `10_codex/CODEX_BOOTSTRAP_PROMPT.md`.
7. Do not authorize full-game production before the vertical slice passes `10_codex/VERTICAL_SLICE_ACCEPTANCE.md`.

## For writers

- Start with `02_narrative/narrative_bible.md`.
- Read every visible character's `04_characters/<slug>/skills.md`.
- Check `04_characters/relationship_graph.json`.
- Use `10_codex/CONTENT_AUTHORING_WORKFLOW.md`.
- Mark Canon/Fanon/Original and actual fanon intensity.
- Write EN and JA as parallel authored localizations.

## For programmers / Codex

- Start with `10_codex/CODEX_BOOTSTRAP_PROMPT.md`.
- Implement M00–M04 before gameplay modes.
- Build only the Empty Cushion vertical slice first.
- Use `09_data/` as starter fixtures, not as final content.
- Run `python tools/validate_package.py` to verify this design package before copying data.

## For artists

- Read `06_art/one_bit_art_bible.md` and `sprite_modeling_guide.md`.
- Prototype Reimu and Marisa at Model S, M, and L before locking a style.
- Use silhouette recognition and both palette polarities as approval gates.
- Do not trace official or fan sprites.

## For composers / sound designers

- Read `07_audio/audio_direction.md` and `music_legal_notes.md`.
- Treat theme titles as references, not included rights.
- Prototype one Shrine arrangement family with Place/Person/Incident stems.
- Record cue-level provenance and permissions before a track becomes shippable.

## What this ZIP is not

It is not a finished game, a Godot repository, or a bundle of Touhou assets. It is a full preproduction specification, research/agent library, machine-readable starter dataset, visual mockup set, and implementation taskbook.
