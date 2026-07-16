class_name MansionServiceSpotFactory
extends RefCounted
## Typed foyer-to-kitchen spot packet selected as an exploration component.


static func build() -> ExplorationSpotDefinition:
	var spot := ExplorationSpotDefinition.new()
	spot.location_id = &"loc.scarlet_devil_mansion"
	spot.spot_id = &"loc.scarlet_devil_mansion.foyer"
	spot.objective_id = &"obj.sdm.trace_missing_minute"
	spot.mode_id = &"explore.sdm.foyer_service"
	spot.companion_id = &"char.sakuya_izayoi"
	spot.required_sequence = [&"prop.sdm.offset_clock", &"prop.sdm.reset_tray"]
	spot.start_position = Vector2(72, 140)
	spot.environment_style = &"mansion_service"
	spot.header_primary_key = &"ui.exploration.sdm.location.foyer"
	spot.header_secondary_key = &"ui.exploration.sdm.location.kitchen"
	spot.complete_key = &"ui.exploration.sdm.objective.complete"
	spot.hint_key = &"ui.exploration.sdm.hint"
	spot.companion_key = &"ui.exploration.sdm.companion"
	# Service furniture sits behind the walk lane, so the story route never depends
	# on discovering the optional hop input.
	spot.solid_obstacles = []
	spot.interactables = [
		# The interaction anchor sits below the clock face, within the shared 36 px
		# probe used by a floor-bound player.
		_interactable(&"prop.sdm.offset_clock", Vector2(118, 104), &"observe", &"ui.exploration.sdm.note.clock", &"sfx.step.wood", 32.0, true),
		_interactable(&"prop.sdm.reset_tray", Vector2(220, 130), &"observe", &"ui.exploration.sdm.note.tray", &"sfx.prop.cup", 28.0, true),
		_interactable(&"prop.sdm.foyer_door", Vector2(306, 122), &"use", &"ui.exploration.sdm.note.door", &"sfx.door.wood", 28.0),
		_interactable(&"prop.sdm.kitchen_pass", Vector2(410, 112), &"observe", &"ui.exploration.sdm.note.pass", &"sfx.prop.cup", 30.0),
		_interactable(&"prop.sdm.checklist", Vector2(486, 126), &"observe", &"ui.exploration.sdm.note.checklist", &"sfx.step.wood", 28.0),
		_interactable(&"char.sakuya_izayoi", Vector2(552, 130), &"talk", &"ui.exploration.sdm.note.sakuya", &"sfx.door.wood", 32.0),
	]
	spot.event_triggers.append(ExplorationEventTrigger.new(
		&"trigger.sdm.late_by_three_minutes",
		&"evt.sdm.late_by_three_minutes",
		Rect2(524, 102, 62, 40),
		spot.objective_id
	))
	return spot


static func _interactable(target_id: StringName, position: Vector2, kind: StringName, note_key: StringName, sfx_id: StringName, radius: float, required: bool = false) -> ExplorationInteractable:
	var prompt_key: StringName = {&"talk": &"ui.exploration.talk", &"use": &"ui.exploration.use"}.get(kind, &"ui.exploration.observe")
	var action := ExplorationAction.new(StringName("explore.%s.%s" % [kind, String(target_id).replace(".", "_")]), kind, target_id, prompt_key, note_key, sfx_id)
	var interactable := ExplorationInteractable.new(target_id, position, action, radius)
	interactable.required_for_objective = required
	return interactable
