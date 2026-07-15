# Accessibility and Comfort Specification

## 1. Presets

At first launch, offer:
- **Original:** authored timings and patterns;
- **Story:** generous hazards, unlimited narrative retries, simple fighter inputs;
- **Low Motion:** reduced camera movement, border animation, and parallax;
- **Custom:** exposes every setting.

Presets are starting points, not difficulty identities. They may be changed at any time without affecting achievements or endings.

## 2. Visual

- scalable UI to 150% within the 320 × 180 composition, with alternate reflow layouts;
- high-clarity font option;
- bullet outline thickness 1–3 px;
- player hitbox always visible option;
- background dim 0–80%;
- ordered-dither reduction;
- flashing replacement with border pulse;
- screen shake 0–100%;
- motion blur prohibited;
- safe-area adjustment;
- color is never the only signal, even if an optional accent-color edition is later added.

## 3. Danmaku assists

- game speed 100 / 90 / 80 / 70%;
- bullet density 100 / 85 / 70 / 55%;
- larger graze radius without larger damage hitbox;
- safe-lane preview for selected story patterns;
- auto-bomb;
- unlimited story retries;
- Assist Clear after three defeats;
- pattern practice by phase.

## 4. Fighter assists

- one-button specials;
- hold-to-guard;
- auto face opponent;
- slower game speed;
- infinite story rematches;
- input display and frame-step training;
- remove rapid-tap requirements.

## 5. Reading and language

- instant text;
- typewriter speed 10–120 glyphs/s;
- auto-advance multiplier;
- backlog;
- speaker label always visible;
- separate EN and JA font-size settings;
- name-only protagonist mode avoids grammatical pronoun issues;
- no essential information in timed text.

## 6. Audio

- independent music, SFX, UI, ambience sliders;
- mono mix;
- dynamic-range presets;
- visual cues for off-screen attacks;
- optional rhythm pulse for audio-timing minigames;
- no required microphone input.

## 7. Cognitive load

- one active objective by default;
- Journal “What changed?” summary;
- rumor confidence expressed with plain labels: Seen / Reported / Contradicted / Resolved;
- rematch begins at last failed phase;
- tutorials can be replayed from Journal;
- navigation hint appears after 45 seconds of no progress, configurable.

## 8. Content comfort

Toggles for:
- needles and clinical imagery;
- alcohol-centered scenes;
- jump scares;
- coercive pursuit framing;
- body horror;
- screen-covering insects/eyes;
- intense grief.

The project is all-ages / PG-13. These options further tune presentation, not explicit content.

## 9. QA requirement

Every vertical-slice acceptance test must be run once using keyboard-only, once controller-only, once Story preset, and once Low Motion. At least one external tester must complete the slice without prior Touhou knowledge.
