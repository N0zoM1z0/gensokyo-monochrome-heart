class_name EventDebugOverlayModel
extends RefCounted
## Compact developer-only text projection for the runtime overlay.

var lines: Array[String] = []


static func build(snapshot: EventDebugSnapshot) -> EventDebugOverlayModel:
	var model := EventDebugOverlayModel.new()
	if snapshot == null:
		model.lines.append("EVENT DEBUG unavailable")
		return model
	model.lines = [
		"EVENT %s / %s wait=%s" % [snapshot.event_id, snapshot.node_id, snapshot.waiting_for],
		"STEPS %d seed=%d checkpoint=%s" % [snapshot.total_steps, snapshot.deterministic_seed, snapshot.pending_checkpoint],
		"TEXT %s origin C%d/F%d/O%d" % [snapshot.localization_key, snapshot.origin_canon, snapshot.origin_fanon, snapshot.origin_original],
	]
	for predicate: PredicateEvaluationRecord in snapshot.predicate_results:
		model.lines.append("PRED %s=%s %s" % [predicate.predicate, predicate.passed, predicate.diagnostic])
	if not snapshot.last_command_ids.is_empty():
		model.lines.append("COMMANDS %s" % ",".join(_strings(snapshot.last_command_ids)))
	return model


static func _strings(values: Array[StringName]) -> Array[String]:
	var result: Array[String] = []
	for value: StringName in values:
		result.append(String(value))
	return result
