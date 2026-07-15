class_name RelationshipViewBuilder
extends RefCounted
## Converts hidden values to qualitative presentation contracts without number leakage.


static func build(character: CharacterState) -> RelationshipSummaryView:
	var view := RelationshipSummaryView.new()
	if character == null:
		view.summary_key = &"resonance.summary.unknown"
		return view
	view.character_id = character.character_id
	for facet: StringName in RelationshipFacetRules.FACETS:
		view.facets.append(
			RelationshipBandView.new(
				facet,
				RelationshipFacetRules.band_for(character.relationship, facet),
				RelationshipFacetRules.qualitative_key(character.relationship, facet)
			)
		)
	view.summary_key = _summary_key(character.relationship)
	return view


static func _summary_key(relationship: RelationshipState) -> StringName:
	if RelationshipFacetRules.band_for(relationship, &"strain") == &"high":
		return &"resonance.summary.repair_needed"
	if RelationshipFacetRules.band_for(relationship, &"spark") == &"high":
		return &"resonance.summary.unspoken"
	if RelationshipFacetRules.band_for(relationship, &"ease") == &"high":
		return &"resonance.summary.allows_silence"
	if RelationshipFacetRules.band_for(relationship, &"trust") in [&"open", &"high"]:
		return &"resonance.summary.expects_return"
	return &"resonance.summary.still_measuring"
