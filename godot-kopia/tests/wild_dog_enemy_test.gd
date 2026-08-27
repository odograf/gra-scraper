extends SceneTree

var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	var dog := game.get_node_or_null("DzikiWychudzonyPies") as WildDogEnemy
	_expect(dog != null, "Dziki wychudzony pies stoi na mapie")
	if dog == null:
		quit(1)
		return
	_expect(game.get_tree().get_nodes_in_group("park_dogs").size() == 9, "Park zamieszkuje dziewięć dzikich psów")
	_expect(game.get_tree().get_nodes_in_group("park_pack_1").size() == 2, "Pierwsza wataha ma dwa psy")
	_expect(game.get_tree().get_nodes_in_group("park_pack_2").size() == 3, "Druga wataha ma trzy psy")
	_expect(game.get_tree().get_nodes_in_group("park_pack_3").size() == 4, "Trzecia wataha ma cztery psy")
	_expect(dog.global_position.x < 1200.0 and dog.global_position.y > 900.0, "Watahy stoją w lewym dolnym parku")
	var can_count := 0
	for pickup in game.get_tree().get_nodes_in_group("pickup_item"):
		if pickup.name.begins_with("Puszka"):
			can_count += 1
	_expect(can_count == 30, "Przy watahach leży sześć dodatkowych puszek")

	_expect(dog.sprite.sprite_frames.get_frame_count("idle") == 4, "Bezczynność ma cztery klatki")
	_expect(dog.sprite.sprite_frames.get_frame_count("walk") == 4, "Chód ma cztery klatki")
	_expect(dog.sprite.sprite_frames.get_frame_count("attack") == 4, "Ugryzienie ma cztery klatki")
	_expect(dog.sprite.sprite_frames.get_animation_loop("idle"), "Bezczynność zapętla się")
	_expect(dog.sprite.sprite_frames.get_animation_loop("walk"), "Chód zapętla się")
	_expect(not dog.sprite.sprite_frames.get_animation_loop("attack"), "Atak jest pojedynczą sekwencją")
	_expect(dog.SPRITE_SHEET.get_size() == Vector2(2048, 1152), "Arkusz ma regularną siatkę 4 na 3")
	_expect(dog.SPRITE_SHEET.get_image().get_pixel(0, 0).a == 0.0, "Arkusz ma prawdziwą przezroczystość")
	_expect(dog.sprite.offset + dog.FRAME_ANCHOR - Vector2(dog.FRAME_SIZE) * 0.5 == Vector2.ZERO, "Wszystkie animacje mają wspólną podstawę łap")
	_expect(dog.level == 1 and dog.health == 30, "Dziki pies ma poziom 1 i zaczyna z 30 punktami życia")
	_expect(dog.attack_damage == 5 and dog.attack_range == 1, "Dziki pies ma atak 5 i zasięg 1")
	_expect(dog.xp_reward == 50, "Pokonanie psa daje 50 XP")
	_expect((dog.hurtbox.collision_layer & 8) != 0, "Hurtbox psa odbiera zamach reklamówką")

	var player := game.player as Player
	_expect(game.player_health == 100 and game.player_max_health == 100, "Bohater zaczyna ze 100 punktami życia")
	_expect(game.health_bar != null and game.health_bar.value == 100.0, "HUD pokazuje pełny pasek zdrowia bohatera")
	dog.active = true
	dog.global_position = player.global_position + Vector2(200, 0)
	_expect(player.start_spin_attack(), "Bohater rozpoczyna animację ataku")
	dog._physics_process(0.05)
	_expect(dog.velocity.length() > 0.0 and dog.sprite.animation == "walk", "Pies nadal porusza się podczas animacji ataku bohatera")
	player._finish_action()
	dog.active = false
	dog.global_position = player.global_position + Vector2(55, 0)
	_expect(player.attack_damage() == 10 and is_equal_approx(player.attack_range_pixels(), 128.0), "Bohater ma atak 10 i zasięg dwóch pól")
	_expect(player.request_target_attack(dog), "Lewy klik może zlecić atak wybranego psa")
	var retreat_position := player.global_position + Vector2(-240, 80)
	player.set_move_target(retreat_position)
	_expect(player.has_buffered_move_command(), "Klik mapy podczas ataku wskazanego celu trafia do kolejki")
	_expect(not player.is_moving_to_target(), "Zakolejkowany odwrót nie przerywa animacji ataku")
	await create_timer(0.25).timeout
	_expect(dog.health == 20, "Atak wskazanego celu odejmuje psu 10 punktów życia")
	await create_timer(0.43).timeout
	_expect(player.is_moving_to_target(), "Po ataku bohater automatycznie rozpoczyna zakolejkowany odwrót")
	_expect(player.move_target == retreat_position, "Po ataku bohater idzie do ostatnio klikniętego punktu")

	var bite_damage: Array[int] = []
	dog.attack_landed.connect(func(damage: int) -> void: bite_damage.append(damage))
	game.gameplay_active = true
	dog.active = true
	dog.attack_cooldown_left = 0.0
	dog.global_position = player.global_position + Vector2(55, 0)
	dog._physics_process(0.01)
	_expect(dog.attacking, "Pies rozpoczyna atak, gdy gracz znajdzie się w zasięgu")
	_expect(dog.sprite.animation == "attack", "Atak przełącza właściwy rząd sprite'a")
	await create_timer(0.34).timeout
	_expect(bite_damage == [dog.attack_damage], "Ugryzienie trafia raz w odpowiednim momencie animacji")
	_expect(game.player_health == 95, "Ugryzienie odejmuje 5 punktów z życia bohatera w HUD-zie")

	# Rozpoczęty zamach nie może dobiec do trafienia po zatrzymaniu rozgrywki modalem.
	dog.attack_cooldown_left = 0.0
	dog.attacking = false
	dog.state = RealtimeEnemy.State.IDLE
	dog.global_position = player.global_position + Vector2(55, 0)
	dog._physics_process(0.01)
	_expect(dog.attacking, "Pies rozpoczyna drugi atak przed otwarciem menu")
	game.inventory_open = true
	game._process(0.01)
	var health_before_modal_wait: int = game.player_health
	await create_timer(0.34).timeout
	_expect(game.player_health == health_before_modal_wait and not dog.attacking, "Otwarcie menu anuluje oczekujące ugryzienie")
	game.inventory_open = false

	var xp_before: int = game.player_xp
	dog.receive_realtime_hit(10, player.global_position)
	dog.receive_realtime_hit(10, player.global_position)
	_expect(dog.dead, "Trzy ataki po 10 obrażeń pokonują psa")
	_expect(game.player_xp != xp_before or game.player_level > 1, "Pokonanie psa przyznaje 50 XP")
	await create_timer(0.48).timeout
	_expect(not is_instance_valid(dog), "Pokonany pies znika po krótkim wygaszeniu")

	if failures == 0:
		print("WILD_DOG_ENEMY_TEST_OK")
	else:
		printerr("WILD_DOG_ENEMY_TEST_FAILED: %d" % failures)
	quit(failures)

func _expect(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + description)
