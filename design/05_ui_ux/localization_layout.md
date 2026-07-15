# Localization Layout Rules

## 1. Source-of-truth policy

English and Japanese are parallel authored localizations. Neither is produced by mechanically translating the other at runtime. Event IDs, intent, state changes, actions, and timing cues are shared; line text is locale-specific.

## 2. String format

```csv
key,context,en,ja,max_width_px,notes
ui.map.travel,verb button,Travel,移動,48,imperative noun-style button
reimu.empty_cup.003,private dusk line,I simply hadn't put it away yet.,片づけてなかっただけよ。,214,understated denial
```

No scene script contains display text. Text is referenced by key.

## 3. Expansion and reflow

- Author English against 85% of available width.
- Japanese line length target: 18–26 full-width characters depending on panel.
- English dialogue target: 42–58 characters per line, three lines maximum before manual page break.
- Never shrink core dialogue below the minimum legible font; reflow or paginate.
- Names may use short display forms defined per locale.

## 4. Punctuation

English:
- typographic apostrophes/quotes only if the font supports them cleanly;
- em dash may be represented by spaced double hyphen in strict pixel font mode;
- ellipsis is three periods or a single supported glyph, consistently.

Japanese:
- full-width punctuation;
- kinsoku rules;
- restrained use of `……` and long vowels;
- honorific choices belong to relationship state, not literal English equivalence.

## 5. Voice consistency review

Every dialogue PR must answer:
- Does EN sound like the character rather than like translated anime shorthand?
- Does JA use a plausible register without overusing catchphrases?
- Is the emotional indirectness equivalent even where sentence structure differs?
- Are canon terms and spell-card names consistent with the project's terminology register?

## 6. Technical tests

- missing-key detector;
- width report at every supported UI scale;
- orphan punctuation detector for JA;
- accidental ASCII-only Japanese row detector;
- duplicate text with different keys report;
- screenshot tests in EN and JA;
- save/load across a locale switch.
