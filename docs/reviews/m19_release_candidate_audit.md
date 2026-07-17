# M19 Release-Candidate Audit

Date: 2026-07-17 (Asia/Singapore)
Candidate version: `0.1.0-rc.1`
Content revision: `2026.07.17.1`
Save schema: `2`

## Delivered technical release path

- `scripts/install_godot_export_templates.sh` installs Godot 4.7.1 export
  templates only after checking the SHA-256 published by Godot's official
  GitHub release API.
- `scripts/build_release_candidate.sh` validates synchronized content and
  release assets, exports `Release Linux`, starts the exported binary with a
  fresh `XDG_DATA_HOME`, rejects Godot errors, and emits `SHA256SUMS` plus a
  JSON release manifest.
- `scripts/verify_release_linux.sh` uses a new temporary workspace, verifies
  the portable binary/PCK and manifest, runs the smoke test, then moves the
  whole package away from its install path while keeping isolated user data.
  This is the appropriate install/run/uninstall simulation for the Linux
  portable package; it does not claim a Windows or macOS test.
- `Release Windows` exports a Windows x86_64 `.exe` and `.pck` with the same
  provenance, runtime-content, and checksum rules. The checked
  `WINDOWS_CLEAN_MACHINE_PROTOCOL.md` records the external Windows evidence
  required before any compatibility claim.
- Runtime CSV mirrors under `content/runtime/` avoid Godot's Translation CSV
  export stripping. The exported game now loads 71 characters, 19 locations,
  104 events, 713 beats, 2,065 strings, and 89 cues without errors.

## Fan-work and packaging review

The current official [Touhou Project fan-work guideline](https://touhou-project.news/guideline/)
was opened on 2026-07-17. It is dated 2024-05-31, requires clear fan-work
identification, prohibits confusing work with official content and infringement
of others' rights, identifies allowed distribution categories, and says the
guideline may change. The package includes the bilingual `NOTICE.md` and
generated asset credits. The candidate deliberately has no storefront, price,
crowdfunding plan, or public support contact assigned.

`CREDITS.generated.md` is copied into the package as `CREDITS.md`; release
validation reports 63 registered and 63 discovered runtime assets with zero
ledger errors.

## Save, rollback, and support packet

`SAVE_COMPATIBILITY.md` records schema-2 migration and rollback behavior.
`KNOWN_ISSUES.md` records the M07 llvmpipe full-render measurement, lack of
screen-reader claim, owner-waived audio audition, and unresolved human review.
`SUPPORT.md` defines the default privacy boundary but explicitly refuses to
pretend a public contact exists. `STORE_COPY_DRAFT.md` supplies EN/JA draft
copy and marks the required human editorial approval.

## Public-release decision

**Do not publish this candidate yet.** The technical Linux package is
reproducible and smoke-tested, but public release remains blocked by the M17
human review manifest, a target-class GPU capture before hardware claims, a
named permitted storefront/distribution decision, and an owned support contact.
The real-device speaker/headphone audition is not a blocker because the owner
explicitly waived it; no audition is claimed to have occurred.
