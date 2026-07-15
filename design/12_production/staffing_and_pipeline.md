# Staffing and Pipeline

## 1. Minimum responsible roles

One person may hold several roles, but every responsibility needs an explicit owner.

- Producer / scope owner
- Game director / systems design
- Lead engineer
- Narrative lead
- Character/canon editor
- English editor
- Japanese writer/editor
- Pixel art director
- Character animator
- Environment/UI artist
- Composer/arranger
- Sound designer / implementer
- QA lead
- Accessibility reviewer
- Build/release and rights/provenance owner

## 2. Recommended small-team shape

Core:
- 1 producer/director;
- 2 engineers (systems/tools and gameplay/modes);
- 1 narrative/character lead;
- 1 bilingual or paired EN/JA editor capacity;
- 2 pixel artists/animators;
- 1 composer/sound designer hybrid or two contractors;
- 1 embedded QA/content operations role.

External review:
- Touhou canon readers;
- Japanese native editor;
- accessibility testers;
- legal/platform consultation where needed;
- guest illustrators/arrangers with written agreements.

## 3. Handoff pipeline

```text
Pitch
→ canon/fanon check
→ graybox event graph
→ fixture dialogue
→ mechanical prototype
→ narrative draft EN/JA
→ character review
→ implementation integration
→ art/audio request
→ accessibility pass
→ playtest
→ polish
→ provenance/license check
→ content lock
```

No department waits for “all writing” or “all art” to finish. Produce vertical slices and region batches.

## 4. Event ownership

Each event has:
- narrative owner;
- implementation owner;
- character reviewer;
- EN/JA reviewers;
- art/audio request owner;
- QA owner;
- final producer sign-off.

The event tracker includes stable ID, state, blockers, text counts, asset list, cue list, review status, and build first/last verified.

## 5. Pull-request expectations

Code PR:
- design reference;
- tests;
- screenshots or replay when presentation changes;
- migration impact;
- performance note;
- no new dependency without approval.

Content PR:
- branch map;
- EN/JA rows;
- skills/relationship review;
- origin tags and fanon dial;
- clear/loss/assist results;
- comfort variants;
- screenshots;
- asset provenance.

## 6. Meeting cadence

- weekly playable build review, not slide-only status;
- biweekly scope/risk review;
- monthly canon/fanon consistency audit across recent content;
- milestone accessibility and rights gate;
- no daily meeting required for a small asynchronous team if tracker is current.

## 7. Contractor packet

Every contractor receives:
- exact deliverables and dimensions/formats;
- source and asset restrictions;
- fan-work context and unofficial status;
- payment and revision schedule;
- ownership/license terms including game and soundtrack/promotional use;
- credit name/text;
- confidentiality if applicable;
- AI/tool policy;
- delivery/provenance requirements.

## 8. AI-assisted work policy

Recommended:
- agent drafts only for internal ideation or structured validation;
- human review mandatory;
- no runtime generation;
- no final visual/audio asset generation without explicit contributor and project policy;
- provenance recorded where required;
- never use AI to imitate a living fan artist's style or launder official assets.
