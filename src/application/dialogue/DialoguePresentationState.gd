class_name DialoguePresentationState
extends RefCounted
## Current localized beat reveal and speaker projection.

var event_id: StringName
var node_id: StringName
var beat: DialogueBeatRecord
var speaker_name: String
var locale: StringName
var arguments: Array[NamedTextArgument] = []
var full_text: String
var graphemes: Array[String] = []
var revealed_count: int = 0
var is_complete: bool = false
var auto_seconds_remaining: float = 0.0


func visible_text() -> String:
	var visible: PackedStringArray = []
	for index: int in range(mini(revealed_count, graphemes.size())):
		visible.append(graphemes[index])
	return "".join(visible)
