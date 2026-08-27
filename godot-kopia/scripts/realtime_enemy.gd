class_name RealtimeEnemy
extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal attack_landed(damage: int)
signal defeated

enum State { IDLE, CHASE, ATTACK, DEAD }

const HurtboxScript := preload("res://scripts/realtime_hurtbox.gd")
const CombatantConfigScript := preload("res://scripts/combatant_config.gd")

var player: Player
var active := false:
	set(value):
		if active == value:
			return
		active = value
		if not active:
			_cancel_attack()
var combat_config: Dictionary = {}
var level := 1
var max_health := 1
var attack_damage := 0
var attack_range := 1
var xp_reward := 0
var health := 1
var sprite: AnimatedSprite2D
var hurtbox: RealtimeHurtbox
var attack_cooldown_left := 0.0
var attacking := false
var dead := false
var state := State.IDLE
var _attack_generation := 0
var _flash_tween: Tween

func _ready() -> void:
	combat_config = CombatantConfigScript.enemy(String(_combatant_id()))
	level = int(combat_config.level)
	max_health = int(combat_config.max_health)
	attack_damage = int(combat_config.attack)
	attack_range = int(combat_config.attack_range)
	xp_reward = int(combat_config.xp_reward)
	health = max_health
	collision_layer = 1
	collision_mask = 1 | 2
	_create_shadow()
	_create_sprite()
	_create_body_collision()
	_create_hurtbox()
	queue_redraw()

func _physics_process(delta: float) -> void:
	if dead:
		velocity = Vector2.ZERO
		return
	attack_cooldown_left = maxf(0.0, attack_cooldown_left - delta)
	if not active or player == null:
		velocity = Vector2.ZERO
		_set_state(State.IDLE)
		return
	if state == State.ATTACK:
		velocity = Vector2.ZERO
		return
	var to_player := player.global_position - global_position
	var distance := to_player.length()
	if distance <= _bite_distance_pixels() and attack_cooldown_left <= 0.0:
		_start_attack()
		return
	if distance <= _detection_range():
		velocity = to_player.normalized() * _move_speed()
		_update_facing(to_player.x)
		_set_state(State.CHASE)
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		_set_state(State.IDLE)

func receive_realtime_hit(damage: int, source_position: Vector2) -> void:
	if dead or damage <= 0:
		return
	health = maxi(0, health - damage)
	health_changed.emit(health, max_health)
	queue_redraw()
	_update_facing(source_position.x - global_position.x)
	_flash_hit()
	if health <= 0:
		_die()

func attack_range_pixels() -> float:
	return CombatantConfigScript.range_in_pixels(attack_range)

func cancel_pending_attack() -> void:
	_cancel_attack()

func _start_attack() -> void:
	if not active or dead or player == null:
		return
	_attack_generation += 1
	var generation := _attack_generation
	attacking = true
	velocity = Vector2.ZERO
	_update_facing(player.global_position.x - global_position.x)
	_set_state(State.ATTACK)
	_run_attack(generation)

func _run_attack(generation: int) -> void:
	await get_tree().create_timer(_attack_hit_time()).timeout
	if not _attack_is_current(generation):
		return
	if global_position.distance_to(player.global_position) <= _bite_distance_pixels() + _hit_tolerance():
		attack_landed.emit(attack_damage)
		var player_tween := player.create_tween()
		player_tween.tween_property(player, "modulate", _player_hit_color(), _player_flash_in())
		player_tween.tween_property(player, "modulate", Color.WHITE, _player_flash_out())
	await get_tree().create_timer(maxf(0.0, _attack_duration() - _attack_hit_time())).timeout
	if not _attack_is_current(generation):
		return
	attacking = false
	attack_cooldown_left = _attack_cooldown()
	_set_state(State.IDLE)

func _attack_is_current(generation: int) -> bool:
	return generation == _attack_generation and active and not dead and attacking and player != null

func _cancel_attack() -> void:
	if not attacking and state != State.ATTACK:
		return
	_attack_generation += 1
	attacking = false
	velocity = Vector2.ZERO
	attack_cooldown_left = maxf(attack_cooldown_left, _attack_cooldown())
	if not dead:
		_set_state(State.IDLE)

func _set_state(next_state: State) -> void:
	if state == next_state:
		return
	state = next_state
	match state:
		State.IDLE: _play_if_needed(&"idle")
		State.CHASE: _play_if_needed(&"walk")
		State.ATTACK: _play_if_needed(&"attack")

func _die() -> void:
	dead = true
	_cancel_attack()
	active = false
	state = State.DEAD
	velocity = Vector2.ZERO
	set_physics_process(false)
	for child in get_children():
		if child is CollisionShape2D:
			(child as CollisionShape2D).set_deferred("disabled", true)
	if hurtbox != null:
		hurtbox.set_deferred("monitorable", false)
		var hurt_shape := hurtbox.get_node_or_null("KsztaltTrafienia") as CollisionShape2D
		if hurt_shape != null:
			hurt_shape.set_deferred("disabled", true)
	defeated.emit()
	_run_death_sequence()

func _run_death_sequence() -> void:
	if _uses_defeat_animation():
		sprite.play(&"defeat")
		await get_tree().create_timer(_defeat_duration()).timeout
	var tween := create_tween()
	if _death_drop_distance() != 0.0:
		tween.set_parallel(true)
		tween.tween_property(self, "position:y", position.y + _death_drop_distance(), _fade_duration())
	tween.tween_property(self, "modulate:a", 0.0, _fade_duration())
	await tween.finished
	queue_free()

