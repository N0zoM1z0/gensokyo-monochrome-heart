class_name MutateRumorCommand
extends GameCommand
## Rewrites a claim while preserving its stable rumor identity and source.

var rumor_id: StringName
var next_claim_key: StringName
var reliability_delta_milli: int
var next_privacy: StringName


func _init(
	p_rumor_id: StringName,
	p_next_claim_key: StringName,
	p_reliability_delta_milli: int,
	p_next_privacy: StringName
) -> void:
	super(&"state.mutate_rumor")
	rumor_id = p_rumor_id
	next_claim_key = p_next_claim_key
	reliability_delta_milli = p_reliability_delta_milli
	next_privacy = p_next_privacy
