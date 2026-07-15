# Recommended Implementation Repository

```text
.
├── project.godot
├── ENGINE_VERSION.md
├── README.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── export_presets.cfg
├── design/                       # this package, pinned or submodule
├── addons/                       # empty unless explicitly approved
├── assets/
│   ├── art/
│   │   ├── characters/
│   │   ├── locations/
│   │   ├── ui/
│   │   ├── bullets/
│   │   └── placeholders/
│   ├── audio/
│   │   ├── music/
│   │   ├── sfx/
│   │   └── test_tones/
│   └── fonts/
├── content/
│   ├── characters/
│   ├── locations/
│   ├── events/
│   ├── dialogue/
│   ├── minigames/
│   ├── combat/
│   ├── items/
│   ├── localization/
│   ├── credits/
│   └── indexes/                  # generated
├── schemas/
├── src/
│   ├── autoload/
│   ├── domain/
│   │   ├── state/
│   │   ├── rules/
│   │   ├── commands/
│   │   └── results/
│   ├── application/
│   │   ├── events/
│   │   ├── saves/
│   │   ├── content/
│   │   └── modes/
│   ├── presentation/
│   │   ├── shell/
│   │   ├── ui/
│   │   ├── exploration/
│   │   ├── dialogue/
│   │   ├── danmaku/
│   │   ├── fighter/
│   │   └── minigames/
│   ├── infrastructure/
│   │   ├── file_io/
│   │   ├── localization/
│   │   ├── audio/
│   │   └── platform/
│   └── tools/
├── tests/
│   ├── run_all.gd
│   ├── unit/
│   ├── integration/
│   ├── replay/
│   ├── fixtures/
│   └── screenshots/
├── scripts/
├── LICENSES/
├── permissions/
├── docs/
│   ├── decisions/
│   ├── test_reports/
│   └── performance/
└── .github/workflows/            # or selected CI provider
```

## Ownership rules

- `design/` explains intent; implementation changes do not silently rewrite it.
- `content/` contains reviewable source data.
- `indexes/` is generated and reproducible.
- `assets/placeholders/` must use project-original geometry/test tones.
- `permissions/` stores metadata references, not publicly redistributed private contracts in a public repo.
- `src/domain` has no scene paths or autoload calls.
- `tests/fixtures` contains no official assets or copied dialogue.

## Import direction

```text
presentation → application → domain
infrastructure → application/domain contracts
content → parsers → typed domain records
tools → all layers in development only
```

Circular dependencies are a release-blocking architecture issue.
