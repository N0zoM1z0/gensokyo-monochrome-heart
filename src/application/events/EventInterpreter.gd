class_name EventInterpreter
extends RefCounted
## Step-limited typed graph execution with exactly-once transactional node effects.

const MAX_STEPS_PER_ADVANCE := 64
const MAX_COMMAND_HISTORY := 5

var _graph: EventGraphRecord
var _content: ContentRepository
var _state: GameState
var _runtime: EventRuntimeState
var _predicate_evaluator := EventPredicateEvaluator.new()
var _choice_resolver := EventChoiceResolver.new()
var _effect_compiler := EventEffectCommandCompiler.new()
var _pending_cues: Array[EventPresentationCue] = []
var _last_predicates: Array[PredicateEvaluationRecord] = []
var _pending_checkpoint: StringName
var _localization_key: StringName


func start(
	graph: EventGraphRecord,
	state: GameState,
	content: ContentRepository,
	is_replay: bool = false
) -> EventInterpreterResult:
	_reset_yield_data()
	if graph == null or state == null or content == null:
		return _error("event graph, GameState, and ContentRepository are required")
	var graph_errors := EventGraphValidator.new().validate(graph)
	if not graph_errors.is_empty():
		return _error("event graph failed runtime validation: %s" % "; ".join(graph_errors))
	var state_errors := GameStateValidator.new().validate(state)
	if not state_errors.is_empty():
		return _error("opening GameState is invalid: %s" % "; ".join(state_errors))
	_graph = graph
	_content = content
	_state = state.deep_copy() if is_replay else state
	_runtime = EventRuntimeState.new()
	_runtime.event_id = graph.id
	_runtime.deterministic_seed = _state.rng.fork_seed(graph.id)
	_runtime.is_replay = is_replay
	if not is_replay:
		_last_predicates = _predicate_evaluator.evaluate_all(graph.availability, _state)
		if not _predicate_evaluator.all_pass(_last_predicates):
			return _error("event availability predicates did not pass")
		if graph.id in _state.completed_event_ids:
			return _error("completed event cannot start outside replay: %s" % graph.id)
	if _state.active_event_id != &"" and _state.active_event_id != graph.id:
		return _error("another event is active: %s" % _state.active_event_id)
	if _state.active_event_id == graph.id:
		if graph.node(_state.active_event_node_id) == null:
			return _error("persisted event node is absent from graph: %s" % _state.active_event_node_id)
		_runtime.node_id = _state.active_event_node_id
	else:
		var begin := _commit_commands([
			SetEventPositionCommand.new(graph.id, graph.entry_node_id),
		])
		if not begin.is_success():
			return _error("could not persist event entry: %s" % begin.message)
		_runtime.node_id = graph.entry_node_id
	return _run_until_wait()


func advance_line() -> EventInterpreterResult:
	_reset_yield_data()
	if not _is_waiting_on(&"line"):
		return _error("interpreter is not waiting on a dialogue line")
	var node := _current_node()
	var advanced := _advance_to(node.next_node_id)
	if not advanced.is_success():
		return _error("dialogue advance failed: %s" % advanced.message)
	_runtime.waiting_for = &""
	return _run_until_wait()


func choose_tone(tone: StringName) -> EventInterpreterResult:
	_reset_yield_data()
	if not _is_waiting_on(&"choice"):
		return _error("interpreter is not waiting on a choice")
	var node := _current_node()
	var choice := _choice_resolver.resolve(node.choice, _state)
	var option := choice.option_for_tone(tone)
	if option == null:
		return _error("tone is hidden or absent: %s" % tone)
	if not option.is_available:
		_last_predicates = option.predicate_results.duplicate()
		return _error("tone is currently unavailable: %s" % tone)
	_runtime.choices.append(EventChoiceLogRecord.new(choice.choice_id, tone, node.id))
	var advanced := _advance_to(option.next_node_id)
	if not advanced.is_success():
		return _error("choice advance failed: %s" % advanced.message)
	_runtime.waiting_for = &""
	return _run_until_wait()


func resume_mode(result: ModeResult) -> EventInterpreterResult:
	_reset_yield_data()
	if not _is_waiting_on(&"mode"):
		return _error("interpreter is not waiting on a mechanical mode")
	if result == null or result.result_tag == &"":
		return _error("mode result requires a stable result tag")
	var node := _current_node()
	var next_node_id: StringName = &""
	for branch: ModeResultBranchRecord in node.result_branches:
		if branch.result_tag == result.result_tag:
			next_node_id = branch.next_node_id
			break
	if next_node_id == &"":
		return _error("mode result has no authored branch: %s" % result.result_tag)
	var advanced := _advance_to(next_node_id)
	if not advanced.is_success():
		return _error("mode resume failed: %s" % advanced.message)
	_runtime.waiting_for = &""
	return _run_until_wait()


func runtime_state() -> EventRuntimeState:
	return _runtime


