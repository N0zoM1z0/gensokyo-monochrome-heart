class_name EventGraphValidator
extends RefCounted
## Structural, reachability, and unbounded-cycle validation for executable event graphs.

const NODE_TYPES: Array[StringName] = [
	&"music_state",
	&"exploration_objective",
	&"line",
	&"choice",
	&"effects",
	&"start_minigame",
	&"start_danmaku",
	&"start_duel",
	&"give_item",
	&"journal_entry",
	&"end_event",
]
const TONES: Array[StringName] = [&"direct", &"playful", &"patient", &"defiant"]


func validate(graph: EventGraphRecord) -> Array[String]:
	var errors: Array[String] = []
	if graph == null:
		return ["event graph is missing"]
	if graph.id == &"" or graph.entry_node_id == &"":
		errors.append("event graph requires stable event and entry-node IDs")
	var nodes: Dictionary[StringName, EventNodeRecord] = {}
	for node: EventNodeRecord in graph.nodes:
		if node == null or node.id == &"":
			errors.append("event graph contains a missing node")
			continue
		if nodes.has(node.id):
			errors.append("duplicate event node ID: %s" % node.id)
			continue
		nodes[node.id] = node
		_validate_shape(node, errors)
	if not nodes.has(graph.entry_node_id):
		errors.append("entry node does not exist: %s" % graph.entry_node_id)
		return errors
	for node: EventNodeRecord in nodes.values():
		for target: StringName in node.outgoing_node_ids():
			if not nodes.has(target):
				errors.append("node %s targets missing node %s" % [node.id, target])
	var reachable := _reachable(graph.entry_node_id, nodes)
	for node_id: StringName in nodes:
		if node_id not in reachable:
			errors.append("unreachable event node: %s" % node_id)
	var visit_state: Dictionary[StringName, int] = {}
	var stack: Array[StringName] = []
	_detect_cycle(graph.entry_node_id, nodes, visit_state, stack, errors)
	return errors


func _validate_shape(node: EventNodeRecord, errors: Array[String]) -> void:
	if node.type not in NODE_TYPES:
		errors.append("node %s has unsupported type %s" % [node.id, node.type])
		return
	if node.type == &"end_event":
		if node.outcome == &"":
			errors.append("end node %s requires an outcome" % node.id)
		if not node.outgoing_node_ids().is_empty():
			errors.append("end node %s cannot have outgoing edges" % node.id)
		return
	if node.type == &"choice":
		if node.choice == null or node.choice.id == &"":
			errors.append("choice node %s requires a typed choice" % node.id)
			return
		var tones: Array[StringName] = []
		for option: ChoiceOptionRecord in node.choice.options:
			if option.tone not in TONES or option.tone in tones or option.text_key == &"" or option.next_node_id == &"":
				errors.append("choice node %s has an invalid or duplicate tone option" % node.id)
			else:
				tones.append(option.tone)
		if tones.size() != TONES.size():
			errors.append("choice node %s must expose all four authored tones" % node.id)
		return
	if node.type in [&"start_minigame", &"start_danmaku", &"start_duel"]:
		if node.minigame_id == &"" or node.result_branches.is_empty():
			errors.append("mode node %s requires a mode ID and result branches" % node.id)
		return
	if node.type == &"line" and node.beat_id == &"":
		errors.append("line node %s requires a dialogue beat" % node.id)
	if node.type == &"give_item" and node.item_id == &"":
		errors.append("item node %s requires an item ID" % node.id)
	if node.type == &"journal_entry" and node.journal_entry_id == &"":
		errors.append("Journal node %s requires an entry ID" % node.id)
	if node.type == &"effects":
		if node.effects.is_empty():
			errors.append("effects node %s cannot be empty" % node.id)
		for effect: EventEffectRecord in node.effects:
			if effect.operation not in [&"relationship", &"set_flag", &"add_rumor", &"route_stage"]:
				errors.append("effects node %s has unsupported operation %s" % [node.id, effect.operation])
			elif effect.operation == &"set_flag" and not _is_flag_id(effect.key):
				errors.append("effects node %s has invalid flag ID %s" % [node.id, effect.key])
			elif effect.operation == &"route_stage":
				if not _matches_id(effect.character_id, "^char\\.[a-z0-9_]+(?:\\.[a-z0-9_]+)*$"):
					errors.append("effects node %s has invalid route-stage character %s" % [node.id, effect.character_id])
				if effect.stage < 1:
					errors.append("effects node %s has invalid route-stage target" % node.id)
			elif effect.operation == &"add_rumor":
				if not _matches_id(effect.rumor_id, "^rumor\\.[a-z0-9_]+(?:\\.[a-z0-9_]+)*$"):
					errors.append("effects node %s has invalid rumor ID %s" % [node.id, effect.rumor_id])
				if not _matches_id(effect.claim_key, "^rumor\\.[a-z0-9_]+(?:\\.[a-z0-9_]+)*$"):
					errors.append("effects node %s has invalid rumor claim %s" % [node.id, effect.claim_key])
				if effect.reliability_milli < 0 or effect.reliability_milli > 1000:
					errors.append("effects node %s has invalid rumor reliability" % node.id)
				if effect.privacy not in RumorState.PRIVACY_VALUES or effect.status not in RumorState.STATUS_VALUES:
					errors.append("effects node %s has invalid rumor privacy or status" % node.id)
	if node.next_node_id == &"" and node.type not in [&"choice", &"start_minigame", &"start_danmaku", &"start_duel"]:
		errors.append("node %s requires a next edge" % node.id)


func _is_flag_id(flag_id: StringName) -> bool:
	var expression := RegEx.new()
	if expression.compile("^(?:flag|evt)\\.[a-z0-9_]+(?:\\.[a-z0-9_]+)*$") != OK:
		return false
	return expression.search(String(flag_id)) != null


func _matches_id(value: StringName, pattern: String) -> bool:
	return RegEx.create_from_string(pattern).search(String(value)) != null


func _reachable(entry_id: StringName, nodes: Dictionary[StringName, EventNodeRecord]) -> Array[StringName]:
	var result: Array[StringName] = []
	var pending: Array[StringName] = [entry_id]
	while not pending.is_empty():
		var node_id: StringName = pending.pop_back()
		if node_id in result or not nodes.has(node_id):
			continue
		result.append(node_id)
		pending.append_array(nodes[node_id].outgoing_node_ids())
	return result


func _detect_cycle(
	node_id: StringName,
	nodes: Dictionary[StringName, EventNodeRecord],
	visit_state: Dictionary[StringName, int],
	stack: Array[StringName],
	errors: Array[String]
) -> void:
	if not nodes.has(node_id) or visit_state.get(node_id, 0) == 2:
		return
	if visit_state.get(node_id, 0) == 1:
		var start := stack.find(node_id)
		var cycle := stack.slice(start) if start >= 0 else stack.duplicate()
		cycle.append(node_id)
		errors.append("unbounded event cycle: %s" % " -> ".join(_strings(cycle)))
		return
	visit_state[node_id] = 1
	stack.append(node_id)
	for target: StringName in nodes[node_id].outgoing_node_ids():
		_detect_cycle(target, nodes, visit_state, stack, errors)
	stack.pop_back()
	visit_state[node_id] = 2


func _strings(values: Array[StringName]) -> Array[String]:
	var result: Array[String] = []
	for value: StringName in values:
		result.append(String(value))
	return result
