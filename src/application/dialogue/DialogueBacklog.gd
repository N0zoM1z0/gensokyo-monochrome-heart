class_name DialogueBacklog
extends RefCounted
## Bounded accepted dialogue history with live-locale rendering.

const MAX_ENTRIES := 200

var entries: Array[DialogueBacklogEntry] = []


func add(entry: DialogueBacklogEntry) -> void:
	if entry == null:
		return
	entries.append(entry)
	while entries.size() > MAX_ENTRIES:
		entries.pop_front()


func render_lines(resolver: LocalizedContentResolver, locale: StringName) -> Array[String]:
	var result: Array[String] = []
	for entry: DialogueBacklogEntry in entries:
		result.append(entry.render(resolver, locale))
		if entry.nonverbal_key != &"":
			result.append("[%s]" % entry.nonverbal_key)
	return result
