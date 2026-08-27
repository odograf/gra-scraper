class_name Player
extends CharacterBody2D

signal action_finished(action_name: String)
signal spin_attack_hit(target: Area2D, damage: int)
signal target_attack_hit(target: Node2D, damage: int)

const CombatantConfigScript := preload("res://scripts/combatant_config.gd")
const LOCOMOTION_SHEET := preload("res://assets/characters/collector_walk_sheet_v3_canonical.png")
const ACTION_SHEET := preload("res://assets/characters/collector_actions_v2_canonical.png")
const BAG_HAMMER_ATTACK_SHEET := preload("res://assets/characters/collector_bag_hammer_attack_v3_canonical.png")
const LOCOMOTION_FRAME_SIZE := Vector2i(429, 305)
const ACTION_FRAME_SIZE := Vector2i(256, 256)
const BAG_HAMMER_FRAME_SIZE := Vector2i(640, 480)
const LOCOMOTION_COLUMNS := 3
const LOCOMOTION_SCALE := 0.37
const ACTION_SCALE := 0.52
const BAG_HAMMER_SCALE := 0.33
const SPEED := 220.0
const TARGET_REACHED_DISTANCE := 10.0
const STUCK_CANCEL_TIME := 0.45
const SPIN_ATTACK_DURATION := 0.64
const SPIN_ATTACK_DAMAGE := 8
const TARGET_ATTACK_HIT_TIME := 0.22
const TARGET_ATTACK_DURATION := 0.64
const IDLE_COLUMNS := [1]
const WALK_COLUMNS := [0, 1, 2, 1]
const DIRECTIONS := ["down", "left", "right", "up"]
const LOCOMOTION_FRAME_ANCHORS := {
	"move:0:0": Vector2(322.5617, 304.0),
	"move:0:1": Vector2(308.1199, 299.0),
	"move:0:2": Vector2(324.2269, 290.0),
	"move:0:3": Vector2(313.5406, 295.0),
	"move:1:0": Vector2(216.5713, 303.0),
	"move:1:1": Vector2(209.8179, 304.0),
	"move:1:2": Vector2(225.9834, 300.0),
	"move:1:3": Vector2(210.8736, 288.0),
	"move:2:0": Vector2(113.4649, 304.0),
	"move:2:1": Vector2(87.4574, 304.0),
	"move:2:2": Vector2(115.6317, 293.0),
	"move:2:3": Vector2(106.5467, 295.0),
}

var facing := "down"
var sprite: AnimatedSprite2D
var frame_anchors: Dictionary = {}
var action_locked := false
var current_action := ""
var action_timer: Timer
var move_target := Vector2.ZERO
var has_move_target := false
var queued_move_target := Vector2.ZERO
var has_queued_move_target := false
var stuck_time := 0.0
var target_marker: Line2D
var attack_hitbox: Area2D
var hit_targets: Dictionary = {}
var queued_attack_target: Node2D
var player_state: PlayerState

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	_create_shadow()
	_create_target_marker()
	_create_spin_attack()
	_create_sprite()
	_create_collision()
	action_timer = Timer.new()
	action_timer.name = "CzasAkcji"
	action_timer.one_shot = true
	action_timer.timeout.connect(_finish_action)
	add_child(action_timer)

func _physics_process(delta: float) -> void:
	if action_locked:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if queued_attack_target != null:
		if not is_instance_valid(queued_attack_target) or bool(queued_attack_target.get("dead")):
			queued_attack_target = null
			cancel_move_target(false)
		elif global_position.distance_to(queued_attack_target.global_position) <= attack_range_pixels():
			var target := queued_attack_target
			queued_attack_target = null
			_start_target_attack(target)
			return
		else:
			move_target = queued_attack_target.global_position
	var keyboard_direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A): keyboard_direction.x -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D): keyboard_direction.x += 1.0
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W): keyboard_direction.y -= 1.0
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S): keyboard_direction.y += 1.0
	if keyboard_direction != Vector2.ZERO:
		cancel_move_target(true)
	var direction := keyboard_direction
	if direction == Vector2.ZERO and has_move_target:
		var to_target := move_target - global_position
		if to_target.length() <= TARGET_REACHED_DISTANCE:
			cancel_move_target()
		else:
			direction = to_target.normalized()
	velocity = direction.normalized() * SPEED
	_update_animation(direction)
	var position_before := global_position
	move_and_slide()
	if has_move_target and direction != Vector2.ZERO:
		var travelled := global_position.distance_to(position_before)
		stuck_time = stuck_time + delta if travelled < 0.5 else 0.0
		if stuck_time >= STUCK_CANCEL_TIME:
			cancel_move_target()

