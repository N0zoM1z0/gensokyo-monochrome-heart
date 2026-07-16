class_name EventModeSceneRegistry
extends RefCounted
## Data-owned mapping from authored mechanical IDs to packed presentation scenes.

const SCENE_PATHS := {
	&"mini.shrine.tea_temperature": "res://src/presentation/minigames/TeaTemperatureMode.tscn",
	&"mini.sdm.time_grid_service": "res://src/presentation/minigames/TimeGridServiceMode.tscn",
	&"danmaku.hkr.boundary_stain": "res://src/presentation/danmaku/BoundaryStainMode.tscn",
	&"danmaku.sdm.missing_minute_knives": "res://src/presentation/danmaku/MissingMinuteKnivesMode.tscn",
	&"danmaku.mtn.tomorrows_headline": "res://src/presentation/danmaku/TomorrowsHeadlineMode.tscn",
	&"duel.hkr.spell_card_terms": "res://src/presentation/fighter/CompactFighterMode.tscn",
}


func scene_for(mode_id: StringName) -> PackedScene:
	var path: String = SCENE_PATHS.get(mode_id, "")
	return ResourceLoader.load(path, "PackedScene") as PackedScene if not path.is_empty() else null


func registered_mode_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	result.assign(SCENE_PATHS.keys())
	result.sort_custom(func(left: StringName, right: StringName) -> bool: return String(left) < String(right))
	return result
