class_name FiveImpossibleErrandsState
extends RefCounted
## Locale-free record of the five positions the player chose to take.

enum Phase { TUTORIAL, ACTIVE, RESULT }

var phase: Phase = Phase.TUTORIAL
var errand_index: int = 0
var option_cursor: int = 0
var choices: Array[StringName] = []
var elapsed_ticks: int = 0
var result_tag: StringName


func canonical_snapshot() -> String:
	var encoded_choices := PackedStringArray()
	for choice: StringName in choices:
		encoded_choices.append(String(choice))
	return "|".join(PackedStringArray([
		str(phase), str(errand_index), str(option_cursor), ",".join(encoded_choices),
		str(elapsed_ticks), String(result_tag),
	]))
