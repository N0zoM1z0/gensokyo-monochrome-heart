class_name PostgameHubScreen
extends UiScreenBase
## M15 postgame browser that keeps continuity and route implications visible.

var _framework: PostgameFrameworkRecord


func _build_screen() -> void:
	screen_id = &"postgame_hub"
	var content_db := get_node_or_null("/root/ContentDB")
	var repository: ContentRepository = content_db.snapshot() if content_db != null else null
	if repository == null:
		repository = ContentRepository.new()
		repository.load_sources()
	_framework = repository.postgame_framework
	_add_frame(Rect2(8, 8, 304, 164))
	_add_frame(Rect2(12, 34, 132, 112))
	_add_frame(Rect2(150, 34, 158, 112))
	_add_row(&"ui.postgame.dream_theatre", &"open_dream_theatre", &"postgame.dream", Rect2(17, 42, 122, 20))
	_add_row(&"ui.postgame.seasonal", &"open_seasonal", &"postgame.seasonal", Rect2(17, 70, 122, 20))
	_add_row(&"ui.postgame.accord", &"open_accord", &"postgame.accord", Rect2(17, 98, 122, 20))
	_add_action_hint(GameInput.CANCEL, &"ui.common.cancel", Rect2(230, 154, 72, 12))


func continuity_label() -> String:
	return _framework.dream_theatre.label(active_locale()) if _framework != null and _framework.dream_theatre != null else ""


func seasonal_event_count() -> int:
	return _framework.seasonal_events.size() if _framework != null else 0


func _focus_changed(_row: ListRow) -> void:
	queue_redraw()


func _draw_screen(profile: PresentationProfile) -> void:
	var foreground := profile.paper if profile.is_inverted else profile.ink
	_draw_localized(&"ui.postgame.title", Vector2(16, 26), 288, HORIZONTAL_ALIGNMENT_CENTER)
	if _framework == null:
		return
	match focused_index:
		1:
			_draw_seasonal(foreground)
		2:
			_draw_accord(foreground)
		_:
			_draw_dream_theatre(foreground)


func _draw_dream_theatre(foreground: Color) -> void:
	_draw_wrapped_literal(continuity_label(), Rect2(157, 43, 144, 30), 2, foreground)
	_draw_divider(foreground, 78)
	var scope := "POSTGAME ONLY / FANON RANGE 5/5" if active_locale() == &"en" else "クリア後のみ／二次創作表現 5/5"
	_draw_wrapped_literal(scope, Rect2(157, 82, 144, 22), 2, foreground)
	_draw_localized_wrapped(&"ui.postgame.no_route_progress", Rect2(157, 108, 144, 24), 2, 7)


func _draw_seasonal(foreground: Color) -> void:
	_draw_localized(&"ui.postgame.seasonal", Vector2(157, 51), 144, HORIZONTAL_ALIGNMENT_CENTER, 7)
	_draw_divider(foreground, 58)
	var seasons: Array[StringName] = [&"spring", &"summer", &"autumn", &"winter"]
	for index: int in seasons.size():
		var label := _season_label(seasons[index])
		var count := _framework.events_for_season(seasons[index]).size()
		_draw_literal("%s  %d" % [label, count], Vector2(163, 72 + index * 14), 132, HORIZONTAL_ALIGNMENT_LEFT, foreground)
	_draw_localized_wrapped(&"ui.postgame.no_route_progress", Rect2(157, 121, 144, 22), 2, 7)


func _draw_accord(foreground: Color) -> void:
	var rules := _framework.ensemble_accord
	_draw_localized(&"ui.postgame.accord", Vector2(157, 51), 144, HORIZONTAL_ALIGNMENT_CENTER, 7)
	_draw_divider(foreground, 58)
	var requirement := (
		"%d DEEP / %d FRIEND / %d POSTPONED" % [rules.minimum_completed_deep_routes, rules.minimum_friendship_endings, rules.minimum_postponed_promises]
		if active_locale() == &"en"
		else "深い絆%d・友情%d・保留%d" % [rules.minimum_completed_deep_routes, rules.minimum_friendship_endings, rules.minimum_postponed_promises]
	)
	if ui_scale_percent() > 100:
		_draw_wrapped_literal(requirement, Rect2(157, 62, 144, 24), 2, foreground)
		var repair_count := "3 CROSS-FACTION REPAIRS" if active_locale() == &"en" else "陣営間の修復3回"
		var strain_rule := "NO SEVERE STRAIN" if active_locale() == &"en" else "強い緊張なし"
		_draw_literal(repair_count, Vector2(157, 96), 144, HORIZONTAL_ALIGNMENT_CENTER, foreground)
		_draw_literal(strain_rule, Vector2(157, 107), 144, HORIZONTAL_ALIGNMENT_CENTER, foreground)
		_draw_localized(&"ui.postgame.accord_agency", Vector2(157, 119), 144, HORIZONTAL_ALIGNMENT_CENTER, 7)
		_draw_localized_wrapped(&"ui.postgame.community_fallback", Rect2(157, 119, 144, 24), 2, 7)
		return
	_draw_wrapped_literal(requirement, Rect2(157, 67, 144, 24), 2, foreground)
	var repairs := "3 CROSS-FACTION REPAIRS / NO SEVERE STRAIN" if active_locale() == &"en" else "陣営間の修復3回・強い緊張なし"
	_draw_wrapped_literal(repairs, Rect2(157, 94, 144, 25), 2, foreground)
	_draw_localized(&"ui.postgame.accord_agency", Vector2(157, 120), 144, HORIZONTAL_ALIGNMENT_CENTER, 7)
	_draw_localized_wrapped(&"ui.postgame.community_fallback", Rect2(157, 123, 144, 18), 2, 7)


func _draw_divider(foreground: Color, y: float) -> void:
	draw_line(Vector2(158, y), Vector2(300, y), foreground)


func _draw_wrapped_literal(text: String, rect: Rect2, maximum_lines: int, foreground: Color) -> void:
	var font := _japanese_font if active_locale() == &"ja" else _latin_font
	var font_size := _resolved_font_size(7)
	var lines := PixelTextWrapper.wrap(text, font, rect.size.x, font_size, active_locale(), maximum_lines)
	for index: int in mini(lines.size(), maximum_lines):
		draw_string(font, Vector2(rect.position.x, rect.position.y + font_size + index * (font_size + 2)), lines[index], HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size, foreground)


func _draw_literal(text: String, position: Vector2, width: float, alignment: HorizontalAlignment, foreground: Color) -> void:
	var font := _japanese_font if active_locale() == &"ja" else _latin_font
	draw_string(font, position, text, alignment, width, _resolved_font_size(7), foreground)


func _season_label(season: StringName) -> String:
	var english := {&"spring": "SPRING", &"summer": "SUMMER", &"autumn": "AUTUMN", &"winter": "WINTER"}
	var japanese := {&"spring": "春", &"summer": "夏", &"autumn": "秋", &"winter": "冬"}
	return japanese.get(season, "") if active_locale() == &"ja" else english.get(season, "")
