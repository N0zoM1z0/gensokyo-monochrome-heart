class_name FiveImpossibleErrandsCatalog
extends RefCounted
## The five trials are data packets; the sequence runtime does not special-case Kaguya.

const APPROACHES: Array[StringName] = [&"literal", &"clever", &"refuse"]


static func build() -> Array[ImpossibleErrandDefinition]:
	return [
		_errand(&"stone_bowl", &"balance"),
		_errand(&"hourai_branch", &"arrange"),
		_errand(&"fire_rat_robe", &"test"),
		_errand(&"dragon_jewel", &"align"),
		_errand(&"swallow_cowry", &"wait"),
	]


static func _errand(slug: StringName, trial_kind: StringName) -> ImpossibleErrandDefinition:
	var item := ImpossibleErrandDefinition.new()
	item.errand_id = StringName("errand.ein.%s" % slug)
	item.trial_kind = trial_kind
	item.treasure_key = StringName("ui.minigame.errands.%s.treasure" % slug)
	item.request_key = StringName("ui.minigame.errands.%s.request" % slug)
	item.rule_key = StringName("ui.minigame.errands.%s.rule" % slug)
	for approach: StringName in APPROACHES:
		item.options.append(ImpossibleErrandOption.new(
			approach,
			StringName("ui.minigame.errands.approach.%s" % approach),
			StringName("ui.minigame.errands.%s.%s.action" % [slug, approach]),
			StringName("ui.minigame.errands.%s.%s.consequence" % [slug, approach])
		))
	return item
