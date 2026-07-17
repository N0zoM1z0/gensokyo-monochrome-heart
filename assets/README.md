# Runtime Assets

Only original, licensed, or project-supplied approved runtime assets belong here. Concepts and enlarged previews stay under `design/` and must never be release-imported.

Asset provenance is recorded in `CREDITS.yml`, `LICENSES/`, and later cue-level/source ledgers.
The M16 release ledger is `asset_ledger.json`. Run
`python3 scripts/validate_asset_ledger.py --check` before importing or committing
new art, audio, or font files; unregistered runtime assets fail verification.
