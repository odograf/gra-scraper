class_name WildDogEnemy
extends RealtimeEnemy

const SPRITE_SHEET := preload("res://assets/animals/wild_emaciated_dog_sheet_v2_packed.png")
const FRAME_SIZE := Vector2i(512, 384)
const FRAME_ANCHOR := Vector2(230, 330)
const SPRITE_SCALE := 0.29
const MOVE_SPEED := 86.0
const DETECTION_RANGE := 380.0
const ATTACK_COOLDOWN := 1.15
const ATTACK_HIT_TIME := 0.31
const ATTACK_DURATION := 0.58

func _combatant_id() -> StringName: return &"park_dog"
func _sprite_sheet() -> Texture2D: return SPRITE_SHEET
func _sprite_name() -> StringName: return &"DzikiPiesSprite"
func _frame_size() -> Vector2i: return FRAME_SIZE
func _frame_anchor() -> Vector2: return FRAME_ANCHOR
func _sprite_scale() -> float: return SPRITE_SCALE
func _move_speed() -> float: return MOVE_SPEED
func _detection_range() -> float: return DETECTION_RANGE
func _hit_tolerance() -> float: return 22.0
func _attack_cooldown() -> float: return ATTACK_COOLDOWN
func _attack_hit_time() -> float: return ATTACK_HIT_TIME
func _attack_duration() -> float: return ATTACK_DURATION
func _fade_duration() -> float: return 0.42
func _death_drop_distance() -> float: return 10.0
func _enemy_hit_color() -> Color: return Color("#ff6058")
func _enemy_flash_in() -> float: return 0.055
func _enemy_flash_out() -> float: return 0.15
func _player_hit_color() -> Color: return Color("#ff756c")
func _player_flash_in() -> float: return 0.06
func _player_flash_out() -> float: return 0.17
func _shadow_segments() -> int: return 24
func _shadow_size() -> Vector2: return Vector2(43, 11)
func _shadow_color() -> Color: return Color(0.04, 0.04, 0.03, 0.32)
func _shadow_offset_y() -> float: return -3.0
func _body_radius() -> float: return 17.0
func _body_height() -> float: return 46.0
func _body_offset_y() -> float: return -18.0
func _hurtbox_name() -> StringName: return &"HurtboxPsa"
func _hurtbox_radius() -> float: return 28.0
func _hurtbox_height() -> float: return 74.0
func _hurtbox_offset_y() -> float: return -30.0
func _health_bar_rect() -> Rect2: return Rect2(-34, -105, 68, 7)
func _display_label() -> String: return "DZIKI PIES"
func _label_position() -> Vector2: return Vector2(-58, -112)
func _label_width() -> float: return 116.0
func _label_font_size() -> int: return 11

func _make_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	_add_animation_row(frames, &"idle", 0, 3.0, true)
	_add_animation_row(frames, &"walk", 1, 7.5, true)
	_add_animation_row(frames, &"attack", 2, 7.0, false)
	return frames
