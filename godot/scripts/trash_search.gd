class_name TrashSearch
extends Area2D

const TRASH_BINS_TEXTURE := preload("res://assets/props/trash_bins.png")
const INTERACTION_RANGE := 175.0

signal search_requested(trash: TrashSearch)
signal out_of_range

var player: Player
var hovered := false
var interaction_focused := false
var searched := false
var remaining_cans := 0
var remaining_wire := 0
var rolled_cans := 0
var rolled_wire := 0
var guaranteed_wire := false

func _ready() -> void:
	input_pickable = true
	collision_layer = 4
	collision_mask = 0
	add_to_group("keyboard_interactable")
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = TRASH_BINS_TEXTURE
	sprite.position = Vector2(0, -2)
	sprite.scale = Vector2(0.16, 0.16)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(sprite)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(240, 130)
	collision.shape = shape
	collision.position = Vector2(0, -12)
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
	return "ENTER  —  SPRAWDŹ KONTENERY" if not is_empty() else "ENTER  —  PUSTE KONTENERY"

func set_interaction_focused(focused: bool) -> void:
	interaction_focused = focused
	queue_redraw()

func try_interact() -> bool:
	if not is_player_nearby():
		out_of_range.emit()
		return false
	search_requested.emit(self)
	return true

func reveal_loot() -> void:
	if searched:
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var loot := generate_loot(rng)
	if guaranteed_wire:
		loot.wire = 1
	rolled_cans = int(loot.can)
	rolled_wire = int(loot.wire)
	remaining_cans = rolled_cans
	remaining_wire = rolled_wire
	searched = true
	queue_redraw()

func set_test_loot(cans: int, wire: int) -> void:
	rolled_cans = clampi(cans, 1, 3)
	rolled_wire = clampi(wire, 0, 1)
	remaining_cans = rolled_cans
	remaining_wire = rolled_wire
	searched = true
	queue_redraw()

func is_empty() -> bool:
	return searched and remaining_cans <= 0 and remaining_wire <= 0

static func generate_loot(rng: RandomNumberGenerator) -> Dictionary:
	return {
		"can": rng.randi_range(1, 3),
		"wire": 1 if rng.randf() < 0.25 else 0
	}

func _draw() -> void:
	if not hovered and not interaction_focused:
		return
	var color := Color("#efb64799")
	var text := "PRZESZUKAJ"
	if is_empty():
		color = Color("#8b8d8588")
		text = "PUSTY"
	draw_rect(Rect2(-120, -78, 240, 130), color, false, 4)
	draw_string(ThemeDB.fallback_font, Vector2(-58, -86), text, HORIZONTAL_ALIGNMENT_CENTER, 116, 13, color)
