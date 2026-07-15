# Sound-Effect Catalog

## 1. Principles

- SFX must remain readable under dense music and bullet streams.
- A sound family shares envelope and material, not merely pitch.
- Important warnings have visual equivalents.
- Comedy uses timing and material contrast; never rely on copyrighted meme clips.
- Voice count is budgeted. Repeated shots and bullets are pooled and randomized within narrow bounds.

## 2. UI

| ID | Sound | Design |
|---|---|---|
| `ui_focus` | selection move | dry paper tick, two pitches |
| `ui_confirm` | confirm | stamp tap + short pulse |
| `ui_cancel` | cancel | paper slide backward |
| `ui_tab` | page switch | page flick with tonal click |
| `ui_disabled` | unavailable | muted block tap |
| `ui_choice_open` | tone choices appear | four quiet ticks fan outward |
| `ui_choice_commit` | choice accepted | knot pull / string snap-soft |
| `ui_journal_open` | Journal | cover thump, page breath |
| `ui_rumor_stamp` | rumor acquired | ink stamp and faint shutter |
| `ui_keepsake` | keepsake obtained | ceramic/metal/object-specific chime |
| `ui_save_begin` | autosave | pencil scratch start |
| `ui_save_end` | save complete | pencil lifts, tiny bell |
| `ui_error` | technical error | double low pulse, never loud |

## 3. Exploration

- footsteps: wood, stone, dirt, grass, snow, bamboo floor, mansion carpet, metal catwalk, cloud;
- landing light/heavy;
- cloth turn;
- ledge grab/release;
- door paper/wood/stone/metal/boundary;
- inspect sparkle;
- pickup small/large/fragile;
- cup set down;
- page turn;
- broom sweep;
- garden shears;
- knife on board;
- camera wind/shutter/develop;
- clock tick, skipped tick, restored tick;
- bamboo knock;
- spirit collect/release;
- petal landing;
- rumor whisper layer;
- companion skill ready/activate/end.

## 4. Danmaku

### Player
- focused shot;
- unfocused shot;
- option shot;
- bomb ready;
- bomb release;
- graze single;
- graze chain thresholds;
- life lost;
- extend;
- Margin gain/spend;
- assist activated.

### Bullet families
Each has spawn, pass, cancel, and impact variants:
- amulet;
- needle;
- orb;
- star;
- knife;
- butterfly;
- leaf;
- arrow;
- shard;
- plate;
- spirit;
- keystone.

Fast repeated bullets use one low-volume group loop plus sparse individual transients. Never play one full transient per visible bullet.

### Boss
- phase start;
- spell declaration stamp;
- phase break;
- enraged or rule mutation;
- timeout;
- clear;
- nonlethal defeat landing.

## 5. Fighter

- light hit flesh/cloth-neutral;
- heavy stamp impact;
- guard;
- guard break;
- air dash;
- ground dash;
- jump;
- counter;
- throw start/tech;
- wall/ground impact;
- Temperament gain/full/spend;
- spell-card declaration;
- round start/break/end.

Character layers:
- Reimu amulet paper and yin-yang ceramic;
- Marisa furnace ignition and beam pressure;
- Sakuya metal knife and clock vacuum;
- Remilia wing snap and spear air cut;
- Youmu sheathe, slash, spirit echo;
- Aya wind rip and camera capture;
- Kaguya treasure-specific materials;
- Tenshi stone crack and weather resonance.

## 6. Minigame signature sets

- tea steep, pour, cup warmth;
- donation-box coin and suspicious object;
- kitchen order bell, chop, plate, tray;
- library shelf slide, book flutter, spell seal;
- camera focus, shutter, plate develop;
- river/waterwheel valves and pressure;
- bamboo direction knocks;
- medicine grind, vial, wavelength tone;
- soul garden collect/release;
- food aroma lure and bite-offscreen;
- mask rotate and expression lock;
- ferry pole, coin, judgment stamp;
- haniwa formation click;
- back-door open/close/reverse.

## 7. Ambience beds

Ambience is authored as several randomized one-shots over a quiet bed, not a single obvious loop.

- shrine wind, crow, distant bell, kettle;
- mansion clock field, distant fairy steps, rain window;
- library paper, shelf creak, breath/room air;
- mountain wind strata, waterfall, rope tension;
- workshop waterwheel, ratchet, pipe knock;
- bamboo leaves, distant rabbit step, night insect;
- Hakugyokurou petal, garden rake, spirit whisper;
- village crowd, stall cloth, cart wheel;
- Former Hell furnace, crowd, rail cart;
- temple bell, ship wood, communal voices;
- Heaven high wind, peach leaf, distant thunder;
- Sanzu water, ferry wood, far flower field;
- Lunar Capital clean hum, perfect footstep reflection;
- Outside World train, ventilation, phone buzz, rain gutter.

## 8. Loudness targets

Final implementation values depend on middleware and mastering, but target relative hierarchy:
- dialogue-critical cue / warning: highest momentary priority;
- player damage and bomb: high;
- boss shots: medium-high;
- player repeated shots: low-medium;
- ambience: low;
- UI: consistent and audible without dominating.

Run tests on laptop speakers, headphones, and mono phone speaker. Provide a low dynamic-range mix.
