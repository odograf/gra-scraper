class_name CanMachine
extends Area2D

const INTERACTION_RANGE := 165.0

signal sell_requested
signal out_of_range

var player: Player
var hovered := false
var interaction_focused := false

func _ready() -> void:
	input_pickable = true
	collision_layer = 4
	collision_mask = 0
	add_to_group("keyboard_interactable")
	var click_collision := CollisionShape2D.new()
	var click_shape := RectangleShape2D.new()
	click_shape.size = Vector2(82, 126)
	click_collision.shape = click_shape
	click_collision.position = Vector2(0, -55)
	add_child(click_collision)

	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 2
	var body_collision := CollisionShape2D.new()
	var body_shape := RectangleShape2D.new()
	body_shape.size = Vector2(76, 54)
	body_collision.shape = body_shape
	body_collision.position = Vector2(0, -22)
	body.add_child(body_collision)
	add_child(body)
	mouse_entered.connect(func() -> void: hovered = true; queue_redraw())
	mouse_exited.connect(func() -> void: hovered = false; queue_redraw())
	queue_redraw()

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		try_interact()

func is_player_nearby() -> bool:
	return player != null and global_position.distance_to(player.global_position) <= INTERACTION_RANGE

func interaction_prompt() -> String:
	return "ENTER  —  SPRZEDAJ PUSZKI"

func set_interaction_focused(focused: bool) -> void:
	interaction_focused = focused
	queue_redraw()

func try_interact() -> bool:
	if not is_player_nearby():
		out_of_range.emit()
		return false
	sell_requested.emit()
	return true

func _draw() -> void:
	if hovered or interaction_focused:
		draw_circle(Vector2(0, -55), 62, Color("#efb64744"))
	draw_rect(Rect2(-43, -122, 86, 122), Color(0, 0, 0, 0.24))
	draw_rect(Rect2(-40, -128, 80, 122), Color("#42695b"))
	draw_rect(Rect2(-34, -119, 68, 32), Color("#202a27"))
	draw_rect(Rect2(-27, -111, 54, 15), Color("#78a88c"))
	draw_circle(Vector2(0, -66), 19, Color("#1f2825"))
	draw_circle(Vector2(0, -66), 13, Color("#a8b7aa"), false, 4)
	draw_rect(Rect2(-25, -38, 50, 9), Color("#202522"))
	draw_rect(Rect2(-35, -128, 70, 122), Color("#b9c1b5"), false, 3)
	draw_string(ThemeDB.fallback_font, Vector2(-31, -12), "PUSZKI", HORIZONTAL_ALIGNMENT_CENTER, 62, 11, Color("#e7e1d2"))
