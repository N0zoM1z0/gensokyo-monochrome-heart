class_name TestMinigameFoundation
extends RefCounted
## M06 host contract, deterministic tea bands, assists, pause/retry, and state isolation.

const FIXTURE_PATH := "res://tests/fixtures/minigames/tea_excellent_run.json"
const HALF_PHANTOM_MODE := preload("res://src/presentation/minigames/HalfPhantomBalanceMode.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	_expect_definition_and_golden_fixture(failures)
	_expect_result_bands(failures)
	_expect_assists(failures)
	_expect_pause_retry_and_loss(failures)
	_expect_host_and_story_isolation(failures)
	_expect_time_grid_service(failures)
	_expect_five_impossible_errands(failures)
	_expect_soul_garden_release(failures)
	_expect_quiet_chore(failures)
	_expect_half_phantom_tutorial_wrapping(failures)
	return failures


func _expect_half_phantom_tutorial_wrapping(failures: Array[String]) -> void:
	var catalog := UiTextCatalog.new()
	catalog.load_default()
	for locale: StringName in [&"en", &"ja"]:
		var font := UiFontRegistry.japanese() if locale == &"ja" else UiFontRegistry.latin()
		var source := catalog.text(&"ui.minigame.half_phantom.tutorial", locale)
		var lines: Array[String] = HALF_PHANTOM_MODE.wrap_tutorial_text(source, font, locale)
		if lines.size() < 2 or lines.size() > HALF_PHANTOM_MODE.TUTORIAL_MAX_LINES:
			failures.append("Half-Phantom tutorial %s did not wrap to two or three lines" % locale)
			continue
		var rebuilt := "".join(lines) if locale == &"ja" else " ".join(lines)
		if rebuilt != source:
			failures.append("Half-Phantom tutorial %s lost rule text while wrapping" % locale)
		for line: String in lines:
			var width := font.get_string_size(
				line,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				HALF_PHANTOM_MODE.tutorial_font_size(locale)
			).x
			if width > HALF_PHANTOM_MODE.TUTORIAL_TEXT_WIDTH:
				failures.append("Half-Phantom tutorial %s line exceeds its 276 px text box" % locale)
				break


func _expect_quiet_chore(failures: Array[String]) -> void:
	var definition := QuietChoreDefinition.new()
	if not definition.validation_errors().is_empty():
		failures.append("Quiet Chore does not satisfy the shared minigame contract")
	var game := QuietChoreSimulation.new()
	game.configure(_quiet_chore_context(), MinigameAssistSettings.new())
	var confirm := MinigameInputFrame.new()
	confirm.confirm_pressed = true
	game.step(confirm)
	for stroke: int in range(QuietChoreSimulation.REQUIRED_SWEEP_STROKES):
		var sweep := MinigameInputFrame.new()
		sweep.grid_direction.x = -1 if stroke % 2 == 0 else 1
		game.step(sweep)
	for _seam: int in range(QuietChoreSimulation.REQUIRED_MENDED_SEAMS):
		game.step(confirm)
	if game.state.phase != QuietChoreState.Phase.SIT:
		failures.append("Quiet Chore did not progress from sweep and mend into sitting")
	for _tick: int in range(QuietChoreSimulation.STANDARD_SILENCE_TICKS - 1):
		game.step(MinigameInputFrame.new())
	game.step(confirm)
	if game.state.silence_ticks != 0 or game.state.interruptions != 1 or game.final_result != null:
		failures.append("Quiet Chore did not reset silence after player input")
	for _tick: int in range(QuietChoreSimulation.STANDARD_SILENCE_TICKS):
		game.step(MinigameInputFrame.new())
	if game.final_result == null or game.final_result.result_tag != &"clear":
		failures.append("Quiet Chore advanced without a deterministic silence clear")
	elif &"quiet_chore.silence_tolerated" not in game.final_result.outcome_tags:
		failures.append("Quiet Chore result omitted semantic silence evidence")
	var repeated := _run_quiet_chore(false)
	var repeated_again := _run_quiet_chore(false)
	if repeated.final_result.telemetry.final_state_hash != repeated_again.final_result.telemetry.final_state_hash:
		failures.append("Quiet Chore produced nondeterministic telemetry")
	var story := _run_quiet_chore(true)
	if story.state.silence_ticks != QuietChoreSimulation.STORY_SILENCE_TICKS or not story.final_result.used_assist:
		failures.append("Quiet Chore Story pacing did not preserve the same clear with shorter waiting")
	var drift_safe := QuietChoreSimulation.new()
	var drift_settings := MinigameAssistSettings.new()
	drift_settings.slower_pace = true
	drift_safe.configure(_quiet_chore_context(), drift_settings)
	_advance_quiet_chore_to_sit(drift_safe)
	for _pulse: int in range(4):
		for _tick: int in range(30):
			drift_safe.step(MinigameInputFrame.new())
		drift_safe.step(confirm)
	if drift_safe.final_result == null or drift_safe.state.interruptions != 3:
		failures.append("Quiet Chore Story input pulses erased progress or caused a soft lock")
	if EventModeSceneRegistry.new().scene_for(&"mini.hkr.quiet_chore") == null:
		failures.append("Quiet Chore mode is not reachable through the event scene registry")


func _run_quiet_chore(story_pacing: bool) -> QuietChoreSimulation:
	var game := QuietChoreSimulation.new()
	var settings := MinigameAssistSettings.new()
	settings.slower_pace = story_pacing
	game.configure(_quiet_chore_context(), settings)
	_advance_quiet_chore_to_sit(game)
	var required := QuietChoreSimulation.STORY_SILENCE_TICKS if story_pacing else QuietChoreSimulation.STANDARD_SILENCE_TICKS
	for _tick: int in range(required):
		game.step(MinigameInputFrame.new())
	return game


func _advance_quiet_chore_to_sit(game: QuietChoreSimulation) -> void:
	var confirm := MinigameInputFrame.new()
	confirm.confirm_pressed = true
	game.step(confirm)
	for stroke: int in range(QuietChoreSimulation.REQUIRED_SWEEP_STROKES):
		var sweep := MinigameInputFrame.new()
		sweep.grid_direction.x = -1 if stroke % 2 == 0 else 1
		game.step(sweep)
	for _seam: int in range(QuietChoreSimulation.REQUIRED_MENDED_SEAMS):
		game.step(confirm)


func _quiet_chore_context() -> ModeContext:
	var context := ModeContext.new()
	context.mode_type = &"start_minigame"
	context.mode_id = &"mini.hkr.quiet_chore"
	context.event_id = &"evt.hkr.day_nothing_happens"
	context.node_id = &"n_quiet_chore"
	context.deterministic_seed = 14031
	return context


func _expect_soul_garden_release(failures: Array[String]) -> void:
	var definition := SoulGardenDefinition.new()
	if not definition.validation_errors().is_empty():
		failures.append("Soul Garden does not satisfy the shared minigame contract")
	var game := SoulGardenSimulation.new()
	game.configure(_soul_garden_context(), MinigameAssistSettings.new())
	var start := MinigameInputFrame.new()
	start.confirm_pressed = true
	game.step(start)
	_move_soul_cursor(game, game.state.spirit_columns[0])
	var confirm := MinigameInputFrame.new()
	confirm.confirm_pressed = true
	game.step(confirm)
	if game.state.carried_spirit != 0:
		failures.append("Soul Garden could not collect the marked fan spirit")
	_move_soul_cursor(game, SoulGardenSimulation.TREE_COLUMNS[1])
	game.step(confirm)
	if game.state.carried_spirit != 0 or game.state.released_count != 0 or game.state.mismatch_count != 1:
		failures.append("wrong memorial tree consumed a spirit or lost existing progress")
	for spirit_index: int in range(3):
		if game.state.carried_spirit < 0:
			_move_soul_cursor(game, game.state.spirit_columns[spirit_index])
			game.step(confirm)
		_move_soul_cursor(game, SoulGardenSimulation.TREE_COLUMNS[spirit_index])
		game.step(confirm)
	if game.final_result == null or game.final_result.result_tag != &"clear" or game.state.released_count != 3:
		failures.append("three matched spirits did not complete through deliberate release")
	elif &"soul_garden.released.3" not in game.final_result.outcome_tags:
		failures.append("Soul Garden result omitted stable release evidence")
	var repeated := _run_clean_soul_garden()
	var repeated_again := _run_clean_soul_garden()
	if repeated.final_result == null or repeated.final_result.performance_band != &"excellent":
		failures.append("clean Soul Garden release did not retain optional mastery")
	elif repeated.final_result.telemetry.final_state_hash != repeated_again.final_result.telemetry.final_state_hash:
		failures.append("Soul Garden produced nondeterministic release telemetry")
	var assisted := SoulGardenSimulation.new()
	var slower := MinigameAssistSettings.new()
	slower.slower_pace = true
	assisted.configure(_soul_garden_context(), slower)
	assisted.step(start)
	var initial_columns := assisted.state.spirit_columns.duplicate()
	for _tick: int in range(SoulGardenSimulation.STANDARD_DRIFT_TICKS):
		assisted.step(MinigameInputFrame.new())
	if assisted.state.spirit_columns != initial_columns:
		failures.append("Soul Garden slower-pace assist did not delay the first drift")
	for _tick: int in range(SoulGardenSimulation.STANDARD_DRIFT_TICKS):
		assisted.step(MinigameInputFrame.new())
	if assisted.state.spirit_columns == initial_columns:
		failures.append("Soul Garden slower-pace assist stopped drift instead of pacing it")


func _run_clean_soul_garden() -> SoulGardenSimulation:
	var game := SoulGardenSimulation.new()
	game.configure(_soul_garden_context(), MinigameAssistSettings.new())
	var confirm := MinigameInputFrame.new()
	confirm.confirm_pressed = true
	game.step(confirm)
	for spirit_index: int in range(3):
		_move_soul_cursor(game, game.state.spirit_columns[spirit_index])
		game.step(confirm)
		_move_soul_cursor(game, SoulGardenSimulation.TREE_COLUMNS[spirit_index])
		game.step(confirm)
	return game


func _move_soul_cursor(game: SoulGardenSimulation, target: int) -> void:
	while game.state.cursor_column != target:
		var frame := MinigameInputFrame.new()
		frame.grid_direction.x = signi(target - game.state.cursor_column)
		game.step(frame)


func _soul_garden_context() -> ModeContext:
	var context := ModeContext.new()
	context.mode_type = &"start_minigame"
	context.mode_id = &"mini.hgy.soul_garden"
	context.event_id = &"evt.hgy.petal_on_hold"
	context.node_id = &"n_soul_garden"
	context.deterministic_seed = 13021
	return context


func _expect_five_impossible_errands(failures: Array[String]) -> void:
	var definition := FiveImpossibleErrandsDefinition.new()
	if not definition.validation_errors().is_empty():
		failures.append("Five Impossible Errands does not satisfy the shared minigame contract")
	var catalog := FiveImpossibleErrandsCatalog.build()
	var kinds := {}
	if catalog.size() != 5:
		failures.append("Five Impossible Errands catalog does not contain five trials")
	for errand: ImpossibleErrandDefinition in catalog:
		kinds[errand.trial_kind] = true
		if not errand.validation_errors().is_empty():
			failures.append("invalid impossible errand definition: %s" % errand.errand_id)
	if kinds.size() != 5:
		failures.append("Five Impossible Errands collapsed distinct trial modules into one rule")
	for approach_index: int in range(3):
		var committed := _run_errand_choices([approach_index, approach_index, approach_index, approach_index, approach_index])
		if committed.final_result == null or committed.final_result.result_tag != &"clear":
			failures.append("approach %d was not a first-class clear path" % approach_index)
		elif committed.final_result.performance_band != &"committed":
			failures.append("consistent answers were incorrectly ranked instead of described")
	var varied := _run_errand_choices([0, 1, 2, 1, 0])
	var repeated := _run_errand_choices([0, 1, 2, 1, 0])
	if varied.final_result == null or varied.final_result.performance_band != &"varied":
		failures.append("mixed literal, clever, and refusal answers lost their neutral shape tag")
	elif varied.final_result.telemetry.final_state_hash != repeated.final_result.telemetry.final_state_hash:
		failures.append("Five Impossible Errands produced nondeterministic answer telemetry")
	if &"errands.choice.3.refuse" not in varied.final_result.outcome_tags:
		failures.append("Five Impossible Errands result omitted the explicit refusal record")
	var scene := EventModeSceneRegistry.new().scene_for(&"mini.ein.five_impossible_errands")
	if scene == null:
		failures.append("Five Impossible Errands mode is not reachable through the event scene registry")


func _run_errand_choices(choices: Array[int]) -> FiveImpossibleErrandsSimulation:
	var game := FiveImpossibleErrandsSimulation.new()
	game.configure(_errands_context(), MinigameAssistSettings.new())
	var start := MinigameInputFrame.new()
	start.confirm_pressed = true
	game.step(start)
	for choice: int in choices:
		while game.state.option_cursor != choice:
			var movement := MinigameInputFrame.new()
			movement.choice_direction = signi(choice - game.state.option_cursor)
			game.step(movement)
		var confirm := MinigameInputFrame.new()
		confirm.confirm_pressed = true
		game.step(confirm)
	return game


func _errands_context() -> ModeContext:
	var context := ModeContext.new()
	context.mode_type = &"start_minigame"
	context.mode_id = &"mini.ein.five_impossible_errands"
	context.event_id = &"evt.ein.five_impossibilities"
	context.node_id = &"n_errands"
	context.deterministic_seed = 13003
	return context


func _expect_time_grid_service(failures: Array[String]) -> void:
	var definition := TimeGridServiceDefinition.new()
	if not definition.validation_errors().is_empty() or definition.assist_ids.size() != 3:
		failures.append("Time Grid Service does not satisfy the shared minigame contract")
	var first := _run_time_grid(1212, true)
	var second := _run_time_grid(1212, true)
	if first.final_result == null or first.final_result.result_tag != &"excellent":
		failures.append("correct stopped-time service queue did not score Excellent")
	elif first.final_result.telemetry.final_state_hash != second.final_result.telemetry.final_state_hash:
		failures.append("same Time Grid input produced nondeterministic telemetry")
	if first.state.completed_tasks != 6 or first.state.missed_tasks != 0 or first.state.stop_ticks_used <= 0:
		failures.append("Time Grid did not record queued tasks or stopped-time cost")
	var loss := _run_time_grid(1313, false)
	if loss.final_result == null or loss.final_result.result_tag != &"loss":
		failures.append("wrong-station service did not produce the authored Loss escalation")
	var host := MinigameHost.new()
	if not host.load_minigame(TimeGridServiceSimulation.new(), _time_grid_context(1414), MinigameAssistSettings.new()):
		failures.append("shared MinigameHost rejected Time Grid Service")
	var queue_contract := TimeGridServiceSimulation.new()
	queue_contract.configure(_time_grid_context(1515), MinigameAssistSettings.new())
	var start := MinigameInputFrame.new()
	start.confirm_pressed = true
	queue_contract.step(start)
	var moving_queue := MinigameInputFrame.new()
	moving_queue.pour_pressed = true
	queue_contract.step(moving_queue)
	if queue_contract.state.queued_station >= 0:
		failures.append("Time Grid accepted a queue outside stopped time")


func _run_time_grid(seed: int, correct_stations: bool) -> TimeGridServiceSimulation:
	var game := TimeGridServiceSimulation.new()
	game.configure(_time_grid_context(seed), MinigameAssistSettings.new())
	var start := MinigameInputFrame.new()
	start.confirm_pressed = true
	game.step(start)
	while game.final_result == null:
		var target := game.current_station() if correct_stations else 4
		_move_grid_cursor(game, Vector2i(target % 3, target / 3))
		var queue := MinigameInputFrame.new()
		queue.patience_held = true
		queue.pour_pressed = true
		game.step(queue)
		var task_before := game.state.task_index
		while game.final_result == null and game.state.task_index == task_before:
			game.step(MinigameInputFrame.new())
	return game


func _move_grid_cursor(game: TimeGridServiceSimulation, target: Vector2i) -> void:
	while game.state.cursor != target:
		var frame := MinigameInputFrame.new()
		frame.patience_held = true
		frame.grid_direction = Vector2i(signi(target.x - game.state.cursor.x), signi(target.y - game.state.cursor.y))
		game.step(frame)


func _time_grid_context(seed: int) -> ModeContext:
	var context := ModeContext.new()
	context.mode_type = &"start_minigame"
	context.mode_id = &"mini.sdm.time_grid_service"
	context.event_id = &"evt.sdm.late_by_three_minutes"
	context.node_id = &"n006"
	context.target_band = &"exact"
	context.cups = 3
	context.deterministic_seed = seed
	return context


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
