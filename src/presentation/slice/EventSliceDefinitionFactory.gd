class_name EventSliceDefinitionFactory
extends RefCounted
## Region composition edge. Shared slice behavior consumes only this packet.

const COMPONENTS := [&"hakurei_shrine", &"scarlet_devil_mansion", &"youkai_mountain"]


static func build(component_id: StringName) -> EventSliceDefinition:
	var definition := EventSliceDefinition.new()
	definition.component_id = component_id if component_id in COMPONENTS else &"hakurei_shrine"
	match definition.component_id:
		&"scarlet_devil_mansion":
			_configure_mansion(definition)
		&"youkai_mountain":
			_configure_mountain(definition)
		_:
			_configure_shrine(definition)
	return definition


static func for_event(event_id: StringName) -> EventSliceDefinition:
	for component_id: StringName in COMPONENTS:
		var definition := build(component_id)
		if definition.event_id == event_id:
			return definition
	return null


static func for_state(state: GameState, fallback_component: StringName) -> EventSliceDefinition:
	if state != null and state.active_event_id != &"":
		var active := for_event(state.active_event_id)
		if active != null:
			return active
	if state != null:
		for component_id: StringName in COMPONENTS:
			var candidate := build(component_id)
			if (
				candidate.event_id in state.completed_event_ids
				and state.journal.entries.has(candidate.journal_id)
				and not state.journal.entries[candidate.journal_id].is_read
			):
				return candidate
		# A day-end manual save marks the Journal entry read before advancing to
		# the next morning. Preserve the region shell on Continue by matching the
		# completed slice at the player's current location.
		for component_id: StringName in COMPONENTS:
			var candidate := build(component_id)
			if (
				candidate.location_id == state.current_location
				and candidate.event_id in state.completed_event_ids
			):
				return candidate
	return build(fallback_component)


static func _configure_shrine(definition: EventSliceDefinition) -> void:
	definition.event_id = &"evt.hkr.empty_cushion"
	definition.location_id = &"loc.hakurei_shrine"
	definition.journal_id = &"journal.hkr.empty_cushion"
	definition.keepsake_id = &"item.keepsake.unpaired_cup"
	definition.exploration_scene_path = "res://src/presentation/exploration/ExplorationMode.tscn"
	definition.exploration_mode_id = &"explore.hakurei_shrine.veranda"
	definition.spot_id = &"loc.hakurei_shrine.veranda"
	definition.objective_id = &"obj.hkr.find_second_cup"
	definition.companion_id = &"char.reimu_hakurei"
	definition.exploration_target_ids = [&"prop.unpaired_cup", &"prop.empty_cushion"]
	definition.exploration_trigger_position = Vector2(250, 130)
	definition.visible_character_ids = [&"char.reimu_hakurei", &"char.marisa_kirisame"]
	definition.initial_music_id = &"mus_shrine_day"
	definition.default_stage_component = &"shrine"
	definition.afterbeat_node_prefixes = ["n_afterbeat"]
	for node_id: StringName in [&"n_afterbeat_01", &"n_afterbeat_02", &"n_afterbeat_03", &"n_afterbeat_04"]:
		definition.stage_components[node_id] = &"shrine_afterbeat"


