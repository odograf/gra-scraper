class_name MapResident
extends Area2D

signal fight_requested
signal talk_requested
signal out_of_range

const INTERACTION_RANGE := 155.0

var sprite_texture: Texture2D
var sprite_scale := 0.10
var sprite_grid := Vector2i.ONE
var idle_fps := 2.8
var head_band_ratio := 0.28
var display_name := ""
var body_radius := 18.0
var body_height := 42.0
var body_offset_y := -19.0
var shadow_size := Vector2(24.0, 8.0)
var player: Player
var fightable := false
var talkable := false
var interaction_target := ""
var hovered := false
var interaction_focused := false
var frame_anchors: Dictionary = {}

func _ready() -> void:
	if fightable or talkable:
		input_pickable = true
		collision_layer = 4
		collision_mask = 0
		add_to_group("keyboard_interactable")
		_create_interaction_collision()
		mouse_entered.connect(func() -> void: hovered = true; queue_redraw())
		mouse_exited.connect(func() -> void: hovered = false; queue_redraw())
	_calculate_frame_anchors()
	var sprite := AnimatedSprite2D.new()
	sprite.name = "MapaSprite"
	sprite.sprite_frames = _make_sprite_frames()
	sprite.scale = Vector2.ONE * sprite_scale
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.frame_changed.connect(_apply_frame_alignment.bind(sprite))
	add_child(sprite)
	sprite.play("idle")
	sprite.frame = absi(name.hash()) % maxi(1, sprite_grid.x * sprite_grid.y)
	_apply_frame_alignment(sprite)

	var body := StaticBody2D.new()
	body.name = "Kolizja"
	body.collision_layer = 1
	body.collision_mask = 2
	var collision := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = body_radius
	shape.height = body_height
	collision.shape = shape
	collision.position = Vector2(0, body_offset_y)
	body.add_child(collision)
	add_child(body)
	queue_redraw()

func _create_interaction_collision() -> void:
	var collision := CollisionShape2D.new()
	collision.name = "ObszarKlikniecia"
	var shape := CapsuleShape2D.new()
	shape.radius = body_radius + 8.0
	shape.height = maxf(body_height + 30.0, shape.radius * 2.0)
	collision.shape = shape
	collision.position = Vector2(0, body_offset_y - 12.0)
	add_child(collision)

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if (fightable or talkable) and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		try_interact()

func is_player_nearby() -> bool:
	return (fightable or talkable) and player != null and global_position.distance_to(player.global_position) <= INTERACTION_RANGE

func interaction_prompt() -> String:
	if talkable:
		return "ENTER  —  POROZMAWIAJ Z %s" % interaction_target
	return "ENTER  —  WALCZ Z %s" % interaction_target

func set_interaction_focused(focused: bool) -> void:
	interaction_focused = focused
	queue_redraw()

func try_interact() -> bool:
	if not is_player_nearby():
		out_of_range.emit()
		return false
	if talkable:
		talk_requested.emit()
	else:
		fight_requested.emit()
	return true

func set_fight_enabled(enabled: bool) -> void:
	fightable = enabled
	input_pickable = enabled
	if enabled or talkable:
		if not is_in_group("keyboard_interactable"):
			add_to_group("keyboard_interactable")
	else:
		remove_from_group("keyboard_interactable")
		interaction_focused = false
	queue_redraw()

func _make_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("idle")
	frames.set_animation_speed("idle", idle_fps)
	frames.set_animation_loop("idle", true)
	if sprite_texture == null:
		return frames
	var frame_size := _frame_size()
	for row in range(sprite_grid.y):
		for column in range(sprite_grid.x):
			var frame := AtlasTexture.new()
			frame.atlas = sprite_texture
			frame.region = Rect2(Vector2i(column, row) * frame_size, frame_size)
			frames.add_frame("idle", frame)
	return frames

func _frame_size() -> Vector2i:
	return Vector2i(
		floori(float(sprite_texture.get_width()) / float(sprite_grid.x)),
		floori(float(sprite_texture.get_height()) / float(sprite_grid.y))
	)

func _calculate_frame_anchors() -> void:
	frame_anchors.clear()
	if sprite_texture == null:
		return
	var image := sprite_texture.get_image()
	var frame_size := _frame_size()
	for row in range(sprite_grid.y):
		for column in range(sprite_grid.x):
			var origin := Vector2i(column, row) * frame_size
			var min_y := frame_size.y
			var max_y := -1
			for y in range(frame_size.y):
				for x in range(frame_size.x):
					if image.get_pixel(origin.x + x, origin.y + y).a > 0.12:
						min_y = mini(min_y, y)
						max_y = maxi(max_y, y)
			var frame_index := row * sprite_grid.x + column
			if max_y < 0:
				frame_anchors[frame_index] = Vector2(frame_size) * 0.5
				continue
			# Środek głowy jest stabilny nawet wtedy, gdy ręka lub ogon zmienia obrys klatki.
			var visible_height := max_y - min_y + 1
			var head_end := mini(max_y, min_y + ceili(float(visible_height) * head_band_ratio))
			var weighted_x := 0.0
			var total_alpha := 0.0
			for y in range(min_y, head_end + 1):
				for x in range(frame_size.x):
					var alpha := image.get_pixel(origin.x + x, origin.y + y).a
					if alpha > 0.12:
						weighted_x += float(x) * alpha
						total_alpha += alpha
			var anchor_x := float(frame_size.x) * 0.5
			if total_alpha > 0.0:
				anchor_x = weighted_x / total_alpha
			frame_anchors[frame_index] = Vector2(anchor_x, max_y)

func _apply_frame_alignment(sprite: AnimatedSprite2D) -> void:
	if sprite_texture == null:
		return
	var frame_size := _frame_size()
	var anchor: Vector2 = frame_anchors.get(sprite.frame, Vector2(frame_size) * 0.5)
	sprite.offset = Vector2(frame_size) * 0.5 - anchor

func _draw() -> void:
	if hovered or interaction_focused:
		draw_ellipse(Vector2(0, body_offset_y), shadow_size.x + 12.0, shadow_size.y + 8.0, Color("#efb64744"))
		draw_arc(Vector2(0, body_offset_y), shadow_size.x + 13.0, 0.0, TAU, 28, Color("#f2cd72aa"), 2.0)
	draw_ellipse(Vector2(0, -2), shadow_size.x, shadow_size.y, Color("#10120f55"))
	if not display_name.is_empty():
		draw_string(
			ThemeDB.fallback_font,
			Vector2(-50, 18),
			display_name,
			HORIZONTAL_ALIGNMENT_CENTER,
			100,
			11,
			Color("#eee6d7")
		)
