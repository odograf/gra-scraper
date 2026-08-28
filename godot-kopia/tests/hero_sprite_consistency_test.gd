extends SceneTree

var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := Player.new()
	root.add_child(player)
	await process_frame

	_expect(player.LOCOMOTION_SHEET.get_size() == Vector2(1287, 1220), "Arkusz chodu ma dokładną siatkę 3 na 4")
	_expect(player.ACTION_SHEET.get_size() == Vector2(1024, 2048), "Arkusz czynności ma dokładną siatkę 4 na 8")
	_expect(player.BAG_ATTACK_BODY_SHEET.get_size() == Vector2(2048, 768), "Arkusz ciała ataku ma dokładną siatkę 4 na 2")
	_expect(player.BAG_ATTACK_BODY_FRAME_SIZE == Vector2i(512, 384), "Ciało zamachu jest niezależne od rozmiaru broni")
	_expect(player.weapon_sprite != null and player.weapon_sprite.sprite_frames.get_frame_count("attack") == 8, "Osobna warstwa broni ma osiem klatek")
	_expect(player.ACTION_FRAME_SIZE == Vector2i(256, 256), "Klatki czynności mają bezpieczny margines")

	var action_image := player.ACTION_SHEET.get_image()
	_expect(action_image.get_pixel(0, 0).a == 0.0, "Arkusz czynności ma prawdziwe przezroczyste tło")
	for row in range(8):
		for column in range(4):
			var cell := action_image.get_region(Rect2i(column * 256, row * 256, 256, 256))
			var used := _get_visible_rect(cell)
			var frame_label := "%d,%d" % [column, row]
			_expect(used.has_area(), "Klatka %s czynności zawiera sylwetkę" % frame_label)
			_expect(used.position.x >= 8 and used.end.x <= 248, "Klatka %s ma zapas po bokach" % frame_label)
			_expect(used.position.y >= 8, "Klatka %s ma zapas nad głową" % frame_label)
			_expect(absf(float(used.end.y - 1) - 232.0) <= 1.0, "Klatka %s trzyma wspólną linię stóp" % frame_label)
			var anchor: Vector2 = player.frame_anchors["action:%d:%d" % [column, row]]
			_expect(anchor == Vector2(128, 232), "Klatka %s używa wspólnej kotwicy" % frame_label)

	for action_name in ["rummage", "pickup"]:
		for direction in player.DIRECTIONS:
			var animation_name: String = action_name + "_" + direction
			player.sprite.play(animation_name)
			for frame_index in range(4):
				player.sprite.frame = frame_index
				player._apply_frame_alignment()
				var aligned_anchor := player.sprite.offset + Vector2(128, 232) - Vector2(player.ACTION_FRAME_SIZE) * 0.5
				_expect(aligned_anchor.length() < 0.01, "%s klatka %d nie skacze względem podłoża" % [animation_name, frame_index])
				_expect(player.sprite.scale == Vector2.ONE * player.ACTION_SCALE, "%s zachowuje skalę czynności" % animation_name)

	if failures == 0:
		print("HERO_SPRITE_CONSISTENCY_TEST_OK")
	else:
		printerr("HERO_SPRITE_CONSISTENCY_TEST_FAILED: %d" % failures)
	quit(failures)

func _expect(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + description)

func _get_visible_rect(image: Image) -> Rect2i:
	var minimum := Vector2i(image.get_width(), image.get_height())
	var maximum := Vector2i(-1, -1)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.12:
				minimum.x = mini(minimum.x, x)
				minimum.y = mini(minimum.y, y)
				maximum.x = maxi(maximum.x, x)
				maximum.y = maxi(maximum.y, y)
	if maximum.x < minimum.x:
		return Rect2i()
	return Rect2i(minimum, maximum - minimum + Vector2i.ONE)
