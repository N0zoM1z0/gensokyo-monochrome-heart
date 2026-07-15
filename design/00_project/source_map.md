# Source and Provenance Map

## Primary supplied source

`9202b449-c055-4dd2-b4fe-5c6fbd763131.md`

The archive contains a long sequence of romance portraits, seasonal harem-comedy episodes, Outside World extras, and second-season incident arcs. It is treated as **creative source material**, not as canon.

What this package preserves:
- the “chaos to sincerity” scene rhythm;
- location-driven comedy;
- recurring domestic details;
- a broad ensemble;
- the dream/reunion motif;
- the desire for playful danmaku, fighting, and minigames.

What this package transforms:
- direct harem conquest becomes negotiated ensemble play;
- explicit/suggestive material becomes PG-13;
- repetitive possession jokes become character-specific boundary conflicts;
- canon and fanon are visibly separated;
- prose-only scenes become interactive event structures.

See `02_narrative/source_conversation_index.md` and `02_narrative/adaptation_matrix.md`.

## Canon research priority

1. Official game profiles and omake text
2. Official game dialogue
3. Official print works and reference books
4. Community-maintained translations and indexes
5. Fan wiki summaries, used cautiously
6. Community memes, tagged as fanon only

## Key official works consulted conceptually

- Embodiment of Scarlet Devil
- Perfect Cherry Blossom
- Imperishable Night
- Phantasmagoria of Flower View
- Mountain of Faith
- Scarlet Weather Rhapsody / Hisoutensoku
- Subterranean Animism
- Undefined Fantastic Object
- Ten Desires
- Hopeless Masquerade
- Legacy of Lunatic Kingdom
- Hidden Star in Four Seasons
- Wily Beast and Weakest Creature
- Perfect Memento in Strict Sense
- Symposium of Post-mysticism
- Bohemian Archive in Japanese Red
- Forbidden Scrollery
- Wild and Horned Hermit
- Curiosities of Lotus Asia
- Silent Sinner in Blue

## Engineering sources

The implementation plan targets Godot 4.7 stable and relies on official Godot documentation for:
- dedicated 2D rendering and physics;
- resource-driven content;
- CSV translation import;
- headless test execution;
- desktop export.

Pin the exact stable patch version at production kickoff and do not silently upgrade mid-milestone.
