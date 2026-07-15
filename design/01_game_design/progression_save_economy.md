# Progression, Keepsakes, Tea, and Save Economy

## Progression philosophy

The player grows by accumulating social context, not combat statistics.

## Keepsakes

Equip two per day. They provide contextual affordances, not raw damage.

Examples:
- **Repaired Cushion:** one extra Patient observation at shrine events.
- **Borrowed Mini-Hakkero Lens:** reveals unstable objects but may add a noisy complication.
- **Silver Pocket Watch Ribbon:** one timing retry in service or clock minigames.
- **Half-Phantom Thread:** displays paired-object relationships.
- **Unprinted Photograph:** prevents one rumor from becoming public.
- **Bamboo Game Token:** unlocks playful alternatives to formal challenges.

Every Keepsake has:
- source event;
- mechanical effect;
- dialogue tags;
- owner reaction;
- return/keep decision if narratively relevant.

## Tea Blends

At day start, choose one:
- **Plain Green Tea:** no modifier; some characters respect simplicity.
- **Roasted Tea:** easier timing windows.
- **Mushroom Infusion:** more Margin, stranger visual traces.
- **Moon Rabbit Tonic:** perception hints, higher Strain if overused.
- **Ghost Blossom Tea:** more optional spirit dialogue.
- **Mountain Herb Tea:** reduced wind push.

Tea is a small daily texture, not a crafting grind.

## Rumors

Rumors are structured facts with reliability:

```json
{
  "id": "rumor_sdm_missing_minute",
  "claim": "A corridor clock skips one minute at dusk.",
  "source": "aya",
  "reliability": 0.55,
  "privacy": "public",
  "mutation": 1
}
```

Rumors can:
- unlock events;
- alter NPC expectations;
- be corrected;
- become harmful when published;
- be deliberately left unresolved.

## Journal

The Monochrome Journal includes:
- map;
- character pages;
- route threads;
- event memories;
- rumor ledger;
- spell and duel practice;
- music cue notes;
- glossary;
- source/fanon label for lore-sensitive entries.

## Save safety

- autosave before event start;
- checkpoint before any mechanical mode;
- never autosave after a mutually exclusive choice without retaining the prior checkpoint;
- save migration tests required for every milestone;
- corrupted save fallback to last valid snapshot.
