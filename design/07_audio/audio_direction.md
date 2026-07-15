# Audio Direction

## 1. Sonic thesis

The sound should feel like a lost monochrome handheld connected to a tiny live ensemble. The chip layer communicates rules; the acoustic layer communicates people. Comedy comes from timing and instrument choice, not novelty samples pasted over every joke.

## 2. Core palette

### Chip voices
- two pulse channels;
- one triangle/bass channel;
- one noise channel;
- optional 4-bit PCM accent for impacts and breath-like texture.

These are aesthetic constraints, not strict emulation of a single console.

### Acoustic voices
- upright or felt piano;
- small reed organ / harmonium;
- bamboo flute or recorder-like lead used sparingly;
- plucked strings: shamisen, koto, acoustic guitar, or prepared piano substitute;
- small drum, woodblock, hand percussion;
- solo violin/cello for route afterbeats;
- muted brass or low clarinet for mansion comedy;
- no full orchestral wall by default.

## 3. Arrangement architecture

Every major region receives three interoperable layers:
1. **Place** — loopable regional identity.
2. **Person** — a melodic or rhythmic fragment associated with the active character.
3. **Incident** — pulse, dissonance, or meter mutation.

The game mixes layers rather than hard-cutting whenever possible.

Example at the Hakurei Shrine:
- Place: dry woodblock, open fifth, sparse pulse.
- Reimu person layer: compact phrase implying “Maiden's Capriccio.”
- Empty Cup incident: one missing beat every fourth bar.
- Afterbeat: incident layer stops; acoustic instrument finishes the missing beat.

## 4. Music states

```text
CALM → CURIOUS → ESCALATION → MODE INTRO → MODE ACTIVE → CLEAR/LOSS → AFTERBEAT
```

Transitions align to bar boundaries except emergency combat. A cue must provide:
- 2-bar intro;
- seamless 16/32-bar loop;
- 1-bar danger transition;
- clear sting;
- loss sting without comic humiliation;
- 4–8 bar afterbeat tail.

## 5. Mode identity

### Exploration
70–120 seconds per loop, low melodic density, strong environmental rhythm.

### Dialogue
Region loop remains. Character phrase appears as a 1–2 instrument layer. Private scenes remove percussion rather than adding romantic strings automatically.

### Minigame
Clear beat grid and audible success/failure units. Must have a non-audio timing assist.

### Danmaku
145–175 BPM typical, but pattern readability determines subdivision. Bullet density is not scored with indiscriminate note density.

### Fighter
120–160 BPM with strong 8/16-bar phrase landmarks for rounds and spell breaks. Avoid long intros.

### Afterbeat
20–45 seconds, often non-looping. This is where an arrangement may quote the most recognizable melodic fragment, quietly and without spectacle.

## 6. Comedy

Use:
- sudden removal of one channel;
- overly formal cadence for trivial labor;
- percussion object linked to a prop;
- one-beat delayed response;
- motif collision between two characters.

Avoid:
- slide whistle on every fall;
- record scratch as universal punchline;
- loudness as the joke;
- meme audio with unclear rights.

## 7. Dynamic mixing

- music ducks 2–4 dB under important dialogue, not 12 dB;
- bullet SFX are voice-limited and pitch-clustered by family;
- graze sits above shot noise but below warnings;
- off-screen threat warning occupies a distinct mid band;
- low dynamic-range mode limits transient peaks;
- mono mode preserves attack-direction cues through rhythm and icon feedback.

## 8. Silence

Silence is an authored cue. Use it when:
- Aya lowers the camera;
- Sakuya allows a clock tick to pass;
- Kaguya accepts the next morning;
- Youmu lets a petal land;
- the protagonist closes a memory thread.

A silence cue still contains room tone so it does not feel like an audio failure.