func set_move_target(target: Vector2) -> void:
	if action_locked:
		# Ostatni klik podczas animacji zastępuje poprzednią komendę. Bohater
		# kończy akcję, a następnie rusza bez potrzeby ponownego klikania.
		queued_attack_target = null
		queued_move_target = target
		has_queued_move_target = true
		target_marker.global_position = target
		target_marker.visible = true
		return
	_apply_move_target(target)

func _apply_move_target(target: Vector2) -> void:
	queued_attack_target = null
	move_target = target
	has_move_target = true
	stuck_time = 0.0
	target_marker.global_position = move_target
	target_marker.visible = true

func cancel_move_target(clear_queued_attack := true, clear_queued_move := true) -> void:
	has_move_target = false
	stuck_time = 0.0
	if clear_queued_attack:
		queued_attack_target = null
	if clear_queued_move:
		has_queued_move_target = false
	if target_marker != null and not has_queued_move_target:
		target_marker.visible = false

func is_moving_to_target() -> bool:
	return has_move_target

func has_buffered_move_command() -> bool:
	return has_queued_move_target

func start_spin_attack() -> bool:
	if action_locked:
		return false
	cancel_move_target()
	action_locked = true
	current_action = "spin_attack"
	velocity = Vector2.ZERO
	hit_targets.clear()
	sprite.play("bag_hammer_attack")
	_run_spin_attack_window()
	return true

func request_target_attack(target: Node2D) -> bool:
	if action_locked or target == null or not is_instance_valid(target) or bool(target.get("dead")):
		return false
	if global_position.distance_to(target.global_position) <= attack_range_pixels():
		return _start_target_attack(target)
	set_move_target(target.global_position)
	queued_attack_target = target
	return true

func attack_damage() -> int:
	if player_state != null:
		return player_state.realtime_attack_damage()
	return int(CombatantConfigScript.PLAYER.attack)

func attack_range_pixels() -> float:
	return CombatantConfigScript.range_in_pixels(int(CombatantConfigScript.PLAYER.attack_range))

func _start_target_attack(target: Node2D) -> bool:
	if action_locked or target == null or not is_instance_valid(target):
		return false
	cancel_move_target(false)
	face_towards(target.global_position)
	action_locked = true
	current_action = "target_attack"
	velocity = Vector2.ZERO
	sprite.play("bag_hammer_attack")
	_run_target_attack(target)
	return true

func _run_target_attack(target: Node2D) -> void:
	await get_tree().create_timer(TARGET_ATTACK_HIT_TIME).timeout
	if action_locked and current_action == "target_attack" and is_instance_valid(target):
		if global_position.distance_to(target.global_position) <= attack_range_pixels() + 20.0 and target.has_method("receive_realtime_hit"):
			target.call("receive_realtime_hit", attack_damage(), global_position)
			target_attack_hit.emit(target, attack_damage())
	await get_tree().create_timer(TARGET_ATTACK_DURATION - TARGET_ATTACK_HIT_TIME).timeout
	if action_locked and current_action == "target_attack":
		_finish_action()

func _run_spin_attack_window() -> void:
	# Klatki 0-2 to zamach. Hitbox działa podczas szerokiego przelotu torby
	# w klatkach 3-5, a następnie gaśnie przed fazą wyhamowania.
	await get_tree().create_timer(0.22).timeout
	if not action_locked or current_action != "spin_attack":
		return
	attack_hitbox.monitoring = true
	for area in attack_hitbox.get_overlapping_areas():
		_register_spin_hit(area)
	await get_tree().create_timer(0.26).timeout
	attack_hitbox.monitoring = false
	await get_tree().create_timer(SPIN_ATTACK_DURATION - 0.48).timeout
	if action_locked and current_action == "spin_attack":
		_finish_action()

func _register_spin_hit(area: Area2D) -> void:
	if not action_locked or current_action != "spin_attack":
		return
	var target_id := area.get_instance_id()
	if hit_targets.has(target_id):
		return
	hit_targets[target_id] = true
	if area.has_method("receive_realtime_hit"):
		area.call("receive_realtime_hit", SPIN_ATTACK_DAMAGE, global_position)
	spin_attack_hit.emit(area, SPIN_ATTACK_DAMAGE)

