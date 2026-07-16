class_name RumorState
extends RefCounted
## Structured claim state using deterministic integer reliability basis points.

const PRIVACY_VALUES: Array[StringName] = [&"private", &"shared", &"public"]
const STATUS_VALUES: Array[StringName] = [&"unresolved", &"corrected", &"refuted", &"published"]

var rumor_id: StringName
var claim_key: StringName
var source_character_id: StringName
var reliability_milli: int = 0
var privacy: StringName = &"private"
var mutation_count: int = 0
var status: StringName = &"unresolved"
var acquired_day: int = 1


func _init(p_rumor_id: StringName = &"") -> void:
	rumor_id = p_rumor_id


func duplicate_state() -> RumorState:
	var copy := RumorState.new(rumor_id)
	copy.claim_key = claim_key
	copy.source_character_id = source_character_id
	copy.reliability_milli = reliability_milli
	copy.privacy = privacy
	copy.mutation_count = mutation_count
	copy.status = status
	copy.acquired_day = acquired_day
	return copy


func confidence_label() -> StringName:
	return RumorConfidenceRules.label_for(self)
