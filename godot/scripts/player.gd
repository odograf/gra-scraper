class_name Player
extends CharacterBody2D

signal action_finished(action_name: String)

const LOCOMOTION_SHEET := preload("res://assets/characters/collector_walk_sheet_v2.png")
const ACTION_SHEET := preload("res://assets/characters/collector_actions_v1.png")
const LOCOMOTION_FRAME_SIZE := Vector2i(429, 305)
const ACTION_FRAME_SIZE := Vector2i(222, 222)
const LOCOMOTION_COLUMNS := 3
const LOCOMOTION_SCALE := 0.37
const ACTION_SCALE := 0.52
const SPEED := 220.0
const IDLE_COLUMNS := [1]
const WALK_COLUMNS := [0, 1, 2, 1]
const DIRECTIONS := ["down", "left", "right", "up"]

var facing := "down"
var sprite: AnimatedSprite2D
var frame_anchors: Dictionary = {}
var action_locked := false
var current_action := ""
var action_timer: Timer

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	_create_shadow()
	_create_sprite()
	_create_collision()
	action_timer = Timer.new()
	action_timer.name = "CzasAkcji"
	action_timer.one_shot = true
	action_timer.timeout.connect(_finish_action)
	add_child(action_timer)

func _physics_process(_delta: float) -> void:
	if action_locked:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A): direction.x -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D): direction.x += 1.0
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W): direction.y -= 1.0
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S): direction.y += 1.0
	# Klasyczne sterowanie w czterech kierunkach — bez ruchu po skosie.
	if direction.x != 0.0:
		direction.y = 0.0
	velocity = direction.normalized() * SPEED
	_update_animation(direction)
	move_and_slide()

func _update_animation(direction: Vector2) -> void:
	if direction != Vector2.ZERO:
		if direction.x < 0.0: facing = "left"
		elif direction.x > 0.0: facing = "right"
		elif direction.y < 0.0: facing = "up"
		else: facing = "down"
		var walk_name := "walk_" + facing
		if sprite.animation != walk_name:
			# Przy zmianie kierunku zachowaj fazę kroku. Restart od klatki 0
			# przy każdym skręcie wyglądał jak krótkie zacięcie.
			var was_walking := String(sprite.animation).begins_with("walk_")
			var previous_frame := sprite.frame
			sprite.play(walk_name)
			if was_walking:
				sprite.frame = previous_frame % WALK_COLUMNS.size()
	else:
		var idle_name := "idle_" + facing
		if sprite.animation != idle_name:
			sprite.play(idle_name)

func play_action(action_name: String, target_position := global_position) -> bool:
	if action_locked or action_name not in ["rummage", "pickup"]:
		return false
	face_towards(target_position)
	action_locked = true
	current_action = action_name
	velocity = Vector2.ZERO
	sprite.play(action_name + "_" + facing)
	action_timer.start(1.10 if action_name == "rummage" else 0.48)
	return true

func is_action_busy() -> bool:
	return action_locked

func face_towards(target_position: Vector2) -> void:
	var direction := target_position - global_position
	if absf(direction.x) > absf(direction.y):
		facing = "right" if direction.x > 0.0 else "left"
	else:
		facing = "down" if direction.y > 0.0 else "up"

func _finish_action() -> void:
	if not action_locked:
		return
	var finished_action := current_action
	action_locked = false
	current_action = ""
	sprite.play("idle_" + facing)
	action_finished.emit(finished_action)

func _create_shadow() -> void:
	var shadow := Polygon2D.new()
	var points := PackedVector2Array()
	for index in range(24):
		var angle := TAU * float(index) / 24.0
		points.append(Vector2(cos(angle) * 34.0, sin(angle) * 12.0))
	shadow.polygon = points
	shadow.color = Color(0.04, 0.04, 0.03, 0.3)
	shadow.position = Vector2(0, -3)
	shadow.z_index = -1
	add_child(shadow)

func _create_sprite() -> void:
	_calculate_frame_anchors()
	sprite = AnimatedSprite2D.new()
	sprite.name = "BohaterSprite"
	sprite.sprite_frames = _make_sprite_frames()
	sprite.scale = Vector2.ONE * LOCOMOTION_SCALE
	sprite.position = Vector2.ZERO
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.frame_changed.connect(_apply_frame_alignment)
	sprite.animation_changed.connect(_apply_frame_alignment)
	add_child(sprite)
	sprite.play("idle_down")
	_apply_frame_alignment()