static func _configure_mansion(definition: EventSliceDefinition) -> void:
	definition.event_id = &"evt.sdm.late_by_three_minutes"
	definition.location_id = &"loc.scarlet_devil_mansion"
	definition.journal_id = &"journal.sdm.missing_minute"
	definition.keepsake_id = &"item.keepsake.unfinished_checklist"
	definition.exploration_scene_path = "res://src/presentation/exploration/MansionServiceExplorationMode.tscn"
	definition.exploration_mode_id = &"explore.sdm.foyer_service"
	definition.spot_id = &"loc.scarlet_devil_mansion.foyer"
	definition.objective_id = &"obj.sdm.trace_missing_minute"
	definition.companion_id = &"char.sakuya_izayoi"
	definition.exploration_target_ids = [&"prop.sdm.offset_clock", &"prop.sdm.reset_tray"]
	definition.exploration_trigger_position = Vector2(552, 130)
	definition.visible_character_ids = [&"char.sakuya_izayoi", &"char.patchouli_knowledge", &"char.remilia_scarlet"]
	definition.initial_music_id = &"mus_sdm_foyer"
	definition.default_stage_component = &"mansion_clock"
	definition.afterbeat_node_prefixes = ["n_after_"]
	definition.stage_components = {
		&"n_after_01": &"mansion_afterbeat",
		&"n_after_02": &"mansion_afterbeat",
		&"n_patchouli": &"mansion_library",
		&"n_remilia_public": &"mansion_balcony_public",
		&"n_remilia_private": &"mansion_balcony_private",
	}
	definition.invitation_component = &"schedule"
	definition.reward_component = &"checklist"
	definition.map_marker = Vector2(156, 106)
	definition.invitation_header_key = &"ui.slice.sdm.invitation.header"
	definition.invitation_body_key = &"ui.slice.sdm.invitation.body"
	definition.invitation_confirm_key = &"ui.slice.sdm.invitation.confirm"
	definition.map_body_key = &"ui.slice.sdm.map.body"
	definition.map_confirm_key = &"ui.slice.sdm.map.confirm"
	definition.reward_item_name_key = &"ui.slice.sdm.reward.item_name"
	definition.complete_header_key = &"ui.slice.sdm.complete.header"
	definition.complete_body_key = &"ui.slice.sdm.complete.body"


static func _configure_mountain(definition: EventSliceDefinition) -> void:
	definition.event_id = &"evt.mtn.tomorrows_headline"
	definition.location_id = &"loc.youkai_mountain"
	definition.journal_id = &"journal.mtn.tomorrows_headline"
	definition.keepsake_id = &"item.keepsake.unprinted_caption"
	definition.exploration_scene_path = "res://src/presentation/exploration/YoukaiMountainExplorationMode.tscn"
	definition.exploration_mode_id = &"explore.mtn.wind_ridge"
	definition.spot_id = &"loc.youkai_mountain.wind_ridge"
	definition.objective_id = &"obj.mtn.trace_tomorrows_photo"
	definition.companion_id = &""
	definition.exploration_target_ids = [&"prop.mtn.tomorrow_paper", &"prop.mtn.intact_guardrail"]
	definition.exploration_trigger_position = Vector2(552, 130)
	definition.visible_character_ids = [
		&"char.aya_shameimaru",
		&"char.hatate_himekaidou",
		&"char.momiji_inubashiri",
		&"char.nitori_kawashiro",
		&"char.sanae_kochiya",
	]
	definition.initial_music_id = &"mus_mountain_base"
	definition.default_stage_component = &"mountain_report"
	definition.afterbeat_node_prefixes = ["n_after_"]
	definition.stage_components = {
		&"n_direct_line": &"mountain_boundary",
		&"n_playful_line": &"mountain_boundary",
		&"n_patient_line": &"mountain_boundary",
		&"n_defiant_line": &"mountain_boundary",
		&"n_photo_origin": &"mountain_route",
		&"n_danmaku_clear": &"mountain_new_frame",
		&"n_danmaku_assist": &"mountain_new_frame",
		&"n_danmaku_loss": &"mountain_new_frame",
		&"n_after_01": &"mountain_patrol",
		&"n_after_02": &"mountain_camera_lowered",
	}
	definition.invitation_component = &"newspaper"
	definition.reward_component = &"caption"
	definition.map_marker = Vector2(190, 73)
	definition.invitation_header_key = &"ui.slice.mtn.invitation.header"
	definition.invitation_body_key = &"ui.slice.mtn.invitation.body"
	definition.invitation_confirm_key = &"ui.slice.mtn.invitation.confirm"
	definition.map_body_key = &"ui.slice.mtn.map.body"
	definition.map_confirm_key = &"ui.slice.mtn.map.confirm"
	definition.reward_item_name_key = &"ui.slice.mtn.reward.item_name"
	definition.complete_header_key = &"ui.slice.mtn.complete.header"
	definition.complete_body_key = &"ui.slice.mtn.complete.body"
