# Relationship and Dialogue System

## Resonance, not affection points

Each character tracks four hidden facets:

- **Trust:** believes the player will act reliably
- **Ease:** can share ordinary space without performance
- **Respect:** accepts the player's judgment or skill
- **Spark:** romantic or emotionally charged interest

A fifth value, **Strain**, records unresolved pressure.

The UI never shows numbers. The Journal uses qualitative phrases:
- “still measuring you”
- “expects you to return”
- “allows silence”
- “something unspoken is becoming difficult to ignore”

## Tone choices

The player selects:
- Direct
- Playful
- Patient
- Defiant

The selected tone is combined with:
- prior behavior;
- relationship facets;
- the character's current mask;
- public/private context;
- a route-specific sensitivity.

A tone is not a morality alignment. For example:
- Reimu often appreciates Direct or Patient.
- Marisa often appreciates Playful or Defiant.
- Sakuya may respect Direct but only accept Patient in private.
- Aya rewards Playful in public and Direct when the camera is down.
- Kaguya may test whether Defiant is genuine rather than performative.

## Memory callbacks

Events may register compact memories:

```json
{
  "subject": "reimu",
  "event": "shrine_tea_01",
  "player_tone": "patient",
  "detail": "repaired_cushion",
  "visibility": "private"
}
```

Later dialogue asks for semantic tags, not exact branch IDs.

## Romance opt-in

At the third route threshold, a scene offers:
- deepen the bond romantically;
- remain close friends;
- postpone the question.

No content is lost except romance-specific epilogues and flirt lines.

## Conflict and repair

Strain increases through:
- repeated boundary violations;
- public embarrassment;
- choosing a joke when sincerity is needed;
- treating competence as a gimmick;
- breaking a promise.

Repair requires an authored action, not a gift:
- show up;
- tell the truth;
- return an item;
- accept a fair loss;
- help with work;
- apologize without demanding immediate forgiveness.

## Ensemble Accord

Requirements:
- at least six deep routes completed;
- no active severe Strain;
- player chose friendship or romance honestly, not through reload manipulation;
- three cross-faction mediation events completed;
- player rejected a “rank everyone” spectacle;
- the group has established practical boundaries and shared responsibilities.

The Accord ending is warm, comic, and intentionally non-exclusive, but no character loses agency.
