# M16 Production Visual Asset Review

Date: 2026-07-17  
Decision: approved as the first original production atlas pass; integration and
scene-composition review remain required before M16 acceptance.

## Authorship and technical checks

All 33 PNG files under `assets/art/production/` are deterministically generated
by `scripts/build_m16_visual_assets.py` from project-authored drawing code. The
generator reads no official game art, fan art, extracted geometry, or external
image input. Every visible pixel is opaque black or white and all other pixels
are fully transparent.

- Eight launch fighters each have a 384×32 Model M sheet, a 928×48 Model L
  29-action key-pose sheet, and a nine-expression portrait pack.
- The five headline regions each have 64 native 16×16 tiles with distinct
  shrine, mansion, mountain, bamboo, or spirit-garden shape language.
- The bullet atlas implements the contracted amulet, needle, orb, star, knife,
  butterfly, leaf, arrow, shard, plate, spirit, and keystone-chip families.
- Standard and reduced-flash launch VFX are separate atlases; the reduced form
  retains an outline cue without the standard white-center reversal.
- The UI export contains frames, focus markers, tabs, toggles, meters, and
  semantic confirm/cancel/status marks in native one-bit form.

Exact dimensions, sources, byte sizes, and SHA-256 hashes are recorded in the
production manifest and reproduced by the generator check.

## Independent simulated-player review

`remilia_player_review` initially blocked the batch, identifying duplicated
portraits, weak talk/action differentiation, repetitive region slots, debug-box
reduced VFX, a mismatched bullet ID, missing UI metadata, unsafe sidecar handling,
and self-approved generator records. After correction, the reviewer approved
this first asset-file pass with the following measured evidence:

- every portrait pack is 9/9 unique and every fighter VFX row is 4/4 unique;
- Model M sheets contain 10–13 distinct cells with visible four-beat talk cues;
- Model L sheets contain 28–29 distinct semantic key poses;
- region atlases contain 44–64 distinct tiles plus explicit layer/state rows;
- all twelve contracted bullet cells are distinct, including `keystone_chip`;
- generator manifests remain `candidate_for_review`; only this external ledger
  decision promotes their files to `approved_for_release`.

## Scope limits

The atlases are not accepted merely because they exist. Runtime scenes must
replace their greybox rendering with these assets, portrait tokens need a real
resolver, Model L frames need anchor/action mapping, region tiles need collision
metadata and composed proofs, and both VFX modes need screenshot review in the
actual combat background. Those integration gates remain open.
