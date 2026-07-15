class_name DialoguePresenter
extends RefCounted
## Grapheme reveal, instant text, auto timing, live locale switching, and bounded backlog.

const DEFAULT_GRAPHEMES_PER_SECOND := 30.0

var backlog := DialogueBacklog.new()
var current: DialoguePresentationState
var instant_text: bool = false
var auto_mode: bool = false
var graphemes_per_second: float = DEFAULT_GRAPHEMES_PER_SECOND

var _content: ContentRepository
var _resolver: LocalizedContentResolver
var _reveal_accumulator: float = 0.0
var _accepted_current: bool = false


func _init(content: ContentRepository = null) -> void:
	_content = content
	_resolver = LocalizedContentResolver.new(content)


func present(
	beat: DialogueBeatRecord,
	event_id: StringName,
	node_id: StringName,
	locale: StringName,
	arguments: Dictionary = {}
) -> DialoguePresentationState:
	current = DialoguePresentationState.new()
	current.event_id = event_id
	current.node_id = node_id
	current.beat = beat
	current.locale = locale
	current.arguments = NamedTextFormatter.new().typed_arguments(arguments)
	_rebuild_localized_text()
	current.revealed_count = current.graphemes.size() if instant_text or beat.advance_policy == &"instant" else 0
	current.is_complete = current.revealed_count >= current.graphemes.size()
	if current.is_complete:
		current.auto_seconds_remaining = _reading_seconds()
	_reveal_accumulator = 0.0
	_accepted_current = false
	return current


func tick(delta: float) -> void:
	if current == null or _accepted_current:
		return
	if not current.is_complete:
		_reveal_accumulator += maxf(0.0, delta) * maxf(1.0, graphemes_per_second)
		var reveal_now := int(floor(_reveal_accumulator))
		if reveal_now > 0:
			_reveal_accumulator -= reveal_now
			current.revealed_count = mini(current.graphemes.size(), current.revealed_count + reveal_now)
			current.is_complete = current.revealed_count >= current.graphemes.size()
			if current.is_complete:
				current.auto_seconds_remaining = _reading_seconds()
	elif auto_mode or current.beat.advance_policy == &"auto":
		current.auto_seconds_remaining = maxf(0.0, current.auto_seconds_remaining - maxf(0.0, delta))


func confirm() -> bool:
	if current == null or _accepted_current:
		return false
	if not current.is_complete:
		current.revealed_count = current.graphemes.size()
		current.is_complete = true
		current.auto_seconds_remaining = _reading_seconds()
		return false
	_accept_current()
	return true


func can_auto_advance() -> bool:
	return (
		current != null
		and not _accepted_current
		and current.is_complete
		and (auto_mode or current.beat.advance_policy == &"auto")
		and current.auto_seconds_remaining <= 0.0
	)


func consume_auto_advance() -> bool:
	if not can_auto_advance():
		return false
	_accept_current()
	return true


func switch_locale(locale: StringName) -> void:
	if current == null or current.locale == locale:
		return
	var opening_size := maxi(1, current.graphemes.size())
	var reveal_ratio := float(current.revealed_count) / float(opening_size)
	current.locale = locale
	_rebuild_localized_text()
	current.revealed_count = mini(current.graphemes.size(), int(round(reveal_ratio * current.graphemes.size())))
	current.is_complete = current.revealed_count >= current.graphemes.size()
	if current.is_complete:
		current.auto_seconds_remaining = _reading_seconds()


func _rebuild_localized_text() -> void:
	var arguments := NamedTextFormatter.new().dictionary(current.arguments)
	current.full_text = _resolver.resolve(current.beat.text_key, current.locale, arguments).text
	current.graphemes = GraphemeSegmenter.segments(current.full_text)
	var character := _content.character(current.beat.speaker_id) if _content != null else null
	current.speaker_name = character.display_name(current.locale) if character != null else String(current.beat.speaker_id)


func _accept_current() -> void:
	if _accepted_current:
		return
	var entry := DialogueBacklogEntry.new()
	entry.event_id = current.event_id
	entry.node_id = current.node_id
	entry.speaker_id = current.beat.speaker_id
	entry.text_key = current.beat.text_key
	entry.arguments = current.arguments.duplicate()
	entry.nonverbal_key = current.beat.nonverbal_key
	backlog.add(entry)
	_accepted_current = true


func _reading_seconds() -> float:
	var rate := 12.0 if current.locale == &"ja" else 18.0
	return clampf(float(current.graphemes.size()) / rate + 0.5, 0.8, 8.0)
