class_name DialogueBacklogEntry
extends RefCounted
## Accepted line/cue evidence; contains localization intent and no hidden state delta.

var event_id: StringName
var node_id: StringName
var speaker_id: StringName
var text_key: StringName
var arguments: Array[NamedTextArgument] = []
var nonverbal_key: StringName


func render(resolver: LocalizedContentResolver, locale: StringName) -> String:
	return resolver.resolve(text_key, locale, NamedTextFormatter.new().dictionary(arguments)).text
