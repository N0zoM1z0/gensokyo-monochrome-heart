class_name AuthoringWorkbenchService
extends RefCounted
## Typed registry for M11 scene fixtures, save migration fixtures, and legal tones.

const DANMAKU_DEFINITION := "res://content/danmaku/boundary_stain.json"
const FIGHTER_DEFINITION := "res://content/fighter/reimu_marisa_duel.json"

var _targets: Array[WorkbenchTarget] = []


func _init() -> void:
	_register_scene(&"scene.exploration.live", &"exploration", "Exploration live", "res://src/presentation/exploration/ExplorationMode.tscn", "", &"live", "Hakurei Shrine spot exploration")
	_register_scene(&"scene.tea.tutorial", &"minigame", "Tea tutorial", "res://src/presentation/minigames/TeaTemperatureMode.tscn", "builtin://TeaTemperatureSimulation", &"tutorial", "Tea definition and tutorial controls")
	_register_scene(&"scene.tea.active", &"minigame", "Tea active", "res://tests/ui/fixtures/TeaTemperatureActiveFixture.tscn", "builtin://TeaTemperatureSimulation", &"active", "Active deterministic tea attempt")
	_register_scene(&"scene.tea.assist", &"minigame", "Tea assists", "res://tests/ui/fixtures/TeaTemperatureAssistFixture.tscn", "builtin://TeaTemperatureSimulation", &"active", "Tea attempt with authored assists")
	_register_scene(&"scene.danmaku.live", &"danmaku", "Boundary Stain live", "res://src/presentation/danmaku/BoundaryStainMode.tscn", DANMAKU_DEFINITION, &"live", "Playable three-phase definition")
	_register_scene(&"scene.danmaku.phase1", &"danmaku", "Boundary Stain phase 1", "res://tests/ui/fixtures/BoundaryStainPhase1Fixture.tscn", DANMAKU_DEFINITION, &"phase1", "Frozen phase-one review fixture")
	_register_scene(&"scene.danmaku.focus", &"danmaku", "Boundary Stain focus", "res://tests/ui/fixtures/BoundaryStainFocusFixture.tscn", DANMAKU_DEFINITION, &"focus", "Focus hitbox and Margin review")
	_register_scene(&"scene.danmaku.stress", &"danmaku", "Boundary Stain stress", "res://tests/ui/fixtures/BoundaryStainStressFixture.tscn", DANMAKU_DEFINITION, &"stress", "2,500-bullet renderer fixture")
	_register_scene(&"scene.fighter.live", &"fighter", "Compact fighter live", "res://src/presentation/fighter/CompactFighterMode.tscn", FIGHTER_DEFINITION, &"live", "Playable Reimu and Marisa duel definition")
	_register_scene(&"scene.fighter.hitbox", &"fighter", "Fighter hitbox viewer", "res://tests/ui/fixtures/CompactFighterHitboxFixture.tscn", FIGHTER_DEFINITION, &"hitbox", "Data-authored hitbox and hurtbox overlay")
	_register_scene(&"scene.fighter.training", &"fighter", "Fighter training", "res://tests/ui/fixtures/CompactFighterTrainingFixture.tscn", FIGHTER_DEFINITION, &"training", "Input history, frame data, and combat boxes")
	_register_scene(&"scene.fighter.stress", &"fighter", "Fighter stress", "res://tests/ui/fixtures/CompactFighterStressFixture.tscn", FIGHTER_DEFINITION, &"stress", "Two fighters, 128 projectiles, and 40 effects")
	_register_scene(&"scene.slice.complete", &"vertical_slice", "Vertical slice complete", "res://tests/ui/fixtures/VerticalSliceCompleteFixture.tscn", "", &"complete", "Complete Empty Cushion route review")
	_targets.append(WorkbenchTarget.new(&"save.v1_route_affinity", &"save", &"migration", "Version 1 route affinity", "res://tests/fixtures/saves/v1_route_affinity_payload.json", "res://schemas/game_state_v2.schema.json", &"v1_to_v2", "Production save migration fixture"))
	_register_tone(&"tone.shrine_day", &"mus_shrine_day", "Shrine day legal test tone")
	_register_tone(&"tone.border_crossing", &"mus_border_crossing", "Border crossing legal test tone")
	_register_tone(&"tone.shrine_duel", &"mus_shrine_duel", "Shrine duel legal test tone")
	_register_tone(&"tone.reimu_private", &"mus_reimu_private", "Reimu private legal test tone")


func targets() -> Array[WorkbenchTarget]:
	return _targets.duplicate()


func target(target_id: StringName) -> WorkbenchTarget:
	for candidate: WorkbenchTarget in _targets:
		if candidate.id == target_id:
			return candidate
	return null


