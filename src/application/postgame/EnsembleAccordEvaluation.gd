class_name EnsembleAccordEvaluation
extends RefCounted
## Explainable eligibility result; the fallback ending remains available on failure.

var eligible: bool
var completed_deep_routes: int
var friendship_endings: int
var postponed_promises: int
var cross_faction_repairs: int
var severe_strain_character_ids: Array[StringName] = []
var blockers: Array[StringName] = []
var fallback_ending_id: StringName
