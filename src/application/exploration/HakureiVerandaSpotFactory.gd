class_name HakureiVerandaSpotFactory
extends RefCounted
## One typed authored spot packet; generic player control contains no event IDs.


static func build() -> ExplorationSpotDefinition:
	var spot := ExplorationSpotDefinition.new()
	spot.location_id = &"loc.hakurei_shrine"
	spot.spot_id = &"loc.hakurei_shrine.veranda"
	spot.objective_id = &"obj.hkr.find_second_cup"
	spot.required_sequence = [&"prop.unpaired_cup", &"prop.empty_cushion"]
	spot.start_position = Vector2(128, 140)
	spot.solid_obstacles = [Rect2(66, 121, 27, 19), Rect2(18, 106, 13, 34)]
	spot.interactables = [
		_interactable(&"prop.old_tree", Vector2(28, 118), &"observe", &"ui.exploration.note.tree", &"sfx.step.wood", 28.0),
		_interactable(&"prop.donation_box", Vector2(79, 129), &"observe", &"ui.exploration.note.donation_box", &"sfx.step.wood", 26.0),
		_interactable(&"prop.unpaired_cup", Vector2(154, 112), &"observe", &"ui.exploration.note.cup", &"sfx.prop.cup", 28.0, true),
		_interactable(&"prop.empty_cushion", Vector2(205, 136), &"observe", &"ui.exploration.note.cushion", &"sfx.prop.cup", 25.0, true),
		_interactable(&"prop.veranda_door", Vector2(300, 120), &"use", &"ui.exploration.note.door", &"sfx.door.wood", 28.0),
		_interactable(&"prop.broom", Vector2(410, 129), &"observe", &"ui.exploration.note.broom", &"sfx.step.wood", 26.0),
		_interactable(&"char.reimu_hakurei", Vector2(252, 130), &"talk", &"ui.exploration.note.reimu", &"sfx.prop.cup", 30.0),
		_interactable(&"char.marisa_kirisame", Vector2(536, 130), &"talk", &"ui.exploration.note.marisa", &"sfx.door.wood", 30.0),
	]
	spot.event_triggers.append(ExplorationEventTrigger.new(
		&"trigger.hkr.empty_cushion",
		&"evt.hkr.empty_cushion",
		Rect2(234, 104, 54, 38),
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
	var suffix := String(target_id).replace(".", "_")
	var action := ExplorationAction.new(
		StringName("explore.%s.%s" % [kind, suffix]),
		kind,
		target_id,
		prompt_key,
		note_key,
		sfx_id
	)
	var interactable := ExplorationInteractable.new(target_id, position, action, radius)
	interactable.required_for_objective = required
	return interactable
