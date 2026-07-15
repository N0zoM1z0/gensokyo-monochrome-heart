# Scene Tree and Repository Layout

## 1. Recommended repository

```text
project.godot
addons/
assets/
  art/
  audio/
  fonts/
content/
  characters/
  locations/
  events/
  dialogue/
  combat/
  minigames/
  localization/
  indexes/
schemas/
src/
  autoload/
  domain/
  application/
  presentation/
    shell/
    ui/
    exploration/
    dialogue/
    danmaku/
    fighter/
    minigames/
  infrastructure/
  tools/
tests/
  unit/
  integration/
  fixtures/
  screenshots/
export_presets.cfg
```

## 2. Persistent shell

```text
Main (Node)
├── FixedResolutionRoot (SubViewportContainer)
│   └── GameViewport (SubViewport, 320×180)
│       ├── ModeHost (Node)
│       ├── WorldCanvas (CanvasLayer 0)
│       ├── HUDCanvas (CanvasLayer 20)
│       ├── ModalCanvas (CanvasLayer 40)
│       └── TransitionCanvas (CanvasLayer 80)
├── InputRouter
├── AudioRoot
└── DevOverlay [development only]
```

Viewport stretch uses integer scaling where possible. Noninteger window sizes letterbox rather than blur in pixel-perfect mode.

## 3. Exploration mode

```text
ExplorationMode
├── RegionRoot
│   ├── TileMapLayers
│   ├── Props
│   ├── Characters
│   ├── InteractiveRegistry
│   ├── Hazards
│   └── Foreground
├── PlayerAvatar
├── CompanionController
├── CameraRig
├── ObjectiveController
├── AmbientDirector
└── ExplorationHUDAdapter
```

Interactive objects register typed actions rather than requiring the player controller to know object classes.

## 4. Dialogue mode overlay

Dialogue can run over exploration or as a dedicated composition.

```text
DialoguePresenter
├── PortraitStageLeft
├── PortraitStageRight
├── DialoguePanel
├── ChoiceFan
├── CueLayer
├── Backlog
└── AutoAdvanceTimer
```

The presenter consumes `DialogueBeat` objects. It cannot advance the event interpreter until text, required cues, and choice result are complete.

## 5. Danmaku mode

```text
DanmakuMode
├── Arena
│   ├── Background
│   ├── EnemyLayer
│   ├── BulletRenderer
│   ├── ItemRenderer
│   ├── Player
│   └── CollisionWorld
├── PatternRuntime
├── PhaseDirector
├── ReplayRecorder
├── AssistController
├── CameraRig
└── DanmakuHUDAdapter
```

Bullets are data structs in pools, not one `Node2D` per bullet. Rendering may use a custom canvas draw path or batched instances after profiling.

## 6. Fighter mode

```text
FighterMode
├── Stage
├── FighterA
├── FighterB
├── HitboxWorld
├── RoundDirector
├── InputBufferA
├── InputBufferB / AIController
├── CameraRig
├── ReplayRecorder
└── FighterHUDAdapter
```

Simulation is fixed-step and independent of animation playback. Animation emits authored frame events but is not the source of truth for hit timing.

## 7. Minigame host

```text
MinigameMode
├── MinigameHost
│   └── <Loaded Minigame>
├── TutorialOverlay
├── AssistController
└── ResultPresenter
```

Every minigame implements one interface and declares controls, estimated duration, assist options, and scoring bands in data.

## 8. Tool scenes

- Event Graph Previewer;
- Dialogue Previewer EN/JA;
- Character Agent Output Validator;
- Bullet Pattern Lab;
- Fighter Hitbox Viewer;
- Localization Width Report;
- Save Migration Harness;
- Screenshot Matrix Runner;
- Content Dependency Graph.