func _update_animation(direction: Vector2) -> void:
	if direction != Vector2.ZERO:
		if absf(direction.x) > absf(direction.y):
			facing = "left" if direction.x < 0.0 else "right"
		else:
			facing = "up" if direction.y < 0.0 else "down"
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
	cancel_move_target()
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
	if finished_action == "spin_attack":
		attack_hitbox.monitoring = false
	action_locked = false
	current_action = ""
	if has_queued_move_target:
		var buffered_target := queued_move_target
		has_queued_move_target = false
		_apply_move_target(buffered_target)
		_update_animation((buffered_target - global_position).normalized())
	else:
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

func _create_target_marker() -> void:
	target_marker = Line2D.new()
	target_marker.name = "ZnacznikCelu"
	target_marker.width = 3.0
	target_marker.default_color = Color(0.88, 0.73, 0.28, 0.9)
	target_marker.closed = true
	target_marker.z_index = 30
	for index in range(24):
		var angle := TAU * float(index) / 24.0
		target_marker.add_point(Vector2(cos(angle) * 18.0, sin(angle) * 8.0))
	add_child(target_marker)
	target_marker.set_as_top_level(true)
	target_marker.visible = false

func _create_spin_attack() -> void:
	attack_hitbox = Area2D.new()
	attack_hitbox.name = "HitboxZamachuReklamowka"
	attack_hitbox.collision_layer = 0
	attack_hitbox.collision_mask = 8
	attack_hitbox.monitoring = false
	attack_hitbox.monitorable = false
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 112.0
	collision.shape = shape
	collision.position = Vector2(0, -26)
	attack_hitbox.add_child(collision)
	attack_hitbox.area_entered.connect(_register_spin_hit)
	add_child(attack_hitbox)

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
	frames.add_animation("bag_hammer_attack")
	frames.set_animation_speed("bag_hammer_attack", 12.5)
	frames.set_animation_loop("bag_hammer_attack", false)
	for row in range(2):
		for column in range(4):
			frames.add_frame("bag_hammer_attack", _atlas_frame(BAG_HAMMER_ATTACK_SHEET, BAG_HAMMER_FRAME_SIZE, column, row))
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
			frame_anchors["action:%d:%d" % [column, row]] = Vector2(128, 232)
	_calculate_bag_hammer_anchors()

func _calculate_bag_hammer_anchors() -> void:
	# Arkusz v2 jest przepakowany względem środka stóp zamiast obwiedni torby.
	# Każda klatka ma identyczny punkt podłoża, więc szeroki zamach nie szarpie postacią.
	for frame_index in range(8):
		frame_anchors["bag_hammer:%d" % frame_index] = Vector2(320, 420)

func _calculate_locomotion_anchors() -> void:
	# Kotwice są wyliczane przez narzędzie przygotowujące arkusz, a nie przy każdym
	# uruchomieniu gry. Usuwa to ponad milion odczytów pikseli ze ścieżki startowej.
	for anchor_key in LOCOMOTION_FRAME_ANCHORS:
		frame_anchors[anchor_key] = LOCOMOTION_FRAME_ANCHORS[anchor_key]

func _apply_frame_alignment() -> void:
	if sprite == null:
		return
	var animation_name := String(sprite.animation)
	var is_standard_action := animation_name.begins_with("rummage_") or animation_name.begins_with("pickup_")
	var is_bag_hammer := animation_name == "bag_hammer_attack"
	if is_bag_hammer:
		sprite.scale = Vector2.ONE * BAG_HAMMER_SCALE
	else:
		sprite.scale = Vector2.ONE * (ACTION_SCALE if is_standard_action else LOCOMOTION_SCALE)
	var direction_name := animation_name.get_slice("_", 1)
	var direction_row := maxi(0, DIRECTIONS.find(direction_name))
	var anchor_key := ""
	if is_bag_hammer:
		anchor_key = "bag_hammer:%d" % sprite.frame
	elif animation_name.begins_with("walk_"):
		var column: int = WALK_COLUMNS[mini(sprite.frame, WALK_COLUMNS.size() - 1)]
		anchor_key = "move:%d:%d" % [column, direction_row]
	elif animation_name.begins_with("idle_"):
		var column: int = IDLE_COLUMNS[mini(sprite.frame, IDLE_COLUMNS.size() - 1)]
		anchor_key = "move:%d:%d" % [column, direction_row]
	else:
		var action_row := direction_row + (4 if animation_name.begins_with("pickup_") else 0)
		anchor_key = "action:%d:%d" % [sprite.frame, action_row]
	var frame_size := BAG_HAMMER_FRAME_SIZE if is_bag_hammer else (ACTION_FRAME_SIZE if is_standard_action else LOCOMOTION_FRAME_SIZE)
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
