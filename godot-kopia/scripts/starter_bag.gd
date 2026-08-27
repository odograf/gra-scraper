class_name StarterBag
extends Area2D

const INTERACTION_RANGE := 145.0

signal picked_up
signal out_of_range

var player: Player
var interaction_focused := false
var collected := false

func _ready() -> void:
	input_pickable = true
	collision_layer = 4
	collision_mask = 0
	add_to_group("pickup_item")
	add_to_group("keyboard_interactable")
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 30.0
	collision.shape = shape
	add_child(collision)
	queue_redraw()

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		try_collect()

func is_player_nearby() -> bool:
	return not collected and player != null and global_position.distance_to(player.global_position) <= INTERACTION_RANGE

func interaction_prompt() -> String:
	return "ENTER  —  PODNIEŚ REKLAMÓWKĘ"

func try_interact() -> bool:
	return try_collect()

func set_interaction_focused(focused: bool) -> void:
	if interaction_focused == focused:
		return
	interaction_focused = focused and not collected
	queue_redraw()

func try_collect() -> bool:
	if collected or player == null:
		return false
	if not is_player_nearby():
		out_of_range.emit()
		return false
	collected = true
	set_interaction_focused(false)
	input_pickable = false
	picked_up.emit()
	queue_free()
	return true

func _draw() -> void:
	if interaction_focused:
		draw_circle(Vector2(0, 13), 27.0, Color("#efb64724"))
		draw_arc(Vector2(0, 13), 28, 0.0, TAU, 32, Color("#f2cd72aa"), 1.5)
	# Prosta, czytelna reklamówka startowa.
	var bag := PackedVector2Array([
		Vector2(-22, -6), Vector2(22, -6), Vector2(17, 28), Vector2(-17, 28)
	])
	draw_colored_polygon(bag, Color("#deddd1dc"))
	draw_polyline(PackedVector2Array([Vector2(-12, -5), Vector2(-9, -22), Vector2(9, -22), Vector2(12, -5)]), Color("#f2f0e5"), 4.0)
	draw_line(Vector2(-15, 8), Vector2(15, 8), Color("#b8b8ae"), 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(-48, 48), "REKLAMÓWKA", HORIZONTAL_ALIGNMENT_CENTER, 96, 11, Color("#eee6d7"))
