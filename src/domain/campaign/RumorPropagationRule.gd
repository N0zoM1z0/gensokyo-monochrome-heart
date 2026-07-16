class_name RumorPropagationRule
extends RefCounted
## Data-only day-boundary rewrite and the regions reached by that retelling.

var rumor_id: StringName
var expected_claim_key: StringName
var next_claim_key: StringName
var reliability_delta_milli: int
var next_privacy: StringName
var region_conditions: Dictionary[StringName, StringName] = {}


func _init(
	p_rumor_id: StringName = &"",
	p_expected_claim_key: StringName = &"",
	p_next_claim_key: StringName = &"",
	p_reliability_delta_milli: int = 0,
	p_next_privacy: StringName = &""
) -> void:
	rumor_id = p_rumor_id
	expected_claim_key = p_expected_claim_key
	next_claim_key = p_next_claim_key
	reliability_delta_milli = p_reliability_delta_milli
	next_privacy = p_next_privacy
