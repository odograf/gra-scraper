class_name CombatEnemy
extends Area2D

const INTERACTION_RANGE := 155.0

signal fight_requested
signal out_of_range
signal realtime_hit(damage: int)

var player: Player
var hovered := false
var interaction_focused := false

func _ready() -> void:
	input_pickable = true
	collision_layer = 4 | 8
	collision_mask = 0
	add_to_group("keyboard_interactable")
	var click_collision := CollisionShape2D.new()
	var click_shape := CapsuleShape2D.new()
	click_shape.radius = 25.0
	click_shape.height = 78.0
	click_collision.shape = click_shape
	click_collision.position = Vector2(0, -31)
	add_child(click_collision)
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 2
	var body_collision := CollisionShape2D.new()
	var body_shape := CapsuleShape2D.new()
	body_shape.radius = 21.0
	body_shape.height = 46.0
	body_collision.shape = body_shape
	body_collision.position = Vector2(0, -22)
	body.add_child(body_collision)
	add_child(body)
	mouse_entered.connect(func() -> void: hovered = true; queue_redraw())
	mouse_exited.connect(func() -> void: hovered = false; queue_redraw())
	queue_redraw()

func receive_realtime_hit(damage: int, _source_position: Vector2) -> void:
	realtime_hit.emit(damage)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color("#ff6b5f"), 0.06)
	tween.tween_property(self, "modulate", Color.WHITE, 0.16)

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		try_interact()

func is_player_nearby() -> bool:
	return player != null and global_position.distance_to(player.global_position) <= INTERACTION_RANGE

func interaction_prompt() -> String:
	return "ENTER  —  ZACZNIJ WALKĘ"

func set_interaction_focused(focused: bool) -> void:
	interaction_focused = focused
	queue_redraw()

func try_interact() -> bool:
	if not is_player_nearby():
		out_of_range.emit()
		return false
	fight_requested.emit()
	return true

func _draw() -> void:
	if hovered or interaction_focused:
		draw_circle(Vector2(0, -30), 40.0, Color("#efb64744"))
		draw_arc(Vector2(0, -30), 41.0, 0.0, TAU, 32, Color("#f2cd72aa"), 2.0)
	# Prosta sylwetka mapowa: front na wprost, stopy zakotwiczone w (0, 0).
	draw_ellipse(Vector2(0, -2), 27.0, 9.0, Color("#10120f66"))
	draw_line(Vector2(-11, -9), Vector2(-15, -39), Color("#292823"), 12.0, true)
	draw_line(Vector2(11, -9), Vector2(15, -39), Color("#292823"), 12.0, true)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-25, -38), Vector2(-20, -82), Vector2(21, -82), Vector2(27, -38)
	]), Color("#75473a"))
	draw_line(Vector2(-19, -73), Vector2(-34, -43), Color("#292823"), 10.0, true)
	draw_line(Vector2(19, -73), Vector2(35, -48), Color("#292823"), 10.0, true)
	draw_circle(Vector2(0, -99), 18.0, Color("#b18c67"))
	draw_arc(Vector2(0, -101), 18.0, PI, TAU, 16, Color("#292823"), 8.0, true)
	draw_string(ThemeDB.fallback_font, Vector2(-58, 20), "ZADYMIARZ", HORIZONTAL_ALIGNMENT_CENTER, 116, 11, Color("#eee6d7"))
