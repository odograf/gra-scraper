extends SceneTree

var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame

	var rats := game.get_tree().get_nodes_in_group("sewer_rats")
	_expect(rats.size() == 3, "Przy dolnych garażach stoją trzy Szczóry")
	if rats.is_empty():
		quit(1)
		return
	var rat := rats[0] as SewerRatEnemy
	_expect(rat != null, "Pierwszy Szczór używa właściwego typu przeciwnika")
	_expect(rat.global_position.x >= 500.0 and rat.global_position.x <= 1300.0 and rat.global_position.y >= 1100.0, "Szczóry stoją wokół dolnych garaży")
	_expect(game._realtime_enemy_at_position(rat.global_position) == rat, "Kliknięcie Szczóra wybiera go jako cel ataku")
	_expect(rat.SPRITE_SHEET.get_size() == Vector2(2048, 1536), "Arkusz Szczóra ma regularną siatkę 4 na 4")
	_expect(rat.SPRITE_SHEET.get_image().get_pixel(0, 0).a == 0.0, "Arkusz Szczóra ma prawdziwą przezroczystość")
	_expect(rat.FRAME_SIZE == Vector2i(512, 384), "Każda klatka Szczóra ma bezpieczne pole 512 na 384")
	_expect(rat.sprite.offset + rat.FRAME_ANCHOR - Vector2(rat.FRAME_SIZE) * 0.5 == Vector2.ZERO, "Wszystkie animacje mają wspólną podstawę łap")
	for animation_name in ["idle", "walk", "attack", "defeat"]:
		_expect(rat.sprite.sprite_frames.get_frame_count(animation_name) == 4, "%s Szczóra ma cztery klatki" % animation_name)
	_expect(rat.sprite.sprite_frames.get_animation_loop("idle"), "Bezczynność Szczóra zapętla się")
	_expect(rat.sprite.sprite_frames.get_animation_loop("walk"), "Bieg Szczóra zapętla się")
	_expect(not rat.sprite.sprite_frames.get_animation_loop("attack"), "Ugryzienie jest pojedynczą sekwencją")
	_expect(not rat.sprite.sprite_frames.get_animation_loop("defeat"), "Śmierć jest pojedynczą sekwencją")

	_expect(rat.level == 1 and rat.max_health == 12 and rat.health == 12, "Szczór ma poziom 1 i 12 punktów życia")
	_expect(rat.attack_damage == 2 and rat.attack_range == 1, "Szczór zadaje 2 obrażenia i ma zasięg jednego pola")
	_expect(rat.xp_reward == 8, "Pokonanie Szczóra daje 8 XP")
	_expect(is_equal_approx(rat.MOVE_SPEED, 105.0) and is_equal_approx(rat.DETECTION_RANGE, 220.0), "Szczór jest szybki, ale wykrywa gracza z bliska")
	_expect((rat.hurtbox.collision_layer & 8) != 0, "Hurtbox Szczóra odbiera zamach reklamówką")

	var player := game.player as Player
	rat.active = true
	rat.global_position = player.global_position + Vector2(180, 0)
	_expect(player.start_spin_attack(), "Bohater rozpoczyna animację ataku przy Szczórze")
	rat._physics_process(0.05)
	_expect(rat.velocity.length() > 0.0 and rat.sprite.animation == "walk", "Szczór nadal porusza się podczas animacji ataku bohatera")
	player._finish_action()
	var bite_damage: Array[int] = []
	rat.attack_landed.connect(func(damage: int) -> void: bite_damage.append(damage))
	game.gameplay_active = true
	rat.active = true
	rat.attack_cooldown_left = 0.0
	rat.global_position = player.global_position + Vector2(44, 0)
	rat._physics_process(0.01)
	_expect(rat.attacking, "Szczór zapowiada ugryzienie z krótkiego zasięgu")
	_expect(rat.sprite.animation == "attack", "Atak przełącza właściwy rząd sprite'a")
	await create_timer(0.42).timeout
	_expect(bite_damage == [2], "Ugryzienie trafia raz po czytelnej zapowiedzi")
	_expect(game.player_health == 98, "Ugryzienie odejmuje 2 punkty z życia bohatera")

	var xp_before: int = game.player_xp
	rat.active = false
	rat.receive_realtime_hit(10, player.global_position)
	_expect(rat.health == 2 and not rat.dead, "Pierwszy zwykły atak zostawia Szczórowi 2 HP")
	rat.receive_realtime_hit(10, player.global_position)
	_expect(rat.dead, "Drugi zwykły atak pokonuje Szczóra")
	_expect(rat.sprite.animation == "defeat", "Pokonany Szczór odtwarza osobną animację śmierci")
	_expect(game.player_xp == xp_before + 8, "Pokonanie Szczóra przyznaje 8 XP")
	await create_timer(1.08).timeout
	_expect(not is_instance_valid(rat), "Po animacji śmierci Szczór znika")

	if failures == 0:
		print("SEWER_RAT_ENEMY_TEST_OK")
	else:
		printerr("SEWER_RAT_ENEMY_TEST_FAILED: %d" % failures)
	quit(failures)

func _expect(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + description)
