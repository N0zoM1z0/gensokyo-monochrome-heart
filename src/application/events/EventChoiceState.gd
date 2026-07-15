class_name EventChoiceState
extends RefCounted
## Visible four-tone choice projection with stable focus identities.

var choice_id: StringName
var options: Array[EventChoiceOptionState] = []


func option_for_tone(tone: StringName) -> EventChoiceOptionState:
	for option: EventChoiceOptionState in options:
		if option.tone == tone:
			return option
	return null
