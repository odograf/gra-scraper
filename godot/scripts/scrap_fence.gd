class_name ScrapFence
extends Area2D

const FENCE_SHEET := preload("res://assets/props/fence_segments_v1.png")
const FENCE_FRAME_SIZE := Vector2i(724, 724)
const INTERACTION_RANGE := 155.0

signal cut_requested(fence: ScrapFence)
signal out_of_range

var player: Player
var hovered := false
var interaction_focused := false
var cut := false
var blocker: StaticBody2D
var sprite: Sprite2D

func _ready() -> void:
	input_pickable = true
	collision_layer = 4
	collision_mask = 0
	add_to_group("keyboard_interactable")
	sprite = Sprite2D.new()
	sprite.name = "WycinanePrzeslo"
	sprite.texture = _fence_frame(1)
	sprite.position = Vector2(0, -46)
	sprite.scale = Vector2(0.18, 0.18)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(sprite)
	var click_collision := CollisionShape2D.new()
	var click_shape := RectangleShape2D.new()
	click_shape.size = Vector2(124, 76)
	click_collision.shape = click_shape
	click_collision.position = Vector2(0, -20)
	add_child(click_collision)
	blocker = StaticBody2D.new()
	blocker.collision_layer = 1
	blocker.collision_mask = 2
	var body_collision := CollisionShape2D.new()
	var body_shape := RectangleShape2D.new()
	body_shape.size = Vector2(124, 28)
	body_collision.shape = body_shape
	blocker.add_child(body_collision)
	add_child(blocker)
	mouse_entered.connect(func() -> void: hovered = true; queue_redraw())
	mouse_exited.connect(func() -> void: hovered = false; queue_redraw())
	queue_redraw()

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		try_interact()

func is_player_nearby() -> bool:
	return not cut and player != null and global_position.distance_to(player.global_position) <= INTERACTION_RANGE

func interaction_prompt() -> String:
	return "ENTER  —  WYTNIJ SIATKĘ"

func set_interaction_focused(focused: bool) -> void:
	interaction_focused = focused and not cut
	queue_redraw()

func try_interact() -> bool:
	if cut:
		return false
	if not is_player_nearby():
		out_of_range.emit()
		return false
	cut_requested.emit(self)
	return true

func complete_cut() -> void:
	cut = true
	set_interaction_focused(false)
	input_pickable = false
	sprite.texture = _fence_frame(2)
	if is_instance_valid(blocker):
		blocker.queue_free()
	queue_redraw()

func _draw() -> void:
	if cut:
		return
	if hovered or interaction_focused:
		draw_rect(Rect2(-66, -105, 132, 110), Color("#efb64766"), false, 4)
		draw_colored_polygon(PackedVector2Array([Vector2(-8, -113), Vector2(8, -113), Vector2(0, -103)]), Color("#efb647"))
		draw_string(ThemeDB.fallback_font, Vector2(-54, -120), "WYTNIJ", HORIZONTAL_ALIGNMENT_CENTER, 108, 12, Color("#efb647"))

func _fence_frame(column: int) -> AtlasTexture:
	var frame := AtlasTexture.new()
	frame.atlas = FENCE_SHEET
	frame.region = Rect2(Vector2(column * FENCE_FRAME_SIZE.x, 0), Vector2(FENCE_FRAME_SIZE))
	return frame
