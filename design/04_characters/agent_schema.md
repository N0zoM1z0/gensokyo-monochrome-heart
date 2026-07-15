# Character Agent Integration Schema

## Purpose

The agent layer proposes **one beat at a time**. It does not own plot structure, route gates, canon facts, rewards, or final localization. Authored event data supplies the objective and legal actions; the character agent supplies a voice-consistent response candidate.

## Required context packet

```yaml
scene_id: shrine.empty_cushion.03
speaker_id: reimu_hakurei
location_id: hakurei_shrine.veranda
local_time: dusk
privacy: private
relationship:
  trust: 2
  ease: 3
  respect: 2
  spark: 1
  strain: 0
player_tone: patient
event_objective: Reimu must acknowledge the unused second cup without confessing directly.
content_origin:
  canon: 2
  fanon: 0
  original: 4
allowed_actions:
  - pour_tea
  - look_away
  - end_scene
memories:
  - shrine.second_cup
  - protagonist.returned_charm
```

## Generation sequence

1. Load the speaker's `skills.md`.
2. Load relationship edges involving every visible character.
3. Reject facts that are not in event data, memory state, or a marked project-original field.
4. Produce exactly one beat in the JSON schema.
5. Run the canon/fanon guardrail linter.
6. Run EN and JA editorial review separately.
7. Store accepted lines as authored localization; never generate at runtime in the shipped game.

## Hard rejection rules

Reject output when it:
- invents a private relationship as canon;
- repeats a meme as the whole characterization;
- removes a character's ability to refuse;
- turns injury, intoxication, medical care, coercion, or authority into automatic romantic consent;
- narrates a different character's thoughts;
- includes route numbers, affection values, or implementation terms in spoken dialogue;
- copies official dialogue or a fan translation beyond a short reference necessary for analysis;
- fails to express the immediate scene objective.

## Suggested linter checks

- signature phrase repetition across the last 20 lines;
- line-length outlier for the speaker;
- fanon-dial overflow;
- unsupported relationship claim;
- unearned intimacy relative to Trust/Ease/Spark;
- duplicate EN and JA rhythm rather than true localization;
- missing physical cue;
- state delta outside `-1..1`.
