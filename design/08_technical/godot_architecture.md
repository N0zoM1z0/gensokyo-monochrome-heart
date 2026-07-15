# Godot Architecture

## 1. Architectural goals

- Data-authored narrative and encounters.
- A single state model shared by exploration, dialogue, minigames, danmaku, and fighter modes.
- Deterministic event results and reproducible combat patterns where practical.
- Each mode can boot independently from a fixture.
- UI observes presentation state and emits commands; it does not own story flags.
- No character-specific behavior hard-coded into generic mode controllers.
- Every content reference is validated before export.

## 2. Project layers

```text
Domain          Pure data and rules; minimal Node dependencies
Application     Use cases, command handlers, state transitions
Presentation    Scenes, UI, animation, audio, camera
Infrastructure  File IO, localization import, saves, platform services
Content         JSON/Resources, dialogue, events, character skills, assets
Tools           Validators, importers, event preview, screenshot harness
```

The dependency direction points inward. Presentation may call Application. Domain must not load scenes or access singletons directly.

## 3. Autoloads

| Autoload | Responsibility | Must not do |
|---|---|---|
| `GameKernel` | owns active `GameState`, command dispatch, mode transitions | draw UI, parse dialogue text |
| `ContentDB` | typed lookup of characters, locations, events, items, cues | mutate game state |
| `SceneRouter` | additive scene loading and transition handshake | decide narrative outcomes |
| `SaveService` | serialize, migrate, backup, checksum | retain Node references |
| `SettingsService` | controls, accessibility, audio, locale | write story flags |
| `LocalizationService` | key lookup, formatting, locale switch notifications | machine-translate text |
| `AudioDirector` | adaptive music state and buses | determine event branches |
| `EventBus` | typed decoupled signals for presentation | become a global dumping ground |
| `DebugConsole` | dev-only commands and state inspection | exist in release unless disabled |

Prefer explicit dependency injection for systems that can be instantiated in tests. Autoloads are narrow gateways, not service locators for everything.

## 4. Core state

```gdscript
class_name GameState
extends RefCounted

var schema_version: int
var profile_id: StringName
var chapter_id: StringName
var day: int
var time_slot: StringName
var current_location: StringName
var protagonist: ProtagonistState
var characters: Dictionary[StringName, CharacterState]
var regions: Dictionary[StringName, RegionState]
var flags: Dictionary[StringName, Variant]
var inventory: InventoryState
var rumors: Dictionary[StringName, RumorState]
var journal: JournalState
var rng: DeterministicRngState
```

Character relationship facets:
- Trust;
- Ease;
- Respect;
- Spark;
- Strain.

Store bounded integers internally, but never display them directly. Event predicates use semantic bands (`low`, `open`, `high`) resolved by Domain rules.

## 5. Command flow

```text
Input/UI
→ UICommand or GameplayCommand
→ GameKernel.dispatch(command)
→ mode/application handler validates
→ Domain mutation/result
→ GameStateChanged event
→ presentation refresh
→ optional save checkpoint
```

Commands are serializable where useful for replay and debugging.

Examples:
- `SelectSpotCommand`
- `ChooseToneCommand`
- `ResolveMinigameCommand`
- `AcceptLossCommand`
- `CompleteDanmakuPhaseCommand`
- `EquipKeepsakeCommand`
- `AdvanceTimeCommand`

## 6. Mode contract

Every mode scene implements:

```gdscript
class_name GameMode
extends Node

signal ready_for_input
signal mode_completed(result: ModeResult)
signal checkpoint_requested(reason: StringName)

func configure(context: ModeContext) -> void:
    pass

func suspend() -> void:
    pass

func resume() -> void:
    pass

func capture_debug_state() -> Dictionary:
    return {}
```

A `ModeResult` contains authored outcome tags, performance bands, optional assist usage, and replay telemetry. It never mutates route state itself; the event interpreter consumes it.

## 7. Scene loading

Use an always-resident shell:

```text
Main.tscn
├── WorldViewport (320×180)
├── ModeHost
├── PersistentUI
├── AudioRoot
└── TransitionRoot
```

Mode scenes are loaded asynchronously, configured off-screen, then swapped on a transition boundary. Keep UI and audio persistent to avoid pops and lost focus.

## 8. Content format

Use a hybrid:
- JSON/CSV for text-heavy, reviewable content;
- custom typed `Resource` classes for editor-authored combat patterns and minigame parameters;
- generated `.tres` indexes for fast runtime lookup;
- schemas in `09_data/schemas/`;
- stable string IDs, never file paths, in save data.

## 9. Determinism

- Seed event RNG from profile seed + event ID + attempt index.
- Pattern scripts use deterministic timers and no unseeded global random calls.
- Record input and seed for combat reproduction.
- Cosmetic particles may be nondeterministic but cannot affect collision.
- Time-step combat at fixed 60 Hz; presentation interpolation is optional.

## 10. Error strategy

In development:
- fail fast on missing IDs, invalid enum values, impossible branches, or duplicate localization keys;
- show an in-game diagnostic card with event/node path;
- preserve a state dump.

In release:
- return to a safe checkpoint;
- write a compact log;
- show a nontechnical error code;
- never silently mark an event complete.
