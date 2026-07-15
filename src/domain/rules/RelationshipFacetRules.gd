class_name RelationshipFacetRules
extends RefCounted
## Centralized, migratable bounds and qualitative relationship thresholds.

const MINIMUM_VALUE := -3
const MAXIMUM_VALUE := 3
const FACETS: Array[StringName] = [&"trust", &"ease", &"respect", &"spark", &"strain"]
const BANDS: Array[StringName] = [&"low", &"open", &"high"]


static func value_for(state: RelationshipState, facet: StringName) -> int:
	match facet:
		&"trust":
			return state.trust
		&"ease":
			return state.ease
		&"respect":
			return state.respect
		&"spark":
			return state.spark
		&"strain":
			return state.strain
		_:
			return 0


static func set_value(state: RelationshipState, facet: StringName, value: int) -> bool:
	if state == null or facet not in FACETS:
		return false
	var bounded := clampi(value, MINIMUM_VALUE, MAXIMUM_VALUE)
	match facet:
		&"trust":
			state.trust = bounded
		&"ease":
			state.ease = bounded
		&"respect":
			state.respect = bounded
		&"spark":
			state.spark = bounded
		&"strain":
			state.strain = bounded
	return true


static func apply_delta(state: RelationshipState, facet: StringName, delta: int) -> bool:
	if state == null or facet not in FACETS or delta == 0:
		return false
	return set_value(state, facet, value_for(state, facet) + delta)


static func band_for_value(value: int) -> StringName:
	if value >= MAXIMUM_VALUE:
		return &"high"
	if value >= 1:
		return &"open"
	return &"low"


static func band_for(state: RelationshipState, facet: StringName) -> StringName:
	return band_for_value(value_for(state, facet)) if state != null and facet in FACETS else &"low"


static func is_at_least(state: RelationshipState, facet: StringName, required_band: StringName) -> bool:
	if state == null or facet not in FACETS or required_band not in BANDS:
		return false
	return BANDS.find(band_for(state, facet)) >= BANDS.find(required_band)


static func qualitative_key(state: RelationshipState, facet: StringName) -> StringName:
	return StringName("resonance.%s.%s" % [facet, band_for(state, facet)])


static func validate(state: RelationshipState, owner_id: StringName = &"") -> Array[String]:
	var errors: Array[String] = []
	if state == null:
		errors.append("%s relationship state is missing" % owner_id)
		return errors
	for facet: StringName in FACETS:
		var value := value_for(state, facet)
		if value < MINIMUM_VALUE or value > MAXIMUM_VALUE:
			errors.append("%s facet %s is outside %d..%d" % [owner_id, facet, MINIMUM_VALUE, MAXIMUM_VALUE])
	return errors
