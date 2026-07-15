extends SceneTree
## Expected-failure fixture proving that an automatic event loop cannot ship.


func _initialize() -> void:
	var graph := EventGraphRecord.new(
		1,
		&"evt.fixture.unbounded_cycle",
		&"event.fixture.title",
		&"loc.hakurei_shrine",
		&"",
		[],
		&"n1",
		[]
	)
	var first := EventNodeRecord.new(&"n1", &"music_state")
	first.music_state_id = &"mus.fixture"
	first.next_node_id = &"n2"
	var second := EventNodeRecord.new(&"n2", &"music_state")
	second.music_state_id = &"mus.fixture"
	second.next_node_id = &"n1"
	graph.nodes = [first, second]
	for diagnostic: String in EventGraphValidator.new().validate(graph):
		if diagnostic.contains("unbounded event cycle"):
			printerr("ERROR: deliberately cyclic event rejected: %s" % diagnostic)
			quit(1)
			return
	printerr("Cyclic fixture was incorrectly accepted.")
	quit(0)
