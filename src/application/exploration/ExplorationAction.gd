class_name ExplorationAction
extends RefCounted
## Stable, localized action intent registered by an exploration target.

const KINDS: Array[StringName] = [&"observe", &"talk", &"use"]

var action_id: StringName
var kind: StringName
var target_id: StringName
var prompt_key: StringName
var observation_key: StringName
var sfx_id: StringName


func _init(
	p_action_id: StringName = &"",
	p_kind: StringName = &"observe",
	p_target_id: StringName = &"",
	p_prompt_key: StringName = &"",
	p_observation_key: StringName = &"",
	p_sfx_id: StringName = &""
) -> void:
	action_id = p_action_id
	kind = p_kind
	target_id = p_target_id
	prompt_key = p_prompt_key
	observation_key = p_observation_key
	sfx_id = p_sfx_id


func validation_errors() -> Array[String]:
	var errors: Array[String] = []
	if action_id == &"" or target_id == &"":
		errors.append("exploration action requires stable action and target IDs")
	if kind not in KINDS:
		errors.append("unsupported exploration action kind: %s" % kind)
	if prompt_key == &"":
		errors.append("exploration action requires a localized prompt key")
	return errors
