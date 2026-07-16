class_name AdvanceChapterCommand
extends GameCommand
## Monotonic chapter transition guarded by the caller's expected opening chapter.

var expected_chapter_id: StringName
var next_chapter_id: StringName


func _init(p_expected_chapter_id: StringName = &"", p_next_chapter_id: StringName = &"") -> void:
	super(&"campaign.advance_chapter")
	expected_chapter_id = p_expected_chapter_id
	next_chapter_id = p_next_chapter_id
