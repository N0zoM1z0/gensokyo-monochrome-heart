# Release-Candidate Save and Rollback Policy

Current candidate: `0.1.0-rc.1`
Save schema: `2`
Content revision: `2026.07.17.1`

- Release builds use the `gmh_release` save namespace; dev, QA, and demo builds
  use separate namespaces and must not overwrite release saves.
- Schema 1 saves migrate to schema 2 through the checked `SaveMigrationV1ToV2`
  path. Unknown future schemas are retained for read-only diagnostics and are
  never downgraded or overwritten.
- Save writes are atomic and retain a backup. A corrupt or truncated current
  save is restored only after the backup validates.
- A rollback build must use a separate save copy or show a version warning. It
  must never silently replace a newer release save.

Evidence: `tests/unit/TestSaveMigrations.gd`, `tests/unit/TestSaveRepository.gd`,
and the M09/M12/M13 save-resume matrices.
