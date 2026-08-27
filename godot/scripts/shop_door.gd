class_name ShopDoor
extends Area2D

const INTERACTION_RANGE := 155.0

signal enter_requested
signal out_of_range

var player: Player
var hovered := false
var interaction_focused := false

func _ready() -> void:
	input_pickable = true
	collision_layer = 4
	collision_mask = 0
	add_to_group("keyboard_interactable")
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(120, 80)
	collision.shape = shape
	collision.position = Vector2(0, -30)
	add_child(collision)
	mouse_entered.connect(func() -> void: hovered = true; queue_redraw())
	mouse_exited.connect(func() -> void: hovered = false; queue_redraw())
	queue_redraw()

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		try_interact()

func is_player_nearby() -> bool:
	return player != null and global_position.distance_to(player.global_position) <= INTERACTION_RANGE

func interaction_prompt() -> String:
	return "ENTER  —  WEJDŹ DO SKLEPU"

func set_interaction_focused(focused: bool) -> void:
	interaction_focused = focused
	queue_redraw()

func try_interact() -> bool:
	if not is_player_nearby():
		out_of_range.emit()
		return false
	enter_requested.emit()
	return true

func _draw() -> void:
	if not hovered and not interaction_focused:
		return
	draw_rect(Rect2(-59, -78, 118, 76), Color("#efb64788"), false, 4)
	draw_colored_polygon(PackedVector2Array([Vector2(-12, 10), Vector2(12, 10), Vector2(0, -4)]), Color("#efb647"))
