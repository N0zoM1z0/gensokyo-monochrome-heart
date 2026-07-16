class_name ExplorationLoopTopologyRegistry
extends RefCounted
## Closed registry keeps topology selection out of the generic controller.


static func create(component_id: StringName) -> ExplorationLoopTopology:
	match component_id:
		&"bamboo_four_dawns":
			return BambooFourDawnsTopology.new()
		_:
			return null
