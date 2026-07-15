# Game Design Document

## 1. Product definition

**Gensokyo: Monochrome Heart** is a single-player, story-forward Touhou Project fan game combining:

- a Gensokyo world map with time-of-day planning;
- side-view 2D spot exploration;
- dialogue and relationship choices;
- compact location-specific minigames;
- readable retro danmaku encounters;
- short one-on-one fighting-game duels.

A first playthrough is estimated at 15–22 hours. A route-completion playthrough is 30–45 hours. Events are intentionally short and replayable.

## 2. Player role

The protagonist is an ordinary adult human from the Outside World whose prior life in Gensokyo may have been real, dreamed, or both. Their visual identity is deliberately understated and customizable only through name and pronouns. They are not secretly stronger than the cast.

Their meaningful competencies are:

- noticing mundane details;
- remembering what others overlook;
- preparing food and tea;
- mediating conflicting priorities;
- learning spell-card etiquette;
- being willing to help without pretending to be indispensable.

## 3. Core verbs

- **Travel** between regions
- **Observe** spots and character tells
- **Talk** through tone choices
- **Help** through location mechanics
- **Graze** and survive danmaku
- **Duel** under spell-card-style rules
- **Record** memories and rumors
- **Return** to changed places

## 4. Session loop

### Day start
At the protagonist's room or current lodging:
- review letters, rumors, and invitations;
- inspect route threads;
- select one main destination and one optional late event;
- equip two Keepsakes and one Tea Blend.

### Region map
Choose a spot. Each spot previews:
- active characters;
- weather or incident condition;
- estimated length;
- mode likelihood;
- unresolved rumor icons.

### Spot event
Explore, converse, resolve, afterbeat.

### Day end
- write one journal sentence;
- characters may leave notes or change a shared object;
- routes and regional conditions advance;
- autosave.

## 5. Structure

### Main campaign
Six chapters:
1. Dream Wakes Twice
2. The Shrine Keeps an Empty Place
3. A Clock Loses One Minute
4. Tomorrow Arrives as a Newspaper
5. The Bamboo Night Refuses to End
6. Petals Remember How to Fall

### Finale
The Border Behind the Screen.

### Postgame
- route epilogues;
- seasonal incidents;
- Ensemble Accord;
- Outside World memory episodes;
- challenge danmaku and fighter ladders.

## 6. Launch route scope

Deep romance-capable routes:
- Reimu
- Marisa
- Sakuya
- Remilia
- Patchouli
- Youmu
- Yuyuko
- Aya
- Eirin
- Kaguya
- Sanae
- Tenshi

Support routes:
- every other character in the v1 roster, usually 2–4 events.

## 7. System integration

### Shared state
All modes read and write the same state:
- character Resonance facets;
- region condition;
- rumor flags;
- Keepsakes;
- time of day;
- incident chapter;
- player comfort settings.

### Example
At Scarlet Devil Mansion's kitchen:
1. Sakuya insists everything is under control.
2. Player notices one tray is repeatedly reset.
3. Side-view exploration reveals a lost minute.
4. Patient or Defiant dialogue changes the explanation.
5. A time-grid serving minigame begins.
6. Failure can escalate into a knife-pattern danmaku scene.
7. Success unlocks a quiet kitchen afterbeat.
8. The same event grants Sakuya's “Unfinished Checklist” Keepsake and changes later Remilia dialogue.

## 8. Design targets

- 60 FPS on modest integrated graphics
- 320 × 180 internal render
- keyboard and controller parity
- one-handed dialogue navigation option
- no more than six active UI elements in action scenes
- load from title screen to gameplay under five seconds on target hardware
- deterministic event resolution where practical
- data-authored content; no story text hard-coded in scene scripts

## 9. Economy

There is no grind-based currency economy.

Resources:
- **Time Slots:** morning, day, dusk, night
- **Margin:** danmaku resource earned through grazing
- **Rumors:** unlock or mutate events
- **Keepsakes:** contextual passive modifiers and conversation callbacks
- **Tea Blends:** one-day modifiers prepared from ingredients
- **Faith / Reputation / Appetite / Order:** local temporary meters, never global currencies

## 10. Failure

Failure is a branch, not a dead end:
- minigame failure produces a messier afterbeat;
- danmaku defeat allows retry, Assist Clear, or “accept the loss”;
- duel loss may reveal a character's restraint or pride;
- route progress never requires high difficulty;
- challenge rewards are cosmetic journal stamps, alternate patterns, and music-player notes.

## 11. Save model

- three manual slots
- rolling autosaves at day start and before mode transitions
- event checkpoint inside longer scenes
- per-profile settings
- versioned JSON or Godot Resource save with migration layer
- route replay from the Journal after first completion

## 12. Monetization and release posture

Recommended:
- paid downloadable fan game with free demo, subject to current guidelines;
- no gacha, no loot boxes, no paid romance;
- no always-online requirement;
- no AI-generated final art or voice assets without explicit project policy and contributor consent.

## 13. Definition of fun

The game succeeds when the player:
- laughs because a mechanic expresses a character flaw;
- recognizes an incoming pattern from the environment;
- chooses a tone based on understanding rather than metagaming;
- remembers a tiny afterbeat more strongly than a boss explosion.
