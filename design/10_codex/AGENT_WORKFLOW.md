# Character-Agent Authoring Workflow

## Purpose

The 71 `skills.md` profiles are an offline co-writing library. They constrain drafts; they do not make canon claims or replace editors.

## Input packet

```yaml
speaker_id: char.reimu_hakurei
visible_characters:
  - char.marisa_kirisame
scene:
  id: evt.hkr.empty_cushion
  location: loc.hakurei_shrine.veranda
  time: dusk
  privacy: private
state_bands:
  trust: open
  ease: familiar
  respect: steady
  spark: low
  strain: low
player_tone: patient
objective: Acknowledge the second cup through logistics, not confession.
allowed_actions:
  - slide_cup
  - pour_tea
  - look_away
memory_tags:
  - shrine.second_cup
origin_budget:
  canon: 1
  fanon: 0
  original: 4
```

## Required output

Validate against `04_characters/agent_schema.json`. Generate one beat only. Never ask an agent to write an entire route in one pass.

## Review rubric

Score 0–2:
- canon anchors;
- immediate motive;
- voice rhythm EN;
- voice rhythm JA;
- relationship accuracy;
- autonomy;
- indirectness appropriate to character;
- physical/environment cue;
- fanon discipline;
- boundary discipline;
- event objective;
- originality/no copied line.

Any zero is rejection. A total below 20/24 requires revision.

## Automated lint

- schema;
- unsupported IDs;
- line length;
- signature phrase frequency;
- fanon terms against character ceiling;
- hidden numeric/meta language;
- prohibited explicit/coercive patterns;
- duplicated line similarity;
- nonverbal cue present;
- delta range.

Automated lint does not certify canon.

## Provenance record

Accepted rows store:
- author/editor;
- whether an agent draft was used;
- model/tool/version if policy requires;
- date;
- character/canon reviewer;
- EN reviewer;
- JA reviewer;
- content origin tags;
- source notes.

## Shipping rule

The game performs no network generation. Only reviewed localized strings ship. Deleting the authoring tool or API credentials must not affect the build.
