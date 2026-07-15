# M12 Scarlet Devil Mansion Reuse Assessment

M12 must prove that a second region and lead character enter the same typed content, event, save, replay, accessibility, and presentation boundaries without shrine or Sakuya branches in generic code.

## Reused unchanged

- `GameState`, commands, transactions, relationship facets, save codec/migration, checkpoints, Journal, Keepsakes, and replay isolation;
- typed event nodes, predicates, four-tone choices, mode result branches, dialogue presentation, EN/JA localization, wrapping, backlog, and resonance cues;
- `MinigameHost`, assist settings, deterministic mode contexts, fixed-step input frames, and `ModeResult` handoff;
- packed danmaku pool, assist tiers, replay tape, batch renderer, pause/retry/accept-loss semantics, and Bullet Pattern Lab authoring workflow;
- presentation profiles, integer scaling, one-bit validation, screenshot runner, input routing, legal generated test tones, and accessibility presets.

## Coupling found before content work

| Risk | Evidence | Resolution boundary |
| --- | --- | --- |
| Repository retained only one event graph | `ContentRepository.event_graph` and `graph()` addressed the Empty Cushion graph only | index any number of typed graphs by stable event ID while retaining the primary compatibility view |
| Keepsake tag had an event-ID branch | `EventInterpreter` checked `evt.hkr.empty_cushion` | read item metadata from the node; infer the legacy tag from authored dialogue when old data omits it |
| Current vertical-slice shell preloads shrine-specific modes | `VerticalSliceMode` owns a single event and concrete Tea/Boundary/Fighter scenes | introduce a data-owned mode registry/host before integrating the SDM event; do not add SDM conditions to this shell |
| Tea and Boundary Stain presentations own concrete simulations | class names and copy are mechanic-specific | implement time-grid and knife-lattice components behind existing host/result contracts; reuse shared assists and renderer where their semantics match |
| Hakurei exploration spot is factory-owned | `HakureiVerandaSpotFactory` is intentionally specific | add SDM spot data/factory at the region composition edge, never inside the generic exploration motor/controller |

## Content increments

1. Establish the multi-graph repository and remove the existing event-ID special case.
2. Author foyer plus kitchen/corridor spots and the complete bilingual `Late by Three Minutes` graph.
3. Add the deterministic time-grid service minigame and knife-lattice danmaku definition/components.
4. Integrate the missing-minute afterbeat, Patchouli library teaser, and Remilia public/private follow-up through flags, predicates, and data-authored scenes.
5. Prove save/replay/accessibility behavior, scan generic source for SDM/Sakuya branches, capture EN/JA matrices, and run the full project gate.

The architecture scan treats stable IDs inside content, fixtures, region composition, and tests as expected. It rejects character or region ID checks in generic Domain/Application services and shared presentation hosts.