func render_catalog(category: StringName = &"") -> WorkbenchResult:
	var result := validate_registry()
	if not result.is_valid():
		return result
	var rows := PackedStringArray()
	var count := 0
	for candidate: WorkbenchTarget in _targets:
		if category != &"" and candidate.category != category:
			continue
		count += 1
		rows.append("| `%s` | %s | %s | %s | `%s` | `%s` |" % [candidate.id, candidate.kind, candidate.category, candidate.label, candidate.fixture_state, candidate.resource_path])
	var lines := PackedStringArray([
		"# M11 authoring workbench",
		"",
		"- Targets: %d" % count,
		"- Category: `%s`" % (category if category != &"" else "all"),
		"",
		"| Target ID | Kind | Category | Label | State | Resource |",
		"| --- | --- | --- | --- | --- | --- |",
	])
	lines.append_array(rows)
	result.output = "\n".join(lines) + "\n"
	return result


func inspect_target(target_id: StringName) -> WorkbenchResult:
	var result := WorkbenchResult.new()
	result.target = target(target_id)
	if result.target == null:
		result.errors.append("unknown workbench target: %s" % target_id)
		return result
	_validate_target(result.target, result.errors)
	if not result.errors.is_empty():
		return result
	match result.target.kind:
		&"save":
			var loaded := GameStateFixtureLoader.new().load_path(result.target.resource_path)
			if not loaded.is_success():
				result.errors.append_array(loaded.errors)
			else:
				result.output = "MIGRATION migrated=%s\n%s\n" % ["yes" if loaded.was_migrated else "no", GameStateInspector.inspect(loaded.state, loaded.source_label).human_readable()]
		&"tone":
			var pitch := float(AdaptiveTestTonePlayer.STATE_PITCHES[result.target.fixture_state])
			result.output = "LEGAL TEST TONE state=%s pitch_hz=%.2f bar_seconds=%.1f\n" % [result.target.fixture_state, pitch, AdaptiveTestTonePlayer.BAR_SECONDS]
		_:
			result.output = "SCENE target=%s state=%s scene=%s definition=%s\n" % [result.target.id, result.target.fixture_state, result.target.resource_path, result.target.definition_path]
	return result


func validate_registry() -> WorkbenchResult:
	var result := WorkbenchResult.new()
	var ids: Array[StringName] = []
	for candidate: WorkbenchTarget in _targets:
		if candidate.id in ids:
			result.errors.append("duplicate workbench target: %s" % candidate.id)
		else:
			ids.append(candidate.id)
		_validate_target(candidate, result.errors)
	return result


func _validate_target(candidate: WorkbenchTarget, errors: Array[String]) -> void:
	if candidate.kind == &"scene":
		if not FileAccess.file_exists(candidate.resource_path) or not ResourceLoader.exists(candidate.resource_path, "PackedScene"):
			errors.append("%s scene is missing: %s" % [candidate.id, candidate.resource_path])
		_validate_definition(candidate, errors)
	elif candidate.kind == &"save":
		var loaded := GameStateFixtureLoader.new().load_path(candidate.resource_path)
		if not loaded.is_success():
			errors.append("%s save fixture failed: %s" % [candidate.id, "; ".join(loaded.errors)])
	elif candidate.kind == &"tone":
		if not AdaptiveTestTonePlayer.STATE_PITCHES.has(candidate.fixture_state):
			errors.append("%s references unknown test-tone state %s" % [candidate.id, candidate.fixture_state])
	else:
		errors.append("%s has unsupported kind %s" % [candidate.id, candidate.kind])


func _validate_definition(candidate: WorkbenchTarget, errors: Array[String]) -> void:
	if candidate.definition_path.is_empty() or candidate.definition_path.begins_with("builtin://"):
		return
	if candidate.category == &"danmaku":
		var danmaku_loader := DanmakuPatternLoader.new()
		if danmaku_loader.load_path(candidate.definition_path) == null:
			errors.append("%s danmaku definition failed: %s" % [candidate.id, "; ".join(danmaku_loader.errors)])
	elif candidate.category == &"fighter":
		var fighter_loader := FighterDefinitionLoader.new()
		if fighter_loader.load_path(candidate.definition_path) == null:
			errors.append("%s fighter definition failed: %s" % [candidate.id, "; ".join(fighter_loader.errors)])


func _register_scene(id: StringName, category: StringName, label: String, scene_path: String, definition_path: String, state: StringName, description: String) -> void:
	_targets.append(WorkbenchTarget.new(id, &"scene", category, label, scene_path, definition_path, state, description))


func _register_tone(id: StringName, state_id: StringName, description: String) -> void:
	_targets.append(WorkbenchTarget.new(id, &"tone", &"music", String(state_id), "generated://AdaptiveTestTonePlayer", "legal-generated-sine", state_id, description))
