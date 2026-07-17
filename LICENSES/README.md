# Licenses and Provenance

This directory records licenses for the implementation repository and every redistributed dependency or asset.

Current approved inputs:

- **Godot Engine 4.7.1-stable** — MIT License; development tool/runtime, obtained from the official Godot release.
- **DotGothic16** — SIL Open Font License 1.1; the exact license text is stored beside the synchronized font and in this directory.
- **Kiri8 prototype bitmap font** — project-original glyph construction derived from the pinned design package's own 5×7 source table.
- **Design reference assets** — project-supplied preproduction material under `design/`; `.gdignore` prevents accidental runtime import.

`assets/asset_ledger.json` is the release authority for each imported art,
audio, and font file. It records the exact SHA-256, source path, rights basis,
approval evidence, and accessibility pairing. `CREDITS.generated.md` is rebuilt
from that ledger. A licensed entry is rejected when its license file is absent;
an unregistered runtime asset is rejected even if its filename looks final.

No official Touhou game asset is approved for inclusion. A file is not shippable merely because it exists in a local working directory.
