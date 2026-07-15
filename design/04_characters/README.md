# Character Agent Library

This folder is the behavioral specification layer for **Gensokyo: Monochrome Heart**. Every character has an independent `skills.md` file designed for use by writers, narrative tools, gameplay designers, and agent-style content generation.

## What a character skill contains

Each profile defines:

1. **Canon identity anchors** — the minimum facts the project must not contradict.
2. **Portrayal contract** — temperament, active motives, scene role, and autonomy requirements.
3. **Voice model** — English and Japanese cadence, register, silence, and nonverbal behavior.
4. **Relationship anchors** — dynamics that should affect dialogue and event blocking.
5. **Canon / fanon / original control** — permitted joke intensity and mischaracterization guardrails.
6. **Romance and trust progression** — how intimacy grows without erasing the character's own life.
7. **Gameplay expression** — companion exploration skill, danmaku language, fighter identity, and event seeds.
8. **Agent runtime contract** — required inputs and a strict YAML-shaped output.
9. **Original sample lines** — cadence tests, not reusable catchphrases.
10. **Source notes** — confidence and research origin.

## Runtime rule

The `skills.md` file is a constraint document, not a prompt to imitate official text. The runtime must combine it with scene state, relationship facets, location conditions, and authored event objectives. It must never claim generated dialogue is official canon.

## Canon labeling

- **Canon**: supported by official games, profiles, music-room text, or print works.
- **Fanon**: a community joke or common interpretation. Every use has an intensity ceiling.
- **Original**: behavior invented for this game while respecting canon anchors.

Sparse-canon characters such as Koakuma require conservative writing. A lack of official detail is not permission to treat a popular fan version as fact.

## Launch depth

Twelve characters receive deep romance routes in v1: Reimu, Marisa, Sakuya, Remilia, Patchouli, Youmu, Yuyuko, Aya, Eirin, Kaguya, Sanae, and Tenshi. The remaining profiles support regional events, postgame episodes, cameos, danmaku encounters, or future route expansions.

## Machine-readable companions

- `roster.json` — indexed metadata for all profiles.
- `relationship_graph.json` — authored relationship edges with tone and design use.
- `agent_schema.json` — validation schema for generated character beats.
- `agent_schema.md` — human-readable integration rules.