func _flash_hit() -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	modulate = Color.WHITE
	_flash_tween = create_tween()
	_flash_tween.tween_property(self, "modulate", _enemy_hit_color(), _enemy_flash_in())
	_flash_tween.tween_property(self, "modulate", Color.WHITE, _enemy_flash_out())

func _update_facing(horizontal_delta: float) -> void:
	if absf(horizontal_delta) > 1.0:
		sprite.flip_h = horizontal_delta < 0.0

func _play_if_needed(animation_name: StringName) -> void:
	if sprite.animation != animation_name:
		sprite.play(animation_name)

func _create_sprite() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.name = _sprite_name()
	sprite.sprite_frames = _make_sprite_frames()
	sprite.scale = Vector2.ONE * _sprite_scale()
	sprite.offset = Vector2(_frame_size()) * 0.5 - _frame_anchor()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(sprite)
	sprite.play(&"idle")

func _add_animation_row(frames: SpriteFrames, animation_name: StringName, row: int, fps: float, looped: bool) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, looped)
	for column in range(4):
		var atlas := AtlasTexture.new()
		atlas.atlas = _sprite_sheet()
		atlas.region = Rect2(column * _frame_size().x, row * _frame_size().y, _frame_size().x, _frame_size().y)
		frames.add_frame(animation_name, atlas)

func _create_shadow() -> void:
	var shadow := Polygon2D.new()
	shadow.name = "Cien"
	var points := PackedVector2Array()
	for index in range(_shadow_segments()):
		var angle := TAU * float(index) / float(_shadow_segments())
		points.append(Vector2(cos(angle) * _shadow_size().x, sin(angle) * _shadow_size().y))
	shadow.polygon = points
	shadow.color = _shadow_color()
	shadow.position = Vector2(0, _shadow_offset_y())
	shadow.z_index = -1
	add_child(shadow)

func _create_body_collision() -> void:
	var collision := CollisionShape2D.new()
	collision.name = "KolizjaCiala"
	var shape := CapsuleShape2D.new()
	shape.radius = _body_radius()
	shape.height = _body_height()
	collision.shape = shape
	collision.position = Vector2(0, _body_offset_y())
	add_child(collision)

func _create_hurtbox() -> void:
	hurtbox = HurtboxScript.new() as RealtimeHurtbox
	hurtbox.name = _hurtbox_name()
	hurtbox.receiver = self
	hurtbox.collision_layer = 8
	hurtbox.collision_mask = 0
	hurtbox.monitoring = false
	hurtbox.monitorable = true
	var collision := CollisionShape2D.new()
	collision.name = "KsztaltTrafienia"
	var shape := CapsuleShape2D.new()
	shape.radius = _hurtbox_radius()
	shape.height = _hurtbox_height()
	collision.shape = shape
	collision.position = Vector2(0, _hurtbox_offset_y())
	hurtbox.add_child(collision)
	add_child(hurtbox)

func _draw() -> void:
	if dead:
		return
	var bar_rect := _health_bar_rect()
	draw_rect(bar_rect.grow(2.0), Color("#171713dd"), true)
	draw_rect(bar_rect, Color("#592c27"), true)
	draw_rect(Rect2(bar_rect.position, Vector2(bar_rect.size.x * float(health) / max_health, bar_rect.size.y)), Color("#bd493d"), true)
	draw_string(ThemeDB.fallback_font, _label_position(), "%s  •  LVL %d" % [_display_label(), level], HORIZONTAL_ALIGNMENT_CENTER, _label_width(), _label_font_size(), Color("#eee6d7"))

func _combatant_id() -> StringName: return &""
func _sprite_sheet() -> Texture2D: return null
func _sprite_name() -> StringName: return &"EnemySprite"
func _frame_size() -> Vector2i: return Vector2i(1, 1)
func _frame_anchor() -> Vector2: return Vector2.ZERO
func _sprite_scale() -> float: return 1.0
func _make_sprite_frames() -> SpriteFrames: return SpriteFrames.new()
func _move_speed() -> float: return 0.0
func _detection_range() -> float: return 0.0
func _bite_distance_pixels() -> float: return attack_range_pixels()
func _hit_tolerance() -> float: return 0.0
func _attack_cooldown() -> float: return 1.0
func _attack_hit_time() -> float: return 0.2
func _attack_duration() -> float: return 0.5
func _uses_defeat_animation() -> bool: return false
func _defeat_duration() -> float: return 0.0
func _fade_duration() -> float: return 0.3
func _death_drop_distance() -> float: return 0.0
func _enemy_hit_color() -> Color: return Color("#ff6058")
func _enemy_flash_in() -> float: return 0.05
func _enemy_flash_out() -> float: return 0.15
func _player_hit_color() -> Color: return Color("#ff756c")
func _player_flash_in() -> float: return 0.05
func _player_flash_out() -> float: return 0.15
func _shadow_segments() -> int: return 20
func _shadow_size() -> Vector2: return Vector2(24, 7)
func _shadow_color() -> Color: return Color(0.04, 0.04, 0.03, 0.3)
func _shadow_offset_y() -> float: return -2.0
func _body_radius() -> float: return 10.0
func _body_height() -> float: return 25.0
func _body_offset_y() -> float: return -10.0
func _hurtbox_name() -> StringName: return &"Hurtbox"
func _hurtbox_radius() -> float: return 18.0
func _hurtbox_height() -> float: return 38.0
func _hurtbox_offset_y() -> float: return -15.0
func _health_bar_rect() -> Rect2: return Rect2(-28, -64, 56, 6)
func _display_label() -> String: return "WRÓG"
func _label_position() -> Vector2: return Vector2(-47, -70)
func _label_width() -> float: return 94.0
func _label_font_size() -> int: return 10
