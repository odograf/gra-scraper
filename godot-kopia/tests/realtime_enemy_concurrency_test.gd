extends SceneTree

var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.gameplay_active = true
	var dogs: Array[Node] = game.get_tree().get_nodes_in_group("park_dogs")
	_expect(dogs.size() >= 2, "Test ma co najmniej dwóch przeciwników czasu rzeczywistego")
	if dogs.size() < 2:
		quit(failures)
		return
	var first := dogs[0] as WildDogEnemy
	var second := dogs[1] as WildDogEnemy
	first.global_position = game.player.global_position + Vector2(55, 0)
	second.global_position = game.player.global_position + Vector2(-55, 0)
	first.active = true
	second.active = true
	first.attack_cooldown_left = 0.0
	second.attack_cooldown_left = 0.0
	_expect(game.player.start_spin_attack(), "Bohater rozpoczyna animację podczas starcia grupowego")
	first._physics_process(0.01)
	second._physics_process(0.01)
	_expect(first.attacking and second.attacking, "Dwaj przeciwnicy niezależnie przygotowują atak podczas animacji bohatera")
	await create_timer(0.34).timeout
	_expect(game.player_health == 90, "Dwa równoczesne ugryzienia są rozliczane przez wspólny stan zdrowia")
	_finish()

func _expect(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + description)

func _finish() -> void:
	if failures == 0:
		print("REALTIME_ENEMY_CONCURRENCY_TEST_OK")
	else:
		printerr("REALTIME_ENEMY_CONCURRENCY_TEST_FAILED: %d" % failures)
	quit(failures)
