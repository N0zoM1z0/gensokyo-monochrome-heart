# Compact Fighter Runtime Art

The duel consumes the reviewed 32×48 Model L key-pose atlases under
`assets/art/production/characters/`. Reimu and Marisa each expose the same
29-action production contract, and the presentation maps fixed-step combat state
onto those authored actions without changing simulation timing.

The source sheets remain strict one-bit images. Ink-polarity profiles recolor
opaque black and white pixels at runtime, so accessibility does not require
duplicate sprite files. Combat hurtboxes and hitboxes remain independently
authored in `content/fighter/reimu_marisa_duel.json`; sprite bounds never own
gameplay rules.
