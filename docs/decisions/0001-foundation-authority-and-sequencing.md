# ADR-0001: Foundation authority and milestone sequencing

- Status: Accepted
- Date: 2026-07-15
- Owners: Project owner and implementation

## Context

The original M00–M10 engineering taskbook and the later VA00–VA10 UI/art taskbook overlap at repository setup, fixed resolution, import policy, validation, and screenshot infrastructure. Older specialist documents also retain values superseded by the v2 machine-readable UI contracts.

## Decision

1. Implement M00 and the non-gameplay portions of VA00 as one foundation phase.
2. Preserve separate logical commits for design import, project bootstrap, content validation, and presentation validation.
3. Use this authority order for UI/art conflicts:
   - v2 machine-readable JSON;
   - v2 Markdown contracts;
   - original specialist documents;
   - historical ASCII wireframes.
4. Treat the v2 danmaku layout as 224×152 plus an 88-pixel status rail.
5. Treat Model M as 24×32 and the location catalog as 19 records.
6. Distinguish authored story bullet budgets from the 2,500-bullet engineering stress fixture.
7. Do not begin M01/VA01 until all M00/VA00 foundation gates pass.

## Consequences

- The project builds one shell, profile system, validator set, and screenshot harness instead of parallel old/new implementations.
- The pinned design package remains unchanged; implementation decisions and compatibility notes live under `docs/decisions/`.
- Missing starter registries are represented explicitly as deferred fixture references until M02 supplies typed records.
