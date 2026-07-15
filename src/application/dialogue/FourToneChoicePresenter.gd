class_name FourToneChoicePresenter
extends RefCounted
## Stable semantic focus for Direct, Playful, Patient, and Defiant across locale changes.

var choice: EventChoiceState
var locale: StringName = &"en"
var focused_tone: StringName = &"direct"

var _resolver: LocalizedContentResolver


func _init(content: ContentRepository = null) -> void:
	_resolver = LocalizedContentResolver.new(content)


func configure(
	p_choice: EventChoiceState,
	p_locale: StringName,
	preferred_tone: StringName = &"direct"
) -> void:
	choice = p_choice
	locale = p_locale
	if choice != null and choice.option_for_tone(preferred_tone) != null:
		focused_tone = preferred_tone
	elif choice != null and not choice.options.is_empty():
		focused_tone = choice.options[0].tone


func move(direction: int) -> void:
	var tones := visible_tones()
	if tones.is_empty():
		return
	var current_index := maxi(0, tones.find(focused_tone))
	focused_tone = tones[posmod(current_index + signi(direction), tones.size())]


func switch_locale(next_locale: StringName) -> void:
	locale = next_locale


func confirm() -> StringName:
	if choice == null:
		return &""
	var option := choice.option_for_tone(focused_tone)
	return focused_tone if option != null and option.is_available else &""


func presentations() -> Array[ChoiceOptionPresentation]:
	var result: Array[ChoiceOptionPresentation] = []
	if choice == null:
		return result
	for tone: StringName in EventGraphValidator.TONES:
		var option := choice.option_for_tone(tone)
		if option == null:
			continue
		var view := ChoiceOptionPresentation.new()
		view.tone = tone
		view.text = _resolver.resolve(option.text_key, locale).text
		view.is_available = option.is_available
		view.unavailable_reason = (
			_resolver.resolve(option.unavailable_reason_key, locale).text
			if option.unavailable_reason_key != &""
			else ""
		)
		result.append(view)
	return result


func visible_tones() -> Array[StringName]:
	var result: Array[StringName] = []
	if choice == null:
		return result
	for tone: StringName in EventGraphValidator.TONES:
		if choice.option_for_tone(tone) != null:
			result.append(tone)
	return result