func _make_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for row in range(4):
		var walk_name: String = "walk_" + DIRECTIONS[row]
		frames.add_animation(walk_name)
		frames.set_animation_speed(walk_name, 9.0)
		frames.set_animation_loop(walk_name, true)
		for column in WALK_COLUMNS:
			frames.add_frame(walk_name, _atlas_frame(LOCOMOTION_SHEET, LOCOMOTION_FRAME_SIZE, column, row))
		var idle_name: String = "idle_" + DIRECTIONS[row]
		frames.add_animation(idle_name)
		frames.set_animation_speed(idle_name, 1.4)
		frames.set_animation_loop(idle_name, true)
		for column in IDLE_COLUMNS:
			frames.add_frame(idle_name, _atlas_frame(LOCOMOTION_SHEET, LOCOMOTION_FRAME_SIZE, column, row))
		for action_name in ["rummage", "pickup"]:
			var animation_name: String = action_name + "_" + DIRECTIONS[row]
			frames.add_animation(animation_name)
			frames.set_animation_speed(animation_name, 6.5 if action_name == "rummage" else 9.0)
			frames.set_animation_loop(animation_name, action_name == "rummage")
			var action_row := row if action_name == "rummage" else row + 4
			for column in range(4):
				frames.add_frame(animation_name, _atlas_frame(ACTION_SHEET, ACTION_FRAME_SIZE, column, action_row))
	return frames

func _atlas_frame(sheet: Texture2D, frame_size: Vector2i, column: int, row: int) -> AtlasTexture:
	var frame := AtlasTexture.new()
	frame.atlas = sheet
	frame.region = Rect2(Vector2(column, row) * Vector2(frame_size), Vector2(frame_size))
	return frame

func _calculate_frame_anchors() -> void:
	_calculate_locomotion_anchors()
	for row in range(8):
		for column in range(4):
			# Arkusz akcji jest celowo kotwiczony do stałego środka i linii podłoża.
			# Dzięki temu schylanie pozostaje ruchem ciała, a nie przesunięciem całego sprite'a.
			frame_anchors["action:%d:%d" % [column, row]] = Vector2(ACTION_FRAME_SIZE.x * 0.5, ACTION_FRAME_SIZE.y - 6)

func _calculate_locomotion_anchors() -> void:
	var image := LOCOMOTION_SHEET.get_image()
	for row in range(4):
		for column in range(LOCOMOTION_COLUMNS):
			var min_y := LOCOMOTION_FRAME_SIZE.y
			var max_y := 0
			for y in range(LOCOMOTION_FRAME_SIZE.y):
				for x in range(LOCOMOTION_FRAME_SIZE.x):
					if image.get_pixel(column * LOCOMOTION_FRAME_SIZE.x + x, row * LOCOMOTION_FRAME_SIZE.y + y).a > 0.12:
						min_y = mini(min_y, y)
						max_y = maxi(max_y, y)

			# Górny fragment sylwetki zawiera głowę, ale nie reklamówkę.
			# Jej środek jest stabilniejszym punktem odniesienia niż środek całego obrazka.
			var head_end := mini(max_y, min_y + 72)
			var weighted_x := 0.0
			var total_alpha := 0.0
			for y in range(min_y, head_end + 1):
				for x in range(LOCOMOTION_FRAME_SIZE.x):
					var alpha := image.get_pixel(column * LOCOMOTION_FRAME_SIZE.x + x, row * LOCOMOTION_FRAME_SIZE.y + y).a
					if alpha > 0.12:
						weighted_x += float(x) * alpha
						total_alpha += alpha
			var anchor_x := float(LOCOMOTION_FRAME_SIZE.x) * 0.5
			if total_alpha > 0.0:
				anchor_x = weighted_x / total_alpha
			frame_anchors["move:%d:%d" % [column, row]] = Vector2(anchor_x, max_y)

func _apply_frame_alignment() -> void:
	if sprite == null:
		return
	var animation_name := String(sprite.animation)
	var is_action := animation_name.begins_with("rummage_") or animation_name.begins_with("pickup_")
	sprite.scale = Vector2.ONE * (ACTION_SCALE if is_action else LOCOMOTION_SCALE)
	var direction_name := animation_name.get_slice("_", 1)
	var direction_row := maxi(0, DIRECTIONS.find(direction_name))
	var anchor_key := ""
	if animation_name.begins_with("walk_"):
		var column: int = WALK_COLUMNS[mini(sprite.frame, WALK_COLUMNS.size() - 1)]
		anchor_key = "move:%d:%d" % [column, direction_row]
	elif animation_name.begins_with("idle_"):
		var column: int = IDLE_COLUMNS[mini(sprite.frame, IDLE_COLUMNS.size() - 1)]
		anchor_key = "move:%d:%d" % [column, direction_row]
	else:
		var action_row := direction_row + (4 if animation_name.begins_with("pickup_") else 0)
		anchor_key = "action:%d:%d" % [sprite.frame, action_row]
	var frame_size := ACTION_FRAME_SIZE if is_action else LOCOMOTION_FRAME_SIZE
	var anchor: Vector2 = frame_anchors.get(anchor_key, Vector2(frame_size) * 0.5)
	sprite.offset = Vector2(frame_size) * 0.5 - anchor

func _create_collision() -> void:
	var collision := CollisionShape2D.new()
	collision.name = "KolizjaStop"
	var shape := CapsuleShape2D.new()
	shape.radius = 17.0
	shape.height = 40.0
	collision.shape = shape
	collision.position = Vector2(0, -17)
	add_child(collision)
