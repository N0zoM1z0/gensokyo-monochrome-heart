# Build and Release Pipeline

## 1. Branches

- `main`: always releasable internal build;
- short-lived feature branches;
- tagged milestone builds;
- release branches only for stabilization;
- content freeze precedes code freeze by at least one review cycle.

## 2. CI stages

1. verify engine version;
2. format/lint scripts;
3. validate JSON/CSV/schemas;
4. resolve content dependencies;
5. run headless domain/integration tests;
6. run deterministic replay fixtures;
7. import project from clean cache;
8. export development builds;
9. execute smoke test;
10. generate EN/JA screenshot matrix;
11. scan placeholder and unlicensed-asset records;
12. package artifacts and manifest.

## 3. Build channels

- `dev`: debug console, fixture loader, diagnostic overlay;
- `qa`: release-like performance plus test menus;
- `demo`: limited content, separate save namespace;
- `release`: no debug commands, approved content only.

## 4. Platforms

Initial recommended scope:
- Windows 64-bit;
- Linux x86_64;
- macOS universal only after signing/notarization pipeline is owned and tested.

Do not promise consoles or mobile in the first production plan. Input and resolution design should avoid blocking later ports.

## 5. Versioning

Semantic game version plus save schema:
```text
0.3.0-demo.2
save_schema=4
content_revision=2026.07.14.1
```

Content revision participates in replay hashes. Patch notes distinguish code, content, localization, and balance changes.

## 6. Release checklist summary

- official fan-work guidelines rechecked;
- title/store page clearly unofficial;
- no official/ripped assets;
- all music and guest permissions archived;
- EN/JA credits complete;
- content comfort and age-rating review complete;
- save migrations verified;
- controller and keyboard pass;
- accessibility presets pass;
- crash/log privacy review;
- storefront and payment terms confirmed;
- demo/release save compatibility policy stated;
- clean-machine install/uninstall test;
- SHA-256 manifest generated.

## 7. Crash reports and privacy

Default logs contain:
- game/build version;
- OS and renderer category;
- stable content/event IDs;
- error code and stack;
- accessibility configuration only when relevant.

Do not collect protagonist names, full save files, personal paths, or free-form dialogue without explicit user action and preview.

## 8. Rollback

Keep the previous signed build and content manifest. A rollback must not downgrade or overwrite a newer save; show a version warning and use a separate copy if necessary.
