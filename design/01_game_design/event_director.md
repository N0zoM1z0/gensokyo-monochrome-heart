# Event Director

## Purpose

The Event Director selects which authored events are offered. It never procedurally writes dialogue.

## Selection score

An available event receives weighted scores for:
- chapter relevance
- route continuity
- time-of-day preference
- region freshness
- unresolved Strain
- ensemble variety
- player-deferred invitation
- recent mode diversity
- seasonal condition
- required character presence

A deterministic tie-breaker uses the profile seed and day index.

## Anti-repetition

Do not offer:
- the same mechanical mode three times in a row;
- the same lead character in every time slot;
- two high-intensity events without a low-intensity option;
- a private route event immediately after a public humiliation event unless it is a repair scene.

## Invitation collisions

When two characters invite the player to the same slot:
- the player may choose one;
- negotiate a combined event if authored;
- postpone one with an honest message;
- disappear without notice, which creates Strain.

There is no hidden “correct” schedule.

## Ambient events

Short no-slot scenes:
- a note under a teacup;
- a newspaper headline;
- a changed object;
- two characters arguing in the background;
- a weather cue;
- an NPC passing through.

Ambient events should make the world feel active without exhausting the player.

## Debug controls

Developer panel must allow:
- force event by ID;
- set route facets;
- set chapter/time/weather;
- inspect why an event is unavailable;
- print selection scores;
- clear or add rumors;
- replay afterbeat only.