func debug_snapshot() -> EventDebugSnapshot:
	var snapshot := EventDebugSnapshot.new()
	if _runtime == null:
		return snapshot
	snapshot.event_id = _runtime.event_id
	snapshot.node_id = _runtime.node_id
	snapshot.waiting_for = _runtime.waiting_for
	snapshot.total_steps = _runtime.total_steps
	snapshot.deterministic_seed = _runtime.deterministic_seed
	snapshot.pending_checkpoint = _pending_checkpoint
	snapshot.localization_key = _localization_key
	snapshot.predicate_results = _last_predicates.duplicate()
	snapshot.last_command_ids = _runtime.last_command_ids.duplicate()
	if _graph != null:
		snapshot.origin_canon = _graph.origin_canon
		snapshot.origin_fanon = _graph.origin_fanon
		snapshot.origin_original = _graph.origin_original
	return snapshot


func _run_until_wait() -> EventInterpreterResult:
	for _step: int in range(MAX_STEPS_PER_ADVANCE):
		_runtime.total_steps += 1
		var node := _current_node()
		if node == null:
			return _error("current event node is missing: %s" % _runtime.node_id)
		match node.type:
			&"music_state":
				_pending_cues.append(EventPresentationCue.new(&"music", node.music_state_id))
				var music_advance := _advance_to(node.next_node_id)
				if not music_advance.is_success():
					return _error(music_advance.message)
			&"exploration_objective":
				_pending_cues.append(EventPresentationCue.new(&"objective", node.objective_key))
				var objective_advance := _advance_to(node.next_node_id)
				if not objective_advance.is_success():
					return _error(objective_advance.message)
			&"line":
				var beat := _content.dialogue_beat(node.beat_id)
				if beat == null:
					return _error("dialogue beat is missing: %s" % node.beat_id)
				_runtime.waiting_for = &"line"
				_pending_checkpoint = &"event_checkpoint"
				_localization_key = beat.text_key
				var line_result := _yield(EventInterpreterResult.Status.WAIT_INPUT)
				line_result.beat = beat
				return line_result
			&"choice":
				var choice := _choice_resolver.resolve(node.choice, _state)
				if choice.options.is_empty():
					return _error("choice has no visible options: %s" % node.choice.id)
				_runtime.waiting_for = &"choice"
				_pending_checkpoint = &"event_checkpoint"
				_localization_key = choice.options[0].text_key
				var choice_result := _yield(EventInterpreterResult.Status.WAIT_INPUT)
				choice_result.choice = choice
				return choice_result
			&"effects":
				var applied := _apply_effect_node(node)
				if not applied.is_success():
					return _error("effect transaction failed: %s" % applied.message)
			&"start_minigame", &"start_danmaku", &"start_duel":
				_runtime.waiting_for = &"mode"
				_pending_checkpoint = &"before_mode"
				var mode_result := _yield(EventInterpreterResult.Status.WAIT_MODE)
				mode_result.mode_context = _mode_context(node)
				return mode_result
			&"give_item":
				var item_result := _give_item(node)
				if not item_result.is_success():
					return _error("item transaction failed: %s" % item_result.message)
			&"journal_entry":
				var journal_result := _add_journal(node)
				if not journal_result.is_success():
					return _error("Journal transaction failed: %s" % journal_result.message)
			&"end_event":
				var ended := _finish_event(node)
				if not ended.is_success():
					return _error("event completion failed: %s" % ended.message)
				_pending_checkpoint = &"event_completion"
				var end_result := _yield(EventInterpreterResult.Status.END)
				end_result.outcome = node.outcome
				return end_result
			_:
				return _error("unsupported event node type: %s" % node.type)
	return _error("event exceeded %d automatic steps without yielding" % MAX_STEPS_PER_ADVANCE)


func _apply_effect_node(node: EventNodeRecord) -> CommandResult:
	var commands: Array[GameCommand] = []
	if not _runtime.is_replay:
		var compiled := _effect_compiler.compile(node.effects)
		if not compiled.is_success():
			return CommandResult.failure(
				CommandResult.Code.INVALID_COMMAND,
				&"event.effects",
				"; ".join(compiled.errors)
			)
		commands.append_array(compiled.commands)
	commands.append(SetEventPositionCommand.new(_graph.id, node.next_node_id))
	var result := _commit_commands(commands)
	if result.is_success() and not _runtime.is_replay:
		for effect: EventEffectRecord in node.effects:
			if effect.operation != &"relationship" or not _state.characters.has(effect.character_id):
				continue
			var relationship := _state.characters[effect.character_id].relationship
			_pending_cues.append(EventPresentationCue.new(
				&"resonance",
				StringName("cue.resonance.%s.%s" % [String(effect.character_id).trim_prefix("char."), effect.facet]),
				effect.character_id,
				RelationshipFacetRules.qualitative_key(relationship, effect.facet)
			))
	if result.is_success():
		_runtime.node_id = node.next_node_id
	return result


