# Compact Fighter Runtime Sheets

These four runtime PNGs are byte-identical copies of the reviewed, project-original
Model M Reimu and Marisa sheets in
`design/06_art/visual_system_v2/assets/sprites/`. The `design/` tree is excluded
from Godot import by design, so the runtime copies live here. They remain native
24×32 exploration sheets and polarity references; combat hurtboxes and hitboxes
remain independently authored in `content/fighter/reimu_marisa_duel.json`.

Every release-imported sheet is registered by exact hash in
`assets/asset_ledger.json`. Fighter-scale Model L animation is a separate M16
deliverable and must not be synthesized by scaling these sheets.
