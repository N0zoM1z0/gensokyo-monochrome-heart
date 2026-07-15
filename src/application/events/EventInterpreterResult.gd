class_name EventInterpreterResult
extends RefCounted
## One stable interpreter yield: input, mode, end, or explicit error.

enum Status {
	WAIT_INPUT,
	WAIT_MODE,
	END,
	ERROR,
}

var status: Status = Status.ERROR
var event_id: StringName
var node_id: StringName
var beat: DialogueBeatRecord
var choice: EventChoiceState
var mode_context: ModeContext
var outcome: StringName
var checkpoint_reason: StringName
var presentation_cues: Array[EventPresentationCue] = []
var predicate_results: Array[PredicateEvaluationRecord] = []
var diagnostic: String


func is_error() -> bool:
	return status == Status.ERROR
