# ADR-0002: Lock Godot 4.7.1-stable

- Status: Accepted
- Date: 2026-07-15

## Context

The design requires the newest stable 4.7.x patch available at production kickoff and prohibits release-candidate builds. Godot 4.7.1-stable was published on 2026-07-14.

## Decision

Lock development, CI, imports, and fixtures to `4.7.1.stable.official.a13da4feb`. The installer validates the official Linux x86_64 archive against its upstream SHA-512 before use.

## Consequences

- Engine changes require a new decision record and a clean-import/migration branch.
- CI must fail when the runtime version differs.
- Local installation uses a user-owned directory and requires no privileged credential.
