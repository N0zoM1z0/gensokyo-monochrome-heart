# M16 Production Audio Technical Review

Date: 2026-07-17  
Decision: the listed original files are approved as production audio inputs;
the first runtime adaptive-playback and bounded-SFX integration is implemented,
while user-facing mix accessibility and full campaign cue coverage remain open.

## Authorship and rights

All 27 WAV files under `assets/audio/production/` are generated solely by
`scripts/build_m16_audio_assets.py`. The generator reads no recording, MIDI,
score, or arrangement input. Its region motifs use project-authored integer
pitch sequences and explicitly do not transcribe the Touhou references in the
design cue sheet. Rights basis is therefore `project_original`.

## Technical evidence

- 15 music stems cover five headline regions with synchronized Place, Person,
  and Incident roles.
- Each family shares sample rate, frame count, BPM, meter, and exact loop range.
- All files are 22.05 kHz, 16-bit mono PCM; loop metadata is embedded in `smpl`.
- The generator's independent check reproduces every byte and manifest hash.
- Header, byte-size, seam endpoint, DC-offset, and clipping checks pass.
- 12 SFX records carry family, role, voice cap, and stealing priority metadata.

The music references in `content/music/music_cues.csv` remain contextual briefs,
not licenses or source inputs. No generated stem inherits rights from them.

## Runtime integration update

`ProductionAdaptiveMusicPlayer` now replaces test-tone playback in the three
vertical slices. It starts Place, Person, and Incident streams at one shared
position, changes their mix at family-native bar boundaries, and restarts them
only when the requested authored state crosses to another production family.
The legal generated-tone player remains isolated to the M11 authoring workbench.

`ProductionSfxPlayer` replaces procedural runtime SFX in exploration, danmaku,
fighter, and tea scenes. It resolves semantic cue aliases to the twelve reviewed
files and allocates bounded pools from the manifest's family voice caps. Music
and SFX use explicit buses in `default_bus_layout.tres`.

Detailed evidence is recorded in
`docs/reviews/m16_production_audio_runtime_review.md`.

## Blocking remainder

M16 still needs user-facing mono and low-dynamic-range controls, listener review
of the production mix, and deliberate production-family mapping for campaign
regions outside the five headline families. This file approval therefore does
not by itself close the complete M16 audio gate.
