class_name SewerRatEnemy
extends RealtimeEnemy

const SPRITE_SHEET := preload("res://assets/animals/sewer_rat_sheet_v1.png")
const FRAME_SIZE := Vector2i(512, 384)
const FRAME_ANCHOR := Vector2(256, 330)
const SPRITE_SCALE := 0.29
const MOVE_SPEED := 105.0
const DETECTION_RANGE := 220.0
const BITE_DISTANCE := 48.0
const ATTACK_COOLDOWN := 1.60
const ATTACK_HIT_TIME := 0.38
const ATTACK_DURATION := 0.70
const DEFEAT_DURATION := 0.72

func _combatant_id() -> StringName: return &"sewer_rat"
func _sprite_sheet() -> Texture2D: return SPRITE_SHEET
func _sprite_name() -> StringName: return &"SzczorSprite"
func _frame_size() -> Vector2i: return FRAME_SIZE
func _frame_anchor() -> Vector2: return FRAME_ANCHOR
func _sprite_scale() -> float: return SPRITE_SCALE
func _move_speed() -> float: return MOVE_SPEED
func _detection_range() -> float: return DETECTION_RANGE
func _bite_distance_pixels() -> float: return BITE_DISTANCE
func _hit_tolerance() -> float: return 14.0
func _attack_cooldown() -> float: return ATTACK_COOLDOWN
func _attack_hit_time() -> float: return ATTACK_HIT_TIME
func _attack_duration() -> float: return ATTACK_DURATION
func _uses_defeat_animation() -> bool: return true
func _defeat_duration() -> float: return DEFEAT_DURATION
func _fade_duration() -> float: return 0.30
func _enemy_hit_color() -> Color: return Color("#ff6b5f")
func _enemy_flash_in() -> float: return 0.05
func _enemy_flash_out() -> float: return 0.13
func _player_hit_color() -> Color: return Color("#ff8876")
func _player_flash_in() -> float: return 0.05
func _player_flash_out() -> float: return 0.15
func _health_bar_rect() -> Rect2: return Rect2(-28, -64, 56, 6)
func _display_label() -> String: return "SZCZÓR"
func _label_position() -> Vector2: return Vector2(-47, -70)
func _label_width() -> float: return 94.0
func _label_font_size() -> int: return 10

func _make_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	_add_animation_row(frames, &"idle", 0, 3.0, true)
	_add_animation_row(frames, &"walk", 1, 9.0, true)
	_add_animation_row(frames, &"attack", 2, 6.5, false)
	_add_animation_row(frames, &"defeat", 3, 5.5, false)
	return frames
