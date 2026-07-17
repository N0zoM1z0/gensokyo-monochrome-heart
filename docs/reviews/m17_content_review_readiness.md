# M17 Content Review Readiness Audit

Date: 2026-07-17
Decision: automated evidence is ready for editorial review; this is **not** a
human EN/JA, character, or canon sign-off.

## Automated evidence

`scripts/validate_m17_review.py` verifies the reviewable source layer without
claiming to judge voice or canon. Its current normal pass establishes:

- 85 shipped event graphs have a visible cast, bilingual event title/dialogue /
  choice/objective references, nonverbal dialogue cues, positive width budgets,
  origin metadata, and explicit comfort metadata;
- all 71 runtime characters resolve to a `skills.md` profile with a parsed
  Maximum fanon dial;
- every graph's fanon value is no greater than the most conservative ceiling of
  its visible cast;
- 1,488 canonical bilingual localization rows resolve, with accepted
  `Canon`/`Fanon`/`Original`/`UI` origin labels;
- sensitive review markers are inventoried rather than silently accepted:
  consent 13, medical 3, patient 73, photo 2, privacy 1, romance 18.

The tool also lists six visible-character pairs that lack an explicit curated
relationship-graph edge. They are editorial prompts, not automatic failures:

- Eirin ↔ Tewi in Clinic Triage;
- Kaguya ↔ Reisen in Doctor Sleeps and Permanent Cure;
- Eirin ↔ Kosuzu and Kaguya ↔ Kosuzu in Practical Care;
- Patchouli ↔ Sakuya in Late by Three Minutes.

## Review boundary

The command deliberately passes in normal mode only for objective source-data
readiness. `--require-human-review` fails while the named character, EN, and JA
reviewer manifest is absent; it must continue to fail until actual editors enter
all eleven M17 passes for every event. This prevents automated content lint from
being presented as canon, voice, consent, or localization approval.

```text
python3 scripts/validate_m17_review.py --report markdown
python3 scripts/validate_m17_review.py --require-human-review
```

The first command provides the reviewer-facing inventory. The second is the
future sign-off gate and currently fails by design because no human review
manifest has been supplied.

## Human-review handoff

Generate the complete pending template with:

```text
python3 scripts/generate_m17_review_template.py
```

It writes `content/reviews/m17_human_reviews.template.json` with all 85 event
IDs, blank named reviewer fields, and all eleven passes set to `pending`. The
template is deliberately not at the strict-gate path. Only after actual
reviewers complete every event should a coordinator copy it to
`content/reviews/m17_human_reviews.json`, enter names/notes, and set each
reviewed pass to `approved`.
