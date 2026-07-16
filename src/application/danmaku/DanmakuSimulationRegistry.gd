class_name DanmakuSimulationRegistry
extends RefCounted
## Closed component registry for deterministic encounter simulations.

const COMPONENT_SCRIPTS := {
	&"standard": preload("res://src/application/danmaku/BoundaryStainSimulation.gd"),
	&"photo_frame": preload("res://src/application/danmaku/PhotoGrazeSimulation.gd"),
	&"archive_adaptive": preload("res://src/application/danmaku/ArchiveAdaptiveSimulation.gd"),
}


func create(component_id: StringName) -> BoundaryStainSimulation:
	var script: Script = COMPONENT_SCRIPTS.get(component_id, COMPONENT_SCRIPTS[&"standard"])
	return script.new() as BoundaryStainSimulation


func component_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	result.assign(COMPONENT_SCRIPTS.keys())
	result.sort_custom(func(left: StringName, right: StringName) -> bool: return String(left) < String(right))
	return result
