# M11 Authoring and Debug Tool Evidence

M11 keeps author edits in JSON/CSV data and routes validation and preview through production loaders, simulations, renderers, save migration, and audio state code. The authoring commands do not publish a draft into reviewed runtime indexes.

| Taskbook tool | Entry point | Automated evidence |
| --- | --- | --- |
| Event Graph Previewer | `scripts/author_event.sh --action=preview` | all reachable branches, effects, mode results, rewards, journals, and outcomes render deterministically |
| Dialogue Previewer EN/JA | `author_event.sh --action=preview --locale=en\|ja` | edited EN and JA strings appear only in their requested locale |
| Content dependency graph | `author_event.sh --action=dependencies` | typed event/node/beat/localization edges are deterministic |
| Character skills browser/output validator | `scripts/character_authoring.sh` | all 71 contracts are discoverable; schema and single-facet state rules reject invalid output |
| Localization width report | `author_event.sh --action=width-report` | EN/JA at 100% and 150% use approved fonts, wrapping, and Japanese kinsoku rules |
| Spot fixture launcher | `scripts/authoring_workbench.sh --action=launch` | the typed registry exposes exploration, minigame, danmaku, fighter, and full-slice states |
| Bullet Pattern Lab | `scripts/bullet_pattern_lab.sh` | remapped draft IDs, closed component vocabulary, density reports, deterministic full simulation, and four one-bit captures |
| Fighter hitbox/frame viewer | workbench targets `scene.fighter.hitbox` and `scene.fighter.training` | reviewed fighter JSON drives boxes, frame data, and input history |
| Save migration harness | workbench target `save.v1_route_affinity` | production migration returns schema 2 and exposes the typed state inspection |
| Screenshot matrix runner | workbench `--action=screenshot` and `scripts/capture_m11_screenshots.sh` | exact 320×180 synchronized captures pass one-bit validation |
| Legal test-tone audition | workbench `tone.*` targets | generated sine/harmonic states use `AdaptiveTestTonePlayer`; no external recording is loaded |

## Nonprogrammer acceptance rehearsal

`TestEventAuthoringService` performs the taskbook acceptance path without changing GDScript:

1. duplicate the reviewed Empty Cushion bundle into an isolated draft;
2. remap all event-private stable IDs;
3. edit an interactable object ID, final outcome, English title, and Japanese title in JSON/CSV;
4. validate the edited bundle through the production schema and graph rules;
5. render both locales and prove the edited object/result/text appears;
6. generate deterministic dependency and width reports;
7. introduce a missing beat and prove validation identifies its exact source node.

`TestBulletPatternLab` repeats the same data-only proof for danmaku: duplicate and remap the reviewed definition, edit timing and speed fields, validate/report, run the complete fixed-step simulation twice with an identical snapshot, and reject an unsupported component.

The complete project gate is:

```bash
DISPLAY=:0 GODOT_BIN="$HOME/.local/bin/godot" ./scripts/verify_project.sh
```

The gate imports the project cleanly, runs all unit/integration and authoring CLI contracts, validates registered scenes and exact pixel alignment, captures the M11 visual matrix, and checks every generated capture for the one-bit palette.
