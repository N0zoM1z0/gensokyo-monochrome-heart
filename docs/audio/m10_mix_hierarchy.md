# M10 Placeholder Audio Mix Hierarchy

The vertical slice uses original procedural tones, so this is a relative implementation contract rather than a final mastering claim.

| Role | Relative gain |
| --- | ---: |
| dialogue-critical cue / warning | -1 dB |
| player damage / bomb | -3 dB |
| combat impact / result | -5 dB |
| ordinary gameplay cue / graze | -8 dB |
| UI | -10 dB |
| ambience / footsteps / props | -14 dB |
| music bed | -10 dB |

During dialogue and four-tone choices, the music bed ducks another 3 dB. Mute remains absolute and restoring mute preserves the current duck state. Cue roles can be authored explicitly through `AudioCueIntent`; legacy placeholder cues use deterministic stable-ID inference.

Every procedural sound retains its localized visual-cue identity. Loudness is never the only warning or success/failure channel.

Before release mastering, validate the same ordering on laptop speakers, headphones, and a mono phone speaker, then add low-dynamic-range and mono options without weakening visual cues.
