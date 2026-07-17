# M16 Production Audio Technical Review

Date: 2026-07-17  
Decision: the listed original files are approved as production audio inputs;
runtime adaptive playback, mixer settings, and full campaign cue coverage remain open.

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

## Blocking remainder

Release code must still replace test-tone playback with a synchronized stem
director, implement family voice pools and audio buses, expose mono/low-dynamic
settings, map authored events to production cue families, and generate in-game
credits from the ledger. This approval applies to the files, not unfinished
runtime integration.
