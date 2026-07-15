class_name RelationshipState
extends RefCounted
## Hidden five-facet state. Presentation must consume semantic bands instead.

var trust: int = 0
var ease: int = 0
var respect: int = 0
var spark: int = 0
var strain: int = 0


func duplicate_state() -> RelationshipState:
	var copy := RelationshipState.new()
	copy.trust = trust
	copy.ease = ease
	copy.respect = respect
	copy.spark = spark
	copy.strain = strain
	return copy
