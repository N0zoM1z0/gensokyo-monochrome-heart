class_name EventChoiceResolver
extends RefCounted
## Applies authored visibility and availability predicates without ranking tones.

var _predicates := EventPredicateEvaluator.new()


func resolve(choice: ChoiceRecord, state: GameState) -> EventChoiceState:
	var result := EventChoiceState.new()
	if choice == null:
		return result
	result.choice_id = choice.id
	for authored: ChoiceOptionRecord in choice.options:
		var visibility := _predicates.evaluate_all(authored.visible_if, state)
		if not _predicates.all_pass(visibility):
			continue
		var option := EventChoiceOptionState.new()
		option.tone = authored.tone
		option.text_key = authored.text_key
		option.next_node_id = authored.next_node_id
		option.predicate_results = _predicates.evaluate_all(authored.available_if, state)
		option.is_available = _predicates.all_pass(option.predicate_results)
		option.unavailable_reason_key = authored.unavailable_reason_key
		result.options.append(option)
	return result
