class_name RelationshipBandView
extends RefCounted
## Player-safe facet projection containing qualitative IDs only.

var facet: StringName
var band: StringName
var qualitative_key: StringName


func _init(p_facet: StringName, p_band: StringName, p_qualitative_key: StringName) -> void:
	facet = p_facet
	band = p_band
	qualitative_key = p_qualitative_key
