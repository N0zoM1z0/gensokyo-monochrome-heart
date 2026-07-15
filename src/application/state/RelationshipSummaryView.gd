class_name RelationshipSummaryView
extends RefCounted
## Nonnumeric relationship view model safe for Journal and dialogue presentation.

var character_id: StringName
var summary_key: StringName
var facets: Array[RelationshipBandView] = []


func band_for(facet: StringName) -> StringName:
	for view: RelationshipBandView in facets:
		if view.facet == facet:
			return view.band
	return &"low"
