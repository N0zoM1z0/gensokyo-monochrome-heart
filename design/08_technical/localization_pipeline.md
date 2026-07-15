# Localization Pipeline

## 1. Languages

Launch languages: English (`en`) and Japanese (`ja`). Both are first-class source languages for character writing. Interface keys share one semantic definition.

## 2. Source files

Use UTF-8 CSV/PO-compatible source generated from a content database. Recommended review columns:

```text
key,context,speaker,event_id,en,ja,max_width_px,origin,review_en,review_ja,notes
```

Godot import artifacts are generated. Translators do not edit `.translation` binaries.

## 3. Key policy

- semantic stable keys;
- no English sentence used as key;
- arguments are named (`{count}`, `{item_name}`), not positional;
- plural logic remains minimal but uses locale-aware formatting;
- character names and terms have a terminology table;
- spell-card titles may have authored locale-specific punctuation.

## 4. Build steps

1. Export all required keys from events/UI/data.
2. Merge with localization database.
3. Fail on missing source strings.
4. Import EN and JA translations.
5. Generate width/line-count report at each UI scale.
6. Generate screenshot matrix for critical screens.
7. Run orphan punctuation and unsupported-glyph checks.
8. Package only approved rows.

## 5. Japanese-specific QA

- kinsoku line breaking;
- full-width punctuation consistency;
- honorific and pronoun continuity across route bands;
- no accidental overuse of signature particles;
- character name readings and official terminology reviewed;
- font contains required kanji and symbols;
- vertical text is not required in v1; decorative signs use bespoke art where needed.

## 6. English-specific QA

- avoid translationese and generic “anime voice”;
- use contractions according to character register;
- keep dry humor dry;
- do not explain Japanese cultural objects inside emotional dialogue;
- use glossary or environmental context instead;
- check line length separately from grammar.

## 7. Runtime locale switch

Switching locale:
- updates all visible UI and current dialogue beat;
- rebuilds font fallback and line layout;
- preserves choice focus and event state;
- does not restart music or mode;
- is safe during pause, dialogue, and Journal;
- may be disabled only during deterministic screenshot capture.

## 8. Pseudolocalization

Provide:
- expanded Latin pseudo-locale at +35%;
- bracketed key-visibility mode;
- dense Japanese glyph stress mode;
- right-to-left is not a launch target but UI code must avoid unnecessary hard-coded left assumptions.
