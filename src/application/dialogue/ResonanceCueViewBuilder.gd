class_name ResonanceCueViewBuilder
extends RefCounted
## Filters interpreter cues into a nonnumeric player presentation model.


static func build(cues: Array[EventPresentationCue]) -> Array[ResonanceCueView]:
	var result: Array[ResonanceCueView] = []
	for cue: EventPresentationCue in cues:
		if cue.kind != &"resonance":
			continue
		var view := ResonanceCueView.new()
		view.owner_id = cue.owner_id
		view.object_cue_key = cue.cue_id
		view.qualitative_key = cue.semantic_key
		result.append(view)
	return result
