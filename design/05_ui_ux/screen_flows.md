# Screen Flows

## 1. Boot and title

```text
Boot
→ accessibility first-run prompt
→ photosensitivity / audio notice
→ Title
   ├─ Continue
   ├─ New Journey
   ├─ Journal Replay
   ├─ Spell Practice
   ├─ Duel Practice
   ├─ Options
   ├─ Credits / Fan-work Notice
   └─ Quit
```

New Journey asks for:
- profile slot;
- protagonist display name;
- pronoun set or name-only dialogue;
- text language (EN / JA);
- initial assist preset;
- content comfort toggles.

No appearance editor is required in v1; the protagonist remains visually understated.

## 2. Day loop

```text
Lodging Desk
├─ Read letters and rumors
├─ Prepare Tea Blend
├─ Equip two Keepsakes
├─ Review Journal threads
└─ Open Region Map
    → Region
      → Spot preview
        → Travel confirmation
          → Spot Event
            ├─ Exploration
            ├─ Dialogue
            ├─ Minigame
            ├─ Danmaku
            ├─ Duel
            └─ Afterbeat
          → Journal update
          → Next time slot / Return home
```

A spot preview shows active characters, estimated duration, weather, comfort-sensitive tags, and possible mode types. It never reveals the correct dialogue tone or route result.

## 3. Dialogue choice flow

```text
Line
→ optional Observe prompt
→ ToneChoice appears
→ player previews intent text
→ Confirm
→ response beat
→ nonnumeric ResonanceTell
→ next line or mechanical transition
```

On Cancel, the focus returns to the line without selecting. In timed scenes, timing is off by default and explicitly telegraphed when enabled.

## 4. Failure flow

```text
Mechanical failure
→ freeze / clear hazards
→ result card
   ├─ Retry unchanged
   ├─ Retry with selected assist
   ├─ Accept the loss (story branch)
   └─ Practice explanation
```

No story route requires high execution difficulty. “Accept the loss” is authored, never a generic humiliation state.

## 5. Journal flow

The Journal is the player's main comprehension tool.

Pages:
- **Today:** active invitations and open threads;
- **People:** observed preferences and shared-object changes;
- **Places:** spots, conditions, and unresolved contradictions;
- **Rumors:** source, confidence, mutation history;
- **Keepsakes:** mechanical effect and memory context;
- **Archive:** replay unlocked completed events;
- **Music Room:** cue title, arrangement placeholder, unlock note.

Information is phrased as the protagonist's observation, not omniscient truth.

## 6. Save/load flow

- autosave at day start, pre-mode transition, and event end;
- three manual slots from Lodging or Pause;
- save card displays chapter, location, time, visible party, play time, accessibility preset, and version;
- incompatible versions invoke migration or preserve a read-only backup;
- deleting a save requires hold-confirm plus a second explicit choice.

## 7. Route finale flow

A deep route finale is unlocked by story understanding, not a hidden score. The Journal presents the unresolved promise in plain language. The finale asks the player to act on the route's central boundary. After completion, the route can be named as a primary bond, left intimate but undefined, or included in Ensemble Accord if compatibility conditions are met.
