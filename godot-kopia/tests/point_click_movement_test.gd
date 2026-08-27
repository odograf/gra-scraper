extends SceneTree

var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.gameplay_active = true
	var player := game.player as Player
	player.set_physics_process(true)
	var start := player.global_position
	player.set_move_target(start + Vector2(120.0, 80.0))
	_expect(player.is_moving_to_target(), "Kliknięty punkt uruchamia marsz")
	_expect(player.target_marker.visible, "Cel ruchu ma widoczny znacznik")
	await create_timer(0.18).timeout
	_expect(player.global_position.distance_to(start) > 10.0, "Bohater rzeczywiście przesuwa się do celu")
	_expect(player.velocity.x > 0.0 and player.velocity.y > 0.0, "Point and click pozwala iść po skosie")
	_expect(String(player.sprite.animation).begins_with("walk_"), "Marsz odtwarza animację chodu")

	player.set_move_target(player.global_position + Vector2(3.0, 2.0))
	await create_timer(0.08).timeout
	_expect(not player.is_moving_to_target(), "Bohater zatrzymuje się po dotarciu")
	_expect(not player.target_marker.visible, "Znacznik znika po dotarciu")

	player.set_move_target(player.global_position + Vector2(100.0, 0.0))
	_expect(player.play_action("pickup", player.global_position + Vector2.DOWN), "Akcję można rozpocząć podczas marszu")
	_expect(not player.is_moving_to_target(), "Akcja anuluje poprzedni cel ruchu")
	player._finish_action()

	if failures == 0:
		print("POINT_CLICK_MOVEMENT_TEST_OK")
	else:
		printerr("POINT_CLICK_MOVEMENT_TEST_FAILED: %d" % failures)
	quit(failures)

func _expect(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + description)
