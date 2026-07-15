class_name TestScarletDevilMansionContent
extends RefCounted
## M12 data-only event topology, bilingual copy, and reward metadata contracts.

const EVENT_ID := &"evt.sdm.late_by_three_minutes"


func run() -> Array[String]:
	var failures: Array[String] = []
	var repository := ContentRepository.new()
	var report := repository.load_sources()
	if not report.is_success():
		failures.append("SDM content failed typed loading: %s" % report.human_readable())
		return failures
	var graph := repository.graph(EVENT_ID)
	if graph == null:
		failures.append("Late by Three Minutes graph is absent")
		return failures
	if graph.location_id != &"loc.scarlet_devil_mansion" or graph.cast != [&"char.sakuya_izayoi", &"char.patchouli_knowledge", &"char.remilia_scarlet"]:
		failures.append("SDM graph lost its data-authored location or cast")
	_expect_tone_topology(graph, failures)
	_expect_mode_topology(graph, failures)
	_expect_afterbeat_and_rewards(graph, failures)
	_expect_bilingual_content(repository, failures)
	return failures


func _expect_tone_topology(graph: EventGraphRecord, failures: Array[String]) -> void:
	var choice := graph.node(&"n004").choice
	if choice == null or choice.options.size() != 4:
		failures.append("Sakuya opening choice does not expose four tones")
		return
	var expected_facets := {&"direct": &"respect", &"playful": &"spark", &"patient": &"ease", &"defiant": &"strain"}
	for option: ChoiceOptionRecord in choice.options:
		var effect_node := graph.node(option.next_node_id)
		if effect_node == null or effect_node.effects.size() != 1:
			failures.append("%s tone does not lead to one transactional effect" % option.tone)
			continue
		var effect := effect_node.effects[0]
		if effect.character_id != &"char.sakuya_izayoi" or effect.facet != expected_facets.get(option.tone) or effect.delta != 1:
			failures.append("%s tone has the wrong Sakuya relationship effect" % option.tone)


func _expect_mode_topology(graph: EventGraphRecord, failures: Array[String]) -> void:
	var service := graph.node(&"n006")
	if service == null or service.type != &"start_minigame" or service.minigame_id != &"mini.sdm.time_grid_service":
		failures.append("event omitted the time-grid service handoff")
		return
	var branches := _branches(service)
	if branches.get(&"excellent") != &"n_service_excellent" or branches.get(&"clear") != &"n_service_clear" or branches.get(&"loss") != &"n_service_loss":
		failures.append("time-grid outcomes do not preserve authored escalation topology")
	var loss_line := graph.node(&"n_service_loss")
	if loss_line == null or loss_line.next_node_id != &"n_danmaku_music":
		failures.append("service loss does not escalate toward knife danmaku")
	var danmaku := graph.node(&"n_danmaku")
	if danmaku == null or danmaku.minigame_id != &"danmaku.sdm.missing_minute_knives" or _branches(danmaku).size() != 3:
		failures.append("knife escalation lacks the three production result branches")


func _expect_afterbeat_and_rewards(graph: EventGraphRecord, failures: Array[String]) -> void:
	for node_id: StringName in [&"n_after_01", &"n_after_02", &"n_patchouli", &"n_remilia_public", &"n_remilia_private"]:
		if graph.node(node_id) == null:
			failures.append("event omitted afterbeat node %s" % node_id)
	var item := graph.node(&"n_item")
	if item == null or item.item_owner_character_id != &"char.sakuya_izayoi" or item.item_dialogue_tags != [&"sdm.missing_minute"]:
		failures.append("Unfinished Checklist metadata is not data-owned")
	var journal := graph.node(&"n_journal")
	if journal == null or journal.journal_tags != [&"missing_minute", &"service_route"]:
		failures.append("missing-minute Journal tags are not data-owned")


func _expect_bilingual_content(repository: ContentRepository, failures: Array[String]) -> void:
	var sakuya_beats := 0
	for beat: DialogueBeatRecord in repository.all_dialogue_beats():
		if String(beat.id).begins_with("beat.sdm.late."):
			sakuya_beats += 1
			var localized := repository.localized_string(beat.text_key)
			if localized == null or localized.english.is_empty() or localized.japanese.is_empty():
				failures.append("SDM beat lacks bilingual text: %s" % beat.id)
	if sakuya_beats != 16:
		failures.append("Late by Three Minutes expected 16 beats, got %d" % sakuya_beats)


func _branches(node: EventNodeRecord) -> Dictionary[StringName, StringName]:
	var result: Dictionary[StringName, StringName] = {}
	for branch: ModeResultBranchRecord in node.result_branches:
		result[branch.result_tag] = branch.next_node_id
	return result
