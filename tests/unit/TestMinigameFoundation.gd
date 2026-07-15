class_name TestMinigameFoundation
extends RefCounted
## M06 host contract, deterministic tea bands, assists, pause/retry, and state isolation.

const FIXTURE_PATH := "res://tests/fixtures/minigames/tea_excellent_run.json"


func run() -> Array[String]:
	var failures: Array[String] = []
	_expect_definition_and_golden_fixture(failures)
	_expect_result_bands(failures)
	_expect_assists(failures)
	_expect_pause_retry_and_loss(failures)
	_expect_host_and_story_isolation(failures)
	return failures


func _expect_definition_and_golden_fixture(failures: Array[String]) -> void:
	var definition := TeaTemperatureDefinition.new()
	if not definition.validation_errors().is_empty() or definition.estimated_duration_seconds != 45:
		failures.append("Tea Temperature did not satisfy the shared 30-60 second contract")
	if GameInput.FOCUS not in definition.control_actions or definition.assist_ids.size() != 3:
		failures.append("Tea definition omitted patience input or its three assists")
	var first := _run_json_fixture(FIXTURE_PATH)
	var second := _run_json_fixture(FIXTURE_PATH)
	if first == null or first.result_tag != &"excellent":
		failures.append("golden Tea Temperature fixture did not reach Excellent")
	elif second == null or first.telemetry.final_state_hash != second.telemetry.final_state_hash:
		failures.append("same seed/input fixture produced nondeterministic tea telemetry")


func _expect_result_bands(failures: Array[String]) -> void:
	var clear_game := _configured_game(6061)
	clear_game.start_play()
	_step(clear_game, 85, 1, true)
	_step(clear_game, 65, 0, true)
	_pour_pair(clear_game)
	if clear_game.final_result == null or clear_game.final_result.result_tag != &"clear":
		failures.append("moderately warm, adequately steeped tea did not score Clear")
	var loss_game := _configured_game(6062)
	loss_game.start_play()
	_step(loss_game, 225, 1, false)
	_pour_pair(loss_game)
	if loss_game.final_result == null or loss_game.final_result.result_tag != &"loss":
		failures.append("overheated unsteeped tea did not score Loss")
	if loss_game.final_result.outcome_tags != [&"tea.two_cups", &"tea.result.loss"]:
		failures.append("tea result omitted stable authored outcome tags")


func _expect_assists(failures: Array[String]) -> void:
	var slow := MinigameAssistSettings.new()
	slow.slower_heat_change = true
	var slow_game := _configured_game(6060, slow)
	slow_game.start_play()
	_step(slow_game, 180, 1, true)
	_step(slow_game, 40, 1, false)
	_pour_pair(slow_game)
	if slow_game.final_result == null or slow_game.final_result.result_tag != &"excellent" or not slow_game.final_result.used_assist:
		failures.append("slower-heat assist could not complete the Excellent fixture")
	var standard_edge := _configured_game(6060)
	standard_edge.start_play()
	_step(standard_edge, 55, 1, true)
	_step(standard_edge, 65, 0, true)
	_pour_pair(standard_edge)
	if standard_edge.final_result.result_tag != &"loss":
		failures.append("standard target unexpectedly accepted the wider-band edge fixture")
	var wide := MinigameAssistSettings.new()
	wide.wider_target_band = true
	var wide_game := _configured_game(6060, wide)
	wide_game.start_play()
	_step(wide_game, 55, 1, true)
	_step(wide_game, 65, 0, true)
	_pour_pair(wide_game)
	if wide_game.final_result == null or wide_game.final_result.result_tag != &"clear":
		failures.append("wider-band assist did not make its edge fixture completable")
	var untimed := MinigameAssistSettings.new()
	untimed.no_timer = true
	var untimed_game := _configured_game(6060, untimed)
	untimed_game.start_play()
	_step(untimed_game, TeaTemperatureSimulation.TIME_LIMIT_TICKS + 60, 0, false)
	if untimed_game.final_result != null or untimed_game.state.remaining_ticks != TeaTemperatureSimulation.TIME_LIMIT_TICKS:
		failures.append("no-timer assist still expired or changed the time reservoir")
	_step(untimed_game, 110, 1, true)
	_step(untimed_game, 70, 0, true)
	_pour_pair(untimed_game)
	if untimed_game.final_result == null or untimed_game.final_result.result_tag != &"excellent":
		failures.append("no-timer assist could not complete after an extended pause")


func _expect_pause_retry_and_loss(failures: Array[String]) -> void:
	var game := _configured_game(7070)
	game.start_play()
	_step(game, 12, 1, true)
	var before_pause := game.state.canonical_snapshot()
	game.toggle_pause()
	_step(game, 120, 1, true)
	if game.state.canonical_snapshot() != before_pause:
		failures.append("paused minigame continued its fixed-step simulation")
	game.toggle_pause()
	game.reset_attempt()
	if game.is_paused or game.state.phase != TeaTemperatureState.Phase.TUTORIAL or game.state.kettle_heat != 400 or game.state.steep_ticks != 0 or game.state.poured_cups != 0 or game.state.elapsed_ticks != 0 or game.state.remaining_ticks != TeaTemperatureSimulation.TIME_LIMIT_TICKS:
		failures.append("retry retained stale tea timer, heat, steep, cup, or pause state")
	game.start_play()
	var accepted := game.accept_loss()
	if accepted == null or accepted.result_tag != &"loss" or game.state.phase != TeaTemperatureState.Phase.RESULT:
		failures.append("accept-loss flow did not return a valid story result")
	var timed := _configured_game(7071)
	timed.start_play()
	_step(timed, TeaTemperatureSimulation.TIME_LIMIT_TICKS, 0, false)
	if timed.final_result == null or timed.final_result.result_tag != &"loss":
		failures.append("standard timer expiry did not produce a valid Loss")


