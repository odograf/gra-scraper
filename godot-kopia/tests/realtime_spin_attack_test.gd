extends SceneTree

var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := Player.new()
	player.position = Vector2(300, 300)
	root.add_child(player)
	var enemy := CombatEnemy.new()
	enemy.position = player.position + Vector2(70, 0)
	enemy.player = player
	root.add_child(enemy)
	await process_frame

	var hits: Array[int] = []
	player.spin_attack_hit.connect(func(target: Area2D, damage: int) -> void:
		if target == enemy:
			hits.append(damage)
	)
	player.set_move_target(player.position + Vector2(200, 0))
	_expect(player.start_spin_attack(), "Prawy atak można rozpocząć")
	_expect(not player.is_moving_to_target(), "Atak zatrzymuje marsz point and click")
	_expect(player.is_action_busy(), "Animacja ataku blokuje kolejną akcję")
	_expect(player.sprite.animation == "bag_hammer_attack", "Atak korzysta z osobnego arkusza ruchu ciała")
	_expect(player.weapon_sprite.visible and player.weapon_sprite.animation == "attack", "Broń jest osobną, aktywną warstwą animacji")
	_expect(player.sprite.sprite_frames.get_frame_count("bag_hammer_attack") == 8, "Ruch ciała ma osiem klatek")
	_expect(player.weapon_sprite.sprite_frames.get_frame_count("attack") == 8, "Warstwa broni ma osiem zsynchronizowanych klatek")
	_expect(player.BAG_ATTACK_BODY_SHEET.get_size() == Vector2(2048, 768), "Arkusz ciała ma regularną siatkę 4 na 2")
	_expect(player.BAG_ATTACK_BODY_FRAME_SIZE == Vector2i(512, 384), "Klatki ciała zachowują bezpieczne pole zamachu")
	_expect(is_equal_approx(player.BAG_ATTACK_SCALE, 0.43), "Ciało i broń korzystają ze wspólnej skali mapowej")
	_expect(player.equipped_bag_weapon == &"plastic_bag", "Reklamówka jest domyślną bronią torbową")
	var plastic_definition: Dictionary = BagWeaponCatalog.definition(&"plastic_bag")
	var plastic_image: Image = (plastic_definition.texture as Texture2D).get_image()
	_expect(plastic_image.detect_alpha() != Image.ALPHA_NONE, "Warstwa reklamówki ma prawdziwy kanał alfa")
	for frame_index in range(8):
		player.sprite.frame = frame_index
		player._apply_frame_alignment()
		var anchor: Vector2 = player.frame_anchors["bag_hammer:%d" % frame_index]
		var aligned_anchor := player.sprite.offset + anchor - Vector2(player.BAG_ATTACK_BODY_FRAME_SIZE) * 0.5
		_expect(aligned_anchor.length() < 0.01, "Klatka %d zamachu pozostaje zakotwiczona do stóp" % frame_index)
		_expect(anchor == Vector2(256, 336), "Klatka %d używa wspólnej podstawy stóp" % frame_index)
		_expect(player.weapon_sprite.frame == frame_index, "Klatka %d broni jest zsynchronizowana z ciałem" % frame_index)
	var queued_destination := player.global_position + Vector2(240, 60)
	player.set_move_target(queued_destination)
	_expect(player.has_buffered_move_command(), "Klik mapy podczas zamachu trafia do kolejki")
	_expect(not player.is_moving_to_target(), "Bohater nie przerywa zamachu ruchem")
	_expect(player.target_marker.visible and player.target_marker.global_position == queued_destination, "Znacznik od razu pokazuje zakolejkowany cel")
	await create_timer(0.30).timeout
	_expect(player.attack_hitbox.monitoring, "Hitbox jest aktywny w środku obrotu")
	_expect(hits == [player.SPIN_ATTACK_DAMAGE], "Cel w zasięgu otrzymuje dokładnie jedno trafienie")
	await create_timer(0.46).timeout
	_expect(not player.is_action_busy(), "Po obrocie postać odzyskuje sterowanie")
	_expect(not player.attack_hitbox.monitoring, "Po ataku hitbox reklamówki jest wyłączony")
	_expect(player.is_moving_to_target() and not player.has_buffered_move_command(), "Po zamachu kolejka natychmiast uruchamia ruch")
	_expect(String(player.sprite.animation).begins_with("walk_"), "Po zamachu animacja płynnie przechodzi do chodu")
	_expect(not player.weapon_sprite.visible, "Warstwa broni znika poza animacją ataku")
	player.cancel_move_target()
	_expect(player.equip_bag_weapon(&"black_sack"), "Czarny worek można wyposażyć bez zmiany animacji ciała")
	_expect(player.start_spin_attack(), "Atak czarnym workiem korzysta z tego samego ruchu bohatera")
	_expect(player.equipped_bag_weapon_name() == "Czarny worek", "Wyposażona broń ma poprawną nazwę")
	_expect(player.weapon_sprite.material is ShaderMaterial, "Materiał worka usuwa tło wadliwego źródła w czasie renderowania")
	_expect(player.sprite.sprite_frames.get_frame_count("bag_hammer_attack") == 8, "Zmiana torby nie duplikuje ani nie zmienia klatek ciała")
	await create_timer(0.70).timeout

	if failures == 0:
		print("REALTIME_SPIN_ATTACK_TEST_OK")
	else:
		printerr("REALTIME_SPIN_ATTACK_TEST_FAILED: %d" % failures)
	quit(failures)

func _expect(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + description)