func _give_item(node: EventNodeRecord) -> CommandResult:
	var commands: Array[GameCommand] = []
	if not _runtime.is_replay:
		if String(node.item_id).begins_with("item.keepsake."):
			var keepsake := KeepsakeState.new(node.item_id)
			keepsake.source_event_id = _graph.id
			keepsake.owner_character_id = _graph.cast[0] if not _graph.cast.is_empty() else &""
			keepsake.acquired_day = _state.day
			if _graph.id == &"evt.hkr.empty_cushion":
				keepsake.dialogue_tags.append(&"shrine.second_cup")
			commands.append(GrantKeepsakeCommand.new(keepsake))
		else:
			commands.append(AddInventoryItemCommand.new(node.item_id, 1))
	commands.append(SetEventPositionCommand.new(_graph.id, node.next_node_id))
	var result := _commit_commands(commands)
	if result.is_success():
		_runtime.node_id = node.next_node_id
		_pending_cues.append(EventPresentationCue.new(&"item", node.item_id))
	return result


func _add_journal(node: EventNodeRecord) -> CommandResult:
	var commands: Array[GameCommand] = []
	if not _runtime.is_replay:
		var entry := JournalEntryState.new(node.journal_entry_id)
		entry.title_key = StringName("%s.title" % node.journal_entry_id)
		entry.entry_type = &"event_observation"
		entry.source_event_id = _graph.id
		entry.discovered_day = _state.day
		entry.observation_keys.append(StringName("%s.body" % node.journal_entry_id))
		entry.tags.append(&"resonance")
		entry.tags.append(&"quiet_object")
		commands.append(AddJournalEntryCommand.new(entry))
		commands.append(UnlockJournalReplayCommand.new(_graph.id))
	commands.append(SetEventPositionCommand.new(_graph.id, node.next_node_id))
	var result := _commit_commands(commands)
	if result.is_success():
		_runtime.node_id = node.next_node_id
		_pending_cues.append(EventPresentationCue.new(&"journal", node.journal_entry_id))
	return result


func _finish_event(node: EventNodeRecord) -> CommandResult:
	var command: GameCommand = (
		SetEventPositionCommand.new(&"", &"")
		if _runtime.is_replay
		else CompleteEventCommand.new(_graph.id, node.outcome)
	)
	var result := _commit_commands([command])
	if result.is_success():
		_runtime.node_id = node.id
		_runtime.waiting_for = &"end"
	return result


func _advance_to(next_node_id: StringName) -> CommandResult:
	if _graph.node(next_node_id) == null:
		return CommandResult.failure(
			CommandResult.Code.NOT_FOUND,
			&"event.advance",
			"target event node is missing: %s" % next_node_id
		)
	var result := _commit_commands([SetEventPositionCommand.new(_graph.id, next_node_id)])
	if result.is_success():
		_runtime.node_id = next_node_id
	return result


func _commit_commands(commands: Array[GameCommand]) -> CommandResult:
	var transaction := GameStateTransaction.new(_state)
	for command: GameCommand in commands:
		var result := transaction.apply(command)
		_record_command(command.command_id)
		if not result.is_success():
			transaction.rollback()
			return result
	return transaction.commit()


func _mode_context(node: EventNodeRecord) -> ModeContext:
	var context := ModeContext.new()
	context.mode_type = node.type
	context.mode_id = node.minigame_id
	context.event_id = _graph.id
	context.node_id = node.id
	context.target_band = node.target_band
	context.cups = node.cups
	context.deterministic_seed = _state.rng.fork_seed(StringName("%s:%s" % [_graph.id, node.id]))
	context.is_replay = _runtime.is_replay
	return context


func _yield(status: EventInterpreterResult.Status) -> EventInterpreterResult:
	var result := EventInterpreterResult.new()
	result.status = status
	result.event_id = _graph.id if _graph != null else &""
	result.node_id = _runtime.node_id if _runtime != null else &""
	result.checkpoint_reason = _pending_checkpoint
	result.presentation_cues = _pending_cues.duplicate()
	result.predicate_results = _last_predicates.duplicate()
	return result


func _error(message: String) -> EventInterpreterResult:
	var result := _yield(EventInterpreterResult.Status.ERROR)
	result.diagnostic = message
	return result


func _current_node() -> EventNodeRecord:
	return _graph.node(_runtime.node_id) if _graph != null and _runtime != null else null


func _is_waiting_on(kind: StringName) -> bool:
	return _runtime != null and _runtime.waiting_for == kind and _current_node() != null


func _record_command(command_id: StringName) -> void:
	_runtime.last_command_ids.append(command_id)
	while _runtime.last_command_ids.size() > MAX_COMMAND_HISTORY:
		_runtime.last_command_ids.pop_front()


func _reset_yield_data() -> void:
	_pending_cues.clear()
	_last_predicates.clear()
	_pending_checkpoint = &""
	_localization_key = &""
