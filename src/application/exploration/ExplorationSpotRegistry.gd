class_name ExplorationSpotRegistry
extends RefCounted
## Closed component registry keeps authored spots out of the generic controller.


static func build(component_id: StringName) -> ExplorationSpotDefinition:
	match component_id:
		&"mansion_service":
			return MansionServiceSpotFactory.build()
		&"mountain_trail":
			return YoukaiMountainSpotFactory.build()
		&"bamboo_four_dawns":
			return EienteiBambooSpotFactory.build()
		_:
			return HakureiVerandaSpotFactory.build()
