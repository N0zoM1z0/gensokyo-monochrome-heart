class_name RumorConfidenceRules
extends RefCounted
## Player-safe rumor labels. Raw reliability values never need to reach the UI.

const SEEN: StringName = &"seen"
const REPORTED: StringName = &"reported"
const CONTRADICTED: StringName = &"contradicted"
const RESOLVED: StringName = &"resolved"
const LABELS: Array[StringName] = [SEEN, REPORTED, CONTRADICTED, RESOLVED]
const SEEN_RELIABILITY_MILLI := 700


static func label_for(rumor: RumorState) -> StringName:
	if rumor == null:
		return REPORTED
	match rumor.status:
		&"corrected":
			return RESOLVED
		&"refuted":
			return CONTRADICTED
		&"published":
			return REPORTED
		_:
			return SEEN if rumor.reliability_milli >= SEEN_RELIABILITY_MILLI else REPORTED
