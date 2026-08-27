class_name MirekNPC
extends Area2D

const MIREK_SPRITE_SHEET := preload("res://assets/npcs/mirek_idle_smoke_sheet.png")
const FRAME_SIZE := Vector2i(444, 444)
const INTERACTION_RANGE := 165.0

signal interaction_requested
signal out_of_range

var player: Player
var hovered := false
var interaction_focused := false
var sprite: AnimatedSprite2D
var smoke_timer: Timer
var frame_anchors: Dictionary = {}

func _ready() -> void:
	input_pickable = true
	collision_layer = 4
	collision_mask = 0
	add_to_group("keyboard_interactable")
	_calculate_frame_anchors()
	sprite = AnimatedSprite2D.new()
	sprite.name = "MirekSprite"
	sprite.sprite_frames = _make_sprite_frames()
	sprite.position = Vector2.ZERO
	sprite.scale = Vector2(0.30, 0.30)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(sprite)
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.frame_changed.connect(_apply_frame_alignment)
	sprite.animation_changed.connect(_apply_frame_alignment)
	sprite.play("idle")
	_apply_frame_alignment()
	smoke_timer = Timer.new()
	smoke_timer.name = "PrzerwaMiedzyPapierosami"
	smoke_timer.one_shot = true
	smoke_timer.timeout.connect(_start_smoking)
	add_child(smoke_timer)
	_schedule_smoking()
	var click_collision := CollisionShape2D.new()
	var click_shape := CapsuleShape2D.new()
	click_shape.radius = 24.0
	click_shape.height = 82.0
	click_collision.shape = click_shape
	click_collision.position = Vector2(0, -32)
	add_child(click_collision)
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 2
	var body_collision := CollisionShape2D.new()
	var body_shape := CapsuleShape2D.new()
	body_shape.radius = 22.0
	body_shape.height = 48.0
	body_collision.shape = body_shape
	body_collision.position = Vector2(0, -22)
	body.add_child(body_collision)
	add_child(body)
	mouse_entered.connect(func() -> void: hovered = true; queue_redraw())
	mouse_exited.connect(func() -> void: hovered = false; queue_redraw())
	queue_redraw()

func _make_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("idle")
	frames.set_animation_speed("idle", 3.4)
	frames.set_animation_loop("idle", true)
	for column in range(4):
		frames.add_frame("idle", _atlas_frame(column, 0))
	frames.add_animation("smoke")
	frames.set_animation_speed("smoke", 4.8)
	frames.set_animation_loop("smoke", false)
	for column in range(4):
		frames.add_frame("smoke", _atlas_frame(column, 1))
	return frames

func _atlas_frame(column: int, row: int) -> AtlasTexture:
	var frame := AtlasTexture.new()
	frame.atlas = MIREK_SPRITE_SHEET
	frame.region = Rect2(Vector2(column, row) * Vector2(FRAME_SIZE), Vector2(FRAME_SIZE))
	return frame

func _calculate_frame_anchors() -> void:
	var image := MIREK_SPRITE_SHEET.get_image()
	for row in range(2):
		for column in range(4):
			var min_y := FRAME_SIZE.y
			var max_y := 0
			for y in range(FRAME_SIZE.y):
				for x in range(FRAME_SIZE.x):
					if image.get_pixel(column * FRAME_SIZE.x + x, row * FRAME_SIZE.y + y).a > 0.12:
						min_y = mini(min_y, y)
						max_y = maxi(max_y, y)
			var head_end := mini(max_y, min_y + 82)
			var weighted_x := 0.0
			var total_alpha := 0.0
			for y in range(min_y, head_end + 1):
				for x in range(FRAME_SIZE.x):
					var alpha := image.get_pixel(column * FRAME_SIZE.x + x, row * FRAME_SIZE.y + y).a
					if alpha > 0.12:
						weighted_x += float(x) * alpha
						total_alpha += alpha
			var anchor_x := float(FRAME_SIZE.x) * 0.5
			if total_alpha > 0.0:
				anchor_x = weighted_x / total_alpha
			frame_anchors[Vector2i(column, row)] = Vector2(anchor_x, max_y)

func _apply_frame_alignment() -> void:
	if sprite == null:
		return
	var row := 1 if sprite.animation == "smoke" else 0
	var anchor: Vector2 = frame_anchors.get(Vector2i(sprite.frame, row), Vector2(FRAME_SIZE) * 0.5)
	sprite.offset = Vector2(FRAME_SIZE) * 0.5 - anchor

func _schedule_smoking() -> void:
	if smoke_timer != null:
		smoke_timer.start(randf_range(5.0, 9.0))

func _start_smoking() -> void:
	if sprite != null:
		sprite.play("smoke")

func _on_animation_finished() -> void:
	if sprite.animation == "smoke":
		sprite.play("idle")
		_schedule_smoking()

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		try_interact()

func is_player_nearby() -> bool:
	return player != null and global_position.distance_to(player.global_position) <= INTERACTION_RANGE

func interaction_prompt() -> String:
	return "ENTER  —  POROZMAWIAJ Z MIRKIEM"

func set_interaction_focused(focused: bool) -> void:
	interaction_focused = focused
	queue_redraw()

func try_interact() -> bool:
	if not is_player_nearby():
		out_of_range.emit()
		return false
	interaction_requested.emit()
	return true

func _draw() -> void:
	if hovered or interaction_focused:
		draw_circle(Vector2(0, -28), 38, Color("#efb64744"))
	draw_string(ThemeDB.fallback_font, Vector2(-48, 18), "MIREK", HORIZONTAL_ALIGNMENT_CENTER, 96, 12, Color("#eee6d7"))
