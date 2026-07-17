extends PostgameHubScreen


func _on_fixture_configured() -> void:
	focused_index = 2
	_apply_focus()
