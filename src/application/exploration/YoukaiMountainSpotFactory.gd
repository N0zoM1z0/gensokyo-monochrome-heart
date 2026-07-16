class_name YoukaiMountainSpotFactory
extends RefCounted
## Typed trail-to-tengu-threshold spot that hands the player to Aya's headline event.


static func build() -> ExplorationSpotDefinition:
	var spot := ExplorationSpotDefinition.new()
	spot.location_id = &"loc.youkai_mountain"
	spot.spot_id = &"loc.youkai_mountain.wind_ridge"
	spot.objective_id = &"obj.mtn.trace_tomorrows_photo"
	spot.mode_id = &"explore.mtn.wind_ridge"
	spot.companion_id = &""
	spot.required_sequence = [&"prop.mtn.tomorrow_paper", &"prop.mtn.intact_guardrail"]
	spot.start_position = Vector2(72, 140)
	spot.environment_style = &"mountain_trail"
	spot.footstep_sfx_id = &"sfx.step.stone"
	spot.header_primary_key = &"ui.exploration.mtn.location.trail"
	spot.header_secondary_key = &"ui.exploration.mtn.location.threshold"
	spot.complete_key = &"ui.exploration.mtn.objective.complete"
	spot.hint_key = &"ui.exploration.mtn.hint"
	spot.companion_key = &"ui.exploration.mtn.companion"
	spot.counter_label_key = &"ui.exploration.mtn.clues"
	spot.solid_obstacles = []
	spot.interactables = [
		_interactable(&"prop.mtn.tomorrow_paper", Vector2(118, 130), &"observe", &"ui.exploration.mtn.note.paper", &"sfx.paper.rustle", 28.0, true),
		_interactable(&"prop.mtn.intact_guardrail", Vector2(222, 126), &"observe", &"ui.exploration.mtn.note.guardrail", &"sfx.step.stone", 30.0, true),
		_interactable(&"prop.mtn.rope_bridge", Vector2(306, 128), &"use", &"ui.exploration.mtn.note.bridge", &"sfx.wind.gust", 28.0),
		_interactable(&"prop.mtn.patrol_notice", Vector2(394, 122), &"observe", &"ui.exploration.mtn.note.patrol", &"sfx.paper.rustle", 28.0),
		_interactable(&"prop.mtn.camera_perch", Vector2(470, 124), &"observe", &"ui.exploration.mtn.note.perch", &"sfx.camera.shutter", 28.0),
		_interactable(&"char.aya_shameimaru", Vector2(552, 130), &"talk", &"ui.exploration.mtn.note.aya", &"sfx.camera.shutter", 32.0),
	]
	spot.event_triggers.append(ExplorationEventTrigger.new(
		&"trigger.mtn.tomorrows_headline",
		&"evt.mtn.tomorrows_headline",
		Rect2(520, 102, 66, 40),
		spot.objective_id
	))
	return spot


static func _interactable(
	target_id: StringName,
	position: Vector2,
	kind: StringName,
	note_key: StringName,
	sfx_id: StringName,
	radius: float,
	required: bool = false
) -> ExplorationInteractable:
	var prompt_key: StringName = {
		&"talk": &"ui.exploration.talk",
		&"use": &"ui.exploration.use",
	}.get(kind, &"ui.exploration.observe")
	var action := ExplorationAction.new(
		StringName("explore.%s.%s" % [kind, String(target_id).replace(".", "_")]),
		kind,
		target_id,
		prompt_key,
		note_key,
		sfx_id
	)
	var interactable := ExplorationInteractable.new(target_id, position, action, radius)
	interactable.required_for_objective = required
	return interactable
