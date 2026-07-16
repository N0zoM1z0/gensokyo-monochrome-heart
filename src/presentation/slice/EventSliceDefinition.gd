class_name EventSliceDefinition
extends RefCounted
## Presentation composition packet for one authored event slice.

var component_id: StringName
var event_id: StringName
var location_id: StringName
var journal_id: StringName
var keepsake_id: StringName
var exploration_scene_path: String
var exploration_mode_id: StringName
var spot_id: StringName
var objective_id: StringName
var companion_id: StringName
var exploration_target_ids: Array[StringName] = []
var exploration_trigger_position := Vector2.ZERO
var visible_character_ids: Array[StringName] = []
var initial_music_id: StringName
var default_stage_component: StringName
var stage_components: Dictionary[StringName, StringName] = {}
var afterbeat_node_prefixes: Array[String] = []
var invitation_component: StringName = &"note"
var reward_component: StringName = &"cup"
var map_marker := Vector2(109, 58)
var invitation_header_key: StringName = &"ui.slice.invitation.header"
var invitation_body_key: StringName = &"ui.slice.invitation.body"
var invitation_confirm_key: StringName = &"ui.slice.invitation.confirm"
var map_header_key: StringName = &"ui.slice.map.header"
var map_body_key: StringName = &"ui.slice.map.body"
var map_confirm_key: StringName = &"ui.slice.map.confirm"
var reward_header_key: StringName = &"ui.slice.reward.header"
var reward_item_name_key: StringName = &"ui.slice.reward.item_name"
var reward_confirm_key: StringName = &"ui.slice.reward.confirm"
var complete_header_key: StringName = &"ui.slice.complete.header"
var complete_body_key: StringName = &"ui.slice.complete.body"
var complete_confirm_key: StringName = &"ui.slice.complete.confirm"


func stage_component(node_id: StringName) -> StringName:
	return stage_components.get(node_id, default_stage_component)


func is_afterbeat_node(node_id: StringName) -> bool:
	var value := String(node_id)
	for prefix: String in afterbeat_node_prefixes:
		if value.begins_with(prefix):
			return true
	return false
