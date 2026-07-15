# Contributing

## Before changing code or content

1. Read the relevant files under `design/` and cite them in the change description.
2. Keep the change within one milestone and one logical commit.
3. Do not add dependencies, official assets, network services, analytics, or generated final content without explicit approval and a decision record.
4. Preserve the dependency direction: presentation → application → domain.
5. Use typed GDScript at public boundaries and stable dotted IDs for content.

## Verification

Run the complete foundation gate:

```bash
./scripts/verify_project.sh
```

Changes to presentation also require 1× screenshots, English/Japanese review where relevant, forced Profile A review, and reduced-motion/safe-flash review.

## Commit messages

Use English imperative Conventional Commit subjects and a detailed body describing scope, design references, verification, and intentional limitations. Do not combine generated data, gameplay behavior, and unrelated refactors in one commit.

## Asset safety

- Do not extract, trace, or redistribute official Touhou assets.
- Do not import concepts or enlarged previews into release content.
- Every runtime asset needs a provenance record before release.
- Placeholder identifiers beginning with `ph_` are forbidden in release-channel builds.
