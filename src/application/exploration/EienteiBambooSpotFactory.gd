class_name EienteiBambooSpotFactory
extends RefCounted
## Authored four-dawn corridor whose right seam advances only after the right cue.


static func build() -> ExplorationSpotDefinition:
	var spot := ExplorationSpotDefinition.new()
	spot.location_id = &"loc.eientei"
	spot.spot_id = &"loc.eientei.long_corridor"
	spot.objective_id = &"obj.ein.cross_four_dawns"
	spot.mode_id = &"explore.ein.four_dawns"
	spot.companion_id = &""
	spot.required_sequence = BambooFourDawnsTopology.ANCHOR_SEQUENCE.duplicate()
	spot.start_position = Vector2(64, 140)
	spot.environment_style = &"bamboo_loop"
	spot.topology_component = &"bamboo_four_dawns"
	spot.loop_entry_x = 64.0
	spot.loop_exit_x = 586.0
	spot.footstep_sfx_id = &"sfx.step.wood"
	spot.header_primary_key = &"ui.exploration.ein.location.bamboo"
	spot.header_secondary_key = &"ui.exploration.ein.location.corridor"
	spot.complete_key = &"ui.exploration.ein.objective.complete"
	spot.hint_key = &"ui.exploration.ein.hint"
	spot.companion_key = &"ui.exploration.ein.companion"
	spot.counter_label_key = &"ui.exploration.ein.dawn"
	spot.solid_obstacles = []
	spot.interactables = [
		_interactable(&"prop.ein.wind_chime", Vector2(148, 116), &"ui.exploration.ein.note.chime", &"sfx.ein.chime"),
		_interactable(&"prop.ein.medicine_click", Vector2(272, 124), &"ui.exploration.ein.note.medicine", &"sfx.ein.medicine"),
		_interactable(&"prop.ein.rabbit_knock", Vector2(396, 128), &"ui.exploration.ein.note.rabbit", &"sfx.ein.knock"),
		_interactable(&"prop.ein.bird_call", Vector2(514, 112), &"ui.exploration.ein.note.bird", &"sfx.ein.bird"),
	]
	spot.event_triggers.append(ExplorationEventTrigger.new(
		&"trigger.ein.four_dawns",
		&"evt.ein.four_dawns",
		Rect2(574, 102, 52, 40),
		spot.objective_id
	))
	return spot


static func _interactable(
	target_id: StringName,
	position: Vector2,
	note_key: StringName,
	sfx_id: StringName
) -> ExplorationInteractable:
	var action := ExplorationAction.new(
		StringName("explore.listen.%s" % String(target_id).replace(".", "_")),
		&"observe",
		target_id,
		&"ui.exploration.listen",
		note_key,
		sfx_id
	)
	var interactable := ExplorationInteractable.new(target_id, position, action, 30.0)
	interactable.required_for_objective = true
	return interactable
