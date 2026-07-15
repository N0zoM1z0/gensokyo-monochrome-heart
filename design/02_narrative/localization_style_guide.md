# English / Japanese Localization Style Guide

## General

The English and Japanese scripts are parallel performances, not word-for-word mirrors. Preserve:
- intent;
- status relationship;
- joke function;
- emotional turn;
- gameplay information.

## Names

English UI:
- Reimu Hakurei
- Marisa Kirisame
- Sakuya Izayoi

Japanese UI:
- 博麗 霊夢
- 霧雨 魔理沙
- 十六夜 咲夜

Use the common Western order in English and Japanese order in Japanese.

## Japanese voice principles

- Do not append signature particles to every line.
- Marisa's `だぜ` is a cadence tool, not punctuation.
- Politeness levels must reflect relationships and context.
- Reimu is plain and direct, not a generic tsundere.
- Sakuya's formal register can sharpen rather than soften a threat.
- Yuyuko's lightness should not become baby talk.
- Aya may sound professionally bright while steering the answer.
- Tenshi's imperiousness should retain comic self-awareness.
- Kaguya may switch from elegant courtly phrasing to casual challenge, but not every line.
- Eirin is calm, exact, and capable of dry humor.

## English voice principles

Avoid:
- excessive Japanese honorifics in ordinary English lines;
- literal `ze` or `daze`;
- generic anime catchphrases;
- contractions removed from every formal character;
- replacing all Japanese social nuance with sarcasm.

Honorific mode may be offered as an optional localization setting.

## Line limits

At 320 × 180:
- English: target 42 characters per line, maximum 3 lines per box
- Japanese: target 20 full-width characters per line, maximum 3 lines
- character name: 18 Latin characters or 8 full-width characters before compact mode
- long terms use glossary popups, not wall-of-text dialogue

## Japanese line breaking

Implement kinsoku shori:
- do not begin a line with closing punctuation, small kana, prolonged sound mark, or iteration mark;
- do not end a line with opening punctuation;
- preserve ruby or glossary markers as atomic spans.

## Choice localization

Choices represent tone. Keep them short:
- Direct / はっきり言う
- Playful / 冗談で返す
- Patient / 黙って待つ
- Defiant / 反論する

## Sound effects

Use sparse manga-style SFX only when visually useful:
- `カチ`
- `サッ`
- `ドン`
- `ふわ`
English may retain a stylized equivalent or use animation without text.

## Translation QA

Every event requires:
- semantic review;
- character-voice review;
- UI overflow test at 100% and 150%;
- input-glyph test;
- punctuation normalization;
- glossary consistency;
- screenshot diff in both languages.