func _expect_host_and_story_isolation(failures: Array[String]) -> void:
	var content := ContentRepository.new()
	if not content.load_sources().is_success():
		failures.append("could not load content for minigame isolation fixture")
		return
	var character_ids: Array[StringName] = []
	for character: CharacterRecord in content.all_characters():
		character_ids.append(character.id)
	var location_ids: Array[StringName] = []
	for location: LocationRecord in content.all_locations():
		location_ids.append(location.id)
	var story := GameStateFactory.create_new(&"p60", character_ids, location_ids, 6060)
	var before := GameStateCodec.new().canonical_state(story)
	var host := MinigameHost.new()
	var signal_count := [0]
	host.result_ready.connect(func(_result: ModeResult) -> void: signal_count[0] += 1)
	if not host.load_minigame(TeaTemperatureSimulation.new(), _context(6060), MinigameAssistSettings.new()):
		failures.append("shared MinigameHost rejected a valid Tea Temperature runtime")
		return
	var start := MinigameInputFrame.new()
	start.confirm_pressed = true
	host.step(start)
	_step_host(host, 110, 1, true)
	_step_host(host, 70, 0, true)
	_pour_pair_host(host)
	host.step(MinigameInputFrame.new())
	if signal_count[0] != 1:
		failures.append("MinigameHost emitted one mechanical result more than once")
	if GameStateCodec.new().canonical_state(story) != before:
		failures.append("Tea Temperature mutated route/GameState instead of returning ModeResult")
	var hosted_tea := host.runtime as TeaTemperatureSimulation
	var result := hosted_tea.final_result as ModeResult
	if result == null or result.telemetry == null or result.telemetry.deterministic_seed != 6060 or result.telemetry.attempt_count != 1:
		failures.append("typed ModeResult omitted deterministic replay telemetry")
	host.retry()
	if host.attempt_count != 2 or hosted_tea.state.elapsed_ticks != 0:
		failures.append("MinigameHost retry did not increment attempt and fully reset runtime")


func _configured_game(seed: int, assists: MinigameAssistSettings = null) -> TeaTemperatureSimulation:
	var game := TeaTemperatureSimulation.new()
	game.configure(_context(seed), assists if assists != null else MinigameAssistSettings.new())
	return game


func _context(seed: int) -> ModeContext:
	var context := ModeContext.new()
	context.mode_type = &"start_minigame"
	context.mode_id = &"mini.shrine.tea_temperature"
	context.event_id = &"evt.hkr.empty_cushion"
	context.node_id = &"n005"
	context.target_band = &"warm"
	context.cups = 2
	context.deterministic_seed = seed
	return context


func _step(game: TeaTemperatureSimulation, ticks: int, heat_direction: int, patience: bool) -> void:
	for _tick: int in range(ticks):
		var frame := MinigameInputFrame.new()
		frame.heat_direction = heat_direction
		frame.patience_held = patience
		game.step(frame)


func _pour_pair(game: TeaTemperatureSimulation) -> void:
	var pour := MinigameInputFrame.new()
	pour.pour_pressed = true
	game.step(pour)
	_step(game, TeaTemperatureSimulation.POUR_LOCK_TICKS, 0, false)
	game.step(pour)


func _step_host(host: MinigameHost, ticks: int, heat_direction: int, patience: bool) -> void:
	for _tick: int in range(ticks):
		var frame := MinigameInputFrame.new()
		frame.heat_direction = heat_direction
		frame.patience_held = patience
		host.step(frame)


func _pour_pair_host(host: MinigameHost) -> void:
	var pour := MinigameInputFrame.new()
	pour.pour_pressed = true
	host.step(pour)
	_step_host(host, TeaTemperatureSimulation.POUR_LOCK_TICKS, 0, false)
	host.step(pour)


func _run_json_fixture(path: String) -> ModeResult:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var fixture: Variant = JSON.parse_string(file.get_as_text())
	if not fixture is Dictionary:
		return null
	var game := _configured_game(int(fixture.get("seed", 1)))
	game.start_play()
	for raw_segment: Variant in fixture.get("segments", []):
		var segment: Dictionary = raw_segment
		for _tick: int in range(int(segment.get("ticks", 0))):
			var frame := MinigameInputFrame.new()
			frame.heat_direction = int(segment.get("heat_direction", 0))
			frame.patience_held = bool(segment.get("patience_held", false))
			frame.pour_pressed = bool(segment.get("pour_pressed", false))
			game.step(frame)
	return game.final_result
