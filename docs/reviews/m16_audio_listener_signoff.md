# M16 Real-Device Audio Listener Sign-off

Status: owner-waived on 2026-07-17. This real-device listening worksheet remains
available for a later release-quality pass, but it is not an M16 or project
completion gate under the owner's explicit direction. Automated tests must not
claim that a human listener completed it.

## Setup

Use a normal desktop build with a real audio driver. Begin at a comfortable,
moderate system volume; do not raise the volume to compensate for an inaudible
cue until that failure has been recorded.

Review on both:

- laptop or monitor speakers;
- ordinary stereo headphones.

On each device, exercise the four runtime mixes available in Options:

1. default;
2. Mono Audio enabled;
3. Low Dynamic Range enabled;
4. Mono Audio and Low Dynamic Range enabled together.

Confirm that each toggle changes the live mix, survives Apply and relaunch, and
returns to its opening value after Cancel.

## Music families

For each row, listen to the place, person, and incident states long enough to
hear a transition and one complete loop. A passing family has no click, gap, or
large loudness jump; each foreground stem remains distinguishable without
masking warnings or dialogue.

| Family | Runtime coverage | Speakers | Headphones | Notes |
| --- | --- | --- | --- | --- |
| Hakurei Shrine | shrine, Reimu, Marisa, border, duel | [ ] | [ ] | |
| Scarlet Devil Mansion | foyer, gate, library, Remilia, knives | [ ] | [ ] | |
| Youkai Mountain | mountain, Nitori, Hina, Aya, Sanae, Tenshi | [ ] | [ ] | |
| Eientei / Bamboo | forest, Tewi, Reisen, Eirin, Kaguya | [ ] | [ ] | |
| Hakugyokurou | garden, Youmu, Yuyuko, Yukari, feast | [ ] | [ ] | |

Record whether the person and incident layers read as intentional variations
of the same location identity. In particular, judge the documented Marisa,
Sanae, and Tenshi thematic fallbacks rather than accepting them by filename.

## SFX cues

Trigger every cue in gameplay, including rapid repeats where possible. A cue
passes only when its purpose is recognizable in all four mixes and both output
devices.

| Cue | Purpose to verify | Speakers | Headphones | Notes |
| --- | --- | --- | --- | --- |
| UI focus | navigation movement | [ ] | [ ] | |
| UI confirm | accepted action | [ ] | [ ] | |
| UI cancel | backed-out action | [ ] | [ ] | |
| save begin | checkpoint starts | [ ] | [ ] | |
| save end | checkpoint completes | [ ] | [ ] | |
| warning threat | highest-priority danger | [ ] | [ ] | |
| bullet transient | discrete hostile shot | [ ] | [ ] | |
| bullet group loop | sustained pattern | [ ] | [ ] | |
| danmaku graze | near-miss feedback | [ ] | [ ] | |
| combat impact | fighter hit confirmation | [ ] | [ ] | |
| player damage | player-critical failure | [ ] | [ ] | |
| ambience region bed | environmental context | [ ] | [ ] | |

## Runtime mix decisions

Record PASS or FAIL for each decision and include the scene/state used for any
failure.

- [ ] Warning threat remains audible over the densest bullet-group loop.
- [ ] Player damage is unmistakable without becoming painfully loud.
- [ ] Dialogue ducking makes speech space without making music disappear.
- [ ] Rapid combat impacts respect the voice limit without harsh chatter.
- [ ] Save begin/end cues are distinct but do not outrank danger warnings.
- [ ] Mono preserves every direction-critical cue's visual equivalent.
- [ ] Low Dynamic Range reduces jumps while preserving cue priority.
- [ ] Ten minutes of repeated gameplay produces no notable listening fatigue.
- [ ] Mute remains absolute across transitions and live option changes.

## Sign-off

Reviewer:

Date and build/commit:

Devices:

Decision: PASS / FAIL

Failure notes and reproduction steps:
