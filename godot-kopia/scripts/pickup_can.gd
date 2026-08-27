class_name PickupCan
extends Area2D

const CAN_TEXTURE := preload("res://assets/items/crushed_can.png")
const INTERACTION_RANGE := 150.0

signal collected
signal out_of_range
signal inventory_full

var player: Player
var can_accept_callback: Callable
var interaction_focused := false
var already_collected := false
var highlight_sprite: Sprite2D

func _ready() -> void:
	input_pickable = true
	collision_layer = 4
	collision_mask = 0
	add_to_group("pickup_item")
	add_to_group("keyboard_interactable")
	highlight_sprite = Sprite2D.new()
	highlight_sprite.name = "Podswietlenie"
	highlight_sprite.texture = CAN_TEXTURE
	highlight_sprite.scale = Vector2(0.063, 0.063)
	highlight_sprite.modulate = Color("#f0c75c99")
	highlight_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	highlight_sprite.z_index = -1
	highlight_sprite.visible = false
	add_child(highlight_sprite)
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = CAN_TEXTURE
	sprite.scale = Vector2(0.055, 0.055)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(sprite)
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 22.0
	collision.shape = shape
	add_child(collision)
	queue_redraw()

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		try_collect()

func is_player_nearby() -> bool:
	return not already_collected and player != null and global_position.distance_to(player.global_position) <= INTERACTION_RANGE

func interaction_prompt() -> String:
	return "ENTER  —  PODNIEŚ PUSZKĘ"

func try_interact() -> bool:
	return try_collect()

func set_interaction_focused(focused: bool) -> void:
	interaction_focused = focused and not already_collected
	if highlight_sprite != null:
		highlight_sprite.visible = interaction_focused

func try_collect() -> bool:
	if already_collected or player == null:
		return false
	if player.is_action_busy():
		return false
	if not is_player_nearby():
		out_of_range.emit()
		return false
	if can_accept_callback.is_valid() and not bool(can_accept_callback.call()):
		inventory_full.emit()
		return true
	if not player.play_action("pickup", global_position):
		return false
	already_collected = true
	set_interaction_focused(false)
	input_pickable = false
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", player.global_position - Vector2(0, 30), 0.28).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "scale", Vector2(0.15, 0.15), 0.28)
	tween.tween_property(self, "modulate:a", 0.0, 0.28)
	tween.set_parallel(false)
	tween.tween_callback(_finish_collect)
	return true

func _finish_collect() -> void:
	collected.emit()
	queue_free()
