class_name WildDogEnemy
extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal attack_landed(damage: int)
signal defeated

const SPRITE_SHEET := preload("res://assets/animals/wild_emaciated_dog_sheet_v2_packed.png")
const HurtboxScript := preload("res://scripts/realtime_hurtbox.gd")
const CombatantConfigScript := preload("res://scripts/combatant_config.gd")
const FRAME_SIZE := Vector2i(512, 384)
const FRAME_ANCHOR := Vector2(230, 330)
const SPRITE_SCALE := 0.29
const MOVE_SPEED := 86.0
const DETECTION_RANGE := 380.0
const ATTACK_COOLDOWN := 1.15
const ATTACK_HIT_TIME := 0.31
const ATTACK_DURATION := 0.58

var player: Player
var active := false
var combat_config := CombatantConfigScript.enemy("park_dog")
var level := int(combat_config.level)
var max_health := int(combat_config.max_health)
var attack_damage := int(combat_config.attack)
var attack_range := int(combat_config.attack_range)
var xp_reward := int(combat_config.xp_reward)
var health := max_health
var sprite: AnimatedSprite2D
var hurtbox: RealtimeHurtbox
var attack_cooldown_left := 0.0
var attacking := false
var dead := false
var _flash_tween: Tween

func _ready() -> void:
	collision_layer = 1
	collision_mask = 1 | 2
	_create_shadow()
	_create_sprite()
	_create_body_collision()
	_create_hurtbox()
	queue_redraw()

func _physics_process(delta: float) -> void:
	attack_cooldown_left = maxf(0.0, attack_cooldown_left - delta)
	if dead or not active or player == null:
		velocity = Vector2.ZERO
		_play_if_needed("idle")
		return
	if attacking:
		velocity = Vector2.ZERO
		return
	var to_player := player.global_position - global_position
	var distance := to_player.length()
	if distance <= attack_range_pixels() and attack_cooldown_left <= 0.0:
		_start_bite()
		return
	if distance <= DETECTION_RANGE:
		velocity = to_player.normalized() * MOVE_SPEED
		_update_facing(to_player.x)
		_play_if_needed("walk")
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		_play_if_needed("idle")

func receive_realtime_hit(damage: int, source_position: Vector2) -> void:
	if dead:
		return
	health = maxi(0, health - damage)
	health_changed.emit(health, max_health)
	queue_redraw()
	_update_facing(source_position.x - global_position.x)
	_flash_hit()
	if health <= 0:
		_die()

func _start_bite() -> void:
	attacking = true
	velocity = Vector2.ZERO
	_update_facing(player.global_position.x - global_position.x)
	sprite.play("attack")
	_run_bite()

func _run_bite() -> void:
	await get_tree().create_timer(ATTACK_HIT_TIME).timeout
	if dead or not attacking:
		return
	if player != null and global_position.distance_to(player.global_position) <= attack_range_pixels() + 22.0:
		attack_landed.emit(attack_damage)
		var player_tween := player.create_tween()
		player_tween.tween_property(player, "modulate", Color("#ff756c"), 0.06)
		player_tween.tween_property(player, "modulate", Color.WHITE, 0.17)
	await get_tree().create_timer(ATTACK_DURATION - ATTACK_HIT_TIME).timeout
	if dead:
		return
	attacking = false
	attack_cooldown_left = ATTACK_COOLDOWN
	_play_if_needed("idle")

func _die() -> void:
	dead = true
	active = false
	attacking = false
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
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.42)
	tween.tween_property(self, "position:y", position.y + 10.0, 0.42)
	await tween.finished
	queue_free()

func attack_range_pixels() -> float:
	return CombatantConfigScript.range_in_pixels(attack_range)

func _flash_hit() -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	modulate = Color.WHITE
	_flash_tween = create_tween()
	_flash_tween.tween_property(self, "modulate", Color("#ff6058"), 0.055)
	_flash_tween.tween_property(self, "modulate", Color.WHITE, 0.15)

func _update_facing(horizontal_delta: float) -> void:
	if absf(horizontal_delta) > 1.0:
		# Arkusz źródłowy patrzy w prawo.
		sprite.flip_h = horizontal_delta < 0.0

func _play_if_needed(animation_name: String) -> void:
	if sprite.animation != animation_name:
		sprite.play(animation_name)

func _create_sprite() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.name = "DzikiPiesSprite"
	sprite.sprite_frames = _make_sprite_frames()
	sprite.scale = Vector2.ONE * SPRITE_SCALE
	# W każdej przepakowanej klatce łapy mają ten sam punkt bazowy.
	sprite.offset = Vector2(FRAME_SIZE) * 0.5 - FRAME_ANCHOR
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(sprite)
	sprite.play("idle")

func _make_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	_add_animation_row(frames, "idle", 0, 3.0, true)
	_add_animation_row(frames, "walk", 1, 7.5, true)
	_add_animation_row(frames, "attack", 2, 7.0, false)
	return frames

func _add_animation_row(frames: SpriteFrames, animation_name: String, row: int, fps: float, looped: bool) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, looped)
	for column in range(4):
		var atlas := AtlasTexture.new()
		atlas.atlas = SPRITE_SHEET
		atlas.region = Rect2(column * FRAME_SIZE.x, row * FRAME_SIZE.y, FRAME_SIZE.x, FRAME_SIZE.y)
		frames.add_frame(animation_name, atlas)

func _create_shadow() -> void:
	var shadow := Polygon2D.new()
	shadow.name = "Cien"
	var points := PackedVector2Array()
	for index in range(24):
		var angle := TAU * float(index) / 24.0
		points.append(Vector2(cos(angle) * 43.0, sin(angle) * 11.0))
	shadow.polygon = points
	shadow.color = Color(0.04, 0.04, 0.03, 0.32)
	shadow.position = Vector2(0, -3)
	shadow.z_index = -1
	add_child(shadow)

func _create_body_collision() -> void:
	var collision := CollisionShape2D.new()
	collision.name = "KolizjaCiala"
	var shape := CapsuleShape2D.new()
	shape.radius = 17.0
	shape.height = 46.0
	collision.shape = shape
	collision.position = Vector2(0, -18)
	add_child(collision)

func _create_hurtbox() -> void:
	hurtbox = HurtboxScript.new() as RealtimeHurtbox
	hurtbox.name = "HurtboxPsa"
	hurtbox.receiver = self
	hurtbox.collision_layer = 8
	hurtbox.collision_mask = 0
	hurtbox.monitoring = false
	hurtbox.monitorable = true
	var collision := CollisionShape2D.new()
	collision.name = "KsztaltTrafienia"
	var shape := CapsuleShape2D.new()
	shape.radius = 28.0
	shape.height = 74.0
	collision.shape = shape
	collision.position = Vector2(0, -30)
	hurtbox.add_child(collision)
	add_child(hurtbox)

func _draw() -> void:
	if dead:
		return
	var bar_rect := Rect2(-34, -105, 68, 7)
	draw_rect(bar_rect.grow(2.0), Color("#171713dd"), true)
	draw_rect(bar_rect, Color("#592c27"), true)
	draw_rect(Rect2(bar_rect.position, Vector2(bar_rect.size.x * float(health) / max_health, bar_rect.size.y)), Color("#bd493d"), true)
	draw_string(ThemeDB.fallback_font, Vector2(-58, -112), "DZIKI PIES  •  LVL %d" % level, HORIZONTAL_ALIGNMENT_CENTER, 116, 11, Color("#eee6d7"))
